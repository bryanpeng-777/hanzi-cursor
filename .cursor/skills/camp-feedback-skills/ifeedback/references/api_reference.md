# iFeedback MCP API Reference

CLI 通过 MCP 协议（JSON-RPC over HTTP）调用 iFeedback 工具。

- **MCP Server**: `https://ifeedback.mcp.it.woa.com`（可通过 `IFEEDBACK_MCP_URL` 覆盖）
- **Authentication**: `Authorization: Bearer <IFEEDBACK_MCP_TOKEN>` header
- **Optional Header**: `X-Ifeedback-Rtx: <RTX>`（不区分大小写）— 当调用方使用自己的太湖 token 搭建智能体或平台服务时，可通过此 header 传入最终用户的 RTX，服务端会在调用方鉴权通过后，进一步校验该用户是否有权限访问对应应用。不传则不做二次校验。此参数仅用于收紧权限，不会绕过调用方自身的鉴权。
- **Protocol**: JSON-RPC 2.0, method `tools/call`, params `{"name": "<tool>", "arguments": {...}}`

## 1. search

Search user feedback data. Auto-clusters results when feedback count exceeds 100.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `app_name` | str | *required* | iFeedback app name |
| `start_time` | str | *required* | Start time, format: `yyyy-MM-dd HH:mm:ss` |
| `end_time` | str | *required* | End time, format: `yyyy-MM-dd HH:mm:ss` |
| `page` | int | `0` | Page number (0-indexed) |
| `size` | int | `5000` | Page size. `0` = count only, max `100000` |
| `order_key` | str | `"time"` | Sort field |
| `order` | str | `"desc"` | Sort order: `desc` or `asc` |
| `keywords` | str | `""` | Keywords. AND=comma (`,`), OR=space (` `). Example: `"朋友圈,闪退 视频号,卡顿"` = (朋友圈 AND 闪退) OR (视频号 AND 卡顿) |
| `cut_word` | str | `"1"` | 分词匹配开关: `"1"` = 关闭分词，ES wildcard 匹配原文，recall 高但性能差 (default); `"0"` = 开启分词，匹配分词列表，precision 高且性能好，但 recall 较低 |
| `conditions` | list[dict] | `[]` | Filter conditions array |
| `return_fields` | list[str] | `["uin","time","comment"]` | Fields to return. `[]` = all fields |
| `cluster_threshold` | float | `0.3` | Clustering similarity threshold. Smaller = finer-grained clusters. Range 0~1 |

**Response:**
```json
{
  "code": 0, "msg": "success",
  "data": {
    "total": 1234, "uv": 567,
    "feedbacks": [{"uin": "...", "time": "...", "comment": "..."}],
    "clusters": [{"size": 50, "center": {"uin": "...", "comment": "..."}}]
  },
  "url": "https://ifeedback.qq.com/feedback?app_id=42&query_id=..."
}
```

**Clustering behavior:** When `total` > 500, the server auto-clusters and returns results in `clusters` (`feedbacks` will be empty). If the requested `size` is smaller than total, the server fetches up to 5000 records for clustering. When total <= 500, `clusters` is empty and `feedbacks` contains the raw results.

## 2. distribute

Distribution by a specified field. Use `--size` to control how many entries to return.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `app_name` | str | *required* | iFeedback app name |
| `start_time` | str | *required* | Start time |
| `end_time` | str | *required* | End time |
| `key` | str | *required* | Field name for distribution (e.g. `version`, `platform`, `_rule_tag`) |
| `size` | int | `10` | Number of top entries to return |
| `conditions` | list[dict] | `[]` | Filter conditions array |

**Response:**
```json
{
  "code": 0, "msg": "success",
  "data": {"buckets": [{"key": "8.0.50", "doc_count": 123, "pv": 123, "uv": 98}, ...]},
  "url": "..."
}
```

**Note:** If `buckets` is empty, the field has no data for this app/time range. Do NOT use it in conditions.

