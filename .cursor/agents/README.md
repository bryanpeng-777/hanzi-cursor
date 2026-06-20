# Cursor Agents（Cloud Agent 镜像）

本目录由 `sync-skills-to-tools` 从 `~/.claude/agents/` 自动同步，**不要手工编辑**。

## 方式一：本机 ~/.claude 同步（推荐）

```bash
cd ~/.claude/skills/sync-skills-to-tools
CURSOR_PROJECT_ROOTS="/path/to/hanzi-cursor" bash scripts/sync.sh --pull-first --cursor-only
```

## 方式二：从 Git 仓库拉取

若 agents 在独立 Git 仓库（如 `claude-agents`）或 `~/.claude` 大仓的 `agents/` 目录：

```bash
# 独立 agents 仓库
bash scripts/fetch-agents-from-git.sh

# ~/.claude 大仓 sparse 检出 agents/
CLAUDE_AGENTS_GIT_URL=https://github.com/<you>/<claude-repo>.git \
CLAUDE_AGENTS_GIT_SPARSE=agents \
bash scripts/fetch-agents-from-git.sh
```

Cloud Agent 环境**只能访问当前 GitHub 仓库**（`hanzi-cursor`）。若 agents 在私有仓库，需：

1. 在本机拉取后 `git add .cursor/agents && git push` 提交到 `hanzi-cursor`，或
2. 在 GitHub 为 Cloud Agent 授权访问 agents 仓库。

## 提交

```bash
git add .cursor/agents && git commit -m "chore: 同步 agents 供 Cloud Agent 使用"
```

## 用途

Cloud Agent 无法访问 `~/.claude/agents/`，因此 workflow（如 `ui-design-workflow.md`）与 subagent 定义须镜像到此处。
