---
name: galileo-alert-stat-analyzer
description: 伽利略告警自主统计分析。用户提供告警链接（j.woa.com?alert_instance_id=...）、告警截图或告警卡片文字时，自动调用 Galileo MCP 工具查询日志数据、统计错误码分布、版本分布、关联 trace，输出结构化的量化分析报告。无需用户提供 trace 链接或量级链接——直接用 alert_instance_id 自动获取所有告警信息。触发关键词：「分析这个告警」、「看一下这个告警」、「帮我分析一下」、「这个告警什么情况」、「告警初步分析」、「stat分析」。只要用户提供了告警链接（含 alert_instance_id）或告警截图/文字，无论措辞如何，都应主动使用此技能。【例外】消息中包含「伽利略告警登记」「galileo-alert-recorder」时，禁止使用本技能，必须使用伽利略告警登记小助手代替。
---

# 伽利略告警自主统计分析

> PREREQUISITE: 执行 trace 批量拉取前，先确认 `galileo` CLI 可用（`galileo version`）且已鉴权（`galileo auth status`）。若未安装，先读取 `~/.claude/skills/galileo-shared/SKILL.md` 完成安装与登录。

本技能的核心价值：**只需一个告警链接（或截图）**，直接用 Galileo MCP 工具自主查询所有信息，输出带有真实量化数据的分析报告。

## 输入模式

支持以下两种输入，优先使用模式 A：

**模式 A（推荐）**：用户提供含 `alert_instance_id` 的告警链接，如：
```
https://j.woa.com?alert_instance_id=2229319_1773749820&alert_period_id=128e1b2e2ea7eaaa_202603172017_2229319
```

**模式 B（兜底）**：用户提供告警截图或卡片文字，同时需要 `j.woa.com/service/custom-metrics?...` 量级链接。

---

## 脚本分工

> **脚本处理**：URL 解析、提取 `alert_instance_id`/`alert_period_id`、生成 `get_log_data` 查询模板（`scripts/gen_query_params.py`）
> **AI 处理**：执行所有 MCP 调用、分析数据、生成量化报告

```bash
# 模式 A（有 alert URL）：解析 URL，输出 get_alert_detail 参数及后续查询模板
python3 scripts/gen_query_params.py "<alert_url>"
```

输出 JSON 包含 `step1_params`（直接用于 `get_alert_detail`）和 `subsequent_query_templates`（含 groupName 判断分支）。

---

## 分析流程

### 步骤 1：获取告警关键信息

**模式 A**：从 URL 中提取 `alert_instance_id` 和 `alert_period_id`，调用 `get_alert_detail` MCP 工具：

```json
{
  "alert_instance_id": "<从URL提取>",
  "alert_period_id": "<从URL提取>"
}
```

从返回结果中提取：

| 字段 | 来源路径 | 说明 |
|---|---|---|
| `target` | `rule.target` | 如 `iOS.camp-app` |
| `namespace` | `rule.namespace` | Production / Development |
| `moduleName` | `alert_labels[label_desc=tags.moduleName].label_value` | 如 `OneApi` |
| `campType` | `alert_labels[label_desc=tags.campType].label_value` | start / step / end |
| `groupName` | `alert_labels[label_desc=tags.groupName].label_value` | 如 `vip/getprofilevipcareer`，**存在时必须提取** |
| `alertTime` | `alert_data.alert_data_time` | 告警触发时间 |
| `metricValue` | `alert_metrics[0].metric_value` | 触发值和阈值 |
| `fluctuation` | `alert_metrics[1].metric_value` | 波动幅度（如有） |

> ⚠️ **关键判断**：如果 `alert_labels` 中存在 `tags.groupName` 字段，说明本次告警是针对**某个具体接口/分组**的下钻告警，而非模块整体告警。**后续所有 `get_log_data` 查询都必须加上 `AND tags.groupName=<groupName>` 过滤条件**，否则查询结果会混入整个模块的所有接口数据，导致量级统计、错误码分布、版本分布全部产生严重偏差。

**模式 B**：从截图（Read 工具读图）或文字中手动提取上述字段，再调用 `parse_galileo_url` 解析量级链接获取 target。

### 步骤 2（原步骤 3）：查询日志全量统计

调用 `get_log_data`，以**告警时间（alertTime）为中心前后各 6 分钟**为时间窗口：

