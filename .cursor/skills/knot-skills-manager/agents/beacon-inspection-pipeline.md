# 灯塔看板巡检 — Knot 版

营地灯塔看板定时/手动巡检 Agent。默认执行 **Phase 1**（拉取 + 分析 + iWiki + 企微）；用户明确要求「综合报告 / 流水线全套」时继续 **Phase 2**。

---

## Knot 前置条件（缺一不可）

| 项 | 要求 |
|----|------|
| **挂载 Skills** | `beacon-inspection-pipeline`、`beacon-dashboard-inspector`、`beacon-data-fetcher`；全套时加 `beacon-report-synthesizer` |
| **MCP** | `user-iWiki`（createDocument / saveDocumentParts / getDocument）、`user-wework-bot`（send_wework_message） |
| **工作区** | 绑定营地代码仓（`social-ios` 等），供异常时 `git log`；路径取 `$KNOT_WORKSPACE` 或 `$WORKSPACE` |
| **灯塔登录态** | `~/.claude/skills/beacon-data-fetcher/runtime/beacon_auth_state.json` 须有效；过期时按 `beacon-data-fetcher` 技能重新扫码登录 |
| **Python 依赖** | Knot 镜像需有 `python3`；首次运行前在工作区执行：`pip install playwright && playwright install chromium`（见 beacon-data-fetcher） |

---

## 触发与版本口径

| 用户输入 | 行为 |
|---------|------|
| `灯塔巡检 10.112.0603` / `看板巡检 10.112.0603` | 版本专项 + 全量双列对比 |
| `灯塔巡检全量` / 未指定版本 | 仅全量单列 |
| `灯塔全套巡检` / `综合监测报告` | Phase 1 + Phase 2 |

**禁止使用缓存**：每次巡检前批处理脚本会清空 `/tmp/beacon_inspector` 并重新拉取。

---

## 执行流程

### Step 0：确认前置

1. 检查 MCP `user-iWiki`、`user-wework-bot` 可用。
2. 确认 `beacon_auth_state.json` 存在；不存在则 Read `beacon-data-fetcher` SKILL，完成登录后再继续。

### Step 1：批处理（数据 + 报告）

```bash
python3 ~/.claude/skills/beacon-dashboard-inspector/scripts/run_knot_inspection.py \
  --version <版本号或全量>
```

- 串行拉取 13 个看板 ×（版本 + 全量）
- CSV / 分析结果校验（有 `[ERROR]` 须修复后重跑，禁止带错数据出报告）
- 生成 `inspection_report.md` 与 `iwiki_parts.json`

解析 stdout 末尾 `KNOT_INSPECTION_DONE` JSON，记录 `run_time`、`comparison`、`total_immediate`、`iwiki_parts` 路径。

### Step 2：iWiki 写入（Phase 1）

Read `beacon-dashboard-inspector` SKILL 的 **Step 4**：

1. `getSpaceInfo` → 定位「灯塔巡检报告」目录（parentid `4021729814` 或自动发现）
2. `createDocument`（MD）+ `saveDocumentParts` 顺序追加 `iwiki_parts.json` 各片
3. `getDocument` 写后验证（无断表、含自定义核心指标与页脚）

标题：`灯塔看板巡检日报 YYYY-MM-DD HH:mm`（与 `run_time` 一致）。

### Step 3：企微推送（Phase 1）

Read `beacon-dashboard-inspector` SKILL **Step 5**，调用 `send_wework_message`：

- `type`: `markdown`
- 含精简摘要 + iWiki 链接 `https://iwiki.woa.com/p/<docid>`
- 摘要须注明对比窗口（跨天 12h vs 24h 前同时段）

### Step 4：Phase 2（仅用户要全套时）

Read `camp/beacon-report-synthesizer` SKILL，以 Phase 1 的 iWiki docid 为输入，生成 8 章综合报告写入「灯塔巡检综合分析」目录，企微追加综合报告链接。

---

## 定时任务配置（Knot UI）

在 Knot Agent 设置中新增定时触发，建议：

| 项 | 推荐值 |
|----|--------|
| Cron | `0 9 * * *`（每天 09:00，北京时间） |
| 默认 Prompt | `灯塔看板巡检 10.112.0603`（灰度版本号按发版节奏更新） |
| 失败通知 | 开启 Agent 运行失败告警 |

---

## 故障处理

| 现象 | 处理 |
|------|------|
| 登录态过期 | 按 beacon-data-fetcher 重新扫码，更新 `beacon_auth_state.json` |
| Playwright 未安装 | `pip install playwright && playwright install chromium` |
| CSV 校验失败 | 增大 `--wait` 重拉问题看板；确认日志有「业务API匹配」 |
| iWiki 4KB 限制 | 必须用 `split_iwiki_parts.py` 分片，禁止 HTML 导入 |
| 代码分析跳过 | `$KNOT_WORKSPACE` 未配置时 Step 2.5 自动跳过，仅时间规律推断 |
