#!/usr/bin/env python3
"""gen_query_params.py - 从伽利略告警 URL 解析参数，生成 MCP 查询模板
用法: python3 gen_query_params.py <alert_url>
示例: python3 gen_query_params.py "https://j.woa.com?alert_instance_id=2229319_xxx&alert_period_id=128e1b2e_yyy"
输出: JSON，包含 get_alert_detail 参数及 get_log_data 调用模板
"""

import sys
import re
import json
from urllib.parse import urlparse, parse_qs


def parse_alert_url(url: str) -> dict:
    """从告警 URL 提取 alert_instance_id 和 alert_period_id"""
    parsed = urlparse(url)
    params = parse_qs(parsed.query)

    result = {
        "alert_instance_id": params.get("alert_instance_id", [None])[0],
        "alert_period_id": params.get("alert_period_id", [None])[0],
    }

    # 兜底：从原始 URL 用正则提取
    if not result["alert_instance_id"]:
        m = re.search(r'alert_instance_id=([^&\s#]+)', url)
        if m:
            result["alert_instance_id"] = m.group(1)
    if not result["alert_period_id"]:
        m = re.search(r'alert_period_id=([^&\s#]+)', url)
        if m:
            result["alert_period_id"] = m.group(1)

    return result


def gen_mcp_templates() -> dict:
    """生成 get_log_data 查询模板（用于 alert_detail 返回后选择）"""
    return {
        "step1_get_alert_detail": {
            "tool": "get_alert_detail",
            "note": "从返回结果提取 target, namespace, moduleName, campType, groupName, alertTime"
        },
        "step2a_without_groupName": {
            "tool": "get_log_data",
            "note": "若 alert_labels 中无 tags.groupName，使用此模板（模块整体告警）",
            "params": {
                "target": "<from step1: rule.target>",
                "namespace": "Production",
                "start_time": "<alertTime - 6分钟，RFC3339，如 2026-03-17T20:11:00+08:00>",
                "end_time": "<alertTime + 6分钟，RFC3339，如 2026-03-17T20:23:00+08:00>",
                "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType>",
                "group_by_tags": "[\"tags.groupName\", \"tags.ret_code\"]"
            }
        },
        "step2b_with_groupName": {
            "tool": "get_log_data",
            "note": "若 alert_labels 中有 tags.groupName，必须加入 groupName 过滤（下钻告警）",
            "params": {
                "target": "<from step1>",
                "namespace": "Production",
                "start_time": "<alertTime - 6分钟>",
                "end_time": "<alertTime + 6分钟>",
                "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.groupName=<groupName>",
                "group_by_tags": "[\"tags.ret_code\", \"tags.status\"]"
            },
            "warning": "漏加 groupName 会导致量级/错误码统计严重偏差，必须检查！"
        },
        "time_window_note": "alertTime 格式为 RFC3339，从 alert_data.alert_data_time 解析，前后各扩展 6 分钟"
    }


def main():
    if len(sys.argv) < 2:
        print("用法: python3 gen_query_params.py <alert_url>", file=sys.stderr)
        sys.exit(1)

    url = sys.argv[1]
    parsed = parse_alert_url(url)

    if not parsed["alert_instance_id"]:
        print("错误：无法从 URL 中提取 alert_instance_id", file=sys.stderr)
        print(f"URL: {url}", file=sys.stderr)
        sys.exit(1)

    print(f"✓ alert_instance_id: {parsed['alert_instance_id']}", file=sys.stderr)
    print(f"✓ alert_period_id:   {parsed['alert_period_id']}", file=sys.stderr)

    result = {
        "step1_params": {
            "tool": "get_alert_detail",
            "params": {
                "alert_instance_id": parsed["alert_instance_id"],
                "alert_period_id": parsed["alert_period_id"]
            }
        },
        "subsequent_query_templates": gen_mcp_templates()
    }

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
