---
name: monorepo-git
description: 大仓多 Git 仓库批量操作。当前目录下可能存在多个独立 git 仓库（父目录本身 + 各子目录），此技能对所有 git repo 统一执行 pull/push/status 等操作，逐一汇报结果。当用户说「大仓拉取」「大仓推送」「大仓同步」「大仓 status」「monorepo pull」「monorepo push」「批量拉取」「批量推送」「所有仓库拉取」「所有仓库推送」时触发。即使用户只说「大仓拉取」一个词，也应主动使用此技能。
---

# 大仓 Git 批量操作技能

对当前工作目录下的所有独立 git 仓库（父目录本身 + 一级子目录），统一执行 git 操作并汇报结果。

## 使用场景

大仓（Monorepo 工作区）中存在多个相互独立的 git 仓库，例如：

```
~/work_tree_bugfix/          ← 父目录本身也是 git repo
├── flutter_module/          ← 独立 git repo
├── social-ios/              ← 独立 git repo
└── some-tool/               ← 独立 git repo
```

每次拉取/推送都需要进入每个子目录逐一执行，繁琐且容易遗漏。本技能自动发现所有 repo 并批量处理。

---

## 触发词

- **大仓拉取** / **大仓 pull** → 执行 `git pull`
- **大仓推送** / **大仓 push** → 执行 `git push`
- **大仓同步** → 先 pull 再 push（完整同步）
- **大仓 status** / **大仓状态** → 执行 `git status --short`

---

## 核心流程

### Step 1：确认当前工作目录

从对话上下文 `Workspace Path` 或当前终端 `cwd` 获取大仓根目录路径。

若无法确定，询问用户：「请告诉我大仓根目录路径？」

### Step 2：发现所有 git 仓库

运行以下 Shell 命令发现根目录下所有 git repo：

```bash
MONOREPO_ROOT="<大仓根目录>"

# 收集所有 git repo 路径
REPOS=()

# 检查父目录本身
if [ -d "$MONOREPO_ROOT/.git" ]; then
  REPOS+=("$MONOREPO_ROOT")
fi

# 检查一级子目录
for dir in "$MONOREPO_ROOT"/*/; do
  if [ -d "${dir}.git" ]; then
    REPOS+=("${dir%/}")
  fi
done

echo "发现 ${#REPOS[@]} 个 git 仓库："
for repo in "${REPOS[@]}"; do
  echo "  - $repo"
done
```

展示发现的仓库列表，让用户确认后再执行操作（或说「直接执行」跳过确认）。

### Step 3：执行 git 操作

根据触发词确定操作类型，对每个 repo 依次执行：

#### 大仓拉取（git pull）

```bash
for repo in "${REPOS[@]}"; do
  echo ""
  echo "═══════════════════════════════"
  echo "📦 $(basename $repo)"
  echo "   路径：$repo"
  echo "───────────────────────────────"
  
  cd "$repo"
  
  # 检查是否有未提交的修改
  DIRTY=$(git status --short)
  if [ -n "$DIRTY" ]; then
    echo "⚠️  有未提交的修改，跳过 pull（避免冲突）："
    git status --short
    continue
  fi
  
  # 检查是否有远程 upstream
  REMOTE=$(git remote)
  if [ -z "$REMOTE" ]; then
    echo "⚠️  无远程仓库配置，跳过"
    continue
  fi
  
  git pull
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ 拉取成功"
  else
    echo "❌ 拉取失败（exit code: $EXIT_CODE）"
  fi
done
```

#### 大仓推送（git push）

```bash
for repo in "${REPOS[@]}"; do
  echo ""
  echo "═══════════════════════════════"
  echo "📦 $(basename $repo)"
  echo "   路径：$repo"
  echo "───────────────────────────────"
  
  cd "$repo"
  
  # 检查是否有远程 upstream
  REMOTE=$(git remote)
  if [ -z "$REMOTE" ]; then
    echo "⚠️  无远程仓库配置，跳过"
    continue
  fi
  
  git push
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ 推送成功"
  else
    echo "❌ 推送失败（exit code: $EXIT_CODE）"
  fi
done
```

#### 大仓 status

```bash
for repo in "${REPOS[@]}"; do
  echo ""
  echo "═══════════════════════════════"
  echo "📦 $(basename $repo)"
  echo "───────────────────────────────"
  cd "$repo"
  BRANCH=$(git branch --show-current)
  STATUS=$(git status --short)
  AHEAD_BEHIND=$(git status -sb | head -1)
  echo "  分支：$BRANCH"
  echo "  同步：$AHEAD_BEHIND"
  if [ -n "$STATUS" ]; then
    echo "  变更："
    git status --short | sed 's/^/    /'
  else
    echo "  ✅ 工作区干净"
  fi
done
```

### Step 4：输出汇总报告

操作完成后输出汇总：

```
═══════════════════════════════
📊 大仓 pull 汇总
═══════════════════════════════
  ✅ 成功：N 个
  ⚠️  跳过：M 个（有未提交修改 / 无远程）
  ❌ 失败：K 个

⚠️ 跳过的仓库需要手动处理：
  - <repo路径>：有未提交修改
```

### Step 5：收尾验证（必做）

所有 repo 操作完成后，统一跑一遍 `git status` 检查，确保没有遗漏未提交的内容：

```bash
echo ""
echo "═══════════════════════════════"
echo "🔍 收尾验证：检查各 repo 工作区状态"
echo "═══════════════════════════════"

DIRTY_REPOS=()
for repo in "${REPOS[@]}"; do
  cd "$repo"
  STATUS=$(git status --short)
  if [ -n "$STATUS" ]; then
    DIRTY_REPOS+=("$repo")
    echo "⚠️  $(basename $repo) 有未提交内容："
    git status --short | sed 's/^/    /'
  fi
done

if [ ${#DIRTY_REPOS[@]} -eq 0 ]; then
  echo "✅ 所有 repo 工作区干净"
fi
```

若发现有未提交内容，逐一报告并询问用户是否需要提交。

> **特别注意**：经历过 stash / merge / conflict 解决的 repo 更容易有残留未提交内容，收尾验证是防止遗漏的最后一道保障。

---

## 注意事项

- **只扫描一级子目录**：不递归深层嵌套，避免误操作
- **有未提交修改时跳过 pull**：防止 merge 冲突破坏工作区
- **无远程配置时跳过 push/pull**：不报错，只提示跳过
- **父目录本身若是 git repo，也纳入操作范围**
- **操作顺序**：父目录优先，子目录按字母顺序

---

## 示例对话

**用户**：大仓拉取

**AI**：
```
发现 3 个 git 仓库：
  - ~/work_tree_bugfix（父目录）
  - ~/work_tree_bugfix/flutter_module
  - ~/work_tree_bugfix/social-ios

开始执行 git pull...
═══════════════════════════════
📦 work_tree_bugfix（父目录）
───────────────────────────────
✅ 已是最新
═══════════════════════════════
📦 flutter_module
───────────────────────────────
✅ 拉取成功（Fast-forward，3 个文件更新）
═══════════════════════════════
📦 social-ios
───────────────────────────────
⚠️  有未提交的修改，跳过：
   M  src/GameApp/SomeFile.m

📊 汇总：✅ 成功 2 个 | ⚠️ 跳过 1 个（有未提交修改）
```
