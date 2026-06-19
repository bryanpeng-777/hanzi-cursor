# 营地问题线索提取 — Knot 版


接收伽利略告警链接、Bugly Issue 链接，或直接提供的 userId + ANR/Crash/FOOM 问题描述，自动识别输入类型，调用对应处理逻辑，输出标准三要素供 营地问题分析小助手 直接使用。

---

## 支持的输入类型

| 输入类型 | 特征 | 处理方式 |
|---------|------|---------|
| 伽利略告警链接 | URL 含 `alert_instance_id` 参数 | 调用 `galileo-alert-user-extractor` |
| Bugly Issue 链接 | URL 含 `/crash-reporting/` 或 `/exception/crash\|anr\|foom/` 路径 | 调用 `bugly-issue-user-extractor` |
| 直接 userId + ANR/Crash/FOOM | 含有数字 userId 且问题描述含 ANR、Crash、崩溃、FOOM 关键词 | 调用 bugly-assistant 获取精确时间戳 |

---

## Step 1：识别输入类型

用户输入可能是链接或直接的 userId + 问题描述，按以下优先顺序判断：

**伽利略告警链接**：URL 中含 `alert_instance_id`，例如：
```
https://j.woa.com?alert_instance_id=2229319_...&alert_period_id=...
```

**Bugly Issue 链接**：URL 路径含 `/crash-reporting/` 或 `/exception/crash/`、`/exception/anr/`、`/exception/foom/`，例如：
```
https://bugly.woa.com/v2/crash-reporting/crashes/ef14bfff8f/abc123?pid=1
https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&feature=xxx
```

**直接 userId + ANR/Crash/FOOM**：输入中包含数字 userId（一个或多个），且问题描述中含有以下关键词之一：ANR、Crash、crash、崩溃、FOOM、anr，例如：
```
用户 1840083312 的 ANR
2026年5月5日 userId=447074794 crash
这10个用户：1840083312 1463692475 ... 的ANR
```

**无法识别**：告知用户「无法识别输入类型，请提供伽利略告警链接（含 alert_instance_id）、Bugly Issue 详情链接，或包含 userId 和问题类型（ANR/Crash/FOOM）的描述」。

---

## Step 2：调用对应提取技能

### 对直接 userId + ANR/Crash/FOOM 输入

**当输入类型为「直接 userId + ANR/Crash/FOOM」时，执行本节；链接类型跳过，进入下方对应处理。**

1. **提取基础三要素**：
   - `userId`：从输入中解析出所有数字 userId（可能是单个或多个）
   - `问题描述`：识别问题类型关键词（ANR / Crash / FOOM）
   - `发生时间（大致）`：从输入中提取日期（如「2026年5月5日」），若无则默认今天

2. **通过 **营地崩溃排查** 获取精确时间戳**（每个 userId 独立查询，多个 userId 并行执行）：
   - 调用 `营地崩溃排查`：查询该 userId 在指定日期发生的 ANR/Crash/FOOM 事件，取**最近一次上报的精确时间戳**
   - 若查询到精确时间：填入「精确发生时间」字段，格式 `YYYY-MM-DD HH:mm:ss`
   - 若该 userId 在指定日期 Bugly 无记录：标注「（Bugly 无记录，使用用户提供日期）」

3. **计算分析时间窗口**（每个 userId 独立计算）：
   ```
   analysis_start = 精确发生时间 - 1小时
   analysis_end   = 精确发生时间 + 1小时
   ```
   输出格式均为 RFC3339（含时区），例如：`2026-05-05T13:30:00+08:00`

4. **输出格式（每个 userId 一张卡片）**：

```
📋 前置信息提取完成（直接输入模式）

链接来源：直接输入（userId + ANR/Crash/FOOM）
用户userId：{userId}
问题：{ANR / Crash / FOOM}
精确发生时间：{precise_time}（来自 Bugly Agent）
分析时间窗口：{analysis_start} ~ {analysis_end}（前后各1小时）

---
✅ 以上信息可直接传入「营地问题分析小助手」进行深度根因分析。
⚠️ 后续伽利略 trace / 日志查询请以「分析时间窗口」为边界，禁止扩大为全天范围。
```

多个 userId 时，逐个输出卡片，用分割线区隔。

**完成后直接进入 Step 4（跳过 Step 2.5，因为时间窗口已在本节计算完成）。**

---

### 对伽利略告警链接

调用 **galileo-alert-user-extractor** 技能，完整执行其流程：

1. 解析 `alert_instance_id` 和 `alert_period_id`
2. 调用 Galileo MCP `get_alert_detail` 获取告警详情
3. 统计错误码分布，找出主因错误码
4. 提取代表性 userId

**严格按照该技能输出格式**，得到：
```
发生时间：<YYYY-MM-DD HH:mm:ss>
用户userId：<userId>
问题：<ret_code=xxx，errorMsg 摘要>
```

### 对 Bugly Issue 链接

