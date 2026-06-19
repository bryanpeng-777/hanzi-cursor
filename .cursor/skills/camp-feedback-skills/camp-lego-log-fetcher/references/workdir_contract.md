# Workdir 契约

## 写入

- `<wd>/attachments/<zip-name>` — 拉回的日志 zip
- `<wd>/manifest.json` — 合并写入（保留上游字段）：

| 字段 | 含义 |
|---|---|
| `lego_status` | done / failed |
| `lego_task_id` | lego 任务 id |
| `lego_zip_path` | 落盘 zip 路径 |
| `lego_message` | 提示信息 |

下载成功后自动解压分类，追加 `logs[]` / `plain_logs[]` 到 manifest。

## 下游处理

- `status=failed`：流水线继续，报告中标注"lego 补拉失败"
- `status=done` 但 logs 为空：标注"lego 补拉到空日志包"