**若告警含 `groupName`（下钻告警）：**
```json
{
  "target": "<解析出的 target>",
  "namespace": "Production",
  "start_time": "<alertTime - 6分钟，RFC3339格式>",
  "end_time": "<alertTime + 6分钟，RFC3339格式>",
  "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.groupName=<groupName>",
  "group_by_tags": "[\"tags.ret_code\", \"tags.status\"]"
}
```

**若告警不含 `groupName`（模块整体告警）：**
```json
{
  "target": "<解析出的 target>",
  "namespace": "Production",
  "start_time": "<alertTime - 6分钟，RFC3339格式>",
  "end_time": "<alertTime + 6分钟，RFC3339格式>",
  "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType>",
  "group_by_tags": "[\"tags.groupName\", \"tags.ret_code\"]"
}
```

> ⚠️ **groupName 下钻是关键**：不带 `groupName` 的查询会返回整个模块所有接口的混合数据，使得量级统计、错误码占比完全失去参考价值。有 `groupName` 时**必须**加入该过滤条件。

从返回中记录：
- `log_count`：今日总量 / 错误量 vs 昨日对比
- `tag_statistics`：各错误码的数量和占比
- `sample_logs`：取 2-3 条样本，从 `ret_code` / `errorMsg` 中提取失败接口名

> 注意：部分模块错误码字段为 `tags.ret_code` 或 `tags.logic_code`，而非 `tags.errorCode`，若 `tags.errorCode` 统计结果为 0%，应换用 `tags.ret_code` 重新查询。

**深度分析路径（MCP 样本不足时）**：若 MCP 返回的 `tag_statistics` 样本量过少（如总量 < 100 条），或需要获取完整 tag 分布而非摘要，改用 CLI：

```bash
# 全量 tag 分布统计（含 groupName 时示例）
galileo logs analyze tags \
  --query 'tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.groupName=<groupName>' \
  --input '{
    "start": "<alertTime - 6分钟，如 2026-03-17T20:11:00+08:00>",
    "end": "<alertTime + 6分钟>",
    "target": "<target>",
    "namespace": "Production",
    "tags": ["tags.ret_code", "tags.status", "tags.cClientVersionName"]
  }'

# 导出完整样本供离线分析（最多 2000 条）
galileo logs export \
  --query 'tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.groupName=<groupName> AND tags.ret_code=<主要errorCode>' \
  --input '{
    "start": "<alertTime - 6分钟>",
    "end": "<alertTime + 6分钟>",
    "target": "<target>",
    "namespace": "Production",
    "limit": 200,
    "output": "/tmp/alert_logs.jsonl",
    "format": "jsonl"
  }'
```

### 步骤 3（原步骤 4）：版本维度统计（针对主要错误码）

取步骤 2 中占比最高的错误码，再次查询版本分布（**同样须带上 groupName**）：

**含 groupName 时：**
```json
{
  "target": "<target>",
  "namespace": "Production",
  "start_time": "<start_time>",
  "end_time": "<end_time>",
  "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.groupName=<groupName> AND tags.ret_code=<主要errorCode>",
  "group_by_tags": "[\"tags.cClientVersionName\"]"
}
```

**不含 groupName 时：**
```json
{
  "target": "<target>",
  "namespace": "Production",
  "start_time": "<start_time>",
  "end_time": "<end_time>",
  "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.ret_code=<主要errorCode>",
  "group_by_tags": "[\"tags.cClientVersionName\"]"
}
```

### 步骤 4（原步骤 5）：查找关联 trace

**第一步**：从步骤 2 的 `tag_statistics` 中找出**数量最多的那一组**错误码，取其对应 `sample_logs` 中的 trace ID。

> ⚠️ **NetRequest 模块特别注意**：`NetRequest` 日志中同时存在两种 trace ID，必须用正确的那个：
> - `traceID`（大写，日志元数据级别）= **Session 级别 trace**，跨整个用户会话，会把多次调用聚合成一条 span，`/game/xxx` 可能显示 `count:N, status:OK`，掩盖其中的 Error，**不要用这个查 errorMsg**
> - `tags.traceId`（小写，自定义 tag）= **单次请求 trace**，包含完整服务端调用链（apigw → 业务 svr → 下游），Error span 的 `sample_status_msg` 里有真实的 errorMsg，**用这个**
>
> 对于 `NetRequest` 模块，**必须取 `sample_logs[].tags.traceId`（小写）**，不要取 `traceID`（大写）。

