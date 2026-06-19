---
name: camp-wuji-feedback-fetcher
description: 营地无极反馈系统客户端（原水晶）。通过"王者营地 MCP"服务的 get_mgame_feedback_data_list 接口拉取反馈列表，本 skill 负责解析 MCP 返回数据、按条件过滤、下载反馈附带的 logUrl / picUrl 附件。触发关键词：无极反馈、水晶反馈、wzzs-manage、营地反馈定位、反馈详情、按 uid 查反馈。
---

# camp-wuji-feedback-fetcher

营地**无极**反馈系统（原水晶）的独立 skill。分两层协作：

1. **主 LLM 调 MCP**：直接调用"王者营地 MCP"服务的 `get_mgame_feedback_data_list` 工具拉取反馈列表
2. **本 skill 脚本**：解析 MCP 返回数据 → 过滤 → 写 `feedback.json` → 下载附件 → 解压分类 → 写 manifest

> **路由规则**：
> - `client_version >= 10.112.0415`（新版本）→ **优先走本 skill（无极）**，未查到再降级 ifeedback
> - 老版本 / 用户给出 ifeedback URL → 走 `camp-ifeedback-feedback-fetcher`

## 主 LLM 应执行的 MCP 调用流程

### Step 1: 拉取反馈列表

```
MCP tool: get_mgame_feedback_data_list
参数: user_id, game_id, content_keyword, start_time, end_time, page_size
```

详细参数与回参格式见 [references/command_reference.md](references/command_reference.md)。

### Step 2: 保存返回数据 → 调本 skill 解析

```bash
python3 ../camp-wuji-feedback-fetcher/scripts/wuji.py init-mcp \
    --data-file "<MCP返回的JSON文件>" \
    --workdir $WD \
    --first  # 可选，只取第一条
```

### Step 3: 下载附件（可选）

如果 feedback 有 log_url 或 pic_url：

```bash
python3 ../camp-wuji-feedback-fetcher/scripts/wuji.py fetch --workdir $WD
```

## 本 skill CLI 入口

```bash
python3 scripts/wuji.py <subcommand> [options]
```

| 子命令 | 用途 |
|---|---|
| `init-mcp` | 解析 MCP 返回的 JSON 数据 → 写入 workdir |
| `fetch` | 下载 `log_url` / `pic_url` 附件 → 解压 → 分类 → 写 manifest |
| `show` | 打印 `feedback.json` 关键字段（调试用） |

## 与 workdir 的契约

- `init-mcp` 写 `feedback.json`（归一化字段）/ `feedback_candidates.json`
- `fetch` 下载附件 → 写 `manifest.json`（`logs[]` / `plain_logs[]` / `screenshots[]` / `download_failures[]`）

详细字段见 [references/workdir_contract.md](references/workdir_contract.md)。

## 行为约束

- **MCP 调用失败不阻塞**：超时/错误/无数据时降级走 ifeedback，或等价于"无反馈"继续。
- **部分下载失败不阻塞流程**：`download_failures[]` 非空时继续。
- **多条命中时**：不带 `--first` 会写 `feedback_candidates.json`；主 LLM 应展示候选让用户选择，或默认取 `create_time` 最新的一条。
- **log_url 是 COS 链接**：脚本会自动将公网域名改写为 cos-internal 域名后下载（与 ifeedback 同源 bucket），无需额外转换。
- **pic_url 多图逗号分隔**：MCP 返回的 `pic_url` 字段中多张图用逗号分隔。

## 退出码

| 码 | 含义 |
|---|---|
| 0 | 成功 |
| 1 | IO / 参数错误 |
| 3 | 反馈未命中 / `feedback.json` 缺失 |
| 4 | 数据解析失败 |
