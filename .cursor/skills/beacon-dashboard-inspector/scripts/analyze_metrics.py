#!/usr/bin/env python3
"""
灯塔看板指标分析脚本。
输入：inspection_config.json + 各看板下载的 CSV 文件目录
输出：结构化 JSON，包含每个看板的指标值和异常列表

输出结构说明：
  每个看板的 "metrics" 数组包含该看板配置的【全部指标】，包括 status=="ok" 的正常指标。
  "alerts" 是超阈值指标子集（统一称「异常」）；handling_action / handling_reason 给出处理建议。
  "anomalies" / "expected_variations" 为兼容字段，分别对应 handling_action 为「立即排查」「建议观察」的子集。
  ⚠️ AI 在生成报告时，必须遍历 "metrics" 数组输出完整数据表格，不能只使用 alerts。

用法：
  --version 10.112.0603   仅分析指定版本（精确匹配 cClientVersionName 列）
  --version 全量          聚合所有版本（按小时桶合并，NDV 指标为估算值）
  不传 --version          报错提示，强制要求指定
"""
import json
import csv
import os
import sys
import glob
import argparse
import datetime as dt
import re
from collections import defaultdict
from datetime import datetime, timedelta
from typing import Optional

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from format_utils import is_rate_metric

# 分布看板快照文件路径，用于跨日环比
_DISTRIBUTION_SNAPSHOT_FILE = os.path.expanduser(
    "~/.claude/skills/beacon-dashboard-inspector/runtime/distribution_snapshots.json"
)


def _load_distribution_snapshots() -> dict:
    if os.path.exists(_DISTRIBUTION_SNAPSHOT_FILE):
        with open(_DISTRIBUTION_SNAPSHOT_FILE, encoding="utf-8") as f:
            return json.load(f)
    return {}


def _save_distribution_snapshots(snapshots: dict):
    os.makedirs(os.path.dirname(_DISTRIBUTION_SNAPSHOT_FILE), exist_ok=True)
    with open(_DISTRIBUTION_SNAPSHOT_FILE, "w", encoding="utf-8") as f:
        json.dump(snapshots, f, ensure_ascii=False, indent=2)


def find_latest_csv(downloads_dir: str) -> Optional[str]:
    """在 downloads_dir 中找最新的 CSV 文件。"""
    pattern = os.path.join(downloads_dir, "*.csv")
    files = glob.glob(pattern)
    if not files:
        return None
    return max(files, key=os.path.getmtime)


