---
name: git-commit
description: 自动生成符合王者万象棋项目规范的 Git 提交信息，自动提取当前登录用户的上一次提交的 TAPD ID 作为默认值。支持 flutter_module 和 social-ios 两个项目，智能分析代码变更并推荐提交类型和作用域。使用场景：(1) 创建新的 Git 提交，(2) 需要符合 tools/commit-msg.sh 校验的提交信息，(3) 需要复用当前用户的上一次提交的 TAPD ID（--story 或 --bug），(4) 分析代码变更并生成提交信息。
---

# Git Commit

自动生成符合项目规范的 Git 提交信息并执行提交，可选 push 到远端。

## Quick Start

1. 运行 `scripts/commit_helper.py` 获取当前 Git 用户信息和当前用户的上一次提交信息
2. 根据推荐信息确认或修改提交类型、作用域和描述
3. 使用当前用户的上一次提交的 TAPD ID 作为默认值
4. **运行 pre-commit-reviewer 检查代码质量，发现问题逐一确认后修改**
5. 自动暂存文件并执行提交
6. 询问用户是否 push 到远端，确认后执行 `git push`

## Workflow

### 1. 检测工作目录

自动检测当前所在的 Git 仓库：
- `flutter_module` - Flutter 模块
- `social-ios` - iOS 原生应用

如果不在 Git 仓库中，提示用户切换到正确的目录。

### 2. 获取当前 Git 用户信息

运行 `scripts/commit_helper.py` 获取：
- 当前 Git 用户名和邮箱
- 当前用户的上一次提交信息（type、story ID、bug ID）
- 当前 Git 状态（已暂存、未暂存、未跟踪的文件）
- 推荐的提交类型和作用域

### 3. 确定提交信息

根据代码变更和当前用户的上一次提交信息确定：
- **提交类型**：根据变更文件推荐（feat/fix）
- **作用域**：根据文件路径推荐（dependency/database/router 等）
- **描述**：用户输入简洁描述（<20 字）
- **TAPD ID**：默认使用当前用户的上一次提交的 ID

### 4. 智能获取默认 TAPD ID

根据当前提交类型和上一次提交信息智能获取默认值：

| 当前类型 | 上一次类型 | 默认来源 |
|---------|-----------|---------|
| fix | fix | 上一次的 --bug |
| fix | feat | 上一次 body 中的 --bug |
| feat | feat | 上一次的 --story |
| feat | fix | 上一次 body 中的 --story |

### 5. 生成提交信息

根据提交类型选择格式：

**feat 等类型**：
```
<type>(scope): <description> --story=<story_id>
```

**fix 类型**：
```
fix(scope): <description> --bug=<bug_id>
```

### 6. 提交前代码检查

**在执行提交前，必须先运行 pre-commit-reviewer 检查代码质量。**

读取 `/Users/bryanpeng/.claude/skills/pre-commit-review/SKILL.md` 并执行。

**检查流程**：
1. 运行 pre-commit-reviewer 检查代码
2. **如果发现问题**（逻辑问题、内存泄漏、潜在 crash、未完成 TODO、测试代码误提交等）：
   - 列出所有发现的问题
   - **逐个问题询问用户是否同意修改**
   - 只有在用户明确确认后才进行修改
   - 修改完成后，再次运行 pre-commit-reviewer 检查
   - 重复此步骤直到所有问题都被修复
3. **如果没有发现任何问题**，直接继续执行提交流程

**重要**：
- 不得在未经用户确认的情况下自动修改代码
- 必须等用户明确同意后再执行修改操作
- 每次修改后都必须重新运行 pre-commit-reviewer 验证

### 7. 智能暂存文件

- 如果已有暂存文件，使用暂存的文件
- 如果没有暂存文件，自动暂存所有变更文件（排除 .DS_Store、*.lock 等临时文件）
- 显示暂存文件列表，让用户确认

### 8. 执行提交

```bash
git commit -m "<提交信息>"
```

显示提交结果和最新提交信息。

### 9. fix 类型提交后自动触发知识库记录

**仅当提交类型为 `fix` 时执行此步骤。**

提交成功后，读取本次 git diff（已提交的变更），判断是否满足以下任一条件：
- 改动超过 3 个文件，或改动行数超过 30 行
- 修复涉及多线程、生命周期、内存管理、初始化顺序等易踩坑领域
- 根因不显而易见（非简单的空值判断或 typo）

