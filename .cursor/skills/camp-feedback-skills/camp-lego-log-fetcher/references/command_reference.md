# 命令与接口参考

## MCP 接口

### lego.queryLogs — 查询现有日志

```json
{
  "uin": "<user_id>",
  "platform": "android",
  "beginTime": "YYYY-MM-DD HH:mm:ss",
  "endTime": "YYYY-MM-DD HH:mm:ss"
}
```

返回有 COS 链接 → 调 convertAndDecrypt；返回无日志 → 调 createFetchTask。

### lego.convertAndDecrypt — COS 链接转下载 URL

```json
{
  "cosUrl": "<queryLogs 返回的 COS 链接>"
}
```

返回可直接下载的 zip URL。

### lego.createFetchTask — 创建捞取任务

```json
{
  "uin": "<user_id>",
  "platform": "android",
  "beginTime": "YYYY-MM-DD HH:mm:ss",
  "endTime": "YYYY-MM-DD HH:mm:ss",
  "description": "camp-feedback uid=xxx"
}
```

fire-and-forget，提交后立即返回。

---

## CLI 子命令

### download

```bash
python3 scripts/lego.py download --url <URL> --workdir <WD> [--task-id <ID>] [--strict] [--json]
```

| 参数 | 必需 | 说明 |
|---|---|---|
| `--url` | 是 | zip 下载链接（来自 convertAndDecrypt） |
| `--workdir` | 是 | 工作目录 |
| `--task-id` | 否 | 写入 manifest |
| `--strict` | 否 | 失败时退 1 |
| `--json` | 否 | JSON 输出 |

### status

```bash
python3 scripts/lego.py status --workdir <WD> [--json]
```
