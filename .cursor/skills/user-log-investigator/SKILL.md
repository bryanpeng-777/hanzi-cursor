---
name: user-log-investigator
description: 基于 userId 的伽利略日志拉取与问题定位专家。给定一个 userId 和问题描述，自动从伽利略拉取该用户指定时间范围内的日志和 trace，结合 galileo-module-locator 定位相关 moduleName，结合 code-locator 找到对应代码，输出结构化的问题诊断报告。默认拉取今天的日志。当用户说"帮我查一下这个用户的日志"、"这个 userId 遇到了什么问题"、"拉一下用户日志"、"userId XXX 出了什么问题"、"根据 userid 查日志"、"查用户的伽利略日志"时触发。即使用户只说"查一下这个用户"并给出 userId，也应主动使用此技能。
---

# User Log Investigator - 基于 userId 的伽利略问题定位

> PREREQUISITE: 执行 CLI 日志导出和 trace 批量拉取前，先确认 `galileo` CLI 可用（`galileo version`）且已鉴权（`galileo auth status`）。若未安装，先读取 `~/.claude/skills/galileo-shared/SKILL.md` 完成安装与登录。

根据 userId 和问题描述，从伽利略拉取用户日志和 trace，结合代码定位，输出完整的问题诊断报告。

## 输入信息

- **userId**（必填）：App 用户 ID，格式通常为纯数字字符串
- **问题描述**（必填）：用户遇到了什么问题，越详细越好
- **时间范围**（可选）：默认今天（当天 00:00 ~ 23:59），支持指定具体时间段

---

## 脚本分工

> **脚本处理**：生成 RFC3339 时间窗口、构建 `get_log_data`/`get_trace_data` 参数（`scripts/gen_log_query.py`）
> **AI 处理**：执行 MCP 查询、分析日志结果、关联 code-locator 定位代码、输出诊断报告

```bash
# 生成查询参数（今天，无 moduleName 过滤）
python3 scripts/gen_log_query.py <userId>

# 指定日期和模块
python3 scripts/gen_log_query.py <userId> --date 2026-04-14 --module OneApi
```

输出 JSON 包含 `step3_search_targets`、`step4_get_log_data`、`step5_get_trace_data` 参数，AI 直接用于 MCP 调用，无需手动计算时间格式。

---

## 执行流程

### Step 1：确定时间范围

如果用户未指定时间范围，使用**今天**（当地时区，北京时间 UTC+8）：
- `start_time`：今天 `00:00:00+08:00`，格式：`2026-03-20T00:00:00+08:00`
- `end_time`：今天 `23:59:59+08:00`，格式：`2026-03-20T23:59:59+08:00`

如果用户指定了时间（如"昨天"、"今天下午"、"3月19日"），按用户意图转换为 RFC3339 格式。

### Step 2：翻译问题描述为 moduleName

读取 `/Users/bryanpeng/.claude/skills/galileo-module-locator/SKILL.md`，根据问题描述匹配相关的 `moduleName`。

从问题描述中提取关键词，匹配以下维度：
- **是否涉及特定功能**（登录、支付、视频、图片、路由、推送……）
- **平台**（iOS / Flutter / 双端）
- **问题类型**（失败、超时、崩溃、黑屏……）

如果匹配到多个 moduleName，全部列出，后续每个都要查询。

> 如果问题描述过于模糊（如"用户反馈卡"），先尝试查 `AppStart` 和 `AppLifecycle`，并在报告中说明日志范围有限。

### Step 3：找到 App 的 Galileo target

使用 `search_targets` 工具搜索 App 对应的 target：

```
search_targets("smoba")
```

从返回的列表中找到王者营地 iOS 客户端对应的 target（通常包含 `smoba` 或 `camp` 关键词，并且是 iOS/mobile 相关的）。

> 如果有多个候选 target，优先选择 Production 环境下的 iOS 客户端 target。

### Step 4：拉取用户日志

**快速通道（默认，适合 5 条样本够用时）**：对每个匹配到的 moduleName，调用 `get_log_data` MCP：

