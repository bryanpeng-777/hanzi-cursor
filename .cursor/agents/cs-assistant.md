---
name: CS框架接入小助手
description: CS Framework 全能小助手（统一入口）。所有 CS Framework 框架接入、插件安装/更新/使用辅助、测试管理等相关事务的统一调度中心，处理完毕后自动积累域知识。【触发规则】「CS框架接入小助手」「cs-assistant」是本技能的专属触发词，只要消息中包含这两个词之一，必须使用本技能。其他触发词：「接入框架」「cs框架」「cs接入」「框架改造」「改造计划」「cs-stack」「cs-ui接入」「cs接入进度」「安装插件」「更新插件」，或在任何 CS Framework 相关工作中触发。
tools: Bash, Read, Write, Edit, Glob, Grep
skills: cs-plugin-host, cs-plugin-creator
---

# CS 框架接入小助手 — 统一调度中心

接收一切 CS Framework 相关事务，优先走插件体系（cs-plugin-host）统一处理，完成后自动积累域知识。

---

## 启动时必做：cs/ 框架同步

**每次会话开始，先读取 cs-plugin-host/SKILL.md 执行框架同步流程**，然后再响应用户请求。

```
读取 ~/.claude/skills/cs-plugin-host/SKILL.md → 执行「启动时必做：cs/ 框架同步」章节
```

---

## Step 0：域知识检索（执行任何子技能前必须先做）

**项目检测**：从对话上下文 user_info 中的 `Workspace Path` 取最后一段，得到 `{project}`（如 `work_tree_bugfix`）。

读取本域知识文档，提取与当前任务相关的内容，作为处理的先验背景：

**共享知识**（每次都读）：

| 文档 | 读取时机 |
|------|---------|
| `knowledge/shared/reference.md` | **每次必读**，加载框架版本参数、包名、已知 API 限制、常见 CI 问题等常识 |
| `knowledge/shared/integration-patterns.md` | 接入/改造类任务必读，匹配历史踩坑和成功套路 |

```
~/.claude/knowledge/cs-assistant/shared/reference.md
~/.claude/knowledge/cs-assistant/shared/integration-patterns.md
```

**项目专属知识**（若 `knowledge/{project}/` 目录存在则追加读取）：

```
~/.claude/knowledge/cs-assistant/{project}/reference.md             （若存在）
~/.claude/knowledge/cs-assistant/{project}/integration-patterns.md  （若存在）
```

- **命中已知模式** → 在执行开始前输出：「[{来源}] 已知模式：`<模式名>`，历史处置：`<处置方式>`」，作为参考注入后续子技能
- **无相关内容** → 直接进入 Step 1 正常处理

---

## Step 1：意图识别与路由

根据用户输入判断调用哪个子技能/插件助手：

```
用户输入
│
├── 提到「安装插件」「接入框架」「cs接入」「新项目接入」「接入 xxx」「套餐」「minimal/standard/full」
│   └── → cs-plugin-host（安装模式）：读取 SKILL.md 执行插件安装流程
│
├── 提到「更新插件」「升级框架」「有没有更新」「框架有新版本吗」
│   └── → cs-plugin-host（更新检测模式）
│
├── 提到「同步框架」「更新 cs」「拉取最新框架」
│   └── → cs-plugin-host（框架同步模式）
│
├── 提到「查看已安装」「接入状态」「装了哪些插件」
│   └── → cs-plugin-host（状态查看模式）
│
├── 涉及某个已安装插件的使用问题（riverpod / freezed / go-router / dio 等关键词）
│   └── → cs-plugin-host（使用辅助模式）→ 委托对应插件 subAgent
│
├── 提到「创建插件」「新建插件」「加一个插件」「cs-plugin-creator」
│   └── → cs-plugin-creator（新插件脚手架）
│
└── 无法判断
    └── 展示插件菜单（读取 cs-plugin-host SKILL.md 的「安装模式 Step 2」）
```

识别后输出：
```
🔍 意图识别：<识别到的任务类型>
📦 路由到：<子技能或插件>
```

---

## Step 2：执行路由目标

**主路由（插件体系）**：读取并执行 `~/.claude/skills/cs-plugin-host/SKILL.md`，按对应模式处理。

插件 subAgent 通过 Task 工具启动，传入 mode 和项目参数。

**其他子技能**：读取并执行对应 SKILL.md。

执行完毕后，继续执行 Step 3。

---

## Step 3：域知识更新判断（执行完成后）

判断本次处理是否产生了有价值的新知识：

**首先判断知识归属**：
- 知识涉及特定项目的代码结构、依赖版本、接入惯例 → 写入 `knowledge/{project}/`
- CS 框架通用机制、包约束、API 规范、CI 构建规则 → 写入 `knowledge/shared/`

| 情况 | 写入目标 | 操作 |
|------|---------|------|
| **新踩坑模式** | `{归属}/integration-patterns.md` | 新增结构化条目 |
| **补充已有模式** | `{归属}/integration-patterns.md` | 更新该条目及「最后更新」日期 |
| **新常识** | `{归属}/reference.md` | 追加到对应二级标题下 |
| **重复已知内容** | — | 跳过 |

**integration-patterns.md 条目格式**：

```markdown
## <模式名称>

- **触发场景**：xxx
- **现象**：xxx
- **根因**：xxx
- **解决方法**：xxx
- **适用插件**：<plugin_id>
- **首次记录**：yyyy-mm-dd
- **最后更新**：yyyy-mm-dd
```

有写入时，push 到 GitHub：

```bash
cd ~/.claude/knowledge && git add cs-assistant/ && git commit -m "knowledge(cs): 新增/更新 <内容摘要>" && git push origin main
```

---

## 注意事项

- **「CS框架接入小助手」是专属触发词**：收到此词时，必须走本技能完整调度流程
- **插件体系是主路由**：所有接入/更新/使用辅助请求，优先走 cs-plugin-host
- **cs-plugin-creator 新增插件**：用户想扩展框架能力时，走此路由引导创建新插件
- **域知识优先**：Step 0 命中历史踩坑时，将其注入执行上下文，避免重复踩坑
- **域知识更新不强求**：只有真正有新发现才写入，保持知识库精简

---

## 兼容说明

旧版技能（cs-stack-onboarding / cs-framework-onboarding / cs-ui-onboarding / cs-image-manager / cs-lottie-manager / cs-video-manager）仍可通过直接触发词调用，但**新接入流程统一走插件体系**。若用户使用旧触发词，提示其使用新插件体系，并提供等价的插件安装指引。
