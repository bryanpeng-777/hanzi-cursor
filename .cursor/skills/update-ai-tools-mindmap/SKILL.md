---
name: update-ai-tools-mindmap
description: >-
  维护和查看 AI 工具调用树思维导图（~/.claude/knowledge/ai-tools-mindmap.canvas.tsx）。
  支持四种模式：
  (1) 查看模式：用户说「查看AI树」「打开思维导图」「看一下工具树」「show mindmap」时输出 Canvas 路径和统计。
  (2) 用户直说模式（最快）：用户明确说「我刚加了 X」「在 Y 下加了 Z」「修改了 X 的描述」时，0 扫描直接 StrReplace。
  (3) Git 增量模式（默认推荐）：用户说「更新AI树」「mindmap 更新」时，仅扫描 git status / git log 中变更的 agents/skills/knowledge 文件。
  (4) 全量模式（兜底）：用户说「全量更新AI树」「彻底重扫」时，跑全量扫描脚本对比所有节点。
---

# update-ai-tools-mindmap — AI 工具调用树维护技能

## 模式判断

收到触发词后，**先判断模式**再执行（优先级从上到下）：

| 触发词 / 场景 | 模式 |
|--------|------|
| 查看AI树 / 打开思维导图 / 看一下工具树 / show mindmap | **查看模式** |
| 用户明确说「我刚加了 X」「在 Y 下加了 Z」「修改了 X 描述」「删除了 X」「X 重命名为 Y」 | **用户直说模式**（最快，0 扫描） |
| 更新AI树 / mindmap 更新 / 更新思维导图 / 刷新一下（默认） | **Git 增量模式**（推荐） |
| 全量更新AI树 / 全量扫描 / 彻底重扫 / full-scan | **全量模式**（兜底） |

---

## 查看模式

直接输出以下两个路径，并说明区别：

| 路径 | 说明 |
|------|------|
| `~/.cursor/projects/Users-bryanpeng-work-tree-bugfix/canvases/ai-tools-mindmap.canvas.tsx` | **点击这个** — Cursor Canvas 展示副本，会渲染为可视化界面 |
| `~/.claude/knowledge/ai-tools-mindmap.canvas.tsx` | 源文件（编辑用），直接打开只显示源码 |

同时运行以下命令获取当前统计并展示：

```bash
python3 -c "
import re
content = open('$HOME/.claude/knowledge/ai-tools-mindmap.canvas.tsx').read()
agents    = len(re.findall(r\"type: 'agent'\", content))
skills    = len(re.findall(r\"type: 'skill'\", content))
workflows = len(re.findall(r\"type: 'workflow'\", content))
cursors   = len(re.findall(r\"type: 'cursor'\", content))
knowledge = len(re.findall(r\"type: 'knowledge'\", content))
print(f'助手 {agents} | 技能 {skills} | 工作流 {workflows} | Cursor 工具 {cursors} | 知识文件 {knowledge}')
"
```

---

## 关键路径（所有更新模式共用）

| 文件 | 说明 |
|------|------|
| `~/.claude/knowledge/ai-tools-mindmap.canvas.tsx` | 主存储（源文件，所有编辑操作的目标） |
| `~/.cursor/projects/Users-bryanpeng-work-tree-bugfix/canvases/ai-tools-mindmap.canvas.tsx` | Cursor 展示副本（每次编辑后必须同步） |
| `~/.claude/skills/update-ai-tools-mindmap/scripts/scan_tools.py` | 全量扫描脚本（仅全量模式使用） |
| `~/.claude/skills/update-ai-tools-mindmap/scripts/git_changed.sh` | Git 增量扫描脚本（增量模式使用） |

> **双文件同步原则**：所有编辑针对**源文件**，每次编辑后立即 `cp` 同步到展示副本，并用 `diff` 验证。

---

## 模式 A：用户直说模式（0 扫描，最快）

**适用**：用户已经明确告诉你变更内容（例如：「我刚加了 `foo-skill` 在 `dev-assistant` 下」「`bar` 改名叫 `baz` 了」「我新增了一个 knowledge `xxx/yyy.md`」「dev-assistant 增加了一个 knowledge」）。

### 执行步骤

1. **快速理解**：从用户描述中提取变更类型（新增/修改/删除/重命名）、目标节点的父节点位置
2. **必要时短问一句**：父节点位置不明确时，简短确认（例：「放在 `dev-assistant` 子节点下还是单独列在 others？」）
3. **如果是新增 knowledge 节点**：读 1~3 行该 knowledge 文件首行作为描述（`head -3` 即可），按规则跳过 `reference.md`
4. **如果是新增 agent / skill**：读对应 SKILL.md 或 .md 文件的 description 字段或首段作为描述
5. **直接 StrReplace**：只改源文件的最小片段
6. **同步 + 验证**：

```bash
cp ~/.claude/knowledge/ai-tools-mindmap.canvas.tsx \
   ~/.cursor/projects/Users-bryanpeng-work-tree-bugfix/canvases/ai-tools-mindmap.canvas.tsx \
&& diff -q ~/.claude/knowledge/ai-tools-mindmap.canvas.tsx \
           ~/.cursor/projects/Users-bryanpeng-work-tree-bugfix/canvases/ai-tools-mindmap.canvas.tsx \
&& echo "✅ 同步完成"
```

> **关键**：这个模式**不要跑任何扫描脚本**，**不要列「待更新清单」**，直接动手。整个流程通常只有 1 次 StrReplace + 1 次 cp，秒级完成。

---

## 模式 B：Git 增量模式（默认推荐）

**适用**：用户说「更新AI树」「mindmap 更新」「刷新一下」，但没有明确告诉你具体变更项。

### 思路

