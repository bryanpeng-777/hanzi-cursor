#!/usr/bin/env python3
"""knot_upload.py - 打包并上传 Skill 到 Knot 平台
用法: python3 knot_upload.py <skill_dir> [--skill-id <id>] [--env test]
Token 读取：~/.knot_token_cache.json {"token": "..."}
"""

import os
import sys
import json
import argparse
import zipfile
import base64
import tempfile

try:
    import requests
except ImportError:
    print("错误：需要安装 requests：pip install requests", file=sys.stderr)
    sys.exit(1)


def load_token() -> str:
    token_file = os.path.expanduser("~/.knot_token_cache.json")
    if not os.path.exists(token_file):
        print(f"错误：Token 文件不存在 {token_file}", file=sys.stderr)
        print("请先在 https://knot.woa.com/settings/token 申请 Token，写入该文件：", file=sys.stderr)
        print('  echo \'{"token": "YOUR_TOKEN"}\' > ~/.knot_token_cache.json', file=sys.stderr)
        sys.exit(1)
    with open(token_file, encoding="utf-8") as f:
        return json.load(f)["token"]


def parse_skill_md(skill_dir: str) -> tuple[str, str]:
    """解析 SKILL.md 的 YAML frontmatter，获取 name 和 description"""
    skill_md = os.path.join(skill_dir, "SKILL.md")
    if not os.path.exists(skill_md):
        print(f"错误：找不到 SKILL.md: {skill_md}", file=sys.stderr)
        sys.exit(1)

    with open(skill_md, encoding="utf-8") as f:
        content = f.read()

    name = desc = None
    if content.startswith("---"):
        fm = content.split("---", 2)[1]
        for line in fm.splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                k = k.strip()
                v = v.strip().strip('"\'')
                if k == "name":
                    name = v
                elif k == "description":
                    desc = v

    if not name:
        print("错误：SKILL.md 缺少 name 字段", file=sys.stderr)
        sys.exit(1)
    return name, desc or ""


def pack_skill(skill_dir: str, skill_name: str) -> str:
    """将 skill 目录打包为 zip，返回 base64 字符串"""
    tmp = tempfile.NamedTemporaryFile(suffix=".zip", delete=False)
    tmp.close()

    with zipfile.ZipFile(tmp.name, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(skill_dir):
            # 排除干扰目录
            dirs[:] = [d for d in dirs if d not in ("__pycache__", ".git", ".venv", "node_modules")]
            for file in files:
                if file in (".DS_Store",):
                    continue
                fp = os.path.join(root, file)
                # zip 内根目录名必须与 SKILL.md name 字段完全一致
                arcname = os.path.join(skill_name, os.path.relpath(fp, skill_dir))
                zf.write(fp, arcname)

    with open(tmp.name, "rb") as f:
        b64 = base64.b64encode(f.read()).decode()
    os.remove(tmp.name)

    size_kb = len(b64) * 3 // 4 // 1024
    print(f"打包完成，zip 大小约 {size_kb} KB", file=sys.stderr)
    if size_kb > 10 * 1024:
        print("警告：zip 超过 10MB，API 上传可能失败（限制 10MB）", file=sys.stderr)

    return b64


def main():
    parser = argparse.ArgumentParser(description="上传 Skill 到 Knot 平台")
    parser.add_argument("skill_dir", help="Skill 目录路径")
    parser.add_argument("--skill-id", help="指定 Skill ID（不填则按 display_name 自动匹配）")
    parser.add_argument("--env", default="knot.woa.com",
                        choices=["knot.woa.com", "test.knot.woa.com"],
                        help="Knot 环境（默认正式环境）")
    parser.add_argument("--dry-run", action="store_true", help="只打包不上传，用于验证")
    args = parser.parse_args()

    skill_dir = os.path.abspath(args.skill_dir)
    if not os.path.isdir(skill_dir):
        print(f"错误：目录不存在 {skill_dir}", file=sys.stderr)
        sys.exit(1)

    name, desc = parse_skill_md(skill_dir)
    base_url = f"https://{args.env}/apigw"
    print(f"Skill:  {name}", file=sys.stderr)
    print(f"环境:   {args.env}", file=sys.stderr)

    print("打包中...", file=sys.stderr)
    b64 = pack_skill(skill_dir, name)

    if args.dry_run:
        print("--dry-run 模式，跳过上传", file=sys.stderr)
        print(json.dumps({"skill_name": name, "env": args.env, "dry_run": True}))
        return

    token = load_token()
    headers = {"Content-Type": "application/json", "X-knot-api-token": token}

    skill_id = args.skill_id
    if not skill_id:
        # 按 display_name 自动查找
        resp = requests.post(f"{base_url}/openapi/v1/skills/get", headers=headers,
                             json={"category": "managed"}, timeout=30)
        resp.raise_for_status()
        skills = resp.json().get("data", {}).get("list", [])
        matches = [s for s in skills if s.get("display_name") == name]

        if len(matches) == 1:
            skill_id = str(matches[0]["id"])
            print(f"找到已有 Skill，ID={skill_id}", file=sys.stderr)
        elif len(matches) == 0:
            print("未找到同名 Skill，创建中...", file=sys.stderr)
            resp = requests.post(f"{base_url}/openapi/v1/skills/add_without_file", headers=headers,
                                 json={"display_name": name, "description": desc}, timeout=30)
            resp.raise_for_status()
            new_id = resp.json().get("data", {}).get("id")
            if not new_id:
                print(f"错误：创建失败 {resp.json()}", file=sys.stderr)
                sys.exit(1)
            skill_id = str(new_id)
            print(f"已创建 Skill，ID={skill_id}", file=sys.stderr)
        else:
            print(f"错误：发现 {len(matches)} 个同名 Skill，请用 --skill-id 指定", file=sys.stderr)
            for m in matches:
                print(f"  ID={m['id']}  {m.get('display_name')}  vis={m.get('visibility')}", file=sys.stderr)
            sys.exit(1)

    print(f"上传中（ID={skill_id}）...", file=sys.stderr)
    resp = requests.post(f"{base_url}/openapi/v1/skills/update_file", headers=headers,
                         json={"id": skill_id, "file_data": b64, "file_name": f"{name}.zip"},
                         timeout=60)
    resp.raise_for_status()
    result = resp.json()

    if result.get("code") == 0:
        print(f"✅ 上传成功！", file=sys.stderr)
        print(f"Skill 详情: https://{args.env}/skills/detail/{skill_id}", file=sys.stderr)
        print(json.dumps({"success": True, "skill_id": skill_id, "skill_name": name,
                          "url": f"https://{args.env}/skills/detail/{skill_id}"}))
    else:
        print(f"❌ 上传失败：{result}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