```
get_log_data(
  target = <Step 3 找到的 target>,
  start_time = <Step 1 的开始时间>,
  end_time = <Step 1 的结束时间>,
  filters = "tags.userId = {userId} AND tags.moduleName = {moduleName}",
  namespace = "Production"
)
```

**重要**：userId 过滤字段可能是 `tags.userId` 或 `tags.uid`，如果第一个没有结果，尝试另一个。

如果只知道 userId 不知道 moduleName，则只用 userId 过滤，拉取该用户今天的全量日志：
```
filters = "tags.userId = {userId}"
```

**全量导出路径（MCP 样本不足或需要完整日志序列时）**：改用 CLI 导出，最多 2000 条，写入本地文件：

```bash
# 拉取指定用户全天日志（含所有模块）
galileo logs export \
  --query 'tags.userId=<userId>' \
  --input '{
    "start": "<Step 1 的开始时间，如 2026-05-08T00:00:00+08:00>",
    "end": "<Step 1 的结束时间，如 2026-05-08T23:59:59+08:00>",
    "target": "<target>",
    "namespace": "Production",
    "limit": 500,
    "sort_type": "asc",
    "output": "/tmp/user_logs_<userId>.jsonl",
    "format": "jsonl"
  }'

# 仅拉取指定模块的失败日志（status < 0）
galileo logs export \
  --query 'tags.userId=<userId> AND tags.moduleName=<moduleName> AND NOT tags.status=0' \
  --input '{
    "start": "<开始时间>",
    "end": "<结束时间>",
    "target": "<target>",
    "namespace": "Production",
    "limit": 200,
    "sort_type": "asc",
    "output": "/tmp/user_errors_<userId>.jsonl",
    "format": "jsonl"
  }'
```

> 如果 `tags.userId` 无结果，将 query 中的字段换成 `tags.uid=<userId>` 重试。

**分析返回数据**，关注：
- 日志数量是否正常（0条可能说明 userId 字段名不对，或时间范围没有数据）
- `status < 0` 的日志（表示失败或异常）
- `campType = end` 且 `status != 0` 的日志（流程异常终止）
- 错误信息（`errorMsg`、`errorCode` 字段）

### Step 5：拉取用户 Trace

**方式一：已知 trace_id（从 Step 4 日志中提取）**，用 CLI 批量拉取完整 trace（无 span 截断）：

```bash
galileo trace batch-get \
  --input '{
    "trace_ids": ["<trace_id_1>", "<trace_id_2>"],
    "target": "<target>",
    "namespace": "Production",
    "ignore_span_events": false
  }'
```

> 一次最多拉取 **10 条**完整 trace，无 span 数量截断。从 Step 4 日志的 `traceID` 或 `tags.traceId` 字段提取（NetRequest 模块用 `tags.traceId` 小写，其他模块用 `traceID` 大写）。

**方式二：直接按 userId 搜索失败 span**（无需预知 trace_id）：

```bash
# 找该用户所有失败 span
galileo trace list-spans \
  --query 'tags.userId=<userId> AND status.code=2' \
  --input '{
    "start": "<开始时间>",
    "end": "<结束时间>",
    "target": "<target>",
    "namespace": "Production",
    "limit": 20,
    "sort_type": "desc"
  }'
```

从 trace 中关注：
- 有没有失败的 span（`status_code = 2`）
- 有没有耗时异常的 span（duration 过长）
- Trace 的完整链路是否中断

### Step 6：关联分析（可选）

如果在日志中发现了 `traceID`，可以进一步拉取该 traceID 下跨 target 的所有相关日志：

**MCP 方式（快速，5-30 条样本）：**
```
get_log_data(
  trace_id = <发现的 traceID>,
  need_all_trace_log = "true",
  start_time = ...,
  end_time = ...
)
```

**CLI 方式（全量，最多 2000 条，写入文件）：**
```bash
galileo logs export \
  --query 'traceID=<traceID>' \
  --input '{
    "start": "<开始时间>",
    "end": "<结束时间>",
    "target": "<target>",
    "namespace": "Production",
    "limit": 500,
    "trace_all_targets": true,
    "output": "/tmp/trace_logs_<traceID>.jsonl",
    "format": "jsonl"
  }'
```

