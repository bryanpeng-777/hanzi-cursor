#!/usr/bin/env python3
"""从 analysis_result.json 生成灯塔巡检日报 Markdown。

用法:
  python3 generate_report.py \\
    --input /tmp/beacon_inspector/analysis_result.json \\
    --output /tmp/beacon_inspector/inspection_report.md
"""
import argparse
import json
import os
import sys
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from format_utils import format_display_value, format_change_pct

STATUS_EMOJI = {
    "ok": "✅",
    "alert": "⚠️",
    "anomaly": "⚠️",
    "expected_variation": "⚠️",
    "missing": "—",
}

WEEKDAYS = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]


def weekday(ds: str) -> str:
    try:
        return WEEKDAYS[datetime.strptime(ds, "%Y-%m-%d").weekday()]
    except (ValueError, TypeError):
        return ""


def pick_dates(data: dict) -> tuple:
    comp = data.get("comparison") or {}
    if comp.get("compare_date"):
        return comp["compare_date"], comp.get("base_date")
    for db in data.get("dashboards", []):
        for m in db.get("metrics", []):
            vd = m.get("version_data") or m.get("all_data") or m
            if vd.get("today_date"):
                return vd["today_date"], vd.get("yesterday_date")
    return None, None


def format_date_range_line(data: dict, today_date: str, yesterday_date: str) -> str:
    """根据 comparison 元信息生成数据区间描述，避免误标「今/昨」。"""
    comp = data.get("comparison") or {}
    mode = comp.get("comparison_mode", "")
    note = comp.get("comparison_note", "")

    if not today_date:
        return ""

    td_wd = weekday(today_date)
    yd_wd = weekday(yesterday_date) if yesterday_date else ""

    if mode == "same_period":
        hours = comp.get("lookback_hours", 12)
        slot = comp.get("same_period_cutoff", "")
        left = f"{today_date}（今日近{hours}h {slot}，{td_wd}）"
        right = (
            f"{yesterday_date}（昨日同时段，{yd_wd}）" if yesterday_date else "—"
        )
    else:
        left = f"{today_date}（{td_wd}）"
        right = f"{yesterday_date}（{yd_wd}）" if yesterday_date else "—"

    line = f"**数据区间**：{left} vs {right}"
    if note:
        line += f"\n**对比说明**：{note}"
    return line


def period_column_labels(data: dict) -> tuple:
    """表格列头：对比期 / 基期（替代误导性的「今日/昨日」）。"""
    mode = (data.get("comparison") or {}).get("comparison_mode", "")
    if mode == "same_period":
        hours = (data.get("comparison") or {}).get("lookback_hours", 12)
        return f"今日近{hours}h", f"昨日同时段"
    return "对比期", "基期"


def _dashboard_alerts(db: dict) -> list:
    alerts = db.get("alerts")
    if alerts is not None:
        return alerts
    return (db.get("anomalies") or []) + (db.get("expected_variations") or [])


def _count_by_action(db: dict) -> tuple:
    alerts = _dashboard_alerts(db)
    immediate = sum(1 for a in alerts if a.get("handling_action") == "立即排查")
    observe = sum(1 for a in alerts if a.get("handling_action") == "建议观察")
    if not alerts:
        immediate = len(db.get("anomalies", []))
        observe = len(db.get("expected_variations", []))
    return len(alerts), immediate, observe


def dashboard_status(db: dict) -> str:
    if db.get("is_distribution"):
        return "ℹ️ 分布快照"
    alert_cnt, immediate, _ = _count_by_action(db)
    if not alert_cnt:
        return "✅ 全部正常"
    if immediate:
        return f"⚠️ 异常（{immediate} 项需立即排查）"
    return f"⚠️ 异常（{alert_cnt} 项建议观察）"


def format_handling_advice(metric: dict) -> str:
    status = metric.get("status", "ok")
    if status not in ("alert", "anomaly", "expected_variation"):
        return "—"
    action = metric.get("handling_action", "")
    reason = metric.get("handling_reason", "")
    if not action:
        if status == "anomaly" or metric in []:
            action = "立即排查"
            reason = reason or "环比超阈值"
        else:
            action = "建议观察"
            reason = reason or metric.get("variation_reason", "已知合理波动")
    if reason:
        return f"{action}：{reason}"
    return action


def metric_status_display(metric: dict) -> str:
    st = metric.get("status", "ok")
    if st in ("alert", "anomaly", "expected_variation"):
        return STATUS_EMOJI.get("alert", "⚠️")
    return STATUS_EMOJI.get(st, st)


def version_has_data(metrics: list) -> bool:
    return any((m.get("version_data") or {}).get("today") is not None for m in metrics)


def render_distribution(db: dict) -> list:
    lines = [
        f"## 📊 {db['dashboard_name']} ✅（分布快照 Top3）",
        "",
        "> 分布型看板，无时间维度，展示 Top3 维度占比。版本列为指定版本用户，全量列为所有版本汇总。",
        "",
        "| 排名 | 维度 | 版本 用户量 | 全量 用户量 |",
        "|------|------|-----------|-----------|",
    ]
    for m in db["metrics"]:
        vd = m.get("version_data", {})
        ad = m.get("all_data", {})
        dim = m.get("column") or m.get("name", "")
        lines.append(
            f"| {m.get('name', '')} | {dim} | "
            f"{format_display_value('用户数', vd.get('today'))} | "
            f"{format_display_value('用户数', ad.get('today'))} |"
        )
    return lines


