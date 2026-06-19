#!/usr/bin/env python3
"""
OA Pages 部署脚本
用法：
  deploy.py check <cname>
  deploy.py create --cname <cname> --files '<json>' [--description <desc>]
  deploy.py update --cname <cname> --files '<json>' [--description <desc>]
  deploy.py patch  --cname <cname> --visibility <public|tof|whitelist>
  deploy.py files  --cname <cname>
  deploy.py delete --cname <cname>
"""

import sys
import os
import json
import argparse
import urllib.request
import urllib.error

BASE_URL = "https://pages.woa.com"


def get_api_key():
    key = os.environ.get("OA_PAGES_API_KEY", "").strip()
    if not key:
        print("ERROR: OA_PAGES_API_KEY 未配置", file=sys.stderr)
        print("请执行：echo 'export OA_PAGES_API_KEY=\"你的key\"' >> ~/.zshrc && source ~/.zshrc", file=sys.stderr)
        sys.exit(1)
    return key


def request(method, path, body=None, api_key=None):
    url = BASE_URL + path
    headers = {"X-Api-Key": api_key or get_api_key()}
    data = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        try:
            return e.code, json.loads(body)
        except Exception:
            return e.code, {"message": body}


def cmd_check(args):
    cname = args.cname
    if not cname.endswith(".woa.com"):
        print(f"ERROR: 域名必须以 .woa.com 结尾，当前：{cname}")
        sys.exit(1)
    status, body = request("GET", f"/api/repos/{cname}")
    if status == 200:
        print(f"TAKEN: {cname} 已被占用")
    elif status == 403 and "不存在" in body.get("message", ""):
        print(f"AVAILABLE: {cname} 可用")
    else:
        print(f"UNKNOWN: HTTP {status} — {body.get('message', body)}")


def cmd_create(args):
    files = json.loads(args.files)
    payload = {"cname": args.cname, "files": files}
    if args.description:
        payload["description"] = args.description
    status, body = request("POST", "/api/sites", payload)
    if status == 200:
        print(f"✅ 创建成功")
        print(f"🌐 URL: {body.get('url', 'https://' + args.cname)}")
        print(f"🔒 权限: {body.get('visibility', 'whitelist')}（白名单为空=仅创建者）")
        print(f"📋 管理: https://pages.woa.com/admin/{args.cname}")
    else:
        print(f"❌ 创建失败 HTTP {status}: {body.get('message', body)}")
        sys.exit(1)


def cmd_update(args):
    payload = {"files": json.loads(args.files)}
    if args.description:
        payload["description"] = args.description
    status, body = request("PUT", f"/api/sites/{args.cname}", payload)
    if status == 200:
        print(f"✅ 更新成功: {body.get('updated_at', '')}")
        print(f"🌐 URL: https://{args.cname}")
    else:
        print(f"❌ 更新失败 HTTP {status}: {body.get('message', body)}")
        sys.exit(1)


def cmd_patch(args):
    payload = {}
    if args.visibility:
        payload["visibility"] = args.visibility
    if args.whitelist:
        payload["whitelist_users"] = args.whitelist.split(",")
    status, body = request("PATCH", f"/api/repos/{args.cname}", payload)
    if status == 200:
        print(f"✅ 配置更新成功")
        print(f"   visibility: {body.get('visibility')}")
        print(f"   whitelist: {body.get('whitelist_users', [])}")
    else:
        print(f"❌ 更新失败 HTTP {status}: {body.get('message', body)}")
        sys.exit(1)


def cmd_files(args):
    status, body = request("GET", f"/api/sites/{args.cname}/files")
    if status == 200:
        files = body.get("files", [])
        print(f"📁 {args.cname} 共 {len(files)} 个文件：")
        for f in files:
            print(f"  {f['path']}  ({f['size']} bytes)")
    else:
        print(f"❌ 查询失败 HTTP {status}: {body.get('message', body)}")
        sys.exit(1)


def cmd_delete(args):
    status, body = request("DELETE", f"/api/repos/{args.cname}")
    if status == 200:
        print(f"✅ {args.cname} 已删除（不可恢复）")
    else:
        print(f"❌ 删除失败 HTTP {status}: {body.get('message', body)}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="OA Pages 部署工具")
    sub = parser.add_subparsers(dest="cmd")

    # check
    p = sub.add_parser("check", help="检查域名可用性")
    p.add_argument("cname")

    # create
    p = sub.add_parser("create", help="创建新网站")
    p.add_argument("--cname", required=True)
    p.add_argument("--files", required=True, help="JSON 格式: {路径: 内容}")
    p.add_argument("--description", default="")

    # update
    p = sub.add_parser("update", help="更新网站文件")
    p.add_argument("--cname", required=True)
    p.add_argument("--files", required=True, help="JSON 格式: {路径: 内容}")
    p.add_argument("--description", default="")

    # patch
    p = sub.add_parser("patch", help="修改网站配置")
    p.add_argument("--cname", required=True)
    p.add_argument("--visibility", choices=["public", "tof", "whitelist"])
    p.add_argument("--whitelist", help="逗号分隔的用户名")

    # files
    p = sub.add_parser("files", help="查看文件列表")
    p.add_argument("--cname", required=True)

    # delete
    p = sub.add_parser("delete", help="删除网站（不可逆）")
    p.add_argument("--cname", required=True)

    args = parser.parse_args()
    if not args.cmd:
        parser.print_help()
        sys.exit(1)

    dispatch = {
        "check": cmd_check,
        "create": cmd_create,
        "update": cmd_update,
        "patch": cmd_patch,
        "files": cmd_files,
        "delete": cmd_delete,
    }
    dispatch[args.cmd](args)


if __name__ == "__main__":
    main()
