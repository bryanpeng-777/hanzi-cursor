---
name: beacon-inspection-pipeline
description: >
  灯塔看板完整巡检流水线（Inspector + Synthesizer 两阶段串联）。
  ⚠️ 专属触发词（含以下任一关键词才触发，不得与 beacon-dashboard-inspector 混淆）：
  「beacon-inspection-pipeline」「灯塔巡检流水线」「灯塔全套巡检」「完整灯塔巡检」「两阶段灯塔巡检」。
  本技能是 beacon-dashboard-inspector（Phase 1：数据拉取 + 分析 + iWiki + 企微推送）
  与 beacon-report-synthesizer（Phase 2：8章综合监测报告二次加工）的统一入口。
  注意：「灯塔巡检」「灯塔日报」「看板巡检」等不含「流水线/全套/两阶段」的词属于
  beacon-dashboard-inspector 的触发词，不应触发本技能。
---

# Beacon Inspection Pipeline

灯塔看板巡检完整流水线，两阶段串联执行：

| 阶段 | 技能 | 内容 |
|------|------|------|
| Phase 1 | `beacon-dashboard-inspector` | 数据拉取 → 环比分析 → iWiki 写入 → 企微推送 |
| Phase 2 | `beacon-report-synthesizer` | 读取巡检日报 → 运行合成脚本 → 生成 8 章综合监测报告 |

---

## 版本口径说明

| 用户输入 | 执行模式 |
|---------|---------|
| `beacon-inspection-pipeline 10.112.0603` | 版本专项 + 全量对比（双列） |
| `beacon-inspection-pipeline 全量` 或不指定 | 仅全量（单列） |

---

## 执行顺序

### Phase 1：灯塔看板巡检

立即读取并执行：

```
~/.claude/skills/beacon-dashboard-inspector/SKILL.md
```

按该技能的 Step 0 → Step 5 完整执行。执行完毕后，记录生成的 `IWIKI_URL`（格式：`https://iwiki.woa.com/p/<docid>`），供 Phase 2 使用。

### Phase 2：综合监测报告二次加工

Phase 1 全部完成后，立即读取并执行：

```
~/.claude/skills/camp/beacon-report-synthesizer/SKILL.md
```

输入来源：Phase 1 写入 iWiki 的巡检日报（通过 `IWIKI_URL` 中的 docid 拉取）。

执行合成脚本，将结果写入 iWiki **「灯塔巡检综合分析」** 目录（`parentid` 取该文件夹 docid，如 `4022042073`；**不要**写入 Phase 1 的「灯塔巡检报告」目录）。标题格式：`灯塔综合监测报告 YYYY-MM-DD HH:mm`（与 Phase 1 巡检时间一致）。并在企微消息中追加综合报告链接。

**Phase 2 iWiki 完成标准（缺一不可）：**

1. 运行 `beacon_report_synthesizer.py` 生成完整 `synthesis_report.md`（8 章）
2. 按 `beacon-report-synthesizer` 技能 **Step 3.1** 分批写入 iWiki（`saveDocument` / `saveDocumentParts`），**禁止只写摘要**
3. 通过 **Step 3.5 门禁**：`getDocument` 确认 8 个章节标题 + 页脚均存在
4. 企微消息中同时附带 **巡检日报链接**（Phase 1）与 **综合监测报告链接**（Phase 2）

---

## 关键约束

- **两个阶段必须在同一次对话中连续完成**，Phase 1 完成后不等待用户确认，直接进入 Phase 2。
- Phase 1 的 iWiki 文档链接是 Phase 2 的唯一输入源，必须确保 Phase 1 iWiki 写入成功后再启动 Phase 2。
- **Phase 2 不得以「综合报告已生成到本地」代替 iWiki 完整落库**；用户追问「写到 iWiki」时，必须执行 synthesizer 的 Step 3.1～3.5。
- 若 Phase 2 脚本不存在（`beacon_report_synthesizer.py` 缺失），跳过 Phase 2 并告知用户，但不影响 Phase 1 的完整性。

---

## 子技能路径

- Phase 1 → `~/.claude/skills/beacon-dashboard-inspector/SKILL.md`
- Phase 2 → `~/.claude/skills/camp/beacon-report-synthesizer/SKILL.md`
