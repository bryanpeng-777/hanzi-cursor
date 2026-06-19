#!/bin/bash
# 营地 Knot Agent 技能同步脚本
# 用法: KNOT_TOKEN=xxx bash sync-camp-to-knot.sh
# 或:   bash sync-camp-to-knot.sh（会提示输入 Token）

set -e

TOKEN=${KNOT_TOKEN:-""}
if [ -z "$TOKEN" ]; then
  read -p "请输入 Knot Token: " TOKEN
fi

CONFIG="$(dirname "$0")/knot-camp-skills.json"
BASE_URL="https://knot.woa.com/apigw"

echo "🚀 开始同步营地 Knot 技能..."

python3 << EOF
import requests, json, os, zipfile, base64, tempfile, sys

TOKEN = "$TOKEN"
BASE_URL = "$BASE_URL"
HEADERS = {"Content-Type": "application/json", "X-knot-api-token": TOKEN}

with open("$CONFIG") as f:
    config = json.load(f)

results = []
for skill in config["skills"]:
    skill_dir = os.path.expanduser(skill["local_path"])
    inner_name = skill["inner_name"]
    skill_id = skill["knot_id"]
    display_name = skill["display_name"]

    if not os.path.exists(skill_dir):
        print(f"⚠️  目录不存在，跳过: {skill_dir}")
        continue

    # 打包
    tmp = tempfile.NamedTemporaryFile(suffix='.zip', delete=False)
    tmp.close()
    with zipfile.ZipFile(tmp.name, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(skill_dir):
            dirs[:] = [d for d in dirs if not d.startswith('.') and d != '__pycache__']
            for f in files:
                if f.startswith('.') or f.endswith('.pyc'):
                    continue
                fp = os.path.join(root, f)
                zf.write(fp, os.path.join(inner_name, os.path.relpath(fp, skill_dir)))
    size = os.path.getsize(tmp.name)
    with open(tmp.name, 'rb') as f:
        b64 = base64.b64encode(f.read()).decode()
    os.remove(tmp.name)

    # 上传
    up = requests.post(f"{BASE_URL}/openapi/v1/skills/update_file", headers=HEADERS,
        json={"id": skill_id, "file_data": b64, "file_name": f"{inner_name}.zip"})
    result = up.json()
    if result.get("code") == 0:
        print(f"  ✅ {display_name} (ID={skill_id})  {size/1024:.1f}KB  {skill['knot_url']}")
    else:
        print(f"  ❌ {display_name} 失败: {result}")

print("\n🎉 同步完成！")
EOF