def parse_csv_rows(csv_path: str) -> list:
    """解析 CSV，返回行列表。灯塔 CSV 使用 UTF-8 with BOM。"""
    rows = []
    with open(csv_path, encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows


def find_column(headers: list, keyword: str) -> Optional[str]:
    """按关键词模糊匹配列名（不区分大小写）。"""
    keyword_lower = keyword.lower()
    for h in headers:
        if keyword_lower in h.lower():
            return h
    return None


def find_version_column(headers: list) -> Optional[str]:
    """识别版本列（常见名称：cClientVersionName、版本、version、dim_1、客户端 VersionName 等）。"""
    for candidate in ["cClientVersionName", "VersionName", "版本号", "版本", "version", "clientversion", "client_version", "dim_1"]:
        col = find_column(headers, candidate)
        if col:
            return col
    return None


def find_date_column(headers: list) -> Optional[str]:
    """识别日期列（常见名称：日期、date、时间、dim_0、event_time 等）。"""
    for candidate in ["日期", "date", "时间", "event_time", "统计日期", "stat_date", "dim_0"]:
        col = find_column(headers, candidate)
        if col:
            return col
    return None


_HOUR_BUCKET_RE = re.compile(r"^\d{4}-\d{2}-\d{2} \d{1,2}$")


_DATE_FMTS = [
    "%Y-%m-%d %H:%M:%S",
    "%Y-%m-%d %H:%M",
    "%Y-%m-%d %H",
    "%Y-%m-%d",
    "%Y/%m/%d",
    "%Y%m%d",
]


def format_hour_bucket(dt_val: datetime) -> str:
    """灯塔小时粒度 dim_0 常见格式：YYYY-MM-DD H"""
    return f"{dt_val.strftime('%Y-%m-%d')} {dt_val.hour}"


def parse_row_datetime(date_str: str) -> Optional[datetime]:
    """解析灯塔 CSV 中的日期或日期时间字符串。"""
    if not date_str or not str(date_str).strip():
        return None
    s = str(date_str).strip()
    m = _HOUR_BUCKET_RE.match(s)
    if m:
        day, hour = s.rsplit(" ", 1)
        try:
            return datetime.strptime(f"{day} {int(hour):02d}", "%Y-%m-%d %H")
        except ValueError:
            return None
    for fmt in _DATE_FMTS:
        try:
            if fmt == "%Y-%m-%d %H":
                continue
            length = 19 if " %H:%M:%S" in fmt else (16 if " %H:%M" in fmt else len(s))
            return datetime.strptime(s[:length], fmt)
        except ValueError:
            continue
    return None


def detect_hour_granularity(rows: list, date_col: str) -> bool:
    """CSV 时间列是否为小时粒度（纯 YYYY-MM-DD 日粒度返回 False）。"""
    hour_like = 0
    day_only = 0
    for row in rows[:100]:
        s = str(row.get(date_col, "")).strip()
        if not s:
            continue
        if _HOUR_BUCKET_RE.match(s):
            hour_like += 1
            continue
        if re.match(r"^\d{4}-\d{2}-\d{2}$", s):
            day_only += 1
            continue
        dt_val = parse_row_datetime(s)
        if not dt_val:
            continue
        if dt_val.hour != 0 or dt_val.minute != 0:
            hour_like += 1
        elif " " in s and ":" in s:
            hour_like += 1
        else:
            day_only += 1
    if day_only > 0 and hour_like == 0:
        return False
    return hour_like > 0


def hour_granularity_error(
    rows: list, date_col: str, dashboard_name: str = "", *, source: str = ""
) -> Optional[str]:
    """非小时粒度时返回可操作的报错文案，否则 None。"""
    if detect_hour_granularity(rows, date_col):
        return None
    samples = []
    for row in rows[:8]:
        v = str(row.get(date_col, "")).strip()
        if v and v not in samples:
            samples.append(v)
    sample_txt = "、".join(samples[:3]) if samples else "（空）"
    who = f"看板「{dashboard_name}」" if dashboard_name else "该看板"
    src = f"（{source}）" if source else ""
    return (
        f"{who}{src} CSV 为日粒度或非小时格式（时间列示例：{sample_txt}）。"
        f"请在灯塔将该看板改为「小时」粒度 + 相对时间 12 小时后再巡检；"
        f"版本专项仍在 Panel 114739，全量在 Panel 114800。"
    )


def filter_rows_for_analysis(
    rows: list,
    headers: list,
    version: str,
) -> list:
    """版本过滤；保留 hourly 行并按小时桶合并。"""
    version_col = find_version_column(headers)
    date_col = find_date_column(headers)

    if version != "全量" and version_col:
        rows = [r for r in rows if r.get(version_col, "").strip() == version]

    if not date_col:
        return rows

    buckets: dict = defaultdict(list)
    for row in rows:
        dt_val = parse_row_datetime(row.get(date_col, ""))
        if not dt_val:
            continue
        slot = dt_val.replace(minute=0, second=0, microsecond=0)
        buckets[slot].append(row)

    if not buckets:
        return rows

    merged = []
    for slot in sorted(buckets):
        summed = _sum_metric_rows(buckets[slot], headers)
        summed[date_col] = format_hour_bucket(slot)
        merged.append(summed)
    return merged


def select_same_period_12h(
    rows: list,
    headers: list,
    date_col: str,
    *,
    reference_now: Optional[datetime] = None,
    lookback_hours: int = 12,
    dashboard_name: str = "",
    source: str = "",
) -> dict:
    """
    同时段对比：聚合今日与昨日相同小时窗口（默认近 12 小时，截至当前整点）。
    例：当前 10:00 → 对比今日 00:00~10:00 合计 vs 昨日 00:00~10:00 合计。
    """
    reference_now = reference_now or datetime.now()
    calendar_today = reference_now.date()
    calendar_yesterday = calendar_today - timedelta(days=1)
    cutoff_hour = reference_now.hour

    granularity_err = hour_granularity_error(
        rows, date_col, dashboard_name, source=source
    )
    if granularity_err:
        return {"error": granularity_err}

    parsed = []
    for row in rows:
        dt_val = parse_row_datetime(row.get(date_col, ""))
        if dt_val:
            parsed.append(
                (dt_val.replace(minute=0, second=0, microsecond=0), row)
            )
    if not parsed:
        return {"error": "无法解析小时时间列"}

    by_slot: dict = defaultdict(list)
    for t, row in parsed:
        by_slot[t].append(row)

    hour_lo = max(0, cutoff_hour - lookback_hours + 1)
    hour_hi = cutoff_hour
    target_hours = list(range(hour_lo, hour_hi + 1))
    actual_window = len(target_hours)

    def collect_period(target_date: dt.date):
        slot_rows = []
        matched_hours = []
        for h in target_hours:
            slot = datetime(target_date.year, target_date.month, target_date.day, h)
            if slot in by_slot:
                matched_hours.append(h)
                slot_rows.extend(by_slot[slot])
        if not slot_rows:
            return None, None, matched_hours
        label = datetime.combine(target_date, datetime.min.time())
        return label, _sum_metric_rows(slot_rows, headers), matched_hours

    _, today_row, today_hours = collect_period(calendar_today)
    _, yest_row, yest_hours = collect_period(calendar_yesterday)

    if not today_row:
        return {
            "error": (
                f"今日（{calendar_today}）在 {hour_lo:02d}:00~{hour_hi:02d}:59 "
                f"无小时数据，无法同时段对比"
            ),
        }
    if not yest_row:
        # 12h 相对时间窗口常只覆盖「昨日尾段 + 今日段」，回退为窗口内按日聚合
        today_all = [r for t, r in parsed if t.date() == calendar_today]
        yest_all = [r for t, r in parsed if t.date() == calendar_yesterday]
        if today_all and yest_all:
            slot_label = f"近{lookback_hours}h抓取窗口"
            return {
                "today_date": datetime.combine(calendar_today, datetime.min.time()),
                "today_row": _sum_metric_rows(today_all, headers),
                "yesterday_date": datetime.combine(calendar_yesterday, datetime.min.time()),
                "yesterday_row": _sum_metric_rows(yest_all, headers),
                "comparison_mode": "same_period",
                "data_granularity": "hour",
                "lookback_hours": lookback_hours,
                "same_period_cutoff": slot_label,
                "comparison_note": (
                    f"同时段对比（抓取近 {lookback_hours}h 窗口）："
                    f"今日段 {calendar_today}（{len(today_all)} 小时点）vs "
                    f"昨日段 {calendar_yesterday}（{len(yest_all)} 小时点）；"
                    f"窗口内小时段不完全对齐，建议看板相对时间改为 ≥24h 以严格同时段"
                ),
            }
        return {
            "error": (
                f"昨日（{calendar_yesterday}）在 {hour_lo:02d}:00~{hour_hi:02d}:59 "
                f"无小时数据；请确认看板抓取窗口覆盖昨日同时段（建议相对时间 ≥24 小时）"
            ),
        }

    common_hours = sorted(set(today_hours) & set(yest_hours))
    slot_label = f"{hour_lo:02d}:00~{hour_hi:02d}:59"
    return {
        "today_date": datetime.combine(calendar_today, datetime.min.time()),
        "today_row": today_row,
        "yesterday_date": datetime.combine(calendar_yesterday, datetime.min.time()),
        "yesterday_row": yest_row,
        "comparison_mode": "same_period",
        "data_granularity": "hour",
        "lookback_hours": actual_window,
        "same_period_cutoff": slot_label,
        "same_period_hours_matched": len(common_hours),
        "comparison_note": (
            f"同时段对比：聚合近 {actual_window} 小时（{slot_label}）"
            f"今日 {calendar_today} vs 昨日 {calendar_yesterday}；"
            f"匹配 {len(common_hours)}/{actual_window} 个小时点"
        ),
    }


def parse_date(date_str: str) -> Optional[datetime]:
    """解析灯塔常见日期格式（兼容旧调用）。"""
    return parse_row_datetime(date_str)


def _sum_metric_rows(rows: list, headers: list) -> dict:
    """合并同一自然日多行（如小时粒度）的数值列。"""
    if not rows:
        return {}
    if len(rows) == 1:
        return dict(rows[0])
    date_col = find_date_column(headers)
    version_col = find_version_column(headers)
    skip_cols = {c for c in (date_col, version_col) if c}
    totals = {}
    for row in rows:
        for col in headers:
            if col in skip_cols:
                continue
            val = parse_number(row.get(col, ""))
            if val is not None:
                totals[col] = totals.get(col, 0.0) + val
    merged = dict(rows[-1])
    for col, val in totals.items():
        merged[col] = str(val)
    return merged


def select_comparison_dates(
    rows: list,
    headers: list,
    date_col: str,
    *,
    reference_now: Optional[datetime] = None,
    lookback_hours: int = 12,
    dashboard_name: str = "",
    source: str = "",
) -> dict:
    """同时段对比：聚合近 lookback_hours 小时，对比今日 vs 昨日同时段。"""
    return select_same_period_12h(
        rows,
        headers,
        date_col,
        reference_now=reference_now,
        lookback_hours=lookback_hours,
        dashboard_name=dashboard_name,
        source=source,
    )


def parse_number(value_str: str) -> Optional[float]:
    """解析数值字符串，处理 %, 万, 亿 等单位。"""
    if not value_str or value_str.strip() in ("", "-", "N/A", "null"):
        return None
    s = value_str.strip()
    multiplier = 1.0
    if s.endswith("%"):
        s = s[:-1]
        # 百分比以小数形式存储
    elif s.endswith("亿"):
        s = s[:-1]
        multiplier = 1e8
    elif s.endswith("万"):
        s = s[:-1]
        multiplier = 1e4
    s = s.replace(",", "").replace("，", "")
    try:
        return float(s) * multiplier
    except ValueError:
        return None


def compute_change_pct(today_val: float, yesterday_val: float) -> Optional[float]:
    """计算环比变化百分点（正数=增长，负数=下降）。"""
    if yesterday_val == 0:
        return None
    return (today_val - yesterday_val) / abs(yesterday_val) * 100


def detect_expected_variation(metric_cfg: dict, today_val: Optional[float],
                               yesterday_val: Optional[float],
                               change_pct: Optional[float]) -> Optional[dict]:
    """
    检测超阈值的波动是否属于已知的合理原因，返回 {type, reason} 或 None。

    两类自动识别规则：
    1. version_expansion：aggregation 含 isLatestApp，且变化为正增长
       → 新版本扩量导致的自然增长，非业务异常
    2. small_sample：today 和 yesterday 均低于 small_count_threshold
       → 绝对值过小，百分比噪音大，不具统计意义
    """
    if change_pct is None:
        return None

    aggregation = metric_cfg.get("aggregation", "")
    small_count_threshold = metric_cfg.get("small_count_threshold", None)

    # 规则 1：isLatestApp 新口径指标 + 正向增长 → 版本扩量
    if "isLatestApp" in aggregation and change_pct > 0:
        return {
            "type": "version_expansion",
            "reason": "isLatestApp 口径随新版推量自然增长，非业务异常",
        }

    # 规则 2：小样本 — 需要 metric_cfg 中配置 small_count_threshold
    if small_count_threshold is not None:
        max_val = max(today_val or 0, yesterday_val or 0)
        if max_val <= small_count_threshold:
            return {
                "type": "small_sample",
                "reason": (
                    "绝对值极小（今 {:.0f} / 昨 {:.0f}），百分比波动不具统计意义".format(
                        today_val or 0, yesterday_val or 0
                    )
                ),
            }

    return None


ERROR_KEYWORDS = ("报错", "失败", "错误", "异常人数", "中断")
UPDATE_KEYWORDS = ("更新", "弹窗", "接受", "安装")


def _metric_cfg_from_entry(entry: dict) -> dict:
    return {
        "aggregation": entry.get("aggregation", ""),
        "small_count_threshold": entry.get("small_count_threshold"),
        "event_code": str(entry.get("event_code", "")),
        "threshold_pct": entry.get("threshold_pct", 10),
    }


def classify_handling_advice(
    metric_cfg: dict,
    display_name: str,
    today_val: Optional[float],
    yesterday_val: Optional[float],
    change_pct: Optional[float],
    variation_info: Optional[dict],
    version_data: Optional[dict] = None,
    all_data: Optional[dict] = None,
) -> dict:
    """
    对超阈值指标给出处理建议。
    返回 {action: '立即排查'|'建议观察', reason: str}
    """
    if variation_info:
        return {
            "action": "建议观察",
            "reason": variation_info["reason"],
        }

    name = display_name

    # 率值下滑 → 立即排查
    if is_rate_metric(name) and change_pct is not None and change_pct < 0:
        reason = f"率值环比下滑 {abs(change_pct):.1f}%"
        if today_val is not None and yesterday_val is not None:
            if abs(today_val) <= 1 and abs(yesterday_val) <= 1:
                pp = (today_val - yesterday_val) * 100
                reason = f"率值降 {abs(pp):.1f}pp"
            elif max(abs(today_val), abs(yesterday_val)) <= 100:
                pp = today_val - yesterday_val
                if abs(pp) >= 0.5:
                    reason = f"率值降 {abs(pp):.1f}pp"
        return {"action": "立即排查", "reason": reason}

    # 报错/失败类上升 → 立即排查
    if any(kw in name for kw in ERROR_KEYWORDS) and change_pct is not None and change_pct > 0:
        return {
            "action": "立即排查",
            "reason": f"报错/失败量升 {change_pct:.1f}%，需核对成功率",
        }

    event = str(metric_cfg.get("event_code", ""))
    if event in ("20006", "20007", "20008") and change_pct is not None and change_pct > 0:
        return {"action": "建议观察", "reason": "发版推量上行，符合预期"}

    aggregation = metric_cfg.get("aggregation", "")
    if "isLatestApp" in aggregation and change_pct is not None and change_pct > 0:
        return {"action": "建议观察", "reason": "新版推量上行，符合预期"}

    if any(kw in name for kw in UPDATE_KEYWORDS) and change_pct is not None and change_pct > 0:
        return {"action": "建议观察", "reason": "版本推送期指标上行，属预期行为"}

    # 版本与全量同向超阈值 → 周期/基数效应
    if version_data and all_data:
        v_pct = version_data.get("change_pct")
        a_pct = all_data.get("change_pct")
        th = metric_cfg.get("threshold_pct", 10)
        if v_pct is not None and a_pct is not None:
            same_dir = (v_pct > 0) == (a_pct > 0)
            either_over = abs(v_pct) > th or abs(a_pct) > th
            both_material = abs(v_pct) >= th * 0.8 and abs(a_pct) >= th * 0.8
            if same_dir and either_over and both_material:
                if not is_rate_metric(name):
                    return {
                        "action": "建议观察",
                        "reason": "版本与全量同向波动，疑为周期/基数效应",
                    }

    if any(kw in name for kw in ("观战", "播放", "视频")) and change_pct is not None and change_pct < 0:
        if not is_rate_metric(name):
            return {"action": "建议观察", "reason": "内容消费工作日回落，属周期规律"}

    if "注册" in name and change_pct is not None and change_pct < 0 and not is_rate_metric(name):
        return {"action": "建议观察", "reason": "注册量下行，需结合完成率综合判断"}

    return {"action": "立即排查", "reason": "环比超阈值，暂无已知合理解释"}


def _attach_handling_advice(
    entry: dict,
    metric_cfg: dict,
    variation_info: Optional[dict],
    version_data: Optional[dict] = None,
    all_data: Optional[dict] = None,
) -> None:
    """写入 handling_action / handling_reason；保留 variation 字段供溯源。"""
    today_val = entry.get("today")
    yesterday_val = entry.get("yesterday")
    change_pct = entry.get("change_pct")
    if today_val is None and version_data:
        today_val = version_data.get("today")
        yesterday_val = version_data.get("yesterday")
        change_pct = version_data.get("change_pct")
    if change_pct is None and all_data:
        change_pct = all_data.get("change_pct")
    if today_val is None and all_data:
        today_val = all_data.get("today")
        yesterday_val = all_data.get("yesterday")
    advice = classify_handling_advice(
        metric_cfg,
        entry["name"],
        today_val,
        yesterday_val,
        change_pct,
        variation_info,
        version_data,
        all_data,
    )
    entry["handling_action"] = advice["action"]
    entry["handling_reason"] = advice["reason"]
    if variation_info:
        entry["variation_type"] = variation_info["type"]
        entry["variation_reason"] = variation_info["reason"]


def build_column_rename_map(csv_dir: str) -> dict:
    """
    从同目录的 api_responses_*.json 中读取 result_desc，
    构建 {index_N: 中文列名} 的重命名映射。
    """
    rename_map = {}
    api_files = glob.glob(os.path.join(csv_dir, "api_responses_*.json"))
    if not api_files:
        return rename_map
    api_file = max(api_files, key=os.path.getmtime)
    try:
        data = json.load(open(api_file, encoding="utf-8"))
        for item in data:
            result = item.get("data", {}).get("result", {})
            if not isinstance(result, dict):
                continue
            desc_list = result.get("result_desc", [])
            if not desc_list:
                continue
            for desc in desc_list:
                key = desc.get("key", "")
                title = desc.get("title", "")
                if key and title and key != title:
                    rename_map[key] = title
            if rename_map:
                break
    except Exception:
        pass
    return rename_map


def apply_rename_map(rows: list, rename_map: dict) -> list:
    """将 rows 中的列名按 rename_map 重命名（index_N → 中文名）。"""
    if not rename_map or not rows:
        return rows
    new_rows = []
    for row in rows:
        new_row = {}
        for k, v in row.items():
            new_row[rename_map.get(k, k)] = v
        new_rows.append(new_row)
    return new_rows


def _status_priority(status: str) -> int:
    """数值越大越严重，用于取「更严重」状态。"""
    return {
        "alert": 2,
        "anomaly": 2,
        "expected_variation": 2,
        "ok": 0,
        "missing": 0,
        "missing_column": -1,
    }.get(status, 0)


def _extract_data_fields(metric: Optional[dict]) -> dict:
    """从指标 entry 中抽取数值型字段，生成 version_data / all_data 子对象。
    强制包含 today / yesterday / change_pct 三个必填字段（缺失时为 None）。"""
    if metric is None:
        return {"today": None, "yesterday": None, "change_pct": None, "status": "missing"}
    optional_keys = (
        "today_date", "yesterday_date", "status",
        "variation_type", "variation_reason",
        "handling_action", "handling_reason",
    )
    result = {
        "today": metric.get("today"),
        "yesterday": metric.get("yesterday"),
        "change_pct": metric.get("change_pct"),
    }
    for k in optional_keys:
        if k in metric:
            result[k] = metric[k]
    return result


def merge_dual_dashboard_results(version_result: dict, all_result: dict) -> dict:
    """
    将指定版本分析结果与全量分析结果合并。
    每个指标强制输出 version_data 和 all_data 两个子对象，
    各自必含 today / yesterday / change_pct 三个字段（缺失时为 None）。
    指标集取两侧的并集，确保每条指标无论数据是否取到都会出现在结果中。
    """
    version_metrics_map = {m["name"]: m for m in version_result.get("metrics", [])}
    all_metrics_map = {m["name"]: m for m in all_result.get("metrics", [])}

    # 取并集：以配置顺序（version 侧优先，再补充 all 侧独有）
    all_names = list(version_metrics_map.keys())
    for name in all_metrics_map:
        if name not in version_metrics_map:
            all_names.append(name)

    merged_metrics = []
    alerts = []
    anomalies = []
    expected_variations = []

    for name in all_names:
        v_metric = version_metrics_map.get(name)
        a_metric = all_metrics_map.get(name)

        # 强制 6 列：version_data 和 all_data 各含 today/yesterday/change_pct
        version_data = _extract_data_fields(v_metric)
        all_data = _extract_data_fields(a_metric)

        v_status = v_metric.get("status", "missing") if v_metric else "missing"
        a_status = a_metric.get("status", "missing") if a_metric else "missing"
        alert_sides = ("alert", "anomaly", "expected_variation")
        if v_status in alert_sides or a_status in alert_sides:
            overall_status = "alert"
        elif _status_priority(v_status) >= _status_priority(a_status):
            overall_status = v_status
        else:
            overall_status = a_status

        # 优先从 version 侧取 metadata，fallback 到 all 侧
        ref_metric = v_metric or a_metric
        merged = {
            "name": name,
            "column": ref_metric.get("column") if ref_metric else None,
            "threshold_pct": ref_metric.get("threshold_pct") if ref_metric else None,
            "status": overall_status,
            "version_data": version_data,
            "all_data": all_data,
        }
        for meta_key in (
            "event_code", "enum_name", "report_location", "aggregation", "meaning",
            "small_count_threshold", "variation_type", "variation_reason",
            "handling_action", "handling_reason",
        ):
            if v_metric and meta_key in v_metric:
                merged[meta_key] = v_metric[meta_key]
            elif a_metric and meta_key in a_metric:
                merged[meta_key] = a_metric[meta_key]

        if overall_status == "alert" and ref_metric:
            trigger = v_metric if v_metric and v_metric.get("status") in alert_sides else a_metric
            if not trigger or trigger.get("status") not in alert_sides:
                trigger = a_metric if a_metric and a_metric.get("status") in alert_sides else v_metric
            variation_info = None
            if trigger:
                if trigger.get("variation_type"):
                    variation_info = {
                        "type": trigger["variation_type"],
                        "reason": trigger.get("variation_reason", ""),
                    }
                else:
                    variation_info = detect_expected_variation(
                        _metric_cfg_from_entry(trigger),
                        trigger.get("today"),
                        trigger.get("yesterday"),
                        trigger.get("change_pct"),
                    )
            _attach_handling_advice(
                merged,
                _metric_cfg_from_entry(ref_metric),
                variation_info,
                version_data,
                all_data,
            )
            # merge 侧无 today/yesterday 顶层字段，用 version 侧主口径
            merged["change_pct"] = version_data.get("change_pct") or all_data.get("change_pct")

        merged_metrics.append(merged)
        if overall_status == "alert":
            alerts.append(merged)
            if merged.get("handling_action") == "立即排查":
                anomalies.append(merged)
            else:
                expected_variations.append(merged)

    merged = {
        "dashboard_name": version_result.get("dashboard_name") or all_result.get("dashboard_name", ""),
        "version": version_result.get("version") or all_result.get("version", ""),
        "has_version_comparison": True,
        "csv_path": version_result.get("csv_path") or all_result.get("csv_path"),
        "metrics": merged_metrics,
        "alerts": alerts,
        "anomalies": anomalies,
        "expected_variations": expected_variations,
    }
    for key in (
        "comparison_mode", "comparison_note", "data_lag_days",
        "data_granularity", "same_period_cutoff", "today_partial",
    ):
        if version_result.get(key) is not None:
            merged[key] = version_result[key]
    return merged


def _analyze_distribution_dashboard(dashboard_cfg: dict, csv_path: str, version: str,
                                     top_n: int = 3, all_csv_path: str = None) -> dict:
    """
    分布看板专用分析：无日期维度，按 dim_0（OS版本/机型）聚合后取 Top N。
    - version 侧：过滤 dim_1 == version，按 index_0 降序取 Top N
    - all 侧：all_csv_path（url_all CSV）若存在则用其所有行；否则用 csv_path 的所有行
    返回结构与普通看板兼容（metrics 数组），status 固定为 "ok"，不触发异常。
    """
    rows = parse_csv_rows(csv_path)
    if not rows:
        return {
            "dashboard_name": dashboard_cfg["name"],
            "version": version,
            "is_distribution": True,
            "error": "CSV 为空",
            "metrics": [], "anomalies": [], "expected_variations": [],
        }

    # 应用列名映射
    csv_dir = os.path.dirname(csv_path)
    rename_map = build_column_rename_map(csv_dir)
    if rename_map:
        rows = apply_rename_map(rows, rename_map)

    headers = list(rows[0].keys())

    # 找 dim_0（维度列）、dim_1（版本列）、metric 列（index_0 或配置的 column_keyword）
    dim0_col = find_column(headers, "dim_0") or headers[0]
    version_col = find_version_column(headers)

    # 找指标列（取第一个配置的 metric，或默认 index_0）
    metric_cfgs = dashboard_cfg.get("metrics", [])
    if metric_cfgs:
        metric_col = find_column(headers, metric_cfgs[0]["column_keyword"])
        display_name = metric_cfgs[0]["display_name"]
    else:
        metric_col = find_column(headers, "index_0")
        display_name = "数值"

    if not metric_col:
        # 找第一个数字列
        for h in headers:
            if h not in (dim0_col, version_col or ""):
                metric_col = h
                break

    def get_val(row):
        return parse_number(row.get(metric_col, "")) or 0

    # version 侧：过滤指定版本
    if version and version != "全量" and version_col:
        version_rows = [r for r in rows if r.get(version_col, "").strip() == version.strip()]
    else:
        version_rows = rows

    # 按 dim_0 聚合 version 侧
    ver_agg = defaultdict(float)
    for r in version_rows:
        dim_val = r.get(dim0_col, "").strip()
        if dim_val:
            ver_agg[dim_val] += get_val(r)
    ver_top = sorted(ver_agg.items(), key=lambda x: x[1], reverse=True)[:top_n]

    # all 侧：对 version CSV 的所有行按 dim_0 聚合（包含所有 App 版本）
    all_agg = defaultdict(float)
    for r in rows:
        dim_val = r.get(dim0_col, "").strip()
        if dim_val:
            val = parse_number(r.get(metric_col, "")) or 0
            all_agg[dim_val] += val
    all_top = sorted(all_agg.items(), key=lambda x: x[1], reverse=True)[:top_n]

    # ── 快照对比（跨日环比） ──────────────────────────────────────────────
    # 用运行日期作为快照 key（T+1 特性：今天运行拿到的是昨天的数据）
    today_key = dt.date.today().strftime("%Y-%m-%d")
    yesterday_key = (dt.date.today() - dt.timedelta(days=1)).strftime("%Y-%m-%d")
    dashboard_key = dashboard_cfg["name"]

    snapshots = _load_distribution_snapshots()
    prev_ver = snapshots.get(dashboard_key, {}).get(yesterday_key)  # 昨天存的版本侧快照
    prev_all = snapshots.get(dashboard_key + "_all", {}).get(yesterday_key)  # 昨天存的全量侧快照

    # 存今天的快照（版本侧 + 全量侧）
    snapshots.setdefault(dashboard_key, {})[today_key] = dict(ver_agg)
    snapshots.setdefault(dashboard_key + "_all", {})[today_key] = dict(all_agg)
    # 只保留最近 7 天快照
    for key in (dashboard_key, dashboard_key + "_all"):
        old_dates = sorted(snapshots[key].keys())[:-7]
        for d in old_dates:
            del snapshots[key][d]
    _save_distribution_snapshots(snapshots)
    # ────────────────────────────────────────────────────────────────────────

    def _change(today_val, prev_snapshot, dim_val, threshold_pct):
        """计算与昨日快照的环比，返回 (yesterday_val, change_pct, status)。"""
        if prev_snapshot is None or dim_val not in prev_snapshot:
            return None, None, "ok"
        yest = prev_snapshot[dim_val]
        if not yest:
            return yest, None, "ok"
        pct = (today_val - yest) / yest * 100
        status = "anomaly" if abs(pct) >= threshold_pct else "ok"
        return yest, round(pct, 2), status

    # 组装 metrics：每个 Top N 条目作为一行
    metrics = []
    all_dict = dict(all_agg)
    threshold_pct = (metric_cfgs[0].get("threshold_pct", 15) if metric_cfgs else 15)

    for rank, (dim_val, ver_val) in enumerate(ver_top, 1):
        all_val = all_dict.get(dim_val)
        ver_yest, ver_chg, ver_status = _change(ver_val, prev_ver, dim_val, threshold_pct)
        all_yest, all_chg, all_status = _change(all_val, prev_all, dim_val, threshold_pct) if all_val else (None, None, "ok")
        overall_status = ver_status if ver_status == "anomaly" or all_status != "anomaly" else all_status
        metrics.append({
            "name": f"Top{rank} {dim_val}",
            "is_distribution_row": True,
            "dim_value": dim_val,
            "rank": rank,
            "status": overall_status,
            "threshold_pct": threshold_pct,
            "version_data": {
                "today": ver_val,
                "yesterday": ver_yest,
                "change_pct": ver_chg,
                "status": ver_status,
            },
            "all_data": {
                "today": all_val,
                "yesterday": all_yest,
                "change_pct": all_chg,
                "status": all_status,
            },
            "display_name": display_name,
        })

    # 补充 all 侧独有的 Top N（版本侧没有的维度）
    all_top_dims = [d for d, _ in all_top]
    ver_top_dims = [d for d, _ in ver_top]
    for dim_val in all_top_dims:
        if dim_val not in ver_top_dims:
            all_val = all_dict.get(dim_val, 0)
            rank = all_top_dims.index(dim_val) + 1
            all_yest, all_chg, all_status = _change(all_val, prev_all, dim_val, threshold_pct)
            metrics.append({
                "name": f"Top{rank}(全量) {dim_val}",
                "is_distribution_row": True,
                "dim_value": dim_val,
                "rank": rank,
                "status": all_status,
                "threshold_pct": threshold_pct,
                "version_data": {
                    "today": None, "yesterday": None, "change_pct": None, "status": "ok",
                },
                "all_data": {
                    "today": all_val,
                    "yesterday": all_yest,
                    "change_pct": all_chg,
                    "status": all_status,
                },
                "display_name": display_name,
            })

    anomalies = [m for m in metrics if m.get("status") == "anomaly"]
    has_prev = prev_ver is not None

    return {
        "dashboard_name": dashboard_cfg["name"],
        "version": version,
        "is_distribution": True,
        "has_version_comparison": True,
        "note": f"分布快照 Top{top_n}（dim_0 = {dim0_col}，{'含跨日环比' if has_prev else '首次运行无历史快照，环比为空'}）",
        "metrics": metrics,
        "anomalies": anomalies,
        "expected_variations": [],
    }


def analyze_dashboard(
    dashboard_cfg: dict,
    csv_path: str,
    version: str,
    comparison_settings: Optional[dict] = None,
    *,
    source: str = "",
) -> dict:
    """分析单个看板的 CSV，返回指标数据和异常列表。"""
    comparison_settings = comparison_settings or {}
    lookback_hours = int(comparison_settings.get("lookback_hours", 12))
    dashboard_name = dashboard_cfg["name"]

    # 分布看板（is_distribution=true）：无日期维度，取 Top 3 维度值展示
    if dashboard_cfg.get("is_distribution"):
        return _analyze_distribution_dashboard(dashboard_cfg, csv_path, version)

    rows = parse_csv_rows(csv_path)
    if not rows:
        return {"dashboard_name": dashboard_cfg["name"], "error": "CSV 为空", "metrics": [], "anomalies": [], "expected_variations": []}

    # 尝试从 api_responses 读取列名映射，将 index_N 重命名为中文名
    csv_dir = os.path.dirname(csv_path)
    rename_map = build_column_rename_map(csv_dir)
    if rename_map:
        rows = apply_rename_map(rows, rename_map)

    headers = list(rows[0].keys())

    rows = filter_rows_for_analysis(rows, headers, version)
    if not rows:
        return {
            "dashboard_name": dashboard_cfg["name"],
            "error": f"版本 {version} 在此看板中无数据",
            "version": version,
            "metrics": [], "anomalies": [], "expected_variations": [],
        }

    # 重新取 headers（聚合后行结构可能变化）
    headers = list(rows[0].keys())
    date_col = find_date_column(headers)

    if not date_col:
        return {
            "dashboard_name": dashboard_name,
            "error": (
                f"看板「{dashboard_name}」CSV 无时间列（dim_0/event_time），"
                f"无法做同时段对比；请确认灯塔看板已导出小时粒度数据"
            ),
            "version": version,
            "metrics": [], "anomalies": [], "expected_variations": [],
        }

    selection = select_comparison_dates(
        rows,
        headers,
        date_col,
        lookback_hours=lookback_hours,
        dashboard_name=dashboard_name,
        source=source,
    )
    if selection.get("error"):
        return {
            "dashboard_name": dashboard_name,
            "error": selection["error"],
            "metrics": [],
            "anomalies": [],
            "expected_variations": [],
        }

    today_date = selection.get("today_date")
    today_row = selection.get("today_row")
    yesterday_date = selection.get("yesterday_date")
    yesterday_row = selection.get("yesterday_row")
    comparison_mode = selection.get("comparison_mode")
    comparison_note = selection.get("comparison_note")

    metrics_result = []
    alerts = []
    anomalies = []
    expected_variations = []

    for metric_cfg in dashboard_cfg.get("metrics", []):
        keyword = metric_cfg["column_keyword"]
        display_name = metric_cfg["display_name"]
        threshold_pct = metric_cfg.get("threshold_pct", 10)

        col = find_column(headers, keyword)
        if not col:
            metrics_result.append({
                "name": display_name,
                "column": None,
                "today": None,
                "yesterday": None,
                "change_pct": None,
                "status": "missing_column",
                "note": "未找到含「{}」的列".format(keyword),
            })
            continue

        today_val = parse_number(today_row.get(col, ""))
        yesterday_val = parse_number(yesterday_row.get(col, "")) if yesterday_row else None

        change_pct = None
        status = "ok"
        variation_info = None

        if today_val is not None and yesterday_val is not None:
            change_pct = compute_change_pct(today_val, yesterday_val)
            if change_pct is not None and abs(change_pct) > threshold_pct:
                variation_info = detect_expected_variation(
                    metric_cfg, today_val, yesterday_val, change_pct
                )
                status = "alert"

        entry = {
            "name": display_name,
            "column": col,
            "today": today_val,
            "yesterday": yesterday_val,
            "change_pct": round(change_pct, 2) if change_pct is not None else None,
            "threshold_pct": threshold_pct,
            "status": status,
        }
        if status == "alert":
            _attach_handling_advice(entry, metric_cfg, variation_info)
        if variation_info and "variation_type" not in entry:
            entry["variation_type"] = variation_info["type"]
            entry["variation_reason"] = variation_info["reason"]
        if today_date:
            entry["today_date"] = today_date.strftime("%Y-%m-%d")
        if yesterday_date:
            entry["yesterday_date"] = yesterday_date.strftime("%Y-%m-%d")

        # 透传 metadata 字段，供 AI 分析步骤使用
        for meta_key in ("event_code", "enum_name", "report_location", "aggregation", "meaning"):
            if meta_key in metric_cfg:
                entry[meta_key] = metric_cfg[meta_key]
        if "small_count_threshold" in metric_cfg:
            entry["small_count_threshold"] = metric_cfg["small_count_threshold"]
        if is_rate_metric(display_name):
            entry["value_format"] = "ratio"

        metrics_result.append(entry)
        if status == "alert":
            alerts.append(entry)
            if entry.get("handling_action") == "立即排查":
                anomalies.append(entry)
            else:
                expected_variations.append(entry)

    return {
        "dashboard_name": dashboard_cfg["name"],
        "version": version,
        "csv_path": csv_path,
        "metrics": metrics_result,
        "alerts": alerts,
        "anomalies": anomalies,
        "expected_variations": expected_variations,
        "comparison_mode": comparison_mode,
        "comparison_note": comparison_note,
        "data_lag_days": selection.get("data_lag_days"),
        "data_granularity": selection.get("data_granularity"),
        "same_period_cutoff": selection.get("same_period_cutoff"),
        "lookback_hours": selection.get("lookback_hours"),
        "today_partial": selection.get("today_partial"),
    }


def main():
    parser = argparse.ArgumentParser(description="灯塔看板指标分析")
    parser.add_argument("--config", required=True, help="inspection_config.json 路径")
    parser.add_argument("--data-dir", required=True, help="版本专项数据目录（每个看板名称一个子目录）")
    parser.add_argument(
        "--data-dir-all", default=None,
        help="全量数据目录（每个看板名称一个子目录，对应 url_all 下载结果）。"
             "提供时直接使用该目录的 CSV 作为全量数据，跳过客户端 SUM 聚合，"
             "保证率值和 NDV 指标的全量数据准确性。"
    )
    parser.add_argument("--output", default="-", help="结果 JSON 输出路径，- 表示 stdout")
    parser.add_argument(
        "--version", required=True,
        help="指定要分析的版本号（如 10.112.0603），或传入「全量」以聚合所有版本"
    )
    args = parser.parse_args()

    with open(args.config, encoding="utf-8") as f:
        config = json.load(f)

    settings = config.get("settings", {})
    comparison_settings = {
        k: settings[k]
        for k in ("lookback_hours",)
        if k in settings
    }

    all_results = []
    total_alerts = 0
    total_immediate = 0
    total_observe = 0

    for dashboard_cfg in config.get("dashboards", []):
        dashboard_name = dashboard_cfg["name"]
        safe_name = dashboard_name.replace(" ", "_").replace("/", "_")

        # ── 查找版本专项 CSV ──────────────────────────────────────────
        downloads_dir = os.path.join(args.data_dir, dashboard_name)
        csv_path = find_latest_csv(downloads_dir)
        if not csv_path:
            downloads_dir = os.path.join(args.data_dir, safe_name, "downloads")
            csv_path = find_latest_csv(downloads_dir)
        if not csv_path:
            all_results.append({
                "dashboard_name": dashboard_name,
                "version": args.version,
                "error": "未找到版本专项 CSV 文件（目录：{}）".format(downloads_dir),
                "metrics": [],
                "alerts": [],
                "anomalies": [],
                "expected_variations": [],
            })
            continue

        if args.version != "全量":
            # ── 分布看板（is_distribution）：用同一个 CSV 取 version + all Top N，跳过 merge ──
            if dashboard_cfg.get("is_distribution"):
                all_csv_path = None
                if args.data_dir_all:
                    all_dir = os.path.join(args.data_dir_all, dashboard_name)
                    all_csv_path = find_latest_csv(all_dir)
                    if not all_csv_path:
                        all_dir = os.path.join(args.data_dir_all, safe_name, "downloads")
                        all_csv_path = find_latest_csv(all_dir)
                # 分布看板直接调用，内部同时计算 version Top N 和 all Top N
                result = _analyze_distribution_dashboard(
                    dashboard_cfg, csv_path, args.version,
                    all_csv_path=all_csv_path
                )
            else:
                version_result = analyze_dashboard(
                    dashboard_cfg, csv_path, args.version, comparison_settings,
                    source="版本专项",
                )

                # ── 全量数据来源：优先使用专属 url_all 的 CSV，否则退化为客户端 SUM ──
                all_csv_path = None
                if args.data_dir_all:
                    all_dir = os.path.join(args.data_dir_all, dashboard_name)
                    all_csv_path = find_latest_csv(all_dir)
                    if not all_csv_path:
                        all_dir = os.path.join(args.data_dir_all, safe_name, "downloads")
                        all_csv_path = find_latest_csv(all_dir)

                if all_csv_path:
                    all_result = analyze_dashboard(
                        dashboard_cfg, all_csv_path, "全量", comparison_settings,
                        source="全量",
                    )
                    all_result["all_source"] = "dedicated_url"
                else:
                    all_result = analyze_dashboard(
                        dashboard_cfg, csv_path, "全量", comparison_settings,
                        source="全量（客户端聚合）",
                    )
                    all_result["all_source"] = "client_sum_fallback"

                merge_errors = [
                    r["error"]
                    for r in (version_result, all_result)
                    if r.get("error")
                ]
                if merge_errors:
                    result = {
                        "dashboard_name": dashboard_name,
                        "version": args.version,
                        "error": "；".join(merge_errors),
                        "metrics": [],
                        "alerts": [],
                        "anomalies": [],
                        "expected_variations": [],
                        "all_source": all_result.get("all_source"),
                    }
                else:
                    # 补全空侧，保证 merge 后每项指标都有 version_data + all_data
                    if not version_result.get("metrics") and all_result.get("metrics"):
                        version_result["metrics"] = [
                            {
                                "name": m["name"],
                                "column": m.get("column"),
                                "threshold_pct": m.get("threshold_pct"),
                                "today": None, "yesterday": None, "change_pct": None,
                                "status": "missing",
                                **{k: m[k] for k in ("event_code", "enum_name", "report_location",
                                                     "aggregation", "meaning") if k in m},
                            }
                            for m in all_result["metrics"]
                        ]
                    elif not all_result.get("metrics") and version_result.get("metrics"):
                        all_result["metrics"] = [
                            {
                                "name": m["name"],
                                "column": m.get("column"),
                                "threshold_pct": m.get("threshold_pct"),
                                "today": None, "yesterday": None, "change_pct": None,
                                "status": "missing",
                                **{k: m[k] for k in ("event_code", "enum_name", "report_location",
                                                     "aggregation", "meaning") if k in m},
                            }
                            for m in version_result["metrics"]
                        ]

                    result = merge_dual_dashboard_results(version_result, all_result)
                    result["all_source"] = all_result.get("all_source", "unknown")
        else:
            result = analyze_dashboard(
                dashboard_cfg, csv_path, args.version, comparison_settings
            )

        all_results.append(result)
        alerts = result.get("alerts") or result.get("anomalies", []) + result.get("expected_variations", [])
        total_alerts += len(alerts)
        total_immediate += len(result.get("anomalies", []))
        total_observe += len(result.get("expected_variations", []))

    comparison_summary = {}
    for r in all_results:
        if r.get("comparison_mode") and not r.get("error"):
            for key in (
                "comparison_mode", "comparison_note", "data_lag_days",
                "data_granularity", "same_period_cutoff", "lookback_hours",
                "today_partial",
            ):
                if r.get(key) is not None:
                    comparison_summary[key] = r[key]
            for m in r.get("metrics", []):
                vd = m.get("version_data") or m.get("all_data") or m
                if vd.get("today_date"):
                    comparison_summary["compare_date"] = vd["today_date"]
                    comparison_summary["base_date"] = vd.get("yesterday_date")
                    break
            if comparison_summary:
                break

    output = {
        "run_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "version": args.version,
        "has_version_comparison": args.version != "全量",
        "comparison": comparison_summary,
        "total_dashboards": len(all_results),
        "total_alerts": total_alerts,
        "total_immediate": total_immediate,
        "total_observe": total_observe,
        "total_anomalies": total_immediate,
        "total_expected_variations": total_observe,
        "dashboards": all_results,
    }

    output_json = json.dumps(output, ensure_ascii=False, indent=2)
    if args.output == "-":
        print(output_json)
    else:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output_json)
        print(f"分析结果已写入：{args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
