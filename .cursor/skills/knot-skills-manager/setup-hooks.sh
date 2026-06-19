#!/bin/bash
# 新机器初始化：让 git 使用仓库内的 hooks 目录（一次性配置）
# 用法：bash ~/.claude/skills/knot-skills-manager/setup-hooks.sh

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOKS_DIR="knot-skills-manager/hooks"

cd "$REPO_ROOT"
git config core.hooksPath "$HOOKS_DIR"

echo "✅ git hooks 已指向: $HOOKS_DIR"
echo "   后续修改 hooks/ 下的文件并 commit，下次 commit 自动生效，无需重新安装。"
