---
name: skill-to-subagent
description: 将「小助手」类 skill（*-assistant 命名规范）从 SKILL.md 格式转换为 ~/.claude/agents/ subagent 格式，并同步在 ~/.claude/knowledge/{name}/ 下创建知识目录、迁移存量 knowledge、提交到 git。当用户说「把 XXX 转为 subagent」「小助手转 subagent」「skill 转 agent」「转换小助手」「skill-to-subagent」「帮我转一下」时触发。支持单个转换和批量转换所有小助手。
---

# Skill → Subagent 转换器

将 `~/.claude/skills/*-assistant/SKILL.md` 转换为 `~/.claude/agents/{name}.md`，同时迁移 knowledge 到 `~/.claude/knowledge/{name}/`。

---

## 准备工作：理解两种格式的差异

| 维度 | SKILL.md 格式 | Subagent .md 格式 |
|------|-------------|-----------------|
| 本质 | AI 读取并执行的「说明书」 | AI 的「系统提示词」（AI 就是这个角色） |
| 存放位置 | `~/.claude/skills/{name}/SKILL.md` | `~/.claude/agents/{name}.md` |
| Knowledge 路径 | `~/.claude/skills/{name}/knowledge/` | `~/.claude/knowledge/{name}/` |
| Git commit 路径 | `~/.claude/skills` | `~/.claude/knowledge` |
| `context_mode` 字段 | frontmatter 中有 | 不需要，去掉 |
| 人格开篇 | 可能有「读取本技能...」类元说明 | 改为「你是 XXX 全能小助手...」 |

---

## Step 1：确定要转换的技能

**单个转换**：用户指定了名字（如「把 galileo-assistant 转为 subagent」）→ 直接处理该技能。

**批量转换**：用户说「转换所有小助手」→ 列出所有候选，让用户确认后逐个处理：

```bash
ls ~/.claude/skills/ | grep "\-assistant$"
ls ~/.claude/skills/camp/ | grep "\-assistant$"
```

过滤掉**已经转换**的（在 `~/.claude/agents/` 下已有对应 `.md` 文件的）：

```bash
ls ~/.claude/agents/ | sed 's/\.md$//'
```

输出差集，告知用户哪些还未转换，请求确认。

---

## Step 2：逐个执行转换流程

对每个待转换技能执行以下子步骤：

### 2.1 读取原始 SKILL.md

```
~/.claude/skills/{name}/SKILL.md
```

若文件不存在，跳过并提示「未找到 {name}/SKILL.md，跳过」。

### 2.2 内容转换规则

在内存中对 SKILL.md 内容做以下变换，生成 agent 内容：

**① 清理 frontmatter**

- 保留 `name`、`description`
- 删除 `context_mode`（subagent 不使用此字段）

**② 开篇人格化**

若正文第一段是技能元说明（如「读取本技能...」「本技能用于...」），替换为：

```
你是 {中文名称}全能小助手，接收一切 {domain} 相关问题，智能分配给对应子流程处理，完成后自动将结论写入相应记录文档。
```

若原 SKILL.md 已有人格化开篇（如「你是...」），保留不改。

**③ 替换 knowledge 路径**

所有出现 `~/.claude/skills/{name}/knowledge/` 的地方，替换为 `~/.claude/knowledge/{name}/`：

- Step 0 的读取路径
- Step 5 的写入路径和 git commit 命令

**④ 替换 git commit 路径**

```
# 旧
cd ~/.claude/skills && git add {name}/knowledge/ && ...

# 新
cd ~/.claude/knowledge && git add {name}/ && ...
```

**⑤ 其余内容保持不变**

子流程调用、判断树、落表逻辑、子技能路径表等全部原样保留。

### 2.3 写入 agents 文件

```bash
# 检查是否已存在
ls ~/.claude/agents/{name}.md 2>/dev/null
```

若已存在，询问用户是否覆盖。确认后写入：

```
~/.claude/agents/{name}.md
```

### 2.4 创建 knowledge 目录并迁移存量数据

**检查原 knowledge 是否存在**：

```bash
ls ~/.claude/skills/{name}/knowledge/ 2>/dev/null
```

**情况 A：原 knowledge 存在** → 迁移：

```bash
mkdir -p ~/.claude/knowledge/{name}
cp -r ~/.claude/skills/{name}/knowledge/. ~/.claude/knowledge/{name}/
echo "迁移完成"
```

**情况 B：原 knowledge 不存在** → 按助手类型创建空模板（参考下方模板规范）。

#### Knowledge 初始模板规范

```bash
mkdir -p ~/.claude/knowledge/{name}/shared
```

根据助手域类型生成对应文件：

| 助手域 | shared/ 下的文件 |
|--------|----------------|
| bugly | `reference.md`, `crash-patterns.md`, `anr-patterns.md`, `foom-patterns.md` |
| galileo | `reference.md`, `alert-patterns.md`, `metric-patterns.md` |
| oncall | `reference.md`, `oncall-patterns.md`, `resolution-guide.md` |
| cr（代码审查） | `reference.md`, `review-patterns.md` |
| 其他 | `reference.md`, `patterns.md` |

每个 patterns 文件使用统一模板：

```markdown
# {Domain} {类型} 知识库

{一句话说明}。由 {name} 在分析过程中自动积累和更新。

---

<!-- 新条目示例格式：

## 模式名称

- **现象**：xxx
- **根因**：xxx
- **处置方式**：建议修复 / 建议屏蔽 + 一句话理由
- **首次记录**：yyyy-mm-dd
- **最后更新**：yyyy-mm-dd

-->

<!-- 知识库初始为空，由 {name} 在实际使用中自动积累 -->
```

`reference.md` 使用：

```markdown
# {Domain} 域常识参考

平台固定参数、机制说明、字段含义等背景知识。由 {name} 在分析过程中自动积累。

---

## 平台参数

（待积累）

## 机制说明

（待积累）
```

### 2.5 提交到 git

```bash
# 提交 agents
cd ~/.claude/agents && git add {name}.md && git commit -m "feat: 新增 {name} subagent（从 skill 转换）" && git push origin main

# 提交 knowledge
cd ~/.claude/knowledge && git add {name}/ && git commit -m "feat: 初始化 {name} knowledge 目录" && git push origin main
```

---

## Step 3：输出转换报告

每个技能转换完后输出摘要：

```
✅ {name} 转换完成

📄 Subagent：~/.claude/agents/{name}.md
📚 Knowledge：~/.claude/knowledge/{name}/shared/（X 个文件）
   ├── shared/reference.md
   ├── shared/xxx-patterns.md
   └── ...
🔄 Knowledge 来源：从 skill 迁移 / 新建空模板
📦 已推送到 GitHub：claude-agents / claude-knowledge
```

批量转换结束后输出汇总：

```
=== 批量转换完成 ===
成功：X 个（列表）
跳过：X 个（已存在，未覆盖）
失败：X 个（原因）
```

---

## 注意事项

- **不删除原 SKILL.md**：转换完成后保留 `~/.claude/skills/{name}/SKILL.md`，两者并存。原 skill 仍可被 `<agent_skills>` 读取，subagent 是新增路径，不是替换
- **knowledge 不重复迁移**：若 `~/.claude/knowledge/{name}/` 已存在，询问用户是否覆盖，默认跳过
- **路径替换要精确**：只替换 knowledge 路径，不要误改子技能的 SKILL.md 路径（如 `~/.claude/skills/bugly-assigner/SKILL.md`）
- **frontmatter 的 description 保留触发词**：subagent 的 description 是触发机制，必须原样保留，不要精简
