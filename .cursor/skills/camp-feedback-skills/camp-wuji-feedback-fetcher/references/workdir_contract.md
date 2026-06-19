# Workdir 契约

## `init-mcp` 写

- `<wd>/feedback.json` —— 单条（`--first` 或仅 1 条）
- `<wd>/feedback_candidates.json` —— 多条候选（同时写 feedback.json 取第一条）

归一化字段映射：

| 下游键 | MCP 字段 | 说明 |
|---|---|---|
| `_id` | `id` / `feedback_id` | 反馈 ID |
| `system` | `system_type` | `android` / `ios` |
| `version` | `client_version` | 营地版本号 |
| `create_time` | `create_time` | 反馈时间 |
| `user_id` | `user_id` | 营地 uid |
| `device_model` | `device_model` | 设备型号 |
| `content` | `content` | 反馈内容 |
| `logUrl` | `log_url` | COS 日志链接 |
| `picUrl` | `pic_url` | 截图（逗号分隔） |

## `fetch` 写

`<wd>/manifest.json`：

| 字段 | 含义 |
|---|---|
| `platform` | `android` / `ios` |
| `feedback_id` | 反馈 ID |
| `source` | `crystal` |
| `logs[]` | `.xlog` 路径 |
| `plain_logs[]` | 明文 `.log` 路径 |
| `screenshots[]` | 截图路径 |
| `download_failures[]` | 下载失败 URL（fail-soft） |