## 3. trend

Time-series feedback counts (PV/UV).

| Parameter | Type | Default | Description |
|---|---|---|---|
| `app_name` | str | *required* | iFeedback app name |
| `start_time` | str | *required* | Start time |
| `end_time` | str | *required* | End time |
| `interval` | str | `"hour"` | Time interval: `minute`, `hour`, `day`, or `Nm` (e.g. `10m`) |
| `conditions` | list[dict] | `[]` | Filter conditions array |
| `keywords` | str | `""` | Keywords filter (same syntax as search: AND=comma, OR=space) |
| `cut_word` | str | `"1"` | 分词匹配开关: `"1"` = 关闭分词，wildcard 匹配原文，recall 高但性能差 (default); `"0"` = 开启分词，precision 高且性能好，但 recall 较低 |
| `size` | int | `1000` | Max number of trend points |

**Response:**
```json
{
  "code": 0, "msg": "success",
  "data": {
    "total_uv": 90, "total_pv": 2223,
    "data": [{"date": "2026-03-10 00:00:00", "uv": 2, "pv": 28}, ...]
  },
  "url": "..."
}
```

## 4. alarm_data

Query alarm/alert data.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `app_name` | str | *required* | iFeedback app name |
| `start_time` | str | *required* | Start time |
| `end_time` | str | *required* | End time |
| `type` | str | `"realtime"` | Alarm type (see below) |
| `size` | int | `10` | Max results (max 20). `0` = count only |

**Alarm types:**

| Value | Description |
|---|---|
| `realtime` | Smart alarm (default) |
| `custom` | Custom alarm |
| `attr` | Attribute alarm |
| `release` | New version alarm |
| `daily_report` | Daily surge report |
| `cluster_daily_report` | Feedback cluster daily report |
| `cluster_weekly_report` | Feedback cluster weekly report |

**Response:**
```json
{
  "code": 0, "msg": "success",
  "data": [...],
  "total": 5
}
```

## 5. keyword_list

Top keyword distribution from feedback content.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `app_name` | str | *required* | iFeedback app name |
| `start_time` | str | *required* | Start time |
| `end_time` | str | *required* | End time |
| `size` | int | `30` | Number of top keywords |
| `conditions` | list[dict] | `[]` | Filter conditions array |
| `vip_keywords` | list[str] | `[]` | Priority keywords to always include in results (placed at the top of the list) |

**Response:**
```json
{
  "code": 0, "msg": "success",
  "data": [{"word": "crash", "count": 123}, ...]
}
```

## 6. generate_url

Generate an iFeedback web UI URL for a given query.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `app_name` | str | *required* | iFeedback app name |
| `start_time` | str | *required* | Start time |
| `end_time` | str | *required* | End time |
| `keywords` | str | `""` | Keywords |
| `cut_word` | str | `"1"` | 分词匹配开关: `"1"` = 关闭分词，wildcard 匹配原文，recall 高但性能差 (default); `"0"` = 开启分词，precision 高且性能好，但 recall 较低 |
| `conditions` | list[dict] | `[]` | Filter conditions |
| `attr` | str | `""` | Distribution display field |

**Response:**
```
"https://ifeedback.qq.com/feedback?app_id=42&query_id=123456"
```

## 7. search_by_url

Parse an iFeedback URL and search its feedback data.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `url` | str | *required* | iFeedback URL (supports query_id, alarm_id, app_id) |
| `page` | int | `0` | Page number |
| `size` | int | `5000` | Page size |
| `order_key` | str | `"time"` | Sort field |
| `order` | str | `"desc"` | Sort order |
| `return_fields` | list[str] | `["uin","time","comment"]` | Fields to return |

**Response:** Same as `search`.

## 8. parse_url

