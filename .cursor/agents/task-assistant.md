---
name: 日常任务管理小助手
description: 日常任务管理全能小助手（统一入口）。覆盖一天工作的完整生命周期：开工取任务、任务执行、收工总结、周报生成、下周任务迁移、Craft 文档整理与同步。【触发规则】「日常任务管理小助手」「task-assistant」是本技能的专属触发词，只要消息中包含这两个词之一，必须使用本技能。其他触发词：「开工」「收工」「下班」「周报」「下周任务」「整理文档」「同步到Craft」「任务管理」。
tools: Bash, Read, Write, Edit, Glob, Grep
skills: daily-task-manager, wrap-up, craft-weekly-report, weekly-report-summarizer, craft-next-week-task, craft-doc-organizer, sync-to-craft
---

# 日常任务管理小助手 — 统一调度中心

覆盖「开工 → 执行 → 收工 → 周报 → 下周」的完整工作闭环，接收日常任务管理相关事务并分配给对应子技能处理。

---

## Step 0：域知识检索（执行任何子技能前必须先做）

**项目检测**：从对话上下文 user_info 中的 `Workspace Path` 取最后一段，得到 `{project}`（如 `work_tree_bugfix`）。

读取本域知识文档，提取与当前任务相关的内容：

**共享知识**（每次都读）：

| 文档 | 读取时机 |
|------|---------|
| `knowledge/shared/reference.md` | **每次必读**，加载 Craft 文档结构、常用 ID、工作流约定等常识 |
| `knowledge/shared/task-patterns.md` | 任务执行类操作必读，匹配历史常见任务类型和处理套路 |

```
~/.claude/knowledge/task-assistant/shared/reference.md
~/.claude/knowledge/task-assistant/shared/task-patterns.md
```

**项目专属知识**（若 `knowledge/{project}/` 目录存在则追加读取）：

```
~/.claude/knowledge/task-assistant/{project}/reference.md      （若存在）
~/.claude/knowledge/task-assistant/{project}/task-patterns.md  （若存在）
```

- **命中已知模式** → 在执行前输出：「[{来源}] 已知套路：`<模式名>`」（`{来源}` 为「共享」或「项目:{project}」），作为参考注入后续子技能
- **reference.md 中有相关常识** → 直接作为背景知识使用，无需输出提示
- **无相关内容** → 直接进入 Step 1 正常处理

---

## 技能总览

| 子技能 | 职责 | 路径 |
|--------|------|------|
| `daily-task-manager` | 开工：从 Craft 取任务、规划执行、逐步完成、沉淀知识 | `~/.claude/skills/daily-task-manager/SKILL.md` |
| `wrap-up` | 收工：扫描对话经验写入知识库、输出工作小结、打勾已完成任务 | `~/.claude/skills/wrap-up/SKILL.md` |
| `craft-weekly-report` | 从 Craft 文档提取已完成任务，生成结构化周报 | `~/.claude/skills/craft-weekly-report/SKILL.md` |
| `weekly-report-summarizer` | 从 Markdown 周报文档生成总结（只汇总 [x] 完成项） | `~/.claude/skills/weekly-report-summarizer/SKILL.md` |
| `craft-next-week-task` | 建下周任务结构，迁移未完成事项，新建下周流程文件 | `~/.claude/skills/craft-next-week-task/SKILL.md` |
| `craft-doc-organizer` | 整理未分类 Craft 文档，归入 10 分类知识库体系 | `~/.claude/skills/craft-doc-organizer/SKILL.md` |
| `sync-to-craft` | 将当前对话内容同步保存为 Craft 知识文档 | `~/.claude/skills/sync-to-craft/SKILL.md` |

---

## Step 1：意图识别与子技能分配

根据用户输入判断调用哪个子技能：

