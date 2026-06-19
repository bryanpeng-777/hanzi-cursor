---
name: bugly-data-analyzer
description: Bugly 指标查询和问题分析 Agent。通过 SSE 接口向 Bugly Agent 发送消息并获取解析后的响应。支持：崩溃率/ANR 率/FOOM 查询、新增/劣化/收敛问题分析、版本对比、大盘趋势、AI 诊断、日志检索分析等。当用户需要查询 Bugly Agent、与 Agent 对话、分析问题时使用此 skill。触发词：查询 Agent、Bugly Agent、分析问题、Agent 对话、bugly-data-analyzer。
---

# 查询 Bugly Agent

## 前提条件

首次使用，安装依赖（路径相对于本 SKILL.md 所在目录）：

```bash
pip3 install -r scripts/requirements.txt
```

设置认证 Token（首次使用必须）：

```bash
export BUGLY_USER_TOKEN=<your_token>
```

> **bryanpeng 的 Token**：`54a5f8a2-495c-40e9-81f7-03d69913cc63`（已缓存到 `~/.bugly_token_cache.json`，无需重复 export）
>
> Token 可在 [Bugly 平台个人中心](https://bugly.woa.com/v2/user/token) 获取。
>
> **Token 自动缓存**：检测到环境变量后，Token 会自动持久化到 `~/.bugly_token_cache.json`。之后开启新会话时无需重新 `export`，脚本会自动从缓存读取。若需更新 Token，重新 `export` 新值即可覆盖缓存。

## 参数说明

| 参数 | 必填 | 默认值 | 说明 |
|---|---|---|---|
| `--product-id` | ✅ | — | 产品 ID |
| `--agent-id` | | `12` | Agent ID |
| `--message` | ✅ | — | 发送给 Agent 的消息内容 |
| `--thread-id` | | 自动生成 | 会话 ID，用于多轮对话 |
| `--base-url` | | 测试环境 | API 基础地址 |
| `--output` | | `text` | 输出格式：`text`（可读文本）或 `json`（完整 JSON） |
| `--verbose` | | `false` | 加上此标志输出详细的 SSE 事件信息 |

## 用法

所有操作均通过直接运行 `scripts/query_agent.py` 完成（路径相对于本 SKILL.md 所在目录），无需编写代码。

```bash
# 基本查询（文本格式输出）
python3 scripts/query_agent.py --product-id <产品ID> --message "分析今天新增问题"

# JSON 格式输出（包含完整的文本消息、工具调用和工具结果）
python3 scripts/query_agent.py --product-id <产品ID> --message "分析今天新增问题" --output json

# 多轮对话（指定 thread-id 保持上下文）
python3 scripts/query_agent.py --product-id <产品ID> --message "第一个问题" --thread-id my-thread-001
python3 scripts/query_agent.py --product-id <产品ID> --message "继续分析" --thread-id my-thread-001

# 详细模式（调试用，输出所有 SSE 事件）
python3 scripts/query_agent.py --product-id <产品ID> --message "分析今天新增问题" --verbose

# 指定自定义 Agent ID
python3 scripts/query_agent.py --product-id <产品ID> --agent-id 15 --message "查询问题"

# 指定自定义 API 地址
python3 scripts/query_agent.py --product-id <产品ID> --message "查询问题" --base-url http://api.bugly.woa.com
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
| `未找到 BUGLY_USER_TOKEN` | 未配置认证 Token 且无缓存 | 执行 `export BUGLY_USER_TOKEN=<your_token>`，之后自动缓存 |
| 请求超时 | Agent 处理耗时过长 | 脚本默认超时 300 秒，可重试 |
| SSE 流被截断 | 网络中断 | 检查网络后重试 |
| 连接被拒绝 | 代理或目标服务不可用 | 检查网络代理设置和 API 地址 |

## 支持的常用问题

| 序号 | 问题类型 | 说明 |
|------|----------|------|
| 1 | 分析今天/某天新增问题 | 按日期查某天或日期区间内首次出现的问题（崩溃/ANR/FOOM） |
| 2 | 分析某版本新增问题 | 按 app_version 查该版本上线后新增的问题 |
| 3 | 查看大盘汇总与异常率趋势 | 产品整体次数、影响设备数、异常率及环比；异常率随时间趋势（折线等） |
| 4 | 对比两个版本的差异 | 两版本（或「某版本 vs 小于该版本」）的新增问题、已解决问题、劣化问题 |
| 5 | 分析问题波动（新增/劣化/收敛 Top） | 当前周期 vs 对比周期的新增、劣化、收敛 Top 问题列表 |
| 6 | 获取收敛问题报告 | 基于收敛问题列表生成格式化的收敛报告（支持 crash/anr/foom） |
| 7 | 查询问题列表 | 按时间与筛选条件查 Issue 列表，支持按次数/设备数/上报时间排序、分页 |
| 8 | 按维度查分布或 Top 数据 | 按版本、机型、地区、渠道等维度查分布统计或 Top 指标（异常率、设备数等） |
| 9 | 获取问题详情与堆栈 | 批量获取问题全量详情；按 feature 获取翻译后堆栈 |
| 10 | 对 Top 问题进行 AI 诊断 | 对指定问题做新增/增长类 AI 诊断，给出可能原因与建议 |
| 11 | 获取版本问题分析报告 | 按时间范围与设备阈值生成版本问题分析（报告 Step 3 格式，须原样输出） |
| 12 | 日志检索与下载 | 按 URL 下载日志；按设备/用户 ID、时间、版本等检索上报日志；按问题特征获取异常附件并解码 |
| 13 | 卡顿问题列表与卡顿指标趋势 | 查卡顿问题列表；查 FPS/挂起率/卡顿率等趋势（挂起率仅支持单日） |
| 14 | 根据堆栈/附件做代码级原因分析 | 启动分析容器，下载代码仓库或问题附件，结合完整堆栈做深度原因分析（依赖 Issue Analyze 环境） |
| 15 | 查询产品版本发布信息 | 查版本号、发布类型（开发/灰度/发布）等，用于后续 token、版本对比等调用 |

## 注意事项

- `--product-id` 和 `--message` 为必填参数
- 该接口为 SSE（Server-Sent Events）流式接口，脚本会自动等待流结束后再输出完整结果
- 多轮对话需要保持相同的 `--thread-id`
- 默认连接测试环境 `test.api.bugly.woa.com`，生产环境请通过 `--base-url` 指定
