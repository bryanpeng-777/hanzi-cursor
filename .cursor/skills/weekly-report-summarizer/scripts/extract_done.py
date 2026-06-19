#!/usr/bin/env python3
"""extract_done.py - 从周报 markdown 中提取已完成任务（[x] 标记），按一级/二级标题分桶
用法: python3 extract_done.py <markdown_file>
输出: JSON 格式的已完成任务（stdout），统计信息（stderr）
"""

import sys
import re
import json
from pathlib import Path


def extract_done_tasks(md_path: str) -> dict:
    """读取 markdown 文件，按标题结构提取 [x] 任务"""
    text = Path(md_path).read_text(encoding="utf-8")
    lines = text.splitlines()

    result: dict[str, list[str]] = {}
    current_section = "未分类"

    for line in lines:
        # 一级标题
        h1 = re.match(r'^#\s+(.+)$', line)
        if h1:
            current_section = h1.group(1).strip()
            continue

        # 二级标题也做分类边界
        h2 = re.match(r'^##\s+(.+)$', line)
        if h2:
            current_section = h2.group(1).strip()
            continue

        # 已完成任务 [x] / [X]
        done = re.match(r'^\s*-\s*\[[xX]\]\s+(.+)$', line)
        if done:
            task = done.group(1).strip()
            result.setdefault(current_section, []).append(task)

    # 去掉空分类
    return {k: v for k, v in result.items() if v}


def main():
    if len(sys.argv) < 2:
        print("用法: python3 extract_done.py <markdown_file>", file=sys.stderr)
        sys.exit(1)

    md_path = sys.argv[1]
    if not Path(md_path).exists():
        print(f"错误：文件不存在 {md_path}", file=sys.stderr)
        sys.exit(1)

    tasks = extract_done_tasks(md_path)
    total = sum(len(v) for v in tasks.values())

    print(f"# 已完成任务（共 {total} 条，来自 {len(tasks)} 个分类）", file=sys.stderr)
    for section, items in tasks.items():
        print(f"  [{section}]: {len(items)} 条", file=sys.stderr)

    print(json.dumps(tasks, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
