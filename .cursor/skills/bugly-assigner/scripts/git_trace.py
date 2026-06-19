#!/usr/bin/env python3
"""git_trace.py - 根据堆栈文件路径回溯 git 提交，统计开发者贡献权重
用法:
  从堆栈文本 stdin:  cat stack.txt | python3 git_trace.py
  直接传路径:        python3 git_trace.py /path/to/File.swift:123
输出: JSON（stdout），包含开发者权重排名

权重规则:
  精确文件+行号匹配 → weight=3
  文件级别匹配     → weight=1
"""

import subprocess
import sys
import json
import re
from collections import defaultdict
from datetime import datetime, timedelta


def run_git(args: list, cwd: str = None) -> str:
    try:
        result = subprocess.run(
            ["git"] + args,
            capture_output=True, text=True, cwd=cwd, timeout=30
        )
        return result.stdout.strip()
    except Exception:
        return ""


def git_log_for_file(filepath: str, line: int | None, months: int) -> list[dict]:
    """执行 git log 查询，返回提交列表（带权重）"""
    since = (datetime.now() - timedelta(days=30 * months)).strftime("%Y-%m-%d")
    fmt = "%H|%an|%ae|%ad"
    entries = []

    # 方式1：精确行号（权重最高）
    if line:
        out = run_git(["log", f"--since={since}",
                       f"-L{line},{line}:{filepath}",
                       f"--pretty=format:{fmt}"])
        for ln in out.splitlines():
            parts = ln.split("|")
            if len(parts) == 4:
                entries.append({"hash": parts[0], "name": parts[1],
                                "email": parts[2], "date": parts[3], "weight": 3})

    # 方式2：文件级（权重低）
    out = run_git(["log", f"--since={since}",
                   f"--pretty=format:{fmt}", "--", filepath])
    seen = {e["hash"] for e in entries}
    for ln in out.splitlines():
        parts = ln.split("|")
        if len(parts) == 4 and parts[0] not in seen:
            entries.append({"hash": parts[0], "name": parts[1],
                            "email": parts[2], "date": parts[3], "weight": 1})

    return entries


def parse_stack_entries(text: str) -> list[tuple[str, int | None]]:
    """从堆栈文本解析 (filepath, line_number) 列表"""
    result = []
    seen = set()
    patterns = [
        r'(/[\w/.\-]+\.(?:swift|m|dart|kt|java|py|cpp|mm)):(\d+)',
        r'([\w/.\-]+\.(?:swift|m|dart|kt|java|py|cpp|mm)):(\d+)',
    ]
    for line in text.splitlines():
        for pat in patterns:
            m = re.search(pat, line)
            if m:
                key = (m.group(1), int(m.group(2)))
                if key not in seen:
                    seen.add(key)
                    result.append(key)
                break
    return result


def main():
    inputs: list[tuple[str, int | None]] = []

    if not sys.stdin.isatty():
        stack_text = sys.stdin.read()
        inputs = parse_stack_entries(stack_text)
        print(f"从 stdin 解析出 {len(inputs)} 个文件位置", file=sys.stderr)
    elif len(sys.argv) > 1:
        for arg in sys.argv[1:]:
            if ":" in arg:
                parts = arg.rsplit(":", 1)
                try:
                    inputs.append((parts[0], int(parts[1])))
                except ValueError:
                    inputs.append((arg, None))
            else:
                inputs.append((arg, None))
    else:
        print("用法: cat stack.txt | python3 git_trace.py", file=sys.stderr)
        print("      python3 git_trace.py /path/to/File.swift:123", file=sys.stderr)
        sys.exit(1)

    if not inputs:
        print("未解析出任何文件路径，请检查堆栈格式", file=sys.stderr)
        sys.exit(1)

    # 按月份回溯（1→2→3 个月）
    all_entries = []
    found_months = 0

    for months in [1, 2, 3]:
        batch = []
        for filepath, line in inputs:
            batch.extend(git_log_for_file(filepath, line, months))
        if batch:
            all_entries = batch
            found_months = months
            print(f"✓ 在 {months} 个月内找到 {len(batch)} 条提交记录", file=sys.stderr)
            break

    if not all_entries:
        print("未找到相关提交记录（已回溯 3 个月）", file=sys.stderr)
        print(json.dumps({"ranked_authors": [], "total_commits": 0, "found_months": 0},
                         ensure_ascii=False, indent=2))
        return

    # 聚合统计
    authors: dict[str, dict] = defaultdict(
        lambda: {"name": "", "email": "", "score": 0, "commits": 0, "last_date": ""}
    )
    for e in all_entries:
        key = e["email"]
        authors[key]["name"] = e["name"]
        authors[key]["email"] = e["email"]
        authors[key]["score"] += e["weight"]
        authors[key]["commits"] += 1
        if not authors[key]["last_date"] or e["date"] > authors[key]["last_date"]:
            authors[key]["last_date"] = e["date"]

    ranked = sorted(authors.values(), key=lambda x: x["score"], reverse=True)

    print(f"\n推荐责任人：{ranked[0]['name']} ({ranked[0]['email']})  权重={ranked[0]['score']}", file=sys.stderr)

    print(json.dumps({
        "ranked_authors": ranked,
        "total_commits": len(all_entries),
        "found_months": found_months,
        "analyzed_files": [f"{p}:{l}" if l else p for p, l in inputs]
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
