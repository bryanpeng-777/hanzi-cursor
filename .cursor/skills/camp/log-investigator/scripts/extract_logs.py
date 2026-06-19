#!/usr/bin/env python3
"""
Token-efficient log extractor for iOS camp xlog files.

Splits the log into structured entries (each starting with [I/E/W/D][smoba][...][)
then filters by mode before feeding to LLM — reducing hundreds of KB to a few KB.

Modes:
  --stats           Inventory: API call frequency + error count (use first)
  --api NAME        Extract complete OneAPI blocks for a specific API endpoint
  --keywords K1,K2  Extract entries containing any of the keywords
  --errors          Extract error entries + surrounding context entries
  --after KW        Extract N entries after the first entry matching keyword
                    (combine with --count, default 40)

Examples:
  python3 extract_logs.py app.log --stats
  python3 extract_logs.py app.log --api /info/listinfov2
  python3 extract_logs.py app.log --after "TRouter" --count 30
  python3 extract_logs.py app.log --keywords "小鹿迷露,list"
  python3 extract_logs.py app.log --errors
"""

import sys
import re
import os
import argparse
from collections import Counter

# Matches the start of a structured log entry from WEGLogHelper
ENTRY_START = re.compile(r'\[([IEWD])\]\[smoba\]\[')

# Matches the api name line inside a OneAPI block
API_NAME_RE = re.compile(r'^api:\s*(.+)$', re.MULTILINE)

# Matches Flutter route change lines (non-structured entries)
ROUTE_RE = re.compile(r'TRouter|navigator.*push|routeInfo', re.IGNORECASE)


def split_entries(text):
    """
    Split raw log text into a list of (level, content) tuples.
    level is one of I/E/W/D (or 'raw' for lines outside structured entries).
    """
    entries = []
    positions = [(m.start(), m.group(1)) for m in ENTRY_START.finditer(text)]

    if not positions:
        # No structured entries found — treat whole text as raw lines
        for line in text.splitlines(keepends=True):
            entries.append(('raw', line))
        return entries

    # Content before the first structured entry
    if positions[0][0] > 0:
        raw_prefix = text[:positions[0][0]]
        for line in raw_prefix.splitlines(keepends=True):
            if line.strip():
                entries.append(('raw', line))

    for i, (pos, level) in enumerate(positions):
        end = positions[i + 1][0] if i + 1 < len(positions) else len(text)
        entries.append((level, text[pos:end]))

    return entries


def get_api_name(entry_content):
    """Extract the 'api: xxx' value from a OneAPI block, or None."""
    if 'OneAPI Callback Info' not in entry_content:
        return None
    m = API_NAME_RE.search(entry_content)
    return m.group(1).strip() if m else None


def mode_stats(entries, top_n=25):
    """Return a compact inventory: API frequencies, error count, route changes."""
    api_counts = Counter()
    error_count = 0
    route_count = 0
    flutter_lines = []

    for level, content in entries:
        if level == 'E':
            error_count += 1
        api = get_api_name(content)
        if api:
            api_counts[api] += 1
        if level == 'raw' and ROUTE_RE.search(content):
            route_count += 1
            flutter_lines.append(content.strip()[:120])

    lines = []
    lines.append(f"API 调用频率 (Top {min(top_n, len(api_counts))}):")
    for api, cnt in api_counts.most_common(top_n):
        lines.append(f"  {api}: {cnt} 次")
    if not api_counts:
        lines.append("  (未找到 OneAPI 调用)")
    lines.append("")
    lines.append(f"错误条目 [E]: {error_count} 条")
    lines.append(f"Flutter 路由事件: {route_count} 条")
    if route_count > 0:
        lines.append("  路由示例:")
        for l in flutter_lines[:5]:
            lines.append(f"    {l}")
    return "\n".join(lines)


def mode_api(entries, api_filter, last_n=None):
    """Extract complete OneAPI blocks matching api_filter (substring match)."""
    matched = []
    for level, content in entries:
        api = get_api_name(content)
        if api and api_filter.lower() in api.lower():
            matched.append(content)

    if last_n:
        matched = matched[-last_n:]

    if not matched:
        return f"(未找到 api 包含 '{api_filter}' 的 OneAPI block)", 0

    return "\n".join(f"--- block {i+1} ---\n{b}" for i, b in enumerate(matched)), len(matched)


def mode_keywords(entries, keywords):
    """Extract entries where any keyword appears (case-insensitive)."""
    kws = [k.strip().lower() for k in keywords.split(',') if k.strip()]
    matched = []
    for level, content in entries:
        if any(kw in content.lower() for kw in kws):
            matched.append(content)

    if not matched:
        return f"(未找到包含关键词 {keywords} 的 entry)", 0

    return "\n".join(matched), len(matched)