如果步骤 2 的样本日志没有覆盖到最大量的那一组，则补充一次 `get_log_data` 查询（**同样须带上 groupName**），从返回的 `sample_logs` 中取 `tags.traceId`（NetRequest 模块）或 `traceID`（其他模块）：

**含 groupName 时：**
```json
{
  "target": "<target>",
  "namespace": "Production",
  "start_time": "<start_time>",
  "end_time": "<end_time>",
  "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.groupName=<groupName> AND tags.ret_code=<量最大的errorCode>",
  "group_by_tags": "[\"tags.cClientVersionName\"]"
}
```

**第二步**：用取到的 trace ID 通过 CLI 查询完整 trace（支持批量，无 span 截断）：

```bash
galileo trace batch-get \
  --input '{
    "trace_ids": ["<trace_id_1>", "<trace_id_2>"],
    "target": "<target>",
    "namespace": "Production",
    "ignore_span_events": false
  }'
```

> CLI 优于 MCP 的关键点：一次可拉取最多 **10 条**完整 trace，且无 100 spans 截断限制。需要分析多个错误码的代表性 trace 时，将所有 trace_id 一次传入，避免多轮等待。

若已知错误条件但还没有 trace_id（如需要找特定错误码的 trace），可先用 `trace list` 按 DSL 检索：

```bash
galileo trace list \
  --query 'tags.moduleName=<moduleName> AND tags.ret_code=<errorCode>' \
  --input '{
    "start": "<alertTime - 6分钟>",
    "end": "<alertTime + 6分钟>",
    "target": "<target>",
    "namespace": "Production",
    "limit": 5
  }'
```

关注 trace 中：
- 整体调用链是否正常（网络层/接口层）
- 哪些 span 出现 Error 状态
- 用户会话的整体行为路径
- **`errorMsg` 字段**：Error 状态的 span 中通常携带 `tags.errorMsg` 字段，包含服务端返回的错误信息或客户端的异常描述，是判断根因的关键线索，必须提取并展示

### 步骤 4.5：代码关联分析（必须执行）

完成 Trace 分析后，**必须**调用 `camp/code-locator` 技能，根据告警的 `moduleName` 和 Trace/日志中发现的错误路径，定位涉事**业务逻辑代码**。

**操作方式**：读取 `~/.claude/skills/camp/code-locator/SKILL.md` 并按其流程执行，以下信息作为查询输入：
- `moduleName`（如 `OneApi`、`NetRequest`）
- 错误现象关键词（从 `errorMsg`、失败接口名、错误码含义中提取）

**定位目标**（按优先级）：
1. 与 `groupName`（具体接口/功能）直接相关的调用或处理逻辑
2. 错误码 / `errorMsg` 对应的错误处理代码路径
3. 告警告警时间附近有 git 变更的相关文件

从定位到的代码中提取：
- **文件路径 + 行号范围**
- **关键代码片段**（不超过 20 行，聚焦问题逻辑）
- **代码与告警的关系说明**（一句话说明这段代码如何引发或关联当前告警）

---

## 报告输出格式

**严格使用以下格式**，所有章节都要用 Markdown 表格呈现量化数据，禁止纯文字叙述代替数据。

---

### 一、告警概况

| 字段 | 值 |
|---|---|
| 告警时间 | `<alertTime>` |
| 告警类型 | `<首次异常 / 持续异常> · <量级超阈值 / 错误率骤升 / 量级骤降>` |
| 模块 | `` `<moduleName>` · `campType: <campType>` `` |
| 下钻接口 | `` `<groupName>`（若无则填"模块整体"）`` |
| 触发值 | `<实际值>（阈值 <阈值>）` |
| 波动幅度 | `<前值> → <后值>（<幅度>，阈值 <阈值>）` |

> 若「下钻接口」非空，说明本次告警仅针对 `<groupName>` 这一个接口，后续所有数据统计均已限定在该接口范围内，与模块整体数据无关。

---

### 二、关联日志统计（`<时间窗口>`）

| 维度 | 今日 | 昨日 | 增幅 |
|---|---|---|---|
| 总日志量 | `<今日>` | `<昨日>` | `<+XX%>` |
| 错误日志数 | `<今日>` | `<昨日>` | `<+XX%>` |
| info 日志数 | `<今日>` | `<昨日>` | `<+XX%>` |

> 对量级变化做一句话解读（如：总量是昨日X倍，但错误率与昨日持平，表明是流量放量驱动）

---

### 三、错误码分布

