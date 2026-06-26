#!/usr/bin/env python3
"""
灯塔巡检数据质量校验（Step 1.5 / Step 2.1）。

在分析前校验 CSV 结构，分析后校验版本 vs 全量逻辑关系，避免静默产出错误报告。

用法：
  # 拉取完成后
  python3 validate_inspection_data.py csv \\
    --config inspection_config.json \\
    --data-dir /tmp/beacon_inspector \\
    --data-dir-all /tmp/beacon_inspector_all

  # 分析完成后
  python3 validate_inspection_data.py analysis \\
    --input /tmp/beacon_inspector/analysis_result.json
"""
from __future__ import annotations

import argparse
import csv
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from analyze_metrics import (  # noqa: E402
    find_date_column,
    find_latest_csv,
    find_version_column,
    parse_csv_rows,
    repair_headerless_hourly_csv,
)
from format_utils import is_rate_metric  # noqa: E402

_HOUR_BUCKET_RE = re.compile(r"^\d{4}-\d{2}-\d{2} \d{1,2}$")
_COUNT_AGGS = ("NDV", "COUNT", "总次数", "总人数", "次数", "人数")


def _load_config(path: str) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _is_count_like_metric(name: str, aggregation: str = "") -> bool:
    if is_rate_metric(name) or "率" in name:
        return False
    agg = (aggregation or "").upper()
    if any(k in agg for k in ("NDV", "COUNT")):
        return True
    return any(k in name for k in ("次数", "人数", "DAU", "启动"))


def validate_csv_file(csv_path: str, label: str) -> list[str]:
    issues: list[str] = []
    if not csv_path or not os.path.isfile(csv_path):
        issues.append(f"[ERROR] {label}: CSV 不存在 ({csv_path})")
        return issues

    rows = parse_csv_rows(csv_path)
    if not rows:
        issues.append(f"[ERROR] {label}: CSV 无数据行 ({csv_path})")
        return issues

    headers = list(rows[0].keys())
    if not find_date_column(headers) and _HOUR_BUCKET_RE.match(str(headers[0]).strip()):
        issues.append(
            f"[ERROR] {label}: 无表头 CSV（首列名像小时桶 `{headers[0]}`），"
            "DOM 表格抓取导致 DictReader 错位；需重拉并确保 api_responses 命中"
        )

    repaired = repair_headerless_hourly_csv(rows, csv_path)
    if len(repaired) != len(rows):
        issues.append(f"[WARN] {label}: 已检测到无表头 CSV，分析脚本会尝试修复 ({csv_path})")

    csv_dir = os.path.dirname(csv_path)
    if not glob.glob(os.path.join(csv_dir, "api_responses_*.json")):
        issues.append(
            f"[WARN] {label}: 缺少 api_responses_*.json，列名可能无法从 result_desc 映射 "
            f"({csv_dir})"
        )

    date_col = find_date_column(list(repaired[0].keys()) if repaired else headers)
    version_col = find_version_column(list(repaired[0].keys()) if repaired else headers)
    if date_col and version_col:
        seen = {}
        dup = 0
        for row in repaired:
            key = (row.get(date_col, "").strip(), row.get(version_col, "").strip())
            if key in seen:
                dup += 1
            seen[key] = True
        if dup:
            issues.append(
                f"[WARN] {label}: 存在 {dup} 组重复 (时间,版本) 行，分析侧会去重；"
                "建议排查 API 是否重复返回"
            )

    return issues


def validate_csv_dirs(config: dict, data_dir: str, data_dir_all: str | None) -> list[str]:
    issues: list[str] = []
    for dash in config.get("dashboards", []):
        name = dash.get("name", "")
        if not name:
            continue
        for base, label in ((data_dir, "版本"), (data_dir_all, "全量")):
            if not base:
                continue
            csv_path = find_latest_csv(os.path.join(base, name))
            issues.extend(validate_csv_file(csv_path, f"{name}/{label}"))
    return issues


def validate_analysis(path: str) -> list[str]:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)

    issues: list[str] = []
    if not data.get("has_version_comparison"):
        return issues

    for board in data.get("dashboards", []):
        bname = board.get("dashboard_name", "?")
        if board.get("error") and not board.get("metrics"):
            issues.append(
                f"[WARN] {bname}: 整板无指标 — {board.get('error')}（须在报告中注明；"
                "若为 CSV 解析问题则按 ERROR 流程重拉）"
            )
            continue

        metrics = board.get("metrics") or []
        if not metrics and not board.get("is_distribution"):
            issues.append(f"[WARN] {bname}: metrics 为空，报告将显示「无数据」")

        for m in metrics:
            v = (m.get("version_data") or {})
            a = (m.get("all_data") or {})
            vt, at = v.get("today"), a.get("today")
            if vt is None or at is None:
                continue
            name = m.get("name", "")
            agg = m.get("aggregation", "")
            if not _is_count_like_metric(name, agg):
                if is_rate_metric(name) and vt and at:
                    if (vt > 50 and at < 5) or (at > 50 and vt < 5):
                        issues.append(
                            f"[ERROR] {bname}/{name}: 率值异常悬殊 "
                            f"(版本 {vt} vs 全量 {at})，疑为列映射错位"
                        )
                continue
            try:
                vf, af = float(vt), float(at)
            except (TypeError, ValueError):
                continue
            if vf > 0 and af < vf * 0.98:
                issues.append(
                    f"[ERROR] {bname}/{name}: 全量今日 ({af}) < 版本今日 ({vf})，"
                    "违反「全量 ⊇ 版本」；疑为 CSV 解析/列映射/重复行累加问题"
                )
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description="灯塔巡检数据质量校验")
    sub = parser.add_subparsers(dest="mode", required=True)

    p_csv = sub.add_parser("csv", help="拉取后校验 CSV")
    p_csv.add_argument("--config", required=True)
    p_csv.add_argument("--data-dir", required=True)
    p_csv.add_argument("--data-dir-all", default="")

    p_ana = sub.add_parser("analysis", help="分析后校验 JSON")
    p_ana.add_argument("--input", required=True)

    args = parser.parse_args()
    if args.mode == "csv":
        cfg = _load_config(args.config)
        issues = validate_csv_dirs(cfg, args.data_dir, args.data_dir_all or None)
    else:
        issues = validate_analysis(args.input)

    errors = [i for i in issues if i.startswith("[ERROR]")]
    warns = [i for i in issues if i.startswith("[WARN]")]

    for line in issues:
        print(line)

    if errors:
        print(f"\n❌ 校验失败：{len(errors)} 个错误，{len(warns)} 个警告")
        return 1
    if warns:
        print(f"\n⚠️ 校验通过（有 {len(warns)} 个警告）")
    else:
        print("\n✅ 校验通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
