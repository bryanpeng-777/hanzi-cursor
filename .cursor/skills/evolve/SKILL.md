---
name: evolve
description: 从当前对话中提炼有价值的经验，更新已有技能（SKILL.md）和项目知识库（CLAUDE.md）。当用户提到「进化」、「进化一下」、「让我进化」、「evolve」、「学一下这次的内容」、「把这次对话更新进去」时触发。即使用户只说「进化」一个字，也应主动使用此技能。
---

# 进化（Evolve）技能

本技能帮助 Claude 从每次对话中「学习」，将有价值的发现系统化地更新到已有 skill 和 CLAUDE.md 中，形成持续进化的知识闭环。

---

## 第一步：分析对话内容

通读当前对话历史，用以下维度提炼有价值的信息：

### 可更新到 **Skill** 的信号
- 对话中发现某个 skill 的流程有缺陷或遗漏步骤
- 用户纠正了 skill 的某个执行方式（「不对，应该先…再…」）
- 发现了某个 skill 的边界情况未被覆盖
- 用户补充了某个 skill 缺少的专业知识（如新的代码规范、新的工具用法）
- 某个 skill 触发了但效果不好，需要优化描述或步骤
- 发现了一个反复出现的工作流，值得固化成 skill 的一部分

### 可更新到 **code-locator 索引** 的信号

code-locator 使用四层索引体系（L1 总索引 → L2 域详情 → L3 场景索引 → L4 代码），进化时重点检查 L3 场景文件是否需要补录：

- 对话中定位了某个功能/模块，但 L3 中没有对应场景描述 → 应补录到对应 L3 文件
- 发现了新的排查入口文件或关键方法，未在 L3 中记录
- 某个路径/类名发生了变更，L2 或 L3 中有过时的记录
- 发现了某个域的新子模块，应更新 L2 + L1 关键词

**更新方式**：直接修改对应的 L3 文件（`/Users/bryanpeng/.claude/skills/camp/code-locator/L3_xxx.md`），补录格式：
```
场景描述 → 入口文件路径（查找提示：关键方法/类名）
```

---

### 可更新到 **CLAUDE.md** 的信号
- 项目新增了架构、约定或规范
- 发现了之前未记录的开发偏好（工具选择、编码风格、流程习惯）
- 某个踩坑经验揭示了项目特有的注意事项
- 新增了某个常用命令、环境配置或构建步骤
- 了解到新的业务背景、模块职责或团队约定
- 发现了 CLAUDE.md 中描述不准确或过时的内容

---

## 第二步：读取现有内容

如果找到了可更新的目标，先读取相关文件：

```
CLAUDE.md 路径（两个 worktree，必须同时更新）：
  - /Users/bryanpeng/work_tree_bugfix/CLAUDE.md
  - /Users/bryanpeng/work/CLAUDE.md
Skills 路径：/Users/bryanpeng/.claude/skills/<skill-name>/SKILL.md
```

对于 skill，只读取最相关的那一个（或两个），不要全量加载。

---

## 第三步：整理更新方案

以清单形式展示你的发现，每条包含：
- **目标**：哪个 skill 或 CLAUDE.md 的哪个章节
- **原因**：为什么这条信息值得更新（用一句话说清楚）
- **建议内容**：具体要新增或修改的内容（展示 diff 风格对比，用 `+` 表示新增，`-` 表示删除）

**筛选标准**（严格把关，宁少勿滥）：
- 只更新具有**持久价值**的内容，不记录一次性的问题或临时方案
- 不记录显而易见的信息（比如「用 flutter pub get 安装依赖」）
- 不记录用户已经知道的内容，只记录对未来 Claude 有价值的信息
- 如果没有值得更新的内容，诚实告知「这次对话没有发现值得沉淀的新信息」

---

## 第四步：等待用户确认

展示方案后，询问：「以上更新你觉得可以吗？可以整体确认，也可以告诉我哪几条不要。」

不要在用户确认前擅自修改任何文件。

---

## 第五步：执行更新

