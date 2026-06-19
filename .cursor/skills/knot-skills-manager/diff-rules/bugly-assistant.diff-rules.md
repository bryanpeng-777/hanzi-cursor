# bugly-assistant diff-rules

最后同步时间：2026-06-17

## 已删除/简化的内容

### 1. 「编排型角色」委托禁令 → 删除
原文：`⛔ 执行身份强制规则：本角色是「编排型入口」，必须由主对话 Claude 实例直接扮演执行，严禁通过 Agent tool 把自身整体委托给子 agent`
Knot版：删除，允许被 camp-problem-analyzer 通过 Agent tool 调度

### 2. `Read ~/.claude/agents/bugly-assistant.md` 自读操作 → 删除
原文：第一个动作必须 `Read ~/.claude/agents/bugly-assistant.md`
Knot版：删除，Knot 上没有本地文件

### 3. 本地知识文件读取 → 替换为 camp-knowledge-base 技能调用
原文：`~/.claude/knowledge/bugly-assistant/shared/reference.md` 等
Knot版：调用 camp-knowledge-base 技能（domain=bugly）

### 4. `python3 ~/.claude/skills/bugly-issue-analyze-agent/scripts/query_agent.py` 调用 → 删除
原文：Step 1 调用本地 Python 脚本进行深度分析
Knot版：使用 bugly-user-investigator + bugly-data-analyzer 技能替代

### 5. `cr-assistant` 代码审查循环 → 删除
原文：Step 2 代码审查循环（cr-assistant → bugly-issue-analyze-agent）
Knot版：删除，简化流程

### 6. 域知识 git push → 删除
原文：`cd ~/.claude/knowledge && git add bugly-assistant/ && git commit -m "..." && git push origin main`
Knot版：删除

### 7. 模式B（易修复巡检模式）→ 删除
原文：包含 scanner.py 脚本调用等复杂巡检逻辑
Knot版：删除，仅保留排查模式

### 8. Step 0~4 全套清单 → 简化为4步清单
原文：Step 0~4 含域知识检索、bugly-issue-analyze-agent、CR循环、责任人分配
Knot版：简化为 Step 0~3（知识检索、查询Bugly、深度分析、责任人分配）
