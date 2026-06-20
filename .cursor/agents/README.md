# Cursor Agents（Cloud Agent 镜像）

本目录由 `sync-skills-to-tools` 从 `~/.claude/agents/` 自动同步，**不要手工编辑**。

## 同步命令（在本机执行）

```bash
cd ~/.claude/skills/sync-skills-to-tools
CURSOR_PROJECT_ROOTS="/path/to/hanzi-cursor" bash scripts/sync.sh --pull-first --cursor-only
```

同步完成后在本项目提交：

```bash
git add .cursor/agents && git commit -m "chore: 同步 agents 供 Cloud Agent 使用"
```

## 用途

Cloud Agent 无法访问 `~/.claude/agents/`，因此 workflow（如 `ui-design-workflow.md`）与 subagent 定义须镜像到此处。
