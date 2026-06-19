#!/usr/bin/env python3
"""gen_log_query.py - 生成伽利略 get_log_data / get_trace_data 查询参数
用法: python3 gen_log_query.py <userId> [--date YYYY-MM-DD] [--module MODULE_NAME]
输出: JSON，包含标准化的 MCP 查询参数（时间已转换为 RFC3339）
"""

import sys
import json
import argparse
from datetime import datetime, timedelta, timezone


def gen_query_params(user_id: str, date_str: str = None, module_name: str = None) -> dict:
    tz_bj = timezone(timedelta(hours=8))

    if date_str:
        try:
            base_date = datetime.strptime(date_str, "%Y-%m-%d").replace(tzinfo=tz_bj)
        except ValueError:
            print(f"错误：日期格式应为 YYYY-MM-DD，收到：{date_str}", file=sys.stderr)
            sys.exit(1)
    else:
        base_date = datetime.now(tz_bj).replace(hour=0, minute=0, second=0, microsecond=0)

    start_time = base_date.replace(hour=0, minute=0, second=0).isoformat()
    end_time = base_date.replace(hour=23, minute=59, second=59).isoformat()

    # 构建 filters（userId 字段名可能是 tags.userId 或 tags.uid，两个都要试）
    if module_name:
        filters_primary = f"tags.userId = {user_id} AND tags.moduleName = {module_name}"
        filters_fallback = f"tags.uid = {user_id} AND tags.moduleName = {module_name}"
    else:
        filters_primary = f"tags.userId = {user_id}"
        filters_fallback = f"tags.uid = {user_id}"

    # trace_data 的 filters 格式不同（JSON 数组）
    trace_filters = json.dumps([{"label": "userId", "operate": 1, "values": [str(user_id)]}])

    return {
        "meta": {
            "userId": user_id,
            "date": base_date.strftime("%Y-%m-%d"),
            "moduleName": module_name or "<未指定，需从问题描述匹配 galileo-module-locator>",
            "time_window": f"{start_time} ~ {end_time}"
        },
        "step3_search_targets": {
            "tool": "search_targets",
            "params": {"keyword": "smoba"},
            "note": "选 Production 环境 iOS 客户端，通常为 iOS.camp-app"
        },
        "step4_get_log_data": {
            "tool": "get_log_data",
            "params": {
                "target": "<from search_targets>",
                "start_time": start_time,
                "end_time": end_time,
                "filters": filters_primary,
                "namespace": "Production"
            },
            "fallback_filters": filters_fallback,
            "note": "若无结果，用 fallback_filters（uid 字段名）重试"
        },
        "step5_get_trace_data": {
            "tool": "get_trace_data",
            "params": {
                "target": "<from search_targets>",
                "start_time": start_time,
                "end_time": end_time,
                "filters": trace_filters,
                "namespace": "Production"
            }
        }
    }


def main():
    parser = argparse.ArgumentParser(description="生成伽利略日志查询参数")
    parser.add_argument("user_id", help="App 用户 ID")
    parser.add_argument("--date", help="查询日期 YYYY-MM-DD（默认今天）")
    parser.add_argument("--module", help="moduleName（可选，不填则无 moduleName 过滤）")
    args = parser.parse_args()

    result = gen_query_params(args.user_id, args.date, args.module)

    print(f"✓ 查询参数生成完成", file=sys.stderr)
    print(f"  userId: {result['meta']['userId']}", file=sys.stderr)
    print(f"  日期:   {result['meta']['date']}", file=sys.stderr)
    print(f"  窗口:   {result['meta']['time_window']}", file=sys.stderr)

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
