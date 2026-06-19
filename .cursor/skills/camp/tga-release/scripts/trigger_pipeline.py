#!/usr/bin/env python3
"""
TGA 蓝盾流水线触发脚本（通过蓝鲸 API 网关 MCP 接口）

access_token 获取：https://devops.woa.com/ms/auth/api/user/bkToken/get
  （需已登录蓝盾，页面直接返回 JSON，取 access_token 字段，有效期约 180 天）

用法：
  触发流水线：
    python trigger_pipeline.py trigger --pipeline-id TGALiveSDK --token <access_token> [--branch master] [--msg "描述"]

  查询构建状态：
    python trigger_pipeline.py status --build-id b-xxx --token <access_token>

  Dry-run 模式（只打印，不实际请求）：
    python trigger_pipeline.py trigger --pipeline-id TGALiveSDK --token <token> --dry-run
"""

import argparse
import json
import sys
import urllib.request
import urllib.error

# 蓝鲸 API 网关配置
MCP_URL = "https://bk-apigateway.apigw.o.woa.com/prod/api/v2/mcp-servers/devops-prod-pipeline-streamable/mcp/"
PROJECT_ID = "sgame-tv"

# 已知流水线 ID 映射
PIPELINE_MAP = {
    "TGALibs":     "p-e1d81e453b594e48b71d79e10818fa1f",
    "TGAFoundation": "p-6bac50ae3760411c816e8f9ab04af98a",
    "TGALiveSDK":  "p-b9021eb34394484ca814383d3a705e7d",
}


def call_mcp(token: str, tool: str, arguments: dict) -> dict:
    """调用蓝盾 MCP 工具接口"""
    payload = json.dumps({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {"name": tool, "arguments": arguments}
    }).encode("utf-8")
    headers = {
        "X-Bkapi-Authorization": json.dumps({"access_token": token}),
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",
    }
    req = urllib.request.Request(MCP_URL, data=payload, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode("utf-8")
            # MCP 返回 SSE 格式，取 data: 行
            for line in raw.splitlines():
                if line.startswith("data: "):
                    return json.loads(line[6:])
            print(f"[ERROR] 未找到 data 行，原始响应：{raw[:200]}", file=sys.stderr)
            sys.exit(1)
    except urllib.error.HTTPError as e:
        print(f"[ERROR] HTTP {e.code}: {e.read().decode()}", file=sys.stderr)
        sys.exit(1)


def resolve_pipeline_id(name_or_id: str) -> str:
    return PIPELINE_MAP.get(name_or_id, name_or_id)


def cmd_trigger(args):
    pipeline_id = resolve_pipeline_id(args.pipeline_id)
    if args.dry_run:
        print(f"[DRY-RUN] MCP tool: build_start")
        print(f"[DRY-RUN] pipeline: {pipeline_id}, branch: {args.branch}, msg: {args.msg}")
        print("BUILD_ID=dry-run-build-id")
        return

    print(f"[INFO] 触发流水线 {args.pipeline_id}（{pipeline_id}），分支: {args.branch} ...")
    result = call_mcp(args.token, "build_start", {
        "path_param": {"projectId": PROJECT_ID},
        "query_param": {"pipelineId": pipeline_id},
        "body_param": {
            "BK_CI_BUILD_MSG": args.msg,
            "hookBranch": args.branch,
        }
    })
    body = json.loads(result["result"]["content"][0]["text"])["response_body"]
    if body.get("status") != 0:
        print(f"[ERROR] 触发失败: {body}", file=sys.stderr)
        sys.exit(1)
    data = body["data"]
    build_id = data["id"]
    build_num = data["num"]
    print(f"[INFO] 触发成功！构建号: #{build_num}  build_id: {build_id}")
    print(f"[INFO] 详情: https://devops.woa.com/console/pipeline/{PROJECT_ID}/{pipeline_id}/detail/{build_id}/executeDetail")
    print(f"BUILD_ID={build_id}")


def cmd_status(args):
    if args.dry_run:
        print(f"[DRY-RUN] MCP tool: build_status, build_id: {args.build_id}")
        return

    result = call_mcp(args.token, "build_status", {
        "path_param": {"projectId": PROJECT_ID},
        "query_param": {"buildId": args.build_id}
    })
    body = json.loads(result["result"]["content"][0]["text"])["response_body"]
    data = body.get("data", {})
    status = data.get("status", "UNKNOWN")
    print(f"状态: {status}")
    print(f"触发人: {data.get('userId', '-')}")
    print(f"构建号: #{data.get('buildNum', '-')}")
    if status in {"SUCCEED"}:
        print("[INFO] 构建成功 ✅")
    elif status in {"FAILED", "CANCELED", "TERMINATE"}:
        print(f"[ERROR] 构建失败: {status}", file=sys.stderr)
        sys.exit(1)
    else:
        print(f"[INFO] 仍在执行中，稍后再查...")


def main():
    parser = argparse.ArgumentParser(description="TGA 蓝盾流水线触发工具（via MCP）")
    parser.add_argument("--dry-run", action="store_true", help="只打印不实际请求")
    sub = parser.add_subparsers(dest="command", required=True)

    p_trigger = sub.add_parser("trigger", help="触发流水线")
    p_trigger.add_argument("--pipeline-id", required=True,
                            help="流水线名称（TGALibs/TGAFoundation/TGALiveSDK）或 p- 开头的 ID")
    p_trigger.add_argument("--token", required=True, help="蓝盾 access_token")
    p_trigger.add_argument("--branch", default="master", help="构建分支（默认 master）")
    p_trigger.add_argument("--msg", default="tga-release 自动触发", help="构建描述")
    p_trigger.set_defaults(func=cmd_trigger)

    p_status = sub.add_parser("status", help="查询构建状态")
    p_status.add_argument("--build-id", required=True, help="构建 ID（b- 开头）")
    p_status.add_argument("--token", required=True, help="蓝盾 access_token")
    p_status.set_defaults(func=cmd_status)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
