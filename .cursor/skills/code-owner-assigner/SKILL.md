---
name: code-owner-assigner
description: 通用代码责任人分配技能。给定堆栈文本/图片、代码片段或文件路径，通过 git log 多轮回溯找出最近活跃的开发者并输出权重排名。支持 crash/anr/foom 堆栈、普通代码片段、指定文件路径三种输入模式。从 crash-assigner 和 bugly-assigner 提取核心逻辑，作为主程小助手（tech-lead-assistant）的底层子技能。
---

# Code Owner Assigner — 通用代码责任人分配

## Overview

给定任意形式的代码位置信息（堆栈、代码片段、文件路径），通过 `git log` 多轮回溯，输出责任开发者权重排名，推荐主责人。

适用场景：
- **堆栈分析**：crash / ANR / FOOM 堆栈（图片或文本）
- **代码片段**：用户粘贴的某段代码，找出是谁写的
- **文件路径**：直接指定 `path/to/File.swift:123`

---

## 脚本分工

> **脚本处理**：提取文件路径+行号 → git log 回溯 → 输出 JSON 排名
> **AI 处理**：解析输入（图片/文本/代码片段）→ 过滤系统框架层 → 生成最终报告

```bash
# 从 stdin 堆栈文本分析
cat stack.txt | python3 scripts/git_trace.py

# 指定具体文件路径（支持多个）
python3 scripts/git_trace.py /path/to/File.swift:123 /path/to/Other.m:456
```

输出 JSON 中 `ranked_authors` 为权重排名，AI 取 `ranked_authors[0]` 为主责人。

---

## 输入模式

### 模式 A：堆栈文本 / 图片

**图片输入**：
- 用 Read 工具读取图片，识别文本内容
- 提取：文件路径、行号、类名、方法名、函数签名

**文本输入**：
- 直接解析堆栈文本，提取相同字段

**堆栈过滤规则**（过滤后只留业务代码层）：

| 过滤类型 | 示例关键词 |
|---------|-----------|
| 系统框架 | `UIKit` `Foundation` `libdispatch` `libobjc` `CoreFoundation` |
| Flutter 引擎 | `flutter_engine` `dart:` `package:flutter/` |
| 三方库 | `Pods/` `node_modules/` `.pub-cache/` |
| 匿名/未知符号 | `???` `<unknown>` `0x0000` |

### 模式 B：代码片段

用户粘贴一段代码时：
1. 提取代码中的类名、方法名、关键符号
2. 在 git 仓库中用 `git log -S` 搜索这些符号
3. 补充用 `grep -r` 定位文件路径，再转为模式 A

### 模式 C：文件路径

用户直接给出 `path/to/File.swift:123`：
- 直接进入 **步骤3：git 回溯**

---

## 工作流程

### 步骤 1：识别输入模式

判断用户输入属于 A / B / C，转为统一的「文件路径 + 行号列表」格式：

```
[
  { "file": "path/to/File.swift", "line": 123, "match_type": "exact" },
  { "file": "path/to/Other.swift", "line": null, "match_type": "fuzzy_class" }
]
```

### 步骤 2（仅堆栈）：分析堆栈结构

1. 从顶层往下扫描，过滤系统框架层
2. 取前 3~5 个业务代码帧
3. 输出：

```
关键帧:
  #0 MyController.swift:45 — MyController.viewDidLoad()
  #1 MyManager.swift:120  — MyManager.handleEvent(_:)
```

### 步骤 3：git 多轮回溯

对每个文件路径，按「1个月 → 2个月 → 3个月 → 6个月 → 1年」逐步扩大：

**方式1：精确匹配文件 + 行号（权重 3）**
```bash
git log --since="1 month ago" --name-only --pretty=format:"%h|%an|%ae|%ad|%s" -- [文件路径]
git log --since="1 month ago" -L [行号],[行号]:[文件路径] --pretty=format:"%h|%an|%ae|%ad|%s"
```

**方式2：模糊匹配类名 / 方法名（权重 2）**
```bash
git log --since="1 month ago" -S"[类名]" --pretty=format:"%h|%an|%ae|%ad|%s"
git log --since="1 month ago" --grep="[方法名]" --pretty=format:"%h|%an|%ae|%ad|%s"
```

**方式3：模块目录级匹配（权重 1）**
```bash
git log --since="1 month ago" -- [目录路径] --pretty=format:"%h|%an|%ae|%ad|%s"
```

**查看提交详情（⛔ 性能约束）**：

禁止裸 `git show <hash>`（会输出完整 diff，大提交极慢甚至卡死）。仅需作者/时间/摘要时用：

```bash
# 仅元信息（首选，最快）
timeout 10 git show <hash> --no-patch --format="%h|%an|%ae|%ad|%s"

# 需要变更文件列表时
timeout 10 git show <hash> --stat --format="%h|%an|%ae|%ad|%s"
```

禁止 `-p`、禁止省略 `--stat`/`--no-patch`。

退出条件：任意方式找到至少 1 条提交记录即停止扩大时间范围。

### 步骤 4：计算权重排名

```
开发者权重 = Σ(提交匹配方式权重 × 提交次数)
```

| 维度 | 权重 |
|------|------|
| 精确匹配文件/行号 | 3 |
| 类名/方法名模糊匹配 | 2 |
| 模块目录级别 | 1 |

**输出格式**：
```
提交者统计:
  开发者A (a@example.com):
    - 总分: 9  精确:3次  模糊:0次  模块:0次
    - 最近提交: 2026-04-20

  开发者B (b@example.com):
    - 总分: 3  精确:0次  模糊:1次  模块:1次
    - 最近提交: 2026-03-10
```

### 步骤 5：确定主责人

**分配规则**：
1. 权重最高者为主责人
2. 权重相同 → 选最近提交时间
3. 多人权重相近（差值 ≤ 2）→ 列出候选人供用户选择

### 步骤 6：输出责任分析报告

```
=== 代码责任人分析报告 ===

输入模式: [堆栈 / 代码片段 / 文件路径]
分析位置:
  [文件路径]:[行号] — [类名].[方法名]

Git 回溯范围: [X] 个月（[起始日期] ~ [结束日期]）
匹配提交数: [X] 次  涉及开发者: [X] 人

推荐主责人:
  👤 [姓名] ([邮箱])
  理由: [X]个月内提交 [N] 次，精确匹配权重 [X]，总权重 [X]

其他候选人:
  - [开发者A]: 总权重 [X]，最近提交 [日期]

相关提交记录:
  [hash] [日期] [姓名] — [commit message]
  [hash] [日期] [姓名] — [commit message]
```

---

## 重要规则

1. **时间回溯顺序**：严格按 1→2→3→6→12 个月，找到即停
2. **精确优先**：有精确匹配时不依赖模糊/模块结果
3. **过滤系统层**：堆栈模式下必须过滤，不把系统库帧带入 git 查询
4. **多候选人**：总权重差 ≤ 2 时列出候选，不强制选一个
5. **仓库目录**：在用户提供的项目路径下执行 git 命令，路径不对时主动询问
6. **git show 性能**：查看提交详情必须 `timeout 10` + `--no-patch` 或 `--stat`；禁止裸 `git show <hash>` 输出完整 diff
