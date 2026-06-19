# tech-lead-assistant diff-rules

最后同步时间：2026-06-17

## 已删除/简化的内容

### 1. 本地知识文件读取 → 删除
原文：`~/.claude/knowledge/tech-lead-assistant/shared/reference.md`
Knot版：删除，tech-lead-assistant 主要通过 code-owner-assigner 查 git log，无需领域知识

### 2. `Read ~/.claude/agents/dev-assistant.md` 委托模式 → 简化
原文：读取本地 dev-assistant.md 全文，通过 Task 工具粘贴全文委托
Knot版：直接通过 Knot 子 Agent 调用 dev-assistant，无需粘贴全文

### 3. `Read ~/.claude/agents/cr-assistant.md` 委托模式 → 删除
原文：读取本地 cr-assistant.md 全文，委托 cr-assistant
Knot版：删除，Knot 版 tech-lead-assistant 仅专注责任人分配，不转发 cr 任务

### 4. Step 5 域知识更新 → 删除
原文：写入 knowledge 目录
Knot版：删除

### 5. cr-assistant 路由 → 删除
原文：涉及「CR」「代码审查」时转发 cr-assistant
Knot版：删除，Knot 版仅保留责任人分配能力
