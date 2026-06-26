#!/bin/bash
# 灯塔巡检 Knot 技能同步脚本
# 用法: bash sync-beacon-to-knot.sh
# Token 从 ~/.knot_token_cache.json 读取（knot_upload.py 自动处理）

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPLOAD="$SCRIPT_DIR/scripts/knot_upload.py"
CONFIG="$SCRIPT_DIR/knot-beacon-skills.json"

echo "🚀 开始同步灯塔巡检 Skills 到 Knot..."

declare -A RESULTS

for skill_path in \
  "$HOME/.claude/skills/beacon-inspection-pipeline" \
  "$HOME/.claude/skills/beacon-dashboard-inspector" \
  "$HOME/.claude/skills/beacon-data-fetcher" \
  "$HOME/.claude/skills/camp/beacon-report-synthesizer"
do
  name="$(basename "$skill_path")"
  echo ""
  echo "📦 上传: $name"
  out=$(python3 "$UPLOAD" "$skill_path" 2>&1)
  echo "$out"
  id=$(echo "$out" | grep -o '"skill_id": "[^"]*"' | head -1 | cut -d'"' -f4)
  url=$(echo "$out" | grep -o '"url": "[^"]*"' | head -1 | cut -d'"' -f4)
  if [ -n "$id" ]; then
    RESULTS["$name"]="$id|$url"
  fi
done

echo ""
echo "🎉 上传完成！请根据返回的 skill_id 更新 knot-beacon-skills.json。"
echo ""
echo "下一步（Knot UI 手动）："
echo "  1. 新建 Agent「灯塔看板巡检」"
echo "  2. 挂载上述 4 个 Skills + MCP: user-iWiki, user-wework-bot"
echo "  3. 粘贴 Prompt: $SCRIPT_DIR/agents/beacon-inspection-pipeline.md"
echo "  4. 绑定营地代码仓工作区"
echo "  5. 配置定时 Cron: 0 9 * * *"
echo "  6. 首次运行前: pip install playwright && playwright install chromium"
echo "  7. 初始化灯塔登录态: beacon-data-fetcher/scripts/beacon_login.py"