def mode_errors(entries, context_n=3):
    """Extract [E] entries plus context_n surrounding entries on each side."""
    error_indices = [i for i, (level, _) in enumerate(entries) if level == 'E']

    if not error_indices:
        # Fall back to keyword search for common error patterns
        error_kws = ['error', 'crash', 'exception', 'fatal', '⚠️', 'failed', 'assert']
        error_indices = [
            i for i, (_, content) in enumerate(entries)
            if any(kw in content.lower() for kw in error_kws)
        ]

    if not error_indices:
        return "(未发现错误/异常 entry)", 0

    include = set()
    for idx in error_indices:
        for j in range(max(0, idx - context_n), min(len(entries), idx + context_n + 1)):
            include.add(j)

    result_parts = []
    prev = None
    for idx in sorted(include):
        if prev is not None and idx > prev + 1:
            result_parts.append(f"\n[... {idx - prev - 1} entries omitted ...]\n")
        result_parts.append(entries[idx][1])
        prev = idx

    return "".join(result_parts), len(error_indices)


def mode_after(entries, keyword, count):
    """Extract `count` entries after the first entry matching keyword."""
    kw_lower = keyword.lower()
    start_idx = None
    for i, (_, content) in enumerate(entries):
        if kw_lower in content.lower():
            start_idx = i
            break

    if start_idx is None:
        return f"(未找到包含 '{keyword}' 的 landmark entry)", 0

    window = entries[start_idx: start_idx + count + 1]
    landmark_summary = entries[start_idx][1].splitlines()[0][:120]
    header = f"[landmark 第 {start_idx+1} 条] {landmark_summary}\n{'='*60}\n"
    body = "".join(content for _, content in window)
    return header + body, len(window)


def apply_size_limit(text, max_kb):
    max_bytes = max_kb * 1024
    encoded = text.encode('utf-8')
    if len(encoded) <= max_bytes:
        return text
    truncated = encoded[:max_bytes].decode('utf-8', errors='ignore')
    # trim to last complete line
    truncated = truncated.rsplit('\n', 1)[0]
    return truncated + f"\n\n[⚠️ 输出已截断至 {max_kb}KB 上限]"


def main():
    parser = argparse.ArgumentParser(
        description='Token-efficient log extractor for iOS camp xlog',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('log_file', help='日志文件路径')

    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument('--stats', action='store_true',
                            help='统计 API 调用频率（侦察模式，先跑这个）')
    mode_group.add_argument('--api', metavar='NAME',
                            help='提取指定 API 的完整 OneAPI block')
    mode_group.add_argument('--keywords', metavar='K1,K2',
                            help='提取包含关键词的 entry（逗号分隔）')
    mode_group.add_argument('--errors', action='store_true',
                            help='提取错误/异常 entry 及上下文')
    mode_group.add_argument('--after', metavar='KEYWORD',
                            help='提取 landmark 关键词之后的 N 条 entry')

    parser.add_argument('--count', type=int, default=40,
                        help='--after 模式取多少条 entry（默认 40）')
    parser.add_argument('--last', type=int, default=None,
                        help='--api 模式只取最近 N 次调用')
    parser.add_argument('--context', type=int, default=3,
                        help='--errors 模式上下文条数（默认 3）')
    parser.add_argument('--max-kb', type=int, default=40,
                        help='输出大小上限 KB（默认 40）')
    parser.add_argument('--top', type=int, default=25,
                        help='--stats 显示 Top N API（默认 25）')

    args = parser.parse_args()

    if not os.path.exists(args.log_file):
        print(f"错误: 文件不存在: {args.log_file}", file=sys.stderr)
        sys.exit(1)

    file_size_kb = os.path.getsize(args.log_file) // 1024

    with open(args.log_file, 'r', encoding='utf-8', errors='replace') as f:
        raw_text = f.read()

    entries = split_entries(raw_text)
    total_entries = len(entries)

    # --- Run selected mode ---
    hit_count = 0

    if args.stats:
        body = mode_stats(entries, top_n=args.top)
        mode_label = "--stats"
        hit_count = sum(1 for _, c in entries if get_api_name(c))
    elif args.api:
        body, hit_count = mode_api(entries, args.api, last_n=args.last)
        mode_label = f"--api {args.api}"
    elif args.keywords:
        body, hit_count = mode_keywords(entries, args.keywords)
        mode_label = f"--keywords {args.keywords}"
    elif args.errors:
        body, hit_count = mode_errors(entries, context_n=args.context)
        mode_label = "--errors"
    elif args.after:
        body, hit_count = mode_after(entries, args.after, args.count)
        mode_label = f"--after \"{args.after}\" --count {args.count}"

    # Apply size limit
    body = apply_size_limit(body, args.max_kb)

    output_kb = len(body.encode('utf-8')) // 1024
    reduction = max(0, round((1 - output_kb / max(file_size_kb, 1)) * 100))

    # Print header
    print(f"[log-investigator] 文件: {os.path.basename(args.log_file)} | "
          f"大小: {file_size_kb}KB | 总 entry: {total_entries} 条")
    print(f"[模式: {mode_label}] 命中: {hit_count} | "
          f"输出: {output_kb}KB (节省约 {reduction}%)")
    print("=" * 60)
    print(body)


if __name__ == '__main__':
    main()