> `trace_all_targets: true` 会跨所有 target 拉取该 trace 关联的日志，适合排查跨服务调用链路。此选项会增加查询成本，仅在需要完整跨服务日志时启用。

### Step 7：定位相关代码

基于 Step 4/5 中发现的问题（异常 moduleName、失败阶段、错误码），使用 code-locator 技能定位代码：

> 📍 代码定位：先读取 `/Users/bryanpeng/.claude/skills/camp/code-locator/CODE_MAP.md`，
> 根据「[问题涉及的功能]」匹配相关模块路径，再精准读取对应文件，不做全局搜索。

重点关注：
- 失败日志对应的业务逻辑（比如 `moduleName=Pay` → 查支付流程代码）
- 错误码的含义（在代码中搜索对应的错误码定义）
- 异常 step 对应的执行路径

### Step 8：输出诊断报告

ALWAYS 使用以下模板输出报告：

```
## 用户日志诊断报告

**用户 ID**：{userId}
**问题描述**：{问题描述}
**查询时间范围**：{start_time} ~ {end_time}
**查询环境**：Production

---

### 日志概况

| 模块（moduleName） | 日志总量 | 失败条数 | 关键异常 |
|---|---|---|---|
| XXX | 100 | 3 | status=-1, step=xxx |

---

### 关键异常发现

（列出最重要的 2-5 条异常日志，包含时间、moduleName、status、errorMsg 等关键字段）

**异常 1**：
- 时间：2026-03-20 14:30:22
- moduleName：XXX
- campType：end
- status：-1
- errorMsg：xxx
- 关联 traceID：xxxxxx

**异常 2**：
...

---

### Trace 分析

（如果有 trace，描述 trace 链路的问题；如果没有，说明）

---

### 初步根因分析

（综合伽利略日志和 trace 数据，分析可能的根因，给出 1-3 个假设）

1. **假设 1**：...
   - 支撑证据：...
   - 可能性：高/中/低

2. **假设 2**：...

---

### 相关代码位置

（code-locator 定位到的代码路径和关键函数）

- 主要实现：`[文件路径:行号]` 描述
- 关联文件：`[文件路径]` 描述

---

### 建议排查步骤

1. ...
2. ...
```

---

## 注意事项

- **userId 字段名**：伽利略日志中 userId 字段可能是 `tags.userId` 或 `tags.uid`，两个都试
- **日志为空的处理**：如果拉取结果为空，先检查 userId 是否正确，再尝试放宽时间范围或去掉 moduleName 过滤条件
- **多 moduleName 并行查询**：如果匹配到多个 moduleName，同时发起多个查询，不要串行等待
- **target 选择**：优先选 Production 环境的 iOS 客户端 target；如果用户明确说是测试环境，使用 Development namespace
- **王者营地 iOS 客户端的伽利略 target 名称**：`iOS.camp-app`（不是 `iOS.camp.ios`）。配置来源：`social-ios/src/GameApp/Main/WEGAppLaunchEssentialServices.m` 中 `setupWithServiceName:@"iOS.camp-app"`
- **时间精度**：如果用户说"今天下午两点左右出问题"，可以缩小时间范围到 13:30~14:30 以减少干扰日志
- **隐私保护**：日志中涉及用户隐私的信息（手机号、真实姓名等）在报告中用 `***` 脱敏处理
- **CLI 路径**：`galileo` 命令默认在 `$HOME/.galileo/bin/`，若 PATH 未生效需执行 `export PATH="$HOME/.galileo/bin:$PATH"`
- **MCP vs CLI 选择原则**：单次快速查看用 MCP（响应快，无文件 I/O）；需要 >30 条日志、多条 trace 全量数据、或跨 target 完整链路时，优先用 CLI
- **CLI trace_id 来源**：从 MCP `get_log_data` 的 `sample_logs` 中提取 `traceID`（大写）或 `tags.traceId`（小写，NetRequest 模块专用），再传给 `galileo trace batch-get`
