# skill-creator 本地扩展

> 这个文件是对上级 SKILL.md 的本地增补，内容不来自上游。
> SKILL.md 在 "Interview and Research" 章节末尾有一行 pointer 指向此处。
> 如果 SKILL.md 被上游覆盖，只需重新加回那一行 pointer 即可——本文件不受影响。

---

## Patch 1 — Placement Rule（2026-03-30）

在 Write the SKILL.md 的 `name` 字段后，加入 `placement` 字段：

```
- **placement**: Before creating, determine where the skill belongs:
  - 项目专属（如营地专属）→ `~/.claude/skills/camp/` 子目录下
  - 腾讯内部通用 → `~/.claude/skills/tencent/`（待建）
  - 完全通用（任意项目可用）→ `~/.claude/skills/` 根目录
  - 判断标准：如果 skill 的 description 或内部逻辑中包含项目特定的路径、工具名、代码框架，则为项目专属；否则为通用
```

---

## Patch 2 — Programmatic Feasibility Check（2026-04-14）

**在 "Interview and Research" 之后、"Write the SKILL.md" 之前执行此步骤。**

在开始写 SKILL.md 之前，先判断这个技能的核心逻辑是否适合用脚本实现。

### 评估维度

| 特征 | 倾向脚本 | 倾向 AI 指令 |
|---|---|---|
| 输入输出形态 | 可枚举、固定 schema | 依赖上下文理解 |
| 确定性 | 相同输入总产出相同结果 | 需要逐案推理 |
| Token 代价 | 高重复、大数据量 | 可接受 |
| 出错范围 | 局部、可调试 | 需要判断 |

### 决策流程

**如果存在 ≥1 个确定性核心步骤：**

1. **先设计脚本**，放入 `scripts/` 目录
2. **SKILL.md 变成编排者**：告诉 AI「运行脚本，再处理剩余的模糊部分」
3. 在 SKILL.md 开头注明分工：「脚本处理 X，AI 处理 Y」

**如果没有确定性核心（纯理解/判断任务）：**

- 直接写 SKILL.md 即可，无需脚本

### 典型例子

| 技能场景 | 确定性部分（→ 脚本） | 模糊部分（→ AI） |
|---|---|---|
| 批量图片处理 | resize、format 转换 | 风格描述、质量判断 |
| 代码迁移 | import 路径替换、API 重命名 | 复杂组件替换方案选择 |
| 文档生成 | 模板填充、字段提取 | 摘要撰写、结构设计 |
| 数据报告 | 数据拉取、计算、格式化 | 异常解读、结论表述 |

### 为什么重要

脚本 100% 确定、可复现，能吸收 80% 重复性 token 消耗，让 AI 只聚焦真正需要理解的 20%。纯 AI 指令的技能在确定性任务上每次都在重新推导相同结论，既浪费 token 又引入幻觉。

**参考**：《Skill 编写方法论：脚本与 AI 分工 + 自进化机制》（通用知识库条目 16）
