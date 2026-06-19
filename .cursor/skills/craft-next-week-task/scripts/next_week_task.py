#!/usr/bin/env python3
"""next_week_task.py - 计算下周任务日期，提取本周 markdown 中的未完成任务
用法:
  python3 next_week_task.py                     # 只计算下周一前缀
  python3 next_week_task.py <current_week.md>   # 同时提取未完成任务
  python3 next_week_task.py --date 2026-04-13   # 指定基准日期
输出: JSON（stdout），包含 prefix、文件名、Craft config、uncompleted_content
"""

import sys
import re
import json
import argparse
from datetime import date, timedelta
from pathlib import Path


def get_next_monday(today: date = None) -> tuple[str, date]:
    """计算下周一，返回 (MMDD前缀, date)"""
    if today is None:
        today = date.today()
    # weekday(): 0=周一...6=周日；下周一 = 今天 + (7 - weekday())
    days_ahead = 7 - today.weekday()
    next_monday = today + timedelta(days=days_ahead)
    return next_monday.strftime("%m%d"), next_monday


def extract_uncompleted(md_text: str) -> str:
    """
    提取未完成任务，保留文档结构：
    - 保留标题行（# / ## / 数字列表标题）
    - 跳过 - [x] / - [X] 已完成任务
    - 保留 - [ ] 未完成任务及空行
    - 若父任务未完成，子任务全保留（无论完成与否）
    """
    lines = md_text.splitlines()
    result = []
    # 记录当前 "未完成父任务" 的缩进层级，子项跟随保留
    uncompleted_parent_indent: int | None = None

    for line in lines:
        stripped = line.strip()

        # 标题行（#、##、数字. 开头）直接保留
        if re.match(r'^#+\s|^\d+\.\s', stripped):
            result.append(line)
            uncompleted_parent_indent = None
            continue

        # 空行保留
        if not stripped:
            result.append(line)
            continue

        indent = len(line) - len(line.lstrip())

        # 已完成任务
        if re.match(r'\s*-\s*\[[xX]\]\s', line):
            # 若此任务是某个未完成父任务的子项，跟随父项保留
            if uncompleted_parent_indent is not None and indent > uncompleted_parent_indent:
                result.append(line)
            else:
                uncompleted_parent_indent = None  # 遇到同级或更高的已完成任务，重置
            continue

        # 未完成任务
        if re.match(r'\s*-\s*\[\s\]\s', line):
            result.append(line)
            uncompleted_parent_indent = indent  # 标记此缩进层级为"未完成父"
            continue

        # 普通行（非 checkbox 列表项）
        result.append(line)
        uncompleted_parent_indent = None

    # 去除尾部多余空行
    while result and not result[-1].strip():
        result.pop()

    return "\n".join(result)


def main():
    parser = argparse.ArgumentParser(description="计算下周任务结构")
    parser.add_argument("markdown_file", nargs="?", help="当前周 markdown 文件（可选）")
    parser.add_argument("--date", help="基准日期 YYYY-MM-DD（默认今天）")
    args = parser.parse_args()

    today = date.today()
    if args.date:
        try:
            today = date.fromisoformat(args.date)
        except ValueError:
            print("错误：日期格式应为 YYYY-MM-DD", file=sys.stderr)
            sys.exit(1)

    prefix, next_monday = get_next_monday(today)
    print(f"✓ 今天：{today}  下周一：{next_monday}  前缀：{prefix}", file=sys.stderr)

    result = {
        "next_monday": next_monday.isoformat(),
        "prefix": prefix,
        "folder_name": prefix,
        "files_to_create": [f"{prefix}-KingGuard", f"{prefix}-camp"],
        "craft_config": {
            "parent_folder_id": "986AC3A8-4EA4-408B-8D9B-CC7620BEDFFB",
            "note": "贡献与付出（c）文件夹固定 ID，直接使用"
        },
        "uncompleted_content": None,
        "uncompleted_task_count": 0
    }

    if args.markdown_file:
        md_path = Path(args.markdown_file)
        if not md_path.exists():
            print(f"错误：文件不存在 {args.markdown_file}", file=sys.stderr)
            sys.exit(1)

        md_text = md_path.read_text(encoding="utf-8")
        uncompleted = extract_uncompleted(md_text)
        task_count = len(re.findall(r'^\s*-\s*\[\s\]', uncompleted, re.MULTILINE))

        print(f"✓ 提取未完成任务：{task_count} 条", file=sys.stderr)
        result["uncompleted_content"] = uncompleted
        result["uncompleted_task_count"] = task_count

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
