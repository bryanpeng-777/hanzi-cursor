# 命令与接口参考

## MCP 接口：get_mgame_feedback_data_list

### 入参

```json
{
  "user_id": "",                         // 用户ID，按 uid 查时填入
  "game_id": "",                         // 游戏ID，默认传空（不限制），见下方枚举
  "content_keyword": "",                 // 内容关键词搜索
  "start_time": "YYYY-MM-DD HH:mm:ss",  // 开始时间
  "end_time": "YYYY-MM-DD HH:mm:ss",    // 结束时间
  "page_size": 5                         // 每页条数
}
```

> **重要**：`game_id` 建议默认传空字符串（不限制），让服务端返回该用户所有游戏的反馈。仅在用户明确指定查某个游戏时才填入具体值。
```

### 字段枚举

| 字段 | 值 | 含义 |
|---|---|---|
| `game_id` | `20001` | 王者荣耀 |
| `game_id` | `30001` | 王者万象棋 |
| `game_id` | `30005` | 王者荣耀世界 |
| `game_id` | `50001` | 王者营地 |
| `req_source` | `0` | 王者营地 |
| `req_source` | `1` | PC启动器 |

> `game_id` 为入参，可按业务过滤；`req_source` 为回参字段，标识反馈提交来源。

### content 拼接规则

`content` 字段由服务端按竖线 `|` 拼接，格式视是否有联系方式而定：

| 条件 | 格式 |
|---|---|
| 无对方ID、无联系方式 | `内容` |
| 有对方营地ID | `对方营地ID|内容` |
| 有对方营地ID + 联系方式 | `对方营地ID|联系方式类型|联系方式|内容` |

> 解析时按 `|` split，最后一段为用户实际反馈文本。

常见场景：
- 按 uid 查最近反馈：填 `user_id` + `start_time`/`end_time`，`game_id` 留空
- 拉最新 N 条：只填 `start_time`/`end_time` + `page_size`，`game_id` 留空
- 按关键词搜索：填 `content_keyword` + 时间窗，`game_id` 留空
- 指定游戏查询：仅在用户明确要求时才填 `game_id`（如 `20001`=王者荣耀）

### 回参

```json
{
  "structuredContent": {
    "feedback_list": [
      {
        "id": "4649",
        "user_id": "1689557164",
        "game_id": "20001",
        "req_source": 0,
        "system_type": "android",
        "device_model": "PKX110",
        "client_version": "10.112.0429",
        "content": "...",
        "log_url": "https://cltlog-xxx.cos.ap-guangzhou.myqcloud.com/...",
        "pic_url": "https://report-xxx.file.myqcloud.com/...,https://...",
        "create_time": "2026-05-18 16:57:11",
        "feedback_type": "1000-10400"
      }
    ],
    "total_count": 10,
    "success": true
  },
  "isError": false
}
```

---

## CLI 子命令

### init-mcp — 解析 MCP 返回数据（主入口）

```bash
python3 scripts/wuji.py init-mcp \
  --data-file /path/to/mcp_response.json \
  --workdir ./out \
  --first
```

| 参数 | 必需 | 说明 |
|---|---|---|
| `--data-file` | 是 | MCP 返回的 JSON 文件路径 |
| `--workdir` | 是 | 工作目录 |
| `--feedback-id` | 否 | 指定 feedback_id 只取单条 |
| `--user-id` | 否 | 按 user_id 过滤 |
| `--first` | 否 | 只取第一条 |
| `--json` | 否 | JSON 输出 |

### fetch — 下载附件

```bash
python3 scripts/wuji.py fetch --workdir ./out
```

| 参数 | 必需 | 说明 |
|---|---|---|
| `--workdir` | 是 | 工作目录 |
| `--timeout` | 否 | 单个 URL 下载超时秒数（默认 60） |
| `--no-download` | 否 | 跳过下载，只对已有 attachments/ 重新分类 |
| `--json` | 否 | JSON 输出 |

### show — 打印反馈关键字段

```bash
python3 scripts/wuji.py show --workdir ./out
```
