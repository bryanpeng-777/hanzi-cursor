---
name: sync-skills-to-tools
description: 将 ~/.claude/skills 中的技能同步到 WorkBuddy（.workbuddy/skills/）、CodeBuddy（.codebuddy/skills/）与 Cursor 项目仓库（.cursor/skills/，供 Cloud Agent 使用）；并在每次同步时保证 ~/.claude-internal 下的 skills、agents、knowledge 为指向 ~/.claude 对应目录的符号软链（单一数据源，不 rsync 复制）。当用户提到「更新技能」「更新技能库」「同步技能」「sync skills」「把技能同步到 WorkBuddy/CodeBuddy/Cursor」「同步到其他工具」「skills 同步」「skill 同步」时触发。若用户表述为「更新」或明确要求拉取最新技能，必须先在本机 ~/.claude/skills 仓库执行 git pull，再 rsync；仅说「同步」且未要求更新远端时，可直接 rsync。WorkBuddy/CodeBuddy/Cursor 侧 skills 按技能目录增量镜像；internal 侧仅维护软链。
---

# Sync Skills to Tools

将 `~/.claude/skills/` 中的技能同步到 WorkBuddy、CodeBuddy 与 Cursor 项目仓库；并在**同一次脚本执行**中，保证 `~/.claude-internal/skills`、`~/.claude-internal/agents`、`~/.claude-internal/knowledge` 三者为指向 `~/.claude/skills`、`~/.claude/agents`、`~/.claude/knowledge` 的**符号软链**（绝对路径），**不再**对 internal 做目录复制或 rsync。

## 配置

| 参数 | 值 |
|------|-----|
| skills 源目录 | `~/.claude/skills/`（通常为独立 git 仓库） |
| agents 源目录 | `~/.claude/agents/` |
| knowledge 源目录 | `~/.claude/knowledge/` |
| WorkBuddy skills 目标 | `~/.workbuddy/skills/`（rsync 镜像） |
| CodeBuddy skills 目标 | `~/.codebuddy/skills/`（rsync 镜像） |
| Cursor 项目 skills 目标 | `<项目根>/.cursor/skills/`（rsync 镜像，默认 `hanzi-cursor`） |
| Cursor 项目根列表 | 环境变量 `CURSOR_PROJECT_ROOTS`，逗号分隔，默认 `/Users/pengchao/hanzi/hanzi-cursor` |
| claude-internal skills | `~/.claude-internal/skills` → **软链** → `~/.claude/skills` |
| claude-internal agents | `~/.claude-internal/agents` → **软链** → `~/.claude/agents` |
| claude-internal knowledge | `~/.claude-internal/knowledge` → **软链** → `~/.claude/knowledge` |
| 同步模式 | WB/CB/Cursor：按顶层技能目录（含分组如 `camp/`）增量 rsync；internal：仅 `ln -s`（若原为实体目录则改名为 `*.pre-symlink.时间戳` 后建链） |

## 「更新」与「同步」

| 用户意图 | 脚本调用 |
|----------|----------|
| **更新**（更新技能库、拉最新、同步前先拉 git 等） | `bash scripts/sync.sh --pull-first` |
| **仅同步**（不把 skills 仓库与远程对齐） | `bash scripts/sync.sh` |
| **只修 internal 软链**（不动 WorkBuddy/CodeBuddy/Cursor） | `bash scripts/sync.sh --symlinks-only` |
| **只同步 Cursor 项目** | `bash scripts/sync.sh --cursor-only` |

`--pull-first` 会在 rsync 之前进入 `~/.claude/skills`，若存在 `.git` 则执行 `git pull --ff-only`；若不是 git 仓库则打印警告并继续同步。

## 脚本分工

> **脚本全自动处理**：可选 git 拉取、扫描源目录、rsync 到 WB/CB/Cursor 项目、检查/建立 internal 软链（`scripts/sync.sh`）  
> **AI 处理**：判断用户是「更新」还是「仅同步」；确认是否只同步某一目标工具；Cursor 同步后若项目为 git 仓库且用户要求提交，则 `git add .cursor/skills && git commit`

```bash
# 更新：先 git pull ~/.claude/skills，再同步 skills 到各目标，并确保 internal 三软链
bash scripts/sync.sh --pull-first

# 仅同步（不拉 git）：skills → WorkBuddy/CodeBuddy/Cursor；确保 internal 三软链
bash scripts/sync.sh

# 只建立/修正 ~/.claude-internal 下三处软链（不同步 WB/CB/Cursor）
bash scripts/sync.sh --symlinks-only

# 先拉 git，再只同步到 WorkBuddy
bash scripts/sync.sh --pull-first --workbuddy-only

# 仅同步 skills 到 WorkBuddy（不拉 git；仍会确保 internal 三软链）
bash scripts/sync.sh --workbuddy-only

# 仅同步到 CodeBuddy（不拉 git；仍会确保 internal 三软链）
bash scripts/sync.sh --codebuddy-only

# 仅同步到 Cursor 项目 .cursor/skills/（不拉 git；仍会确保 internal 三软链）
bash scripts/sync.sh --cursor-only

# 指定多个 Cursor 项目根（逗号分隔）
CURSOR_PROJECT_ROOTS="/path/a,/path/b" bash scripts/sync.sh --cursor-only
```

---

## 执行步骤

### Step 0：是否为「更新」

若用户说法包含 **更新**、**最新**、**拉一下**、**pull** 等与远端对齐的意图，或明确说「更新技能库」：