| errorCode | 含义（如可识别） | 数量 | 占比 |
|---|---|---|---|
| `<code>` | `<含义>` | `<数量>` | `<XX%>` |
| ... | ... | ... | ... |

---

### 四、核心错误分析：`errorCode=<主要错误码>`

**失败接口（从样本日志 errorMsg 提取）：**

```
api: <接口名>（from: <Flutter/iOS>）
api: <接口名>（from: <Flutter/iOS>）
```

**典型错误日志片段：**
```
➡️ Request:
  api: <接口名>
  from: <平台>
  params: <关键参数>
⬅️ Response:
  code: <错误码>
  message: <错误信息>
  data: <数据>
```

**关键结论**：一句话总结主要失败场景和表现形式。

---

### 五、版本维度（`errorCode=<主要错误码>` 的分布）

| App版本 | 错误数 | 占比 |
|---|---|---|
| `<版本>` | `<数量>` | `<XX%>` |
| ... | ... | ... |

---

### 六、Trace 关联分析

取**数量最多的错误类型**（`errorCode=<主要错误码>`，占比 `<XX%>`）对应的典型 trace（`<traceID>`）分析其完整会话：

- **调用链整体状态**：（正常 / 有错误 span）
- **网络层**：（哪些接口成功 / 哪些失败）
- **页面层**：（哪些页面正常加载）
- **OneApi/业务层**：（在同一 session 内，<moduleName> 的调用结果）

**errorMsg 关键信息（从 Error span 的 `tags.errorMsg` 提取）：**

```
span: <出错的 span operation_name>
errorMsg: <tags.errorMsg 的原始内容>
含义解读: <一句话解释这条错误信息说明了什么>
```

> 若存在多条不同的 errorMsg，逐条列出并对比差异，判断是同一根因还是多个独立失败路径。若所有 span 均为 OK 状态（trace 内无 error span），则说明错误在本 session 的其他位置记录，需结合日志的 `tags.errorMsg` 字段（步骤 2 的 sample_logs）辅助判断。

> 一句话总结 trace 分析发现（如：网络层正常，问题集中在 OneAPI bridge 层对 getABConfig 的处理）

---

### 六.5、代码关联分析

> 本节由 `code-locator` 技能输出，定位与告警直接相关的业务逻辑代码。

**涉事代码：**

| 文件 | 行号 | 说明 |
|---|---|---|
| `<文件路径>` | `<起止行号>` | `<与告警的关联说明>` |

**关键代码片段：**

```
[从 code-locator 提取的关键代码，≤20行，聚焦错误路径/问题逻辑]
```

**代码分析结论**：一句话说明这段代码如何与告警关联（如：`getABConfig` 在网络异常时未做降级处理，直接向上抛出 `ret_code=-3`，与告警错误码吻合）

---

### 七、初步结论 & 排查方向

| 结论 | 说明 |
|---|---|
| **告警性质** | `<量级触发/错误率上升/量级骤降>，<是否新错误>` |
| **主要问题** | `<主要错误码对应的接口失败描述>` |
| **版本集中** | `<版本名> 占 <比例>，值得重点关注` |
| **来源** | `<Flutter侧/iOS侧>` |

**建议优先排查：**
1. 检查 `<主要接口>` 服务端是否正常，或是否有接口变更
2. 确认 `<主要版本>` 是否有相关逻辑变更
3. 排查 `errorCode: <主要错误码>` 的具体含义（接口不存在 / 参数不合法 / 服务不可用）
4. 对比昨日绝对量，判断是否单纯是流量放量导致

---

### 八、处置建议

根据前七节的分析结果，从以下两个方向之一给出明确建议：

**判断依据（综合以下维度）：**
- 错误率是否与昨日持平（仅量级放量） → 倾向屏蔽
- errorCode 对应的失败是业务设计预期（如 status 硬编码 -1）→ 倾向屏蔽
- 错误率相比昨日显著恶化（非比例性增长）→ 倾向修复
- 特定新版本独占绝大多数错误 → 倾向修复
- 用户有实际感知影响（功能不可用、数据丢失）→ 倾向修复

---

**方案 A：建议屏蔽告警**

适用情形：告警反映的是已知的、预期内的行为，错误率未实质恶化，用户无感知。

```
【建议】屏蔽本次告警

原因：<一句话说明为什么这个告警是正常行为的误报>

屏蔽方式（选其一）：
  □ 静默此条告警（适用于一次性偶发）
  □ 调整量级阈值至 <建议值>（当前阈值 <当前值> 过于敏感）
  □ 调整波动阈值至 <建议值>%（当前阈值 <当前值>% 过于敏感）

长期优化建议：<如何让告警阈值更合理地反映真实问题>
```

