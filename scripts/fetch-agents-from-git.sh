#!/usr/bin/env bash
# 从 Git 仓库拉取 agents 到 .cursor/agents/（供 Cloud Agent 或本机无 ~/.claude 时使用）
#
# 环境变量：
#   CLAUDE_AGENTS_GIT_URL      agents 仓库 URL（默认 github.com/bryanpeng-777/claude-agents.git）
#   CLAUDE_AGENTS_GIT_REF      分支或 tag（默认 main）
#   CLAUDE_AGENTS_GIT_SPARSE   大仓 sparse 路径；留空表示仓库根即 agents 内容
#                              设为 agents 时从 ~/.claude 大仓只检出 agents/ 目录
#   PROJECT_ROOT               项目根（默认脚本所在目录的上一级）
#
# 示例：
#   bash scripts/fetch-agents-from-git.sh
#   CLAUDE_AGENTS_GIT_URL=https://github.com/you/claude.git \
#     CLAUDE_AGENTS_GIT_SPARSE=agents bash scripts/fetch-agents-from-git.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
DEST="$PROJECT_ROOT/.cursor/agents"
GIT_URL="${CLAUDE_AGENTS_GIT_URL:-https://github.com/bryanpeng-777/claude-agents.git}"
GIT_REF="${CLAUDE_AGENTS_GIT_REF:-main}"
GIT_SPARSE="${CLAUDE_AGENTS_GIT_SPARSE:-}"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "拉取 agents：$GIT_URL (ref=$GIT_REF sparse=${GIT_SPARSE:-<root>})"

if [[ -n "$GIT_SPARSE" ]]; then
    git clone --depth 1 --filter=blob:none --sparse --branch "$GIT_REF" "$GIT_URL" "$TMPDIR/repo"
    (
        cd "$TMPDIR/repo"
        git sparse-checkout set "$GIT_SPARSE"
    )
    SRC="$TMPDIR/repo/$GIT_SPARSE"
else
    git clone --depth 1 --branch "$GIT_REF" "$GIT_URL" "$TMPDIR/repo"
    SRC="$TMPDIR/repo"
fi

if [[ ! -d "$SRC" ]]; then
    echo "错误：检出后未找到目录 $SRC" >&2
    exit 1
fi

agent_count=$(find "$SRC" -type f \( -name '*.md' -o -name '*.mdc' \) | wc -l | tr -d ' ')
if [[ "$agent_count" -eq 0 ]]; then
    echo "错误：仓库中未找到任何 .md / .mdc agent 文件" >&2
    exit 1
fi

mkdir -p "$DEST"
rsync -a \
    --include='*/' \
    --include='*.md' \
    --include='*.mdc' \
    --exclude='*' \
    "$SRC/" "$DEST/"

echo "完成 ✓ 已写入 $DEST（共 $agent_count 个 agent/workflow 文件）"
