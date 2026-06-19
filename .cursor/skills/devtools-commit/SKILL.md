---
name: devtools-commit
description: 将 ~/.claude 单一仓库中的开发工具变更（含 skills/agents/knowledge 等目录）以及 cs 框架仓库（~/work3/cursorAGIProject/cs）一次性提交并推送到远端。当用户说「开发工具提交」「提交工具仓库」「提交 skills」「提交 agents」「提交 knowledge」「devtools commit」「devtools-commit」「工具提交」「下班」时触发。即使用户只说「工具提交」或「下班」一个词，也应主动使用此技能。
---

# 开发工具提交技能

同时处理两个仓库：
1. **`~/.claude`** — 开发工具仓库（skills / agents / knowledge）
2. **`~/work3/cursorAGIProject/cs`** — cs 框架大仓（cs_core / cs_ui / cs_infra 等）

每个仓库独立检查、独立提交、独立推送，最后输出统一汇总。

## 触发词

- **工具提交** / **开发工具提交** / **devtools commit** / **devtools-commit**
- **提交工具仓库** / **提交 skills** / **提交 agents** / **提交 knowledge**
- **下班**

---

## 核心流程

### Step 1：并行检查两个仓库状态

```bash
git -C ~/.claude status --short
git -C ~/work3/cursorAGIProject/cs status --short
```

按目录维度展示变更摘要：
- `M` / ` M`：已修改文件
- `??`：新增未跟踪文件
- ` D`：已删除文件

**若两个仓库均无变更**，告知用户「两个仓库均已是最新，无需提交」并退出。

---

### Step 2：分别生成提交信息

#### ~/.claude 提交信息规则

| 目录 | 典型场景 | 提交信息示例 |
|------|---------|------------|
| `skills` | 新增/更新技能 | `feat: 更新 skills 中的 xxx 能力` |
| `agents` | 新增/更新 assistant | `feat: 更新 agents 编排规则` |
| `knowledge` | 新增/更新知识文档 | `feat: 更新知识库文档` |
| 混合目录 | 多目录共同变更 | `feat: 同步开发工具配置与技能` |

#### cs 框架仓提交信息规则

| 目录 | 典型场景 | 提交信息示例 |
|------|---------|------------|
| `cs_core/` | 框架核心变更 | `feat: 更新 cs_core` |
| `cs_ui/` | UI 组件变更 | `feat: 更新 cs_ui 组件` |
| `cs_infra/` | 基础设施变更 | `chore: 更新 cs_infra` |
| 混合目录 | 多包共同变更 | `feat: 同步 cs 框架变更` |

#### 通用提交格式

```
feat/chore: <简洁描述>

- <变更点1>
- <变更点2>
...

Co-Authored-By: Claude Sonnet 4.6 (1M context) <noreply@anthropic.com>
```

---

### Step 3：提交 + 推送（逐仓执行）

**~/.claude 仓库（有变更时）：**

```bash
git -C ~/.claude add -A
git -C ~/.claude commit -m "<生成的提交信息>"
git -C ~/.claude push
```

**cs 框架仓库（有变更时）：**

```bash
git -C ~/work3/cursorAGIProject/cs add -A
git -C ~/work3/cursorAGIProject/cs commit -m "<生成的提交信息>"
git -C ~/work3/cursorAGIProject/cs push
```

---

### Step 4：输出汇总报告

```
═══════════════════════════════════
📦 开发工具提交汇总
═══════════════════════════════════
✅ ~/.claude — 已提交并推送
  - skills：新增 X 个，更新 Y 个
  - agents：更新 Y 个
  - knowledge：更新 X 个文件

✅ cs 框架仓 — 已提交并推送
  - cs_ui：更新 X 个文件
  - cs_core：更新 Y 个文件

（若某仓无变更）
⏭  ~/.claude — 无变更，跳过
⏭  cs 框架仓 — 无变更，跳过
═══════════════════════════════════
```

---

## 注意事项

- **无变更跳过**：某个仓库无变更时不创建空 commit，跳过并在汇总中标注 ⏭
- **push 失败处理**：若 push 失败（如需要先 pull），报告错误信息，提示用户手动处理
- **不交互确认**：直接执行，无需逐步询问用户确认（除非 push 出现冲突）
- **cs 仓路径固定**：cs 框架大仓固定在 `~/work3/cursorAGIProject/cs`，子目录（cs_core/cs_ui 等）均属同一个 git repo，不单独提交

---

## 示例对话

**用户**：工具提交

**AI**：
```
检查两个仓库状态...

~/.claude：
  M  agents/ui-design-workflow.md
  M  knowledge/test-assistant/cursorAGIProject/test_manifest.md

cs 框架仓：无变更

开始提交...
═══════════════════════════════════
📦 开发工具提交汇总
═══════════════════════════════════
✅ ~/.claude — 已提交并推送
  - agents：更新 1 个（ui-design-workflow）
  - knowledge：更新 1 个（test_manifest）
⏭  cs 框架仓 — 无变更，跳过
═══════════════════════════════════
```
