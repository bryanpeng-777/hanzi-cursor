# beacon-inspection-pipeline diff-rules

最后同步时间：2026-06-23

## 来源

基于 `beacon-inspection-pipeline` + `beacon-dashboard-inspector` 首次制作 Knot 版 Agent。

## Knot 专属内容（本地 SKILL 中无）

- `run_knot_inspection.py` 批处理入口
- `$KNOT_WORKSPACE` / `$WORKSPACE` 工作区说明
- MCP 前置：`user-iWiki`、`user-wework-bot`
- 定时 Cron 建议 `0 9 * * *`
- Playwright 安装说明

## 与本地版差异

| 本地 | Knot |
|------|------|
| Cursor `preview_url` 扫码 | Knot 需预置 `beacon_auth_state.json` 或终端扫码 |
| `Workspace Path` | `$KNOT_WORKSPACE` |
| 手工逐步拉取看板 | `run_knot_inspection.py` 一键批处理 |
| 可选跳过 iWiki | Knot 定时任务必须写 iWiki + 企微 |