Parse an iFeedback URL into structured query parameters. Useful for understanding the query conditions behind a shared link before deciding on further analysis. Also useful when the user doesn't know the `app_name` — ask them to provide an iFeedback page URL and use this endpoint to resolve the corresponding `app_name`.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `url` | str | *required* | iFeedback URL (supports `query_id`, `alarm_id`, or `app_id` links) |

**Response:**
```json
{
  "app_name": "wechat",
  "app_id": "42",
  "start_time": "2026-03-20 00:00:00",
  "end_time": "2026-03-20 23:59:59",
  "keywords": "闪退",
  "cut_word": "1",
  "conditions": [],
  "scene": "",
  "has_pic": "0",
  "solved": "",
  "attr": ""
}
```

## 9. sample (CLI-only)

Fetch a few raw records with ALL fields to discover the data schema. Equivalent to `search --return_fields '[]' --size N` but more convenient.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `app_name` | str | *required* | iFeedback app name |
| `start_time` | str | *required* | Start time |
| `end_time` | str | *required* | End time |
| `size` | int | `3` | Number of records to fetch |
| `conditions` | list[dict] | `[]` | Filter conditions (same syntax as `search`) |

```bash
python ifeedback_api.py sample --app_name <app> --start_time "..." --end_time "..." --size 3
```

**Note:** Long list/string values in the output are automatically truncated to save tokens.

## 10. fields (CLI-only)

Batch-check multiple fields for data availability in a single call. Internally calls `distribute` for each field and summarizes results.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `app_name` | str | *required* | iFeedback app name |
| `start_time` | str | *required* | Start time |
| `end_time` | str | *required* | End time |
| `keys` | str | *required* | Comma-separated field names to check (e.g. `"version,platform,_rule_tag"`) |
| `top` | int | `10` | Number of top values to show per field |
| `conditions` | list[dict] | `[]` | Filter conditions (same syntax as `search`) |

```bash
python ifeedback_api.py fields --app_name <app> --start_time "..." --end_time "..." \
  --keys "version,platform,feedback_type,_rule_tag,model,os_version" --top 5
```

**Output:**
```json
{
  "version": {"status": "has_data", "distinct": 20, "top": [{"key": "0x2800453f", "pv": 128917, "uv": 90959}, ...]},
  "platform": {"status": "empty"},
  "feedback_type": {"status": "empty"},
  "_rule_tag": {"status": "has_data", "distinct": 5, "top": [{"key": "bug", "pv": 3200, "uv": 2100}, ...]}
}
```

---

## Conditions Syntax

Each condition is a dict with three keys:

```json
{"key": "<field_name>", "relation": "<operator>", "value": "<value>"}
```

**Operators:** `等于`, `不等于`, `大于`, `小于`, `包含`, `不包含`, `为空`, `不为空`

**Common keys (availability varies by app — always verify with `fields` or `distribute` first):**
- `version` — App version (usually populated)
- `platform` — Platform, e.g. iOS/Android (may be empty in some apps)
- `feedback_type` — Feedback type (may be empty; some apps use `_rule_tag` instead)
- `_rule_tag` — Feedback classification tag (e.g. `反馈基础类型-bug`, `反馈基础类型-建议`)
- `model` — Device model (may be empty)
- `os_version` — OS version (may be empty)
- `uin` — User ID
- `solved` — Processing status

## Feedback Data Fields

| Field | Type | Description |
|---|---|---|
| `uin` | str | User ID |
| `time` | str | Feedback time (`yyyy-MM-dd HH:mm:ss`) |
| `comment` | str | Feedback content |
| `picurllist` | str | Image URLs (pipe `|` separated) |
| `solved` | str | Processing status |
| `solved_user` | str | Handler |
| `solved_time` | str | Handle time |

**Note:** Apps may have additional custom fields. Use `sample` or `search --return_fields '[]'` to discover all available fields for a specific app.

## Error Codes

| HTTP Code | Meaning |
|---|---|
| 401 | Missing or invalid Bearer token |
| 403 | Auth check failed (app not authorized) |
| 422 | Missing required parameters or validation error |