def render_metrics_table(db: dict, data: dict) -> list:
    has_cmp = db.get("has_version_comparison", False)
    cur_label, prev_label = period_column_labels(data)
    lines = []
    if has_cmp and not version_has_data(db["metrics"]):
        lines.append("> 版本维度均无数据（版本粒度下该看板数据极少或无匹配行）")
        lines.append("")

    if has_cmp:
        lines.append(
            f"| 指标 | 版本 {cur_label} | 版本 {prev_label} | 版本 环比 | "
            f"全量 {cur_label} | 全量 {prev_label} | 全量 环比 | 状态 | 处理建议 |"
        )
        lines.append("|------|---------|---------|---------|---------|---------|---------|------|---------|")
        for m in db["metrics"]:
            vd = m.get("version_data", {})
            ad = m.get("all_data", {})
            th = m.get("threshold_pct", 10)
            name = m["name"]
            lines.append(
                f"| {name} | "
                f"{format_display_value(name, vd.get('today'))} | "
                f"{format_display_value(name, vd.get('yesterday'))} | "
                f"{format_change_pct(vd.get('change_pct'), th)} | "
                f"{format_display_value(name, ad.get('today'))} | "
                f"{format_display_value(name, ad.get('yesterday'))} | "
                f"{format_change_pct(ad.get('change_pct'), th)} | "
                f"{metric_status_display(m)} | "
                f"{format_handling_advice(m)} |"
            )
    else:
        lines.append(f"| 指标 | {cur_label} | {prev_label} | 环比 | 状态 | 处理建议 |")
        lines.append("|------|------|------|------|------|---------|")
        for m in db["metrics"]:
            th = m.get("threshold_pct", 10)
            name = m["name"]
            lines.append(
                f"| {name} | "
                f"{format_display_value(name, m.get('today'))} | "
                f"{format_display_value(name, m.get('yesterday'))} | "
                f"{format_change_pct(m.get('change_pct'), th)} | "
                f"{metric_status_display(m)} | "
                f"{format_handling_advice(m)} |"
            )
    return lines


def generate_report(data: dict) -> str:
    today_date, yesterday_date = pick_dates(data)
    version = data.get("version", "全量")
    has_cmp = data.get("has_version_comparison", False)

    lines = [
        f"# 灯塔看板巡检日报 {data['run_time']}",
        "",
        f"**巡检时间**：{data['run_time']}",
    ]
    if today_date:
        lines.append(format_date_range_line(data, today_date, yesterday_date))
    if has_cmp:
        lines.append(f"**版本口径**：{version}（版本专项）+ 全量对比")
    else:
        lines.append("**版本口径**：全量")
    lines.extend(["", "---", "", "## 巡检概览", ""])
    lines.append("| 看板 | 指标总数 | 异常 | 立即排查 | 建议观察 | 状态 |")
    lines.append("|------|--------|------|---------|---------|------|")

    for db in data["dashboards"]:
        name = db["dashboard_name"]
        if db.get("is_distribution"):
            lines.append(f"| {name} | Top3 | — | — | — | ℹ️ 分布快照 |")
            continue
        metrics = db.get("metrics", [])
        alert_cnt, immediate, observe = _count_by_action(db)
        lines.append(
            f"| {name} | {len(metrics)} | {alert_cnt} | {immediate} | "
            f"{observe} | {dashboard_status(db)} |"
        )

    lines.extend([
        "",
        "> 超阈值指标统一标记为 ⚠️ 异常；处理建议列区分「立即排查」与「建议观察」及判断理由。",
        "",
    ])

    for db in data["dashboards"]:
        lines.extend(["---", ""])
        if db.get("is_distribution"):
            lines.extend(render_distribution(db))
            continue

        st = dashboard_status(db)
        emoji = "⚠️" if "异常" in st else "✅"
        lines.append(f"## 📊 {db['dashboard_name']} {emoji}")
        lines.append("")
        lines.extend(render_metrics_table(db, data))

        alerts = _dashboard_alerts(db)
        if alerts:
            lines.extend(["", "### 异常分析", ""])
            for a in alerts:
                action = a.get("handling_action", "建议观察")
                reason = a.get("handling_reason", a.get("variation_reason", ""))
                lines.append(f"**⚠️ {a['name']} — {action}**")
                lines.append("")
                if reason:
                    lines.append(f"- **理由**：{reason}")
                lines.append("")

    lines.extend(["---", "", "*由灯塔看板巡检自动生成 · beacon-dashboard-inspector*"])
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="生成灯塔巡检日报 Markdown")
    parser.add_argument("--input", required=True, help="analysis_result.json 路径")
    parser.add_argument("--output", required=True, help="输出 Markdown 路径")
    args = parser.parse_args()

    with open(args.input, encoding="utf-8") as f:
        data = json.load(f)

    report = generate_report(data)
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(report)
    print(f"报告已写入：{args.output}")


if __name__ == "__main__":
    main()
