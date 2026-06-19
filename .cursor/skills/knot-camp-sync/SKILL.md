---
name: knot-camp-sync
description: 营地问题排查小助手 Knot 同步助手。检测本地 agent/knowledge 文件变更，对比 Knot 专属版本（knot-skills-manager/agents/），过滤 diff-rules 中标注的无需同步内容，输出结构化更新报告和逐步操作指引。触发词：「更新knot问题排查小助手」「knot-camp-sync」。
---

# knot-camp-sync — Knot 同步报告生成器

本地有更新后，调用本 Skill，自动产出「需要更新 Knot 哪些内容」的报告。

---

## Step 1：检测本地变更

### 1a. Agent 文件变更检测

对以下 7 个本地 agent 文件，与对应的 Knot 专属版本做 diff：

| 本地源文件 | Knot 专属版本 |
|-----------|--------------|
| `~/.claude/agents/camp-problem-analyzer.md` | `~/.claude/skills/knot-skills-manager/agents/camp-problem-analyzer.md` |
| `~/.claude/agents/camp-info-extractor.md` | `~/.claude/skills/knot-skills-manager/agents/camp-info-extractor.md` |
| `~/.claude/agents/camp-verdict-agent.md` | `~/.claude/skills/knot-skills-manager/agents/camp-verdict-agent.md` |
| `~/.claude/agents/伽利略告警登记小助手.md` | `~/.claude/skills/knot-skills-manager/agents/伽利略告警登记小助手.md` |
| `~/.claude/agents/bugly-assistant.md` | `~/.claude/skills/knot-skills-manager/agents/bugly-assistant.md` |
| `~/.claude/agents/dev-assistant.md` | `~/.claude/skills/knot-skills-manager/agents/dev-assistant.md` |
| `~/.claude/agents/tech-lead-assistant.md` | `~/.claude/skills/knot-skills-manager/agents/tech-lead-assistant.md` |

执行方式：
```bash
diff ~/.claude/agents/<name>.md \
     ~/.claude/skills/knot-skills-manager/agents/<name>.md
```

若 Knot 专属版本文件不存在，标注「⚠️ 尚未建立 Knot 版本，需首次制作」。

### 1b. Knowledge 文件变更检测

检查以下知识文件的 `last_updated` 字段（文件 frontmatter 中），与 `knot-camp-skills.json` 中 `camp-knowledge-base` 的 `last_uploaded` 时间戳对比：

- `~/.claude/skills/knowledge-assistant/cache/camp-problem-analyzer/*.md`（企业微信文档缓存）
- `~/.claude/knowledge/camp-problem-analyzer/shared/*.md`
- `~/.claude/knowledge/galileo-assistant/shared/*.md`
- `~/.claude/knowledge/dev-assistant/shared/*.md`
- `~/.claude/knowledge/bugly-assistant/shared/*.md`

若任一文件比 `last_uploaded` 新，标注知识库需要重新打包。

---

## Step 2：过滤 diff-rules（排除无需同步的变更）

读取 `~/.claude/skills/knot-skills-manager/diff-rules/<agent-name>.diff-rules.md`，
将 Step 1 的 diff 结果中属于「已删除/简化内容」的行过滤掉。

过滤规则（全局适用，无需读文件也可快速判断）：
- 涉及 `~/.claude/` 本地路径的行（已被 skill 调用替换）
- `python3 ~/.claude/` 脚本调用
- `cd ~/.claude && git add/push` 操作
- `Read ~/.claude/agents/` 自读操作
- `bugly-assistant` 的委托禁令段落（「编排型角色」「禁止 Agent tool 整体委托」）
- `dev-assistant` 的编译、git commit、flutter-deps-search 相关段落
- `tech-lead-assistant` 的 cr-assistant 路由和委托段落

过滤后若 diff 为空，该 Agent 标注「✅ 无需更新」。

---

## Step 3：生成更新报告

输出结构化报告：

```
📋 Knot 营地问题排查小助手同步报告
生成时间：<timestamp>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 camp-knowledge-base Skill
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
<状态>
  ✅ 无需更新  /  ⚠️ 需要重新打包（N 个文件有更新）

若需重新打包，变更文件列表：
  - wecom-tab-aWXCa2.md（last_updated: <时间>）
  - ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 Agent System Prompts
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Agent 名称]  <✅ 无需更新 / ⚠️ 有 N 处变更 / 🆕 需首次制作>
  变更摘要（过滤后）：
  + 新增：<内容摘要>
  - 删除：<内容摘要>
  ~ 修改：<内容摘要>
  操作：在 Knot 平台「<Agent名>」→「Prompt」→ 更新以下内容：
    <具体要更新的段落或替换说明>

...（逐个 Agent）
```

---

## Step 4：输出操作指引

根据报告，输出**按顺序执行**的操作步骤：

```
📌 需要执行的操作（按顺序）：

[ ] 1. 重新打包 camp-knowledge-base（如有）
    bash ~/.claude/skills/camp-knowledge-base/build-knowledge.sh
    完成后在 knot-camp-skills.json 中更新 last_uploaded 为今天日期

[ ] 2. 更新 Knot Agent「<名称>」的 System Prompt
    打开：https://knot.woa.com/agents/<id>/edit
    在 Prompt 字段，将以下段落替换为新版本：
    --- 替换前 ---
    <原内容>
    --- 替换后 ---
    <新内容>

[ ] 3. 同步更新 Knot 专属版本文件（保持与 Knot UI 一致）
    文件：~/.claude/skills/knot-skills-manager/agents/<name>.md
    将变更同步到 Knot 专属版本

[ ] 4. 更新 diff-rules 中的同步时间戳
    文件：~/.claude/skills/knot-skills-manager/diff-rules/<name>.diff-rules.md
    将「最后同步时间」改为今天日期

[ ] 5. 更新 knot-camp-skills.json 中 camp-knowledge-base 的 last_uploaded（如有）
```

---

## 注意事项

- **Knot 专属版本文件不存在**时（首次上传后未建立），提示用户先按计划完成首次上传
- **diff-rules 文件不存在**时，跳过过滤步骤，输出完整 diff，并提示「建议首次同步后建立 diff-rules 文件」
- **只报告，不自动修改**：本 Skill 只产出报告和指引，不自动向 Knot API 推送变更（因 Knot 当前不支持 API patch System Prompt）
- **优先检查最高频修改的 Agent**：通常 camp-problem-analyzer 和伽利略告警登记小助手最常更新，可以优先 diff 这两个