---

**方案 B：建议代码修复**

适用情形：存在实质性错误率恶化，或特定版本引入了新的失败路径。

```
【建议】需要代码层修复

紧急程度：【P0 立即处理】/【P1 今日内】/【P2 本周内】
影响面：<受影响用户数量级 / 版本范围>

根因判断：<一句话说明问题所在>

修复方向：
  1. <具体修复思路，如：检查 getABConfig 调用时的异常捕获逻辑>
  2. <如需回滚：建议回滚 <版本> 的 <具体变更>，或关闭 <开关名>（如有）>
  3. <如需服务端配合：联系 <后端接口负责方> 确认 <接口名> 的返回码变化>

验证方式：
  - 修复上线后观察 <moduleName>-<campType> 的错误率是否回落至昨日基线
  - 重点关注版本 <主要版本> 的错误码 <主要错误码> 数量变化
```

---

## 注意事项

- **优先模式 A**：只要 URL 中含有 `alert_instance_id`，无论域名是否为 `j.woa.com`，都直接走 `get_alert_detail` 获取告警信息，**不需要让用户再提供截图或量级链接**
- **时间格式**：调用 MCP 工具时，时间必须使用 RFC3339 格式（`2026-03-17T19:33:00+08:00`）
- **时间窗口推导**：从 `alert_data_time` 字段（如 `Tue, 17 Mar 2026 20:17:00 +0800`）解析出告警时间，前后各扩展 6 分钟作为查询窗口
- **并行查询**：步骤 2（全量统计）和步骤 4（trace 查询）可以并行发起，减少等待时间
- **CLI trace 工具路径**：`$HOME/.galileo/bin/galileo`，若 PATH 未配置需显式指定完整路径，或先执行 `export PATH="$HOME/.galileo/bin:$PATH"`
- **CLI 批量 trace**：`galileo trace batch-get` 一次最多 10 个 trace_id，优先把多种错误码的代表性 trace_id 合并到一次调用
- **CLI 日志导出文件**：默认写入 `/tmp/`，分析完成后无需手动清理，下次覆盖写入即可
- **样本来源**：errorMsg 中的接口名从 `sample_logs` 的 `tags.errorMsg` 字段中正则提取
- **yesterday 对比**：`log_count` 中的 `yesterday` 字段是同一时间窗口的昨日对比，直接使用
- **增幅计算**：`(today - yesterday) / yesterday * 100%`，如果昨日为0则标注"昨日无数据"
- **结论要有数据支撑**：每个结论都要对应表格中的具体数字，禁止空洞描述
- **groupName 下钻强制要求**：`get_alert_detail` 返回的 `alert_labels` 中如果含有 `tags.groupName`，则后续**每一次** `get_log_data` 调用都必须在 filters 中加入 `AND tags.groupName=<groupName>`，否则返回数据是整个模块所有接口的混合统计，量级、错误码、版本分布全部失去意义。漏加此条件是最常见的分析偏差来源，必须在每次构造 filter 时主动检查
- **错误码字段兜底**：若 `group_by_tags` 中指定 `tags.errorCode` 但统计结果显示字段存在率为 0%，说明该模块使用的是 `tags.ret_code` 或 `tags.logic_code` 作为错误码字段，应立即改用 `tags.ret_code` 重新查询，无需等待用户提示
- **errorMsg 字段优先提取**：trace 中 Error 状态的 span 通常会携带 `tags.errorMsg` 字段，内含服务端返回的错误原因或客户端异常堆栈摘要，是定位根因的最直接证据。分析 trace 时**必须**检查每个 Error span 的 `tags.errorMsg`，并在报告第六节展示原文；若日志 `sample_logs` 中也有 `tags.errorMsg` 字段，同样需要提取（即使 trace 中 span 均为 OK）
- **NetRequest 模块 trace 选择**：NetRequest 日志中 `traceID`（大写）是 session 级别 trace，`tags.traceId`（小写）才是单次请求 trace。查 errorMsg 必须用 `tags.traceId`，否则服务端错误信息会被 session 聚合掩盖——session trace 中相同接口的多次调用被合并为一条 span（如 `count:5, status:OK`），其中单次的 Error 会被淹没，导致看不到 errorMsg
