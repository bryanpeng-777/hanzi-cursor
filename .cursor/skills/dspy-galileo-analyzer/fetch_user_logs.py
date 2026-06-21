#!/usr/bin/env python3
"""
fetch_user_logs.py — 用户日志聚合脚本

从多路日志源（userId 查询 + campUid 查询）合并去重，输出供 analyzer.py 使用的文本。

由于伽利略日志通过 MCP 协议拉取，本脚本负责合并去重逻辑；
日志数据由 AI 通过 Galileo MCP 拉取后，保存为文本文件或直接传入 stdin。

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
完整 Pipeline 调用流程（由 AI 编排）：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1 [AI + Galileo MCP]：并行拉取4路日志
  ├── get_log_data(filters="tags.userId={userId}")       → logs_by_uid.txt
  ├── get_log_data(filters="tags.campUid={campUid}")     → logs_by_cuid.txt
  ├── get_trace_data(filters="userId={userId}")          → traces_by_uid.txt
  └── get_trace_data(filters="campUid={campUid}")        → traces_by_cuid.txt

Step 2 [Python]：合并去重
  python3 fetch_user_logs.py \
    --userid 123456 --campuid abc-def-xxx \
    --logs-uid logs_by_uid.txt \
    --logs-cuid logs_by_cuid.txt \
    --traces-uid traces_by_uid.txt \
    --traces-cuid traces_by_cuid.txt \
    --output merged_logs.txt

Step 3 [Python + DSPy]：分析
  python3 analyzer.py --task user-log \
    --userid 123456 --campuid abc-def-xxx \
    --logs "$(cat merged_logs.txt)" \
    --problem "账号B切换后重启App自动登录失败"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
快捷模式（AI 直接传文本，无需文件）：
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  echo "<merged log text>" | python3 fetch_user_logs.py \
    --userid 123456 --campuid abc-def-xxx --stdin \
    | python3 analyzer.py --task user-log \
        --userid 123456 --campuid abc-def-xxx \
        --problem "账号切换后自动登录失败" --logs -
"""

import argparse
import json
import sys
import re
from datetime import datetime


# ── 去重键提取 ──────────────────────────────────────────
def _extract_dedup_key(line: str) -> str:
    """从日志行中提取去重键（traceID + timestamp + message 前30字符）。"""
    trace_match = re.search(r'traceID[=:]\s*([a-zA-Z0-9\-]+)', line)
    time_match  = re.search(r'\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}', line)
    trace_id = trace_match.group(1) if trace_match else ""
    timestamp = time_match.group(0) if time_match else ""
    msg_key = line[:30].strip()
    return f"{trace_id}|{timestamp}|{msg_key}"


# ── 日志源读取 ──────────────────────────────────────────
def _read_source(path: str, label: str) -> list[str]:
    """读取日志文件，每行一条日志，过滤空行。"""
    if not path:
        return []
    try:
        with open(path, encoding="utf-8") as f:
            lines = [l.rstrip() for l in f if l.strip()]
        print(f"  ✅ {label}：读取 {len(lines)} 条", file=sys.stderr)
        return lines
    except FileNotFoundError:
        print(f"  ⚠️  {label}：文件不存在（{path}），跳过", file=sys.stderr)
        return []


# ── 合并去重 ────────────────────────────────────────────
def merge_and_dedup(sources: list[tuple[str, list[str]]]) -> list[str]:
    """
    合并多路日志，按去重键去重，按时间戳升序排列。

    sources: [(label, lines), ...]
    """
    seen_keys: set[str] = set()
    all_lines: list[tuple[str, str]] = []  # (timestamp, line)

    for label, lines in sources:
        for line in lines:
            key = _extract_dedup_key(line)
            if key not in seen_keys:
                seen_keys.add(key)
                time_match = re.search(r'\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}', line)
                ts = time_match.group(0) if time_match else "0000-00-00T00:00:00"
                all_lines.append((ts, line))

    all_lines.sort(key=lambda x: x[0])
    return [line for _, line in all_lines]


# ── 输出格式化 ──────────────────────────────────────────
def format_output(merged: list[str], user_id: str, camp_uid: str) -> str:
    header = (
        f"[用户日志聚合报告]\n"
        f"userId={user_id}  campUid={camp_uid}\n"
        f"合并条数={len(merged)}\n"
        f"{'─'*60}\n"
    )
    return header + "\n".join(merged)


# ── 主逻辑 ──────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="用户日志聚合：userId + campUid 并集去重")

    parser.add_argument("--userid",      required=True, help="用户 userId（用于输出标记）")
    parser.add_argument("--campuid",     required=True, help="用户 campUid（设备ID，用于输出标记）")

    # 日志来源：文件模式
    parser.add_argument("--logs-uid",    default="", help="userId 维度的日志文件路径")
    parser.add_argument("--logs-cuid",   default="", help="campUid 维度的日志文件路径")
    parser.add_argument("--traces-uid",  default="", help="userId 维度的 trace 文件路径")
    parser.add_argument("--traces-cuid", default="", help="campUid 维度的 trace 文件路径")

    # 日志来源：stdin 模式
    parser.add_argument("--stdin",       action="store_true", help="从 stdin 读取已合并的日志文本")

    parser.add_argument("--output",      default="", help="输出文件路径（不传则输出到 stdout）")
    args = parser.parse_args()

    # stdin 快捷模式
    if args.stdin:
        raw = sys.stdin.read()
        lines = [l for l in raw.splitlines() if l.strip()]
        merged = lines
        print(f"  ✅ stdin：读取 {len(merged)} 条", file=sys.stderr)
    else:
        print(f"\n📥 读取日志源...", file=sys.stderr)
        sources = [
            ("logs-by-userId",   _read_source(args.logs_uid,    "logs-by-userId")),
            ("logs-by-campUid",  _read_source(args.logs_cuid,   "logs-by-campUid")),
            ("trace-by-userId",  _read_source(args.traces_uid,  "trace-by-userId")),
            ("trace-by-campUid", _read_source(args.traces_cuid, "trace-by-campUid")),
        ]
        total_raw = sum(len(lines) for _, lines in sources)
        merged = merge_and_dedup(sources)
        print(f"\n🔀 合并去重：{total_raw} 条 → {len(merged)} 条", file=sys.stderr)

    output_text = format_output(merged, args.userid, args.campuid)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output_text)
        print(f"💾 已输出到：{args.output}", file=sys.stderr)
    else:
        print(output_text)


if __name__ == "__main__":
    main()