用户确认后：
1. 对每个需要更新的文件，精准修改对应部分（使用 StrReplace，不要整文件重写）
2. **CLAUDE.md 必须同步到两个 worktree**：每次对 CLAUDE.md 的修改，必须同时对以下两个文件执行相同的 StrReplace：
   - `/Users/bryanpeng/work_tree_bugfix/CLAUDE.md`
   - `/Users/bryanpeng/work/CLAUDE.md`
3. 更新完成后，逐条确认「已更新 XXX」
4. **同步关联 Subagent**：如果更新了某个 SKILL.md，检查 `~/.claude/agents/<skill-name>.md` 是否存在对应 subagent：
   - 若存在，评估 skill 的变更是否需要同步到 subagent（description 调整、流程步骤变更、新增/删除能力等）
   - 若需要同步，一并更新 subagent 文件（使用 StrReplace 精准修改，不整文件重写）
   - 更新后逐条确认「已同步 subagent: XXX」

---

## 第六步：同步变更到 Git 仓库

文件更新完成后，按仓库分别提交变更。涉及三个独立仓库：

```
Skills  仓库：/Users/bryanpeng/.claude/skills/   → github.com/bryanpeng-777/claude-skills.git
Agents  仓库：/Users/bryanpeng/.claude/agents/   → github.com/bryanpeng-777/claude-agents.git
Knowledge仓库：/Users/bryanpeng/.claude/knowledge/ → github.com/bryanpeng-777/claude-knowledge.git
```

**对每个仓库，统一执行流程**：
1. `git status` 检查是否有变更，有变更才执行后续步骤
2. 执行提交：
   ```bash
   cd <仓库路径>
   git add .
   git commit -m "<prefix>: <简要描述本次更新内容>"
   git push origin main
   ```
3. push 成功后告知用户「已同步到 XXX 仓库 ✓」；push 失败时告知用户具体错误，不要静默跳过

**commit message 格式**：

| 仓库 | prefix | 示例 |
|------|--------|------|
| skills | `evolve` | `evolve: 更新 bugfix skill，补充验证日志清理步骤` |
| agents | `evolve` | `evolve: 同步 bugfix subagent，补充验证日志清理步骤` |
| knowledge | `knowledge` | `knowledge: 更新 bugly-assistant，新增 crash 分析模式` |

- 如果同时更新了多个文件：在 commit message 中列出所有变更的名称
- 如果某个仓库无变更，跳过该仓库

**注意**：CLAUDE.md 的变更不属于以上三个仓库，无需在这里提交。

---

最后告诉用户：「进化完成 ✓ 共更新了 X 处内容」（追加已同步的仓库，如「已同步到 skills / agents / knowledge 仓库」）

---

## 直接修改 Subagent 的场景

**任何时候**直接修改 `~/.claude/agents/<name>.md` 或 `~/.claude/knowledge/<name>/` 下的文件（不仅限于 evolve 流程），完成后必须执行以下提交流程：

1. **提交 agents 仓库**（如果修改了 subagent 文件）：
   ```bash
   cd ~/.claude/agents
   git add .
   git commit -m "<type>: <简要描述>"
   git push origin main
   ```

2. **提交 knowledge 仓库**（如果修改了 knowledge 文件）：
   ```bash
   cd ~/.claude/knowledge
   git add .
   git commit -m "knowledge: <简要描述>"
   git push origin main
   ```

commit message type 参考：
- `evolve` — 进化流程触发的更新
- `fix` — 修正 subagent 的错误或遗漏
- `feat` — 新增 subagent 能力
- `refactor` — 重构 subagent 结构

---

## 注意事项

- **不要过度更新**：对话中大量内容是调试、尝试和回退，只提炼最终有价值的结论
- **保持文件风格一致**：新增内容要符合目标文件的语言、格式和层级结构
- **CLAUDE.md 优先级**：通用的项目知识放 CLAUDE.md，特定工作流放对应 skill
- **不新建 skill**：本技能专注于更新已有内容，如需新建 skill 请使用 skill-creator 技能
- **双 worktree 同步**：CLAUDE.md 存在于两个 worktree（`work/` 和 `work_tree_bugfix/`），任何更新必须对两个文件同时执行，绝不能只更新其中一个
- **三仓库分离**：skills / agents / knowledge 是三个独立 git 仓库，变更各自提交，不要混用
