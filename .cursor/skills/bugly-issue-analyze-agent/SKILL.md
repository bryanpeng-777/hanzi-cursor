---
name: bugly-issue-analyze-agent
description: Bugly issue 智能修复和问题分析 Agent。专注于通过堆栈信息、日志和源码分析定位问题根因，支持：下载代码仓库与崩溃附件、结合完整调用链进行深度原因分析、给出标准 git diff 格式的修复代码与验证方法。当用户需要对 Bugly issue 进行代码级根因分析、获取修复方案、分析崩溃/ANR/FOOM 堆栈、分析 issue 问题时使用此 skill。触发词：分析 issue、根因分析、修复建议、堆栈分析、代码分析、智能修复、问题分析、bugly-issue-analyze-agent。
secrets:
  - name: BUGLY_USER_TOKEN
    description: bugly 使用的 token（必需）
    required: true
---

# 查询 Bugly Issue Analyze Agent

## 前提条件

首次使用，安装依赖（路径相对于本 SKILL.md 所在目录）：

```bash
pip3 install -r scripts/requirements.txt
```

### 认证 Token 配置

本 Skill 支持以下三种方式获取 `BUGLY_USER_TOKEN`，按优先级从高到低：

1. **Secrets 密钥注入（推荐）**：本 Skill 已在 frontmatter `secrets` 中声明 `BUGLY_USER_TOKEN`，加载 Skill 时系统会自动触发用户审批，审批通过后 Token 会通过环境变量 `BUGLY_USER_TOKEN` 自动注入，无需手动配置。
2. **Box Token 方式**：系统会自动从环境变量 `BOX_BUGLY_USER_TOKEN` 读取 Token（适用于 Box 环境）。
3. **手动设置环境变量**：`export BUGLY_USER_TOKEN=<your_token>`，设置后 Token 会自动缓存到 `~/.bugly_token_cache.json`。
4. **本地缓存文件**：若环境变量未设置，脚本会自动从 `~/.bugly_token_cache.json` 读取上次缓存的 Token。

> Token 可在 [Bugly 平台个人中心](https://bugly.woa.com/v2/user/token) 获取。

## 参数说明

| 参数 | 必填 | 默认值 | 说明 |
|---|---|---|---|
| `--product-id` | ✅ | — | 产品 ID |
| `--message` | ✅ | — | 发送给 Agent 的消息内容 |
| `--thread-id` | | 自动生成 | 会话 ID，用于多轮对话 |
| `--output` | | `text` | 输出格式：`text`（可读文本）或 `json`（完整 JSON） |
| `--verbose` | | `false` | 加上此标志输出详细的 SSE 事件信息 |

## 用法

所有操作均通过直接运行 `scripts/query_agent.py` 完成（路径相对于本 SKILL.md 所在目录），无需编写代码。

```bash
# 分析指定 crash issue（最常用）
python3 scripts/query_agent.py --product-id <产品ID> --message "分析这个 crash 的 issue FE3C4A7F32CAA5271D84C1AF95C0E484" --verbose

# 分析 ANR issue
python3 scripts/query_agent.py --product-id <产品ID> --message "分析这个 ANR 的 issue <issue_id>" --verbose

# JSON 格式输出（包含完整的文本消息、工具调用和工具结果）
python3 scripts/query_agent.py --product-id <产品ID> --message "分析这个 crash 的 issue <issue_id>" --output json --verbose

# 多轮对话（指定 thread-id 保持上下文）
python3 scripts/query_agent.py --product-id <产品ID> --message "分析这个 crash 的 issue <issue_id>" --thread-id my-thread-001 --verbose
python3 scripts/query_agent.py --product-id <产品ID> --message "继续分析崩溃原因" --thread-id my-thread-001
```

## 输出说明

### text 格式（默认）

自动过滤 Agent 的中间推理过程（`/*PLANNING*/`、`/*ACTION*/`、`/*REASONING*/`），**只输出 `/*FINAL_ANSWER*/` 之后的最终结果**。

加上 `--verbose` 后，输出完整内容：包括中间推理过程、工具调用信息、工具结果、运行状态、threadId / runId。

### json 格式

- 默认：仅返回 `answer`（最终答案文本）和 `error`（错误信息）两个字段。
- 加上 `--verbose`：返回完整的解析结果 JSON，包含字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `text_messages` | `list[str]` | Agent 回复的所有文本消息（含中间过程） |
| `tool_calls` | `list[dict]` | 工具调用信息（工具名、参数） |
| `tool_results` | `list[dict]` | 工具调用结果 |
| `thread_id` | `str` | 会话线程 ID |
| `run_id` | `str` | 运行 ID |
| `raw_events` | `list[dict]` | 原始 SSE 事件列表（仅 verbose 模式填充） |
| `success` | `bool` | 是否成功完成 |
| `error` | `str\|null` | 错误信息 |

## SSE 事件类型

脚本内部处理以下 SSE 事件类型：

| 事件类型 | 说明 |
|---|---|
| `RUN_STARTED` | 运行开始 |
| `TEXT_MESSAGE_START` | 文本消息开始 |
| `TEXT_MESSAGE_CONTENT` | 文本消息内容片段（delta） |
| `TEXT_MESSAGE_END` | 文本消息结束 |
| `TOOL_CALL_START` | 工具调用开始 |
| `TOOL_CALL_ARGS` | 工具调用参数片段 |
| `TOOL_CALL_END` | 工具调用结束 |
| `TOOL_CALL_RESULT` | 工具调用结果 |
| `RUN_FINISHED` | 运行完成 |
| `RUN_ERROR` | 运行错误 |

## 常见问题

| 问题 | 原因 | 处理方式 |
|------|------|----------|
| `未找到 BUGLY_USER_TOKEN` | 未配置认证 Token 且无缓存 | 推荐：在 Token 管理中配置 BUGLY_USER_TOKEN 并授权；或执行 `export BUGLY_USER_TOKEN=<your_token>` |
| 请求超时 | Agent 处理耗时过长 | 脚本默认超时 1200 秒（20 分钟），可重试 |
| SSE 流被截断 | 网络中断 | 检查网络后重试 |
| 连接被拒绝 | 代理或目标服务不可用 | 检查网络代理设置 |

## 支持的常用问题

| 序号 | 问题类型             | 示例 message                      |
|------|------------------|---------------------------------|
| 1 | 分析指定 crash issue | `分析这个 crash 的 issue <issue_id>` |
| 2 | 分析指定 ANR issue   | `分析这个 ANR 的 issue <issue_id>`   |
| 3 | 分析指定 issue 链接    | `分析这个 https://bugly.woa.com/v2/exception/crash/issues/detail?cId=3117b65d-49ce-45b6-bd10-2321047f70c9&clusterStackType=&feature=7BAC98388132326141D2B81DD8445761&messageTab=%E8%81%94%E5%8A%A8%E7%9B%91%E6%8E%A7&pid=1&productId=ae9c799533&tab=case&token=e0fc28969e222e306fd2ff36ec9c7cb6`    |


## 注意事项

- `--product-id` 和 `--message` 为必填参数
- ⏳ **该 Agent 分析过程较耗时**（通常需要 1~5 分钟），涉及代码仓库下载、附件解析、堆栈深度分析等步骤，请耐心等待
- 该接口为 SSE（Server-Sent Events）流式接口，脚本会自动等待流结束后再输出完整结果
- 多轮对话需要保持相同的 `--thread-id`