`~/.claude` 是 git 仓库，所有 agents/skills/knowledge 的新增/删除/改名/修改都会反映在：
- `git status`（未提交变更）
- `git log --diff-filter=AD`（最近 N 次提交里的新增/删除文件）

基于此做增量扫描，**只处理实际发生变化的文件**，比全量快几十倍。

### Step 1：拉取近期变更清单

```bash
# 默认：只看未提交变更（最快，通常只有 几项）
bash ~/.claude/skills/update-ai-tools-mindmap/scripts/git_changed.sh

# 补漏模式：同时扫描最近 N 次提交里的新增/删除/重命名（用于排查画布是否漏更）
bash ~/.claude/skills/update-ai-tools-mindmap/scripts/git_changed.sh 5
```

脚本输出 JSON，结构：

```json
{
  "untracked":     ["agents/foo.md", "skills/bar/SKILL.md", "knowledge/baz/qux.md"],
  "modified":      ["agents/dev-assistant.md"],
  "deleted":       ["skills/old-skill/SKILL.md"],
  "renamed":       [{"from": "agents/old.md", "to": "agents/new.md"}],
  "recent_added":  ["agents/recently-added.md"]
}
```

> 默认 `RECENT_N=0` 只扫未提交变更（`untracked`/`modified`/`deleted`），**速度最快、输出最少**。  
> 当用户说「补漏一下历史变更」或「画布漏了什么」时，传 `5` 或 `10` 让脚本扫描最近 N 次提交里的 `renamed` / `recent_added`。  
> **不要默认传大数字**（>20），否则可能命中历史上的「批量初始化提交」导致输出爆炸。

### Step 2：逐项处理（按以下顺序）

对每一个变更项，按以下规则处理：

| 变更类型 | 处理方式 |
|---------|---------|
| 新增 agent / skill / workflow | 读其 description 或首段作为描述，问用户放置位置（给出推断），追加节点到源文件 |
| 新增 knowledge 文件 | **跳过 `reference.md`**；项目专属用 `{project}` 占位（见树结构规则）；读首行作描述，归入对应助手的 children 顶部 |
| 修改 agent / skill 描述 | 取首行/description 作 new_desc，对比画布中该节点的 old_desc；**若 canvas 描述更详细则跳过** |
| 删除文件 | 在画布中搜对应 name，确认后删除节点 |
| 重命名 | 找到旧 name 节点，改 name 字段；如有 id 引用同步更新 |

### Step 3：每改完一项立即同步

不要等到最后才 cp。每处理完一项或一批同名编辑，就执行：

```bash
cp ~/.claude/knowledge/ai-tools-mindmap.canvas.tsx \
   ~/.cursor/projects/Users-bryanpeng-work-tree-bugfix/canvases/ai-tools-mindmap.canvas.tsx
```

### Step 4：输出总结

```
✅ Git 增量更新完成
  扫描变更项：N 个文件（其中 M 项跳过 reference.md）
  新增节点：N 项
  描述更新：N 项
  删除节点：N 项
  重命名：N 项
```

---

## 模式 C：全量模式（兜底）

**适用**：用户明确要求「全量扫描」「彻底重扫」「全量更新AI树」，或 Git 增量模式漏掉了某些情况（例如：很久之前提交的工具一直没更新、手工修改了画布外的描述、画布大量错位需要重新对齐）。

### 执行步骤

```bash
python3 ~/.claude/skills/update-ai-tools-mindmap/scripts/scan_tools.py
```

输出 JSON 包含 `updates` / `new_tools` / `deleted_tools` / `total_*` / `canvas_items`。按以下顺序处理：

1. **描述更新**：对 `updates` 中每项，在源文件 StrReplace 替换 `desc`（canvas 描述更详细时跳过）
2. **新增工具**：列给用户确认放置位置后追加
3. **已删除工具**：列出后确认删除
4. **每处理完一类立即 cp 同步**
5. **diff 验证**

> 全量模式比增量慢很多，仅在确实需要重新对齐时使用。

---

## 树结构规则

新增工具的默认放置逻辑（按类型和名称推断）：

| 判断条件 | 默认父节点 |
|----------|-----------|
| 名称含 `bugly-` | `bugly-assistant` 子节点 |
| 名称含 `galileo-` | `oncall-assistant` 或 `galileo-reg` 子节点 |
| 名称含 `camp/` 前缀 | `camp-standalone` 分组 |
| 类型为 `agent`，含 `-plugin` | `cs-assistant` 子节点 |
| 类型为 `cursor` | `cursor-tools` 分组 |
| 其他 skill | `others` 中对应语义分组 |
| knowledge 文件 | 归入对应助手的 children 顶部（agent 节点的第一个子节点） |

---

## 注意事项

- **不改变调用关系结构**（谁调用谁），只更新描述和增删节点
- 交叉引用节点（有 `xref` 字段的）不参与描述更新，也不在「已删除」检测范围内
- 画布中 `group` 类型节点（分组标题）不对应任何实际文件，不处理
- 更新前先确认 canvas 文件存在，如不存在提示用户重新生成
- **`reference.md` 文件不列入画布**：各助手目录下的 `reference.md` 属于通用背景知识，内容价值低，不在 knowledge 节点中展示；只列举有具体业务含义的 knowledge 文件（如 patterns.md、manifest.json、alert-registry.md、rule.md 等）
- **项目专属文件用 `{project}` 占位**：`~/.claude/knowledge/{assistant}/{project}/` 下的文件属于「每个项目独立一份」的模式，节点 `name` 字段统一写 `{assistant}/{project}/filename`，不写具体项目名（如 `dev-assistant/{project}/rule.md` 而非 `dev-assistant/demo/rule.md`）
- **优先用最快模式**：能用模式 A 绝不用 B，能用 B 绝不用 C；只有用户明确要求或 B 漏掉时才走 C
