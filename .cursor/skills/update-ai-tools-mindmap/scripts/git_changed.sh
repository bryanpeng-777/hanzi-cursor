#!/bin/bash
# git_changed.sh — 基于 git 的增量扫描脚本
# 输出 ~/.claude 仓库中近期变更的 agents/skills/knowledge 文件 JSON
#
# 用法：
#   bash git_changed.sh                # 默认：仅扫未提交变更（最快）
#   bash git_changed.sh 5              # 同时扫最近 5 次提交里的新增/删除（用于补漏）
#   RECENT_N=10 bash git_changed.sh    # 通过环境变量
#
# 输出 JSON 字段：
#   untracked     - 未跟踪的新文件（agents/*.md, skills/*/SKILL.md, knowledge/**）
#   modified      - 已修改但未提交的文件
#   deleted       - 已删除（未提交）
#   renamed       - 重命名（最近 N 次提交，仅 RECENT_N>0 时）
#   recent_added  - 最近 N 次提交里新增的文件（仅 RECENT_N>0 时；用于补漏）

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
RECENT_N="${1:-${RECENT_N:-0}}"

cd "$CLAUDE_DIR"

# 只关心工具入口级文件：
#   - agents/*.md（顶层 .md 文件，不含子目录）
#   - skills/<name>/SKILL.md（不论嵌套多少层，只看 SKILL.md）
#   - knowledge/<...>/*.md 或 *.json（knowledge 下所有 .md/.json）
INCLUDE_PATTERN='^(agents/[^/]+\.md$|skills/.*/SKILL\.md$|knowledge/.+\.(md|json)$)'

# 排除画布本身和本技能自己
EXCLUDE_PATTERN='knowledge/ai-tools-mindmap\.canvas\.tsx$|skills/update-ai-tools-mindmap/'

filter() {
  grep -E "$INCLUDE_PATTERN" 2>/dev/null | grep -vE "$EXCLUDE_PATTERN" 2>/dev/null || true
}

# 1. untracked（未跟踪的新文件）
UNTRACKED=$(git ls-files --others --exclude-standard | filter | sort -u)

# 2. modified（已修改未提交）
MODIFIED=$(git diff --name-only --diff-filter=M | filter | sort -u)

# 3. deleted（未提交的删除）
DELETED_UNCOMMITTED=$(git diff --name-only --diff-filter=D | filter)

# 4 & 5: 只在 RECENT_N > 0 时扫历史提交
if [ "$RECENT_N" -gt 0 ]; then
  DELETED_RECENT=$(git log -n "$RECENT_N" --diff-filter=D --name-only --pretty=format: | filter)
  DELETED=$(printf "%s\n%s" "$DELETED_UNCOMMITTED" "$DELETED_RECENT" | sort -u | sed '/^$/d')

  RENAMED=$(git log -n "$RECENT_N" --diff-filter=R --name-status --pretty=format: \
    | awk '/^R/ {printf "%s\t%s\n", $2, $3}' \
    | while IFS=$'\t' read -r from to; do
        if echo "$from" | grep -qE "$INCLUDE_PATTERN" && ! echo "$from" | grep -qE "$EXCLUDE_PATTERN"; then
          echo "$from"$'\t'"$to"
        fi
      done | sort -u)

  RECENT_ADDED=$(git log -n "$RECENT_N" --diff-filter=A --name-only --pretty=format: | filter | sort -u)
else
  DELETED="$DELETED_UNCOMMITTED"
  RENAMED=""
  RECENT_ADDED=""
fi

# 输出 JSON
python3 - <<PYEOF
import json, os, sys

def split_lines(s):
    return [l for l in s.strip().split("\n") if l.strip()]

def parse_renamed(s):
    out = []
    for line in s.strip().split("\n"):
        if "\t" in line:
            f, t = line.split("\t", 1)
            out.append({"from": f.strip(), "to": t.strip()})
    return out

untracked    = split_lines("""$UNTRACKED""")
modified     = split_lines("""$MODIFIED""")
deleted      = split_lines("""$DELETED""")
renamed      = parse_renamed("""$RENAMED""")
recent_added = split_lines("""$RECENT_ADDED""")

# recent_added 去掉已经在 untracked 里的项（避免重复）
recent_added = [x for x in recent_added if x not in untracked]

result = {
    "untracked":    untracked,
    "modified":     modified,
    "deleted":      deleted,
    "renamed":      renamed,
    "recent_added": recent_added,
    "summary": {
        "total_changes": len(untracked) + len(modified) + len(deleted) + len(renamed) + len(recent_added),
        "recent_n_commits": $RECENT_N,
    }
}

print(json.dumps(result, ensure_ascii=False, indent=2))
PYEOF
