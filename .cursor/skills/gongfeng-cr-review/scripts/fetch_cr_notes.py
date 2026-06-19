#!/usr/bin/env python3
"""fetch_cr_notes.py - 从工蜂 MR URL 解析参数，生成 MCP 调用序列
用法: python3 fetch_cr_notes.py <mr_url>
示例: python3 fetch_cr_notes.py https://git.woa.com/koh_social/social-ios/-/merge_requests/9058
输出: JSON，包含 search_merge_request / search_merge_request_notes 调用参数
"""

import sys
import json
import re

RISK_MAP = {0: "普通", 1: "低风险", 2: "中风险", 3: "高风险"}
RESOLVE_MAP = {0: "未解决", 2: "已解决"}


def parse_mr_url(url: str) -> dict:
    """解析工蜂 MR URL，提取 project_path 和 iid"""
    pattern = r'https?://git\.woa\.com/(.+?)/-/merge_requests/(\d+)'
    m = re.search(pattern, url)
    if not m:
        print(f"错误：无法解析 MR URL: {url}", file=sys.stderr)
        print("期望格式：https://git.woa.com/<project_path>/-/merge_requests/<iid>", file=sys.stderr)
        sys.exit(1)
    return {
        "project_path": m.group(1),
        "iid": int(m.group(2)),
    }


def gen_mcp_call_sequence(project_path: str, iid: int) -> list:
    """生成完整 MCP 调用序列"""
    return [
        {
            "step": 1,
            "description": "查询 MR 真实 ID（非 iid）",
            "tool": "search_merge_request",
            "mcp_server": "user-gongfengStreamable",
            "params": {
                "project_id": project_path,
                "iid": iid
            },
            "extract": "id（真实 MR ID，后续步骤用这个，不是 iid）"
        },
        {
            "step": 2,
            "description": "抓取 MR 评论（含 AI code review）",
            "tool": "search_merge_request_notes",
            "mcp_server": "user-gongfengStreamable",
            "params": {
                "project_id": project_path,
                "merge_request_id": "<step1 返回的 id>",
                "system": False,
                "sort": "created_asc",
                "per_page": 50
            },
            "filter_ai_comments": {
                "include": {
                    "line_code": "not null（行内评论）",
                    "file_path": "not empty",
                    "person_note_type": 1,
                    "risk": "有值（0=普通 1=低 2=中 3=高）"
                },
                "exclude_patterns": ["本次 Merge 由", "本次 Merge 不能自动合并"]
            },
            "output": {
                "format": "按 risk 降序（高→中→低→普通），含 file_path / line_code / body / resolve_state",
                "risk_map": RISK_MAP,
                "resolve_map": RESOLVE_MAP
            }
        }
    ]


def main():
    if len(sys.argv) < 2:
        print("用法: python3 fetch_cr_notes.py <mr_url>", file=sys.stderr)
        sys.exit(1)

    url = sys.argv[1]
    parsed = parse_mr_url(url)

    print(f"✓ project_path: {parsed['project_path']}", file=sys.stderr)
    print(f"✓ iid:          {parsed['iid']}", file=sys.stderr)

    result = {
        "parsed": parsed,
        "mcp_call_sequence": gen_mcp_call_sequence(parsed["project_path"], parsed["iid"])
    }

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