1. 使用带 **`--pull-first`** 的完整命令（见上表）。
2. 若 `git pull` 失败（冲突、网络），向用户说明错误，不要静默跳过；用户解决后可重试。

若用户只说「同步」且不要求与 git 远程一致，跳过 Step 0，直接 Step 1 起（不带 `--pull-first`）。

### Step 1：扫描源目录，找出所有有效技能

有效技能 = 在 `~/.claude/skills/` 下，包含 `SKILL.md` 文件的子目录。

```bash
# 列出所有有效技能目录名
for dir in ~/.claude/skills/*/; do
  [ -f "${dir}SKILL.md" ] && echo "$(basename $dir)"
done
```

排除以下内容：

- 不含 `SKILL.md` 的目录（如备份目录 `*.backup.*`）
- 根目录下的 `.skill` 文件（打包产物，不是目录）

### Step 2：确认目标目录存在

```bash
mkdir -p ~/.workbuddy/skills/
mkdir -p ~/.codebuddy/skills/
mkdir -p ~/.claude-internal/
```

internal 下的 `skills` / `agents` / `knowledge` 由脚本建为软链，**不要**对其再 `mkdir` 成空目录（否则会阻碍 `ln -s`）。

### Step 3：执行同步

#### 3-A：同步 skills（WorkBuddy + CodeBuddy + Cursor 项目）

由 `scripts/sync.sh` 内 `sync_to` / `sync_cursor_projects` 实现：对每个有效技能目录 rsync 到 WorkBuddy、CodeBuddy 与各 Cursor 项目的 `.cursor/skills/`，并对目标侧已删除的源技能做目录删除（镜像）。

Cursor 项目路径由 `CURSOR_PROJECT_ROOTS` 控制（默认 `hanzi-cursor`）。同步完成后若用户要求提交，进入对应项目根目录执行 `git add .cursor/skills && git commit`。

`rsync -a --update`（用于 WB/CB 单技能目录增量）：

- `-a`：保留文件权限、时间戳，递归同步
- `--update`：只在源文件比目标文件更新时才覆盖（增量更新）

#### 3-B：claude-internal 三路径（软链）

由 `ensure_internal_claude_symlinks` 实现：

1. `mkdir -p ~/.claude-internal`
2. 对每个 `dest`（internal 侧路径）与 `src`（`~/.claude/...`）：
   - 若 `src` 不存在：打印跳过，不建链。
   - 若 `dest` 已是指向 `$(cd "$src" && pwd -P)` 的软链：跳过。
   - 若 `dest` 为软链但目标不对：删除后 `ln -s`。
   - 若 `dest` 已存在且为实体目录或文件：整体 `mv` 为 `dest.pre-symlink.YYYYMMDDHHMMSS` 后再 `ln -s`。
3. 使用**绝对路径**作为软链目标，避免相对路径歧义。

**不要**再对 internal 三路径执行 rsync；内容与权限以 `~/.claude` 侧为准。

### Step 4：输出同步报告

同步完成后，向用户展示：

1. **若执行了 git pull**：简短说明 pull 结果（已最新 / 已快进更新 / 失败原因）
2. **同步统计**：WorkBuddy/CodeBuddy/Cursor 侧 skills 的新增、更新、跳过；internal 三软链状态（新建 / 已正确 / 跳过源不存在 / 是否发生备份改名）
3. **目标目录状态**：WorkBuddy/CodeBuddy 技能数；`readlink` 可验证 internal 指向

报告格式示例：

```
同步完成 ✓

源目录：~/.claude/skills/（共 N 个 SKILL.md）

WorkBuddy (~/.workbuddy/skills/)：
  ...

CodeBuddy (~/.codebuddy/skills/)：
  ...

Cursor (<项目>/.cursor/skills/)：
  ...

claude-internal（软链 -> ~/.claude，无复制）：
  skills：已是正确软链 -> /Users/xxx/.claude/skills
  agents：已是正确软链 -> /Users/xxx/.claude/agents
  knowledge：已是正确软链 -> /Users/xxx/.claude/knowledge
```

## 注意事项

- **误删风险**：若某脚本对 `~/.claude-internal/skills` 等执行 `rm -rf` 且**解析软链**，可能删到 `~/.claude` 下真实目录。自动化或清理脚本应先判断 `[[ -L path ]]`，或只操作 `~/.claude/...`。
- 如果用户只想同步 skills 到其中一个工具或 Cursor 项目，询问确认后使用对应 flag；**internal 三软链仍会检查/建立**（与 `--workbuddy-only` / `--codebuddy-only` / `--cursor-only` 独立）。
- `--symlinks-only` 不能与 `--pull-first`、`--workbuddy-only`、`--codebuddy-only`、`--cursor-only` 同时使用。
- **Cursor Cloud Agent**：项目级 `.cursor/skills/` 须提交到 Git 后 Cloud Agent 才能读取；用户级 `~/.cursor/skills/` 在云 VM 不可用。
- **macOS 默认 Bash 3.2**：`echo` 中 **`$变量` 紧邻全角左括号 `（`** 会误解析；脚本内已避免，新增 echo 时同样注意。
- 如果 rsync 不可用，WB/CB 段需回退方案（本技能以 rsync 为主）；internal 不依赖 rsync。
- 同步完成后不需要重启各工具（视具体产品而定）；claude-internal 读路径即 `~/.claude` 内容。
