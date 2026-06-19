---
name: ai-monorepo-builder
description: 为多个独立 git 仓库搭建 AI 友好型大仓（Monorepo）工作区。以一个主项目为核心，配合多个可复用基础模块积木，建立统一导航索引（根目录 CLAUDE.md）、功能路由表、Cursor 自动 commit 规则和跨包引用规范，让 AI 在大仓顶层接到任意开发任务都能自动路由到正确包。当用户提到「建大仓」「新建大仓」「大仓初始化」「大仓建设」「创建大仓」「把这些项目组织成大仓」「monorepo setup」「ai-monorepo-builder」时触发。即使用户只描述了主项目 + 若干基础模块的组合关系并希望 AI 方便地跨包开发，也应主动使用此技能。
---

# AI 友好型大仓建设技能

将多个独立 git 仓库组织为 AI 可高效导航的本地工作区：以主项目为核心，配合可复用的基础模块积木，AI 可在顶层接到任意开发任务并自动路由到正确包，改完代码后自动提交每个包。

## 核心架构理念

```
workspace/（本地工作区容器，无 git）
├── main-app/    → 主项目（独立 git repo，核心业务）
├── module-a/    → 基础模块（独立 git repo，可复用积木）
├── module-b/    → 基础模块（独立 git repo，可复用积木）
├── CLAUDE.md    → 大仓 AI 导航门户（本技能创建）
└── .cursor/rules/auto-commit.mdc  → AI 自动提交规则（本技能创建）
```

- 每个包保持独立 git repo，可单独发布复用
- 根目录只是本地容器，不是 git repo
- 跨包引用：发布用 Git URL，本地开发用 override 文件（不提交）
- 新增包：git clone 进来 + 更新 CLAUDE.md 两行，零额外配置

---

## Step 1：收集大仓信息

从对话上下文推断，不足时向用户确认：

1. **工作区路径**：大仓根目录在哪？
2. **主项目**：核心 App 是哪个目录？职责是什么？
3. **基础模块列表**：有哪些支持模块？每个的职责一句话描述？
4. **技术栈**：Flutter/Dart？Node.js？混合？（决定 override 文件格式）

整理后展示确认，等待用户确认或补充后继续。

---

## Step 2：扫描现有结构

扫描工作区根目录，对每个子目录检查：

```bash
# 是否有独立 git
ls <dir>/.git

# 是否有 CLAUDE.md
ls <dir>/CLAUDE.md

# 技术栈识别
ls <dir>/pubspec.yaml   → Flutter/Dart
ls <dir>/package.json   → Node.js

# .gitignore 是否已包含 override 排除
grep "pubspec_overrides" <dir>/.gitignore   # Flutter
```

列出扫描结果，标注哪些包需要创建/更新 CLAUDE.md、修复 .gitignore。

---

## Step 3：创建/更新根目录 CLAUDE.md

读取 `references/root-claude-template.md`，根据实际包信息填充后写入 `<workspace>/CLAUDE.md`。

已存在时：检查「包索引」「开发路由」是否包含所有已知包，补充缺失条目。

---

## Step 4：创建 Cursor 自动提交规则

读取 `references/cursor-rule-template.md`，替换包列表后写入 `<workspace>/.cursor/rules/auto-commit.mdc`。

如果 `.cursor/rules/` 目录不存在，先创建：
```bash
mkdir -p <workspace>/.cursor/rules
```

---

## Step 5：修复各包 .gitignore

对每个有独立 git repo 的 Flutter 包，检查 `.gitignore` 是否包含 `pubspec_overrides.yaml`：

```bash
grep "pubspec_overrides" <dir>/.gitignore
```

缺失时追加：
```
# 本地开发 path override，不提交
pubspec_overrides.yaml
```

Node.js 包无需处理（npm 无 override 机制）。

---

## Step 6：为各包创建/更新 CLAUDE.md

对每个包：

**无 CLAUDE.md 时**：读取 `references/package-claude-template.md`，填充包名/职责/路径后创建。

**已有 CLAUDE.md 时**：
1. 检查是否有「大仓可用积木」章节（或类似的跨包引用说明）
2. 没有则追加（参考 `references/package-claude-template.md` 中的积木章节模板）
3. 路径引用是否过时（旧机器路径），过时则更新为当前 workspace 路径

---

## Step 7：输出建设摘要

```
✅ 大仓建设完成！

📂 工作区：<workspace>
📋 根目录 CLAUDE.md：已创建/已更新（N 个包）
⚙️  Cursor 自动提交规则：已创建
🔒 .gitignore：N 个包已修复

包列表：
  ✅ main-app/     主项目 — CLAUDE.md ✓
  ✅ module-a/     基础模块 — CLAUDE.md 已创建
  ✅ module-b/     基础模块 — CLAUDE.md 已更新（补充积木章节）

💡 新增包时：git clone 到工作区 → 更新根目录 CLAUDE.md 两行即可
```

---

## 新增包到现有大仓

用户说「在大仓里加一个新包」「我又建了一个模块」时：

1. 确认包的路径和一句话职责
2. 在根目录 CLAUDE.md 的「包索引」和「开发路由」表中追加该包条目
3. 检查新包的 `.gitignore`（Flutter 包补 `pubspec_overrides.yaml`）
4. 为新包创建 CLAUDE.md（无则创建，有则检查跨包引用章节）

---

## 技术栈对应的 override 文件

| 技术栈 | override 文件 | .gitignore 排除规则 |
|--------|--------------|-------------------|
| Flutter/Dart | `pubspec_overrides.yaml` | `pubspec_overrides.yaml` |
| Node.js (npm) | 无标准机制（用 `npm link` 或 `file:` path dep）| — |
| Node.js (pnpm) | `pnpm-workspace.yaml` 的 workspace 协议 | — |