**满足任一条件**：无需用户开口，直接读取 `/Users/bryanpeng/.claude/skills/knowledge-collector/SKILL.md` 并执行，告知用户正在自动记录。

**均不满足**：静默跳过，不打扰用户。

### 10. Push 到远端

提交成功后，**询问用户是否 push 到远端**：

> 提交完成！是否 push 到远端？（执行 `git push`）

- **用户确认**：执行 `git push`，显示推送结果（包含远端分支信息）
- **用户拒绝**：跳过，告知用户可随时手动执行 `git push`

> **注意**：push 操作必须由 AI 执行，不得让用户自己操作。

## Commit Types

**只允许以下两种类型，禁止使用其他任何类型（如 refactor、docs、style、perf、test、chore、revert 等）：**

| Type | Description | Use Case |
|------|-------------|----------|
| `feat` | 新功能 | 添加新特性、功能模块、代码重构、依赖更新等所有非 bug 修复的变更 |
| `fix` | Bug 修复 | 修复问题、异常 |

## Common Scopes

| Scope | Description | File Patterns |
|-------|-------------|----------------|
| `dependency` | 依赖管理 | pubspec.yaml, Podfile |
| `database` | 数据库 | lib/database/ |
| `router` | 路由 | lib/trouter/, lib/navigator/ |
| `network` | 网络请求 | lib/network/, lib/api/ |
| `ui` | UI 组件 | packages/camp_ui/ |

## Examples

### Example 1: Feature Development

**Scenario**: Add gesture swipe to glory ranking hero selection panel

**Analysis**:
- Files: `packages/camp_ui/lib/hero_selection/`
- Last commit: `feat: 王者万象棋官方tab重构 --story=128912475`

**Result**:
```
feat(荣耀榜英雄选择面板): 新增手势滑动功能 --story=128912475
```

### Example 2: Bug Fix

**Scenario**: Fix ErrorWidget type error

**Analysis**:
- Files: `packages/camp_ui/lib/widgets/error_widget.dart`
- Last commit: `fix: 页面底部按钮无法点击 --bug=153563109`

**Result**:
```
fix(荣耀榜英雄选择面板): 修复 ErrorWidget 类型错误 --bug=153563109
```

### Example 3: Dependency Update

**Scenario**: Update Flutter component library

**Analysis**:
- Files: `pubspec.yaml`, `pubspec.lock`
- Last commit: `feat(dependency): Replace module version --story=123456789`

**Result**:
```
feat(dependency): 更新组件库，Android 动态照片适配 --story=123456789
```

## Format Specification

See [references/format.md](references/format.md) for detailed format requirements including:
- Commit message format
- Parameter descriptions
- Validation rules
- Common errors and solutions

## Validation

All commits must pass `tools/commit-msg.sh` validation:

- Type must be `feat` or `fix` only（其他类型均不允许）
- `fix` must use `--bug=`, others must use `--story=`
- TAPD ID must be at least 9 digits
- TAPD ID cannot be all zeros
- Format must match `<type>(scope): <description> --<param>=<id>`

## Script Usage

```bash
# Run helper script
python3 scripts/commit_helper.py

# Output:
# === 上一次提交信息 ===
# 提交: feat: 王者万象棋官方tab重构
# 类型: feat
# Story ID: 128912475
#
# === 当前变更 ===
# 已暂存: 0 个文件
# 未暂存: 3 个文件
# 未跟踪: 1 个文件
#
# === 推荐信息 ===
# 推荐类型: feat
# 推荐作用域: dependency
```

## Special Cases

### Merge Commits
Skip validation, use generated merge message directly.

### Conflicts
Detect unresolved conflicts and prompt user to resolve first.

### No Changes
Detect no pending changes and inform user.

### Multiple Repositories
When working across flutter_module and social-ios, clearly indicate which repository is being operated on.

### Bugfix Branch Period
When on a bugfix branch (e.g. `feature/xxx_bugfix`), ALL commits — including new feature additions — must use:
- Type: `fix`
- Format: `fix(scope): <description> --bug=<bug_id>`

This ensures consistency with other commits on the same bugfix branch. Do not use `feat` + `--story=` even when adding new functionality.
