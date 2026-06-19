#!/bin/bash
# build-knowledge.sh — 重新打包 camp-knowledge-base 并上传到 Knot
# 用法：bash build-knowledge.sh [--dry-run]
set -e

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
UPLOAD_SCRIPT=~/.claude/skills/knot-skills-manager/scripts/knot_upload.py

echo "📦 构建 camp-knowledge-base..."
echo "目录：$SKILL_DIR"

# Step 1: 复制动态缓存（企业微信文档）
echo ""
echo "🔄 复制动态缓存文件..."
mkdir -p "$SKILL_DIR/camp"
CACHE_DIR=~/.claude/skills/knowledge-assistant/cache/camp-problem-analyzer
if [ -d "$CACHE_DIR" ]; then
    cp "$CACHE_DIR"/*.md "$SKILL_DIR/camp/" 2>/dev/null && \
        echo "  ✅ camp 动态缓存：$(ls "$CACHE_DIR"/*.md | wc -l | tr -d ' ') 个文件" || \
        echo "  ⚠️ camp 动态缓存目录为空"
else
    echo "  ⚠️ 缓存目录不存在: $CACHE_DIR，跳过"
fi

# Step 2: 复制静态知识文件
echo ""
echo "📖 复制静态知识文件..."

copy_domain() {
    local src="$1" dst="$2" name="$3"
    mkdir -p "$dst"
    if [ -d "$src" ] && ls "$src"/*.md >/dev/null 2>&1; then
        cp "$src"/*.md "$dst/"
        echo "  ✅ $name：$(ls "$src"/*.md | wc -l | tr -d ' ') 个文件"
    else
        echo "  ⚠️ $name 源目录为空或不存在，跳过"
    fi
}

copy_domain ~/.claude/knowledge/camp-problem-analyzer/shared "$SKILL_DIR/camp" "camp 静态知识"
copy_domain ~/.claude/knowledge/galileo-assistant/shared "$SKILL_DIR/galileo" "galileo 静态知识"
copy_domain ~/.claude/knowledge/dev-assistant/shared "$SKILL_DIR/dev" "dev 静态知识"
copy_domain ~/.claude/knowledge/bugly-assistant/shared "$SKILL_DIR/bugly" "bugly 静态知识"

# Step 3: 统计
echo ""
TOTAL=$(find "$SKILL_DIR" -name "*.md" ! -name "SKILL.md" | wc -l | tr -d ' ')
echo "✅ 构建完成：共 $TOTAL 个知识文件"

# Step 4: 上传
if [ "$1" = "--dry-run" ]; then
    echo ""
    echo "🔍 --dry-run 模式，跳过上传"
    python3 "$UPLOAD_SCRIPT" "$SKILL_DIR" --dry-run
else
    echo ""
    echo "🚀 上传到 Knot..."
    python3 "$UPLOAD_SCRIPT" "$SKILL_DIR"
fi