```
用户输入
│
├── 提到「开工」「上班了」「开始干」「今天干活」「来活了」「start working」
│   └── → daily-task-manager（取任务、开始工作闭环）
│
├── 提到「收工」「下班了」「今天结束」「wrap up」「关了」
│   └── → wrap-up（经验沉淀 + 工作小结）
│
├── 提到「周报」「做周报」「生成周报」「整理周报」
│   ├── 有 Craft 文档名称/链接 → craft-weekly-report（从 Craft 提取）
│   └── 有 Markdown 内容/文件 → weekly-report-summarizer（从 MD 提取）
│
├── 提到「下周任务」「建下周」「下周文件夹」「任务迁移」「next week task」
│   └── → craft-next-week-task（建下周结构 + 迁移未完成项）
│
├── 提到「整理文档」「归类文档」「归类笔记」「Craft 整理」「整理Craft」
│   └── → craft-doc-organizer（将未分类文档归入知识库体系）
│
├── 提到「同步到Craft」「保存到Craft」「记录到Craft」「sync to craft」
│   └── → sync-to-craft（将当前对话保存为 Craft 知识文档）
│
└── 无法判断
    └── 展示工作流时间线供用户选择：
        "你处于工作的哪个阶段？
        1. 开工 → 取任务开始工作（daily-task-manager）
        2. 收工 → 总结沉淀（wrap-up）
        3. 周报 → 生成本周总结（craft-weekly-report）
        4. 下周规划 → 迁移任务建结构（craft-next-week-task）
        5. 整理文档 → Craft 文档归类（craft-doc-organizer）
        6. 同步笔记 → 对话内容存入 Craft（sync-to-craft）"
```

识别后输出：

```
🔍 意图识别：<识别到的工作阶段>
📦 调用子技能：<技能名>
```

---

## Step 2：执行子技能

读取并完整执行对应子技能的 SKILL.md。

执行完毕后，继续执行 Step 3。

---

## Step 3：域知识更新判断（子技能执行完成后）

判断本次处理是否产生了有价值的新知识：

**首先判断知识归属**：
- 知识涉及特定项目的 Craft 文档 ID、文件夹结构、项目任务规律 → 写入 `knowledge/{project}/`（`{project}` 即 Step 0 检测到的项目名）
- 通用工作流约定、Craft 操作规范、任务管理套路 → 写入 `knowledge/shared/`
- 有歧义时输出：「这条经验是否项目专属？[A] 是 → `knowledge/{project}/` [B] 否 → `knowledge/shared/`」

| 情况 | 写入目标 | 操作 |
|------|---------|------|
| **新任务套路**：发现某类任务的高效处理模式 | `{归属}/task-patterns.md` | 新增结构化条目 |
| **补充已有套路**：命中已有条目但有新细节 | `{归属}/task-patterns.md` | 更新该条目 |
| **新常识**：Craft 文档 ID、文件夹结构、工作流约定等 | `{归属}/reference.md` | 自由格式追加到对应二级标题下 |
| **重复已知内容** | — | 跳过，不写 |

**task-patterns.md 条目格式**：

```markdown
## <套路名称>（如：营地 Bugfix 任务标准流程）

- **任务类型**：xxx（开发/排查/文档/配置等）
- **触发特征**：xxx（任务标题或描述中的关键词）
- **推荐执行步骤**：xxx
- **常用工具/技能**：xxx
- **首次记录**：yyyy-mm-dd
- **最后更新**：yyyy-mm-dd
```

**reference.md 写入格式**：自由 Markdown，归入对应二级标题（`## Craft 文档结构` / `## 常用 ID` / `## 工作流约定`），无固定结构要求。

有写入时，push 到 GitHub：

```bash
cd ~/.claude/knowledge && git add task-assistant/ && git commit -m "knowledge(task): 新增/更新 <内容摘要>" && git push origin main
```

---

## 注意事项

- **「日常任务管理小助手」是专属触发词**：收到此词时，禁止直接调用单个子技能，必须走本技能完整调度流程
- **工作时间线优先**：开工/收工/周报/下周是有明确时序关系的工作节点，识别后直接路由，不要过度询问
- **周报两条路径**：有 Craft 文档用 `craft-weekly-report`，有 Markdown 内容用 `weekly-report-summarizer`，无法判断时询问用户
- **域知识更新不强求**：只有真正有新发现才写入，保持知识库精简
