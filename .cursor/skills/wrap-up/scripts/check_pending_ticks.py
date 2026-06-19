#!/usr/bin/env python3
"""check_pending_ticks.py - 检查 daily_task_state.md 中已完成但需要在 Craft 打勾的任务
用法: python3 check_pending_ticks.py <state_file_path>
输出: JSON（stdout），包含需要调用 blocks_update 打勾的 blockId 列表
"""

import sys
import re
import json
from pathlib import Path


def parse_state_file(path: str) -> dict:
    """解析状态文件，提取已完成任务及其 blockId"""
    text = Path(path).read_text(encoding="utf-8")

    completed_tasks = []
    in_completed = False

    for line in text.splitlines():
        # 进入已完成区域
        if "✅ 已完成" in line:
            in_completed = True
            continue

        if in_completed:
            # 遇到其他主字段停止
            if re.match(r'- [🔄📌📋]', line):
                break

            # 有 blockId 的完成任务
            m = re.match(r'\s*-\s+(.+?)（blockId:\s*([A-Fa-f0-9\-]{8,})）', line)
            if m:
                completed_tasks.append({
                    "task": m.group(1).strip(),
                    "blockId": m.group(2).strip()
                })
                continue

            # 有完成时间但无 blockId
            m2 = re.match(r'\s*-\s+(.+?)（完成时间', line)
            if m2:
                completed_tasks.append({
                    "task": m2.group(1).strip(),
                    "blockId": None
                })

    pending_ticks = [t for t in completed_tasks if t["blockId"]]
    no_blockid = [t for t in completed_tasks if not t["blockId"]]

    return {
        "pending_ticks": pending_ticks,
        "no_blockid": no_blockid,
        "total_completed": len(completed_tasks)
    }


def main():
    print("[check_pending_ticks] trace: main() entered", file=sys.stderr)
    if len(sys.argv) < 2:
        print("用法: python3 check_pending_ticks.py <state_file>", file=sys.stderr)
        sys.exit(1)

    state_file = sys.argv[1]
    if not Path(state_file).exists():
        print(f"错误：文件不存在 {state_file}", file=sys.stderr)
        sys.exit(1)

    result = parse_state_file(state_file)
    pending = result["pending_ticks"]

    print(f"已完成任务：{result['total_completed']} 条", file=sys.stderr)
    print(f"需要打勾（有 blockId）：{len(pending)} 条", file=sys.stderr)
    print(f"无 blockId（跳过）：{len(result['no_blockid'])} 条", file=sys.stderr)

    if pending:
        print("\n待执行的 blocks_update（blocks_update [{ id, markdown:'- [x] ...' }]）：", file=sys.stderr)
        for t in pending:
            print(f"  blockId={t['blockId']}  任务：{t['task']}", file=sys.stderr)

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