> ⛔ **禁止从 Bugly 自动提取 userId**：Bugly Issue 受影响用户列表中的 userId 为系统随机采样的「代表性样本」，与伽利略/日志系统的 userId 体系不一致，不可直接用于后续分析。**严禁调用 `bugly-issue-user-extractor`。**

执行以下流程：

1. 解析 `product_id`、`issue_id`、`issue_type`
2. 调用 Bugly Agent 查询 Issue 详情，仅提取以下字段（**不提取 userId**）：
   - 问题描述（crash/anr/foom 类型 + 堆栈摘要）
   - 发生时间（Issue 最近上报时间，精确到秒）
3. **userId 留空，输出提示要求用户手动提供**

输出格式：
```
发生时间：<YYYY-MM-DD HH:mm:ss>
用户userId：⚠️ 需要用户手动提供（见下方说明）
问题：<[crash/anr/foom] 问题摘要>
```

---

## Step 2.5：精确发生时间重定义（ANR / Crash / FOOM 专属）

**仅当链接类型为 Bugly Issue（issue_type 为 crash / anr / foom）时执行本步骤。伽利略告警链接跳过，直接进入 Step 3。**

### 目的

用户描述问题时往往给的是"今天"这类模糊时间。ANR / Crash 的伽利略 trace 和日志分析必须基于精确时间窗口，才能在海量日志中精确定位到目标事件。

### 执行流程

1. **确认精确时间戳**：
   - 从 Step 2 的 bugly-issue-user-extractor 返回结果中取 `发生时间` 字段
   - 若已是 `YYYY-MM-DD HH:mm:ss` 格式（含小时和分钟），直接使用
   - 若格式不够精确（仅有日期，或缺少分钟），通过 Bugly Agent 再次查询该 userId 在该 Issue 中**最近一次上报的精确时间戳**

2. **计算分析时间窗口**：
   ```
   analysis_start = 精确时间 - 1小时
   analysis_end   = 精确时间 + 1小时
   ```
   输出格式均为 RFC3339（含时区），例如：`2026-05-07T13:30:00+08:00`

3. **时间字段说明**（用于后续传递给营地问题分析小助手）：
   - `精确发生时间`：Bugly 上报的该用户本次 Crash/ANR 的时间戳
   - `分析时间窗口 start`：精确发生时间 - 1小时
   - `分析时间窗口 end`：精确发生时间 + 1小时

> **重要**：后续营地问题分析小助手中所有伽利略 trace 查询、日志查询，均应以此时间窗口（start ~ end）为查询边界，禁止扩大为全天范围。

---

## Step 3：输出三要素卡片

提取完成后，按链接类型输出对应格式的标准卡片。

### 伽利略告警链接输出格式

```
📋 前置信息提取完成

链接来源：伽利略告警
发生时间：{time}
用户userId：{userId}
问题：{problem}

---
✅ 以上信息可直接传入「营地问题分析小助手」进行深度根因分析。
```

### Bugly Issue 链接输出格式（crash / anr / foom）

```
📋 前置信息提取完成

链接来源：Bugly Issue（{crash/anr/foom}）
精确发生时间：{precise_time}（来自 Bugly Agent，格式：YYYY-MM-DD HH:mm:ss）
分析时间窗口：{analysis_start} ~ {analysis_end}（前后各1小时）
用户userId：⚠️ 未提供（需手动获取）
问题：{problem}

---
⚠️ userId 未自动提取：Bugly Issue 受影响用户为系统随机采样的代表性样本，与伽利略日志系统的 userId 体系不一致，直接使用会导致后续分析查到错误用户数据。

请通过以下方式手动获取真实 userId：
  1. 从用户投诉工单 / 客服记录中获取
  2. 从 iFeedback / 水晶反馈平台中检索
  3. 询问反馈该问题的同事

获取到 userId 后，将其与以上三要素一并传入「营地问题分析小助手」。
⚠️ 后续伽利略 trace / 日志查询请以「分析时间窗口」为边界，禁止扩大为全天范围。
```

若同时提供多个链接，逐个提取并分别输出对应卡片，用分割线区隔。

---

## Step 4：建议后续分析

输出后，主动提示：

```
如需进一步分析，可将以上三要素告知「营地问题分析小助手」，它将并行调度伽利略和 Bugly 专家进行根因分析。
```

若 userId 为「未知」，额外说明：
```
⚠️ 注意：userId 未能从链接中提取，后续分析将跳过需要 userId 的专家（如伽利略日志查询）。可尝试从其他途径（工单系统、客服记录）补充 userId。
```

---

## 注意事项

- **只做提取，不做分析**：本助手职责是从链接提取三要素，深度根因分析由 营地问题分析小助手 负责
- **输出格式固定**：三要素卡片格式固定，不添加冗余说明
- **多链接并行处理**：用户一次提供多个链接时，同类型链接可并行提取，不同类型按识别顺序处理
- **字段缺失用「未知」**：无法提取的字段统一填写「未知」，不要尝试猜测或从其他渠道补全
