---
name: galileo-alert-user-extractor
description: 从伽利略告警链接中找出占比最多的错误原因，并从该错误中提取一个代表性用户 userId、问题具体内容和发生时间。输入一个含 alert_instance_id 的告警链接，自动调用 Galileo MCP 获取告警详情，统计各错误码分布，取占比最高的错误码，再从中找出一个具体 userId 供进一步分析。当用户提到「从告警里找用户」「这个告警影响了哪些用户」「找出一个受影响的用户」「找出受影响的 userId」「这个告警的用户」「galileo-alert-user-extractor」时触发。只要用户提供了伽利略告警链接（含 alert_instance_id）并想知道受影响的用户，都应主动使用此技能。
---

# 伽利略告警用户提取

给定一个伽利略告警链接，找出占比最多的错误原因，并从中提取一个代表性用户 userId、问题内容和发生时间，供后续深入分析。

## 输入

含 `alert_instance_id` 的告警链接，例如：
```
https://j.woa.com?alert_instance_id=2229319_1773749820&alert_period_id=128e1b2e2ea7eaaa_202603172017_2229319
```

---

## 执行流程

### Step 1：解析告警链接

从 URL 中提取 `alert_instance_id` 和 `alert_period_id`。

### Step 2：获取告警详情

调用 `get_alert_detail`：

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
| `moduleName` | `alert_labels[label_desc=tags.moduleName].label_value` | 告警模块 |
| `campType` | `alert_labels[label_desc=tags.campType].label_value` | start / step / end |
| `groupName` | `alert_labels[label_desc=tags.groupName].label_value` | 下钻接口（如有） |
| `alertTime` | `alert_data.alert_data_time` | 告警触发时间（RFC822格式） |

### Step 3：计算查询时间窗口

以 `alertTime` 为中心，**前后各扩展 10 分钟**作为查询窗口，转换为 RFC3339 格式（如 `2026-03-17T20:07:00+08:00`）。

### Step 4：统计错误码分布（找出主要错误原因）

调用 `get_log_data`，过滤失败日志并按错误码 group by，确定占比最高的错误原因：

**有 `groupName` 时（下钻告警）：**
```json
{
  "target": "<target>",
  "namespace": "Production",
  "start_time": "<start_time>",
  "end_time": "<end_time>",
  "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.groupName=<groupName> AND tags.status<0",
  "group_by_tags": ["tags.ret_code"],
  "return_log_samples_num": "5"
}
```

**无 `groupName` 时（模块整体告警）：**
```json
{
  "target": "<target>",
  "namespace": "Production",
  "start_time": "<start_time>",
  "end_time": "<end_time>",
  "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.status<0",
  "group_by_tags": ["tags.ret_code"],
  "return_log_samples_num": "5"
}
```

> ⚠️ **错误码字段兜底**：若 `tags.ret_code` 统计为空，改用 `tags.logic_code` 或 `tags.errorCode` 重新查询。

从 `tag_statistics[tags.ret_code]` 中**取数量最多的那个错误码**作为主因，记为 `topRetCode`，记录其数量和占比。

### Step 5：从主因错误中提取代表性 userId

针对 `topRetCode`，再次调用 `get_log_data`，增加错误码过滤，group by userId，取出现次数最多的用户：

**有 `groupName` 时：**
```json
{
  "target": "<target>",
  "namespace": "Production",
  "start_time": "<start_time>",
  "end_time": "<end_time>",
  "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.groupName=<groupName> AND tags.ret_code=<topRetCode>",
  "group_by_tags": ["tags.userId"],
  "return_log_samples_num": "5",
  "return_tags": ["tags.userId", "tags.errorMsg", "tags.cClientVersionName"]
}
```

**无 `groupName` 时：**
```json
{
  "target": "<target>",
  "namespace": "Production",
  "start_time": "<start_time>",
  "end_time": "<end_time>",
  "filters": "tags.moduleName=<moduleName> AND tags.campType=<campType> AND tags.ret_code=<topRetCode>",
  "group_by_tags": ["tags.userId"],
  "return_log_samples_num": "5",
  "return_tags": ["tags.userId", "tags.errorMsg", "tags.cClientVersionName"]
}
```

> ⚠️ **userId 字段兜底**：若 `tags.userId` group_by 结果为空，改用 `tags.uid` 重新查询。

从 `tag_statistics[tags.userId]` 中取**出现次数最多的 userId** 作为代表用户（`representativeUserId`）。若无法通过 group_by 获得，则从 `sample_logs` 第一条日志的 userId 代替。

### Step 6：输出报告

**严格按照以下格式输出，不得增减字段、不得改变顺序：**

```
发生时间：<该用户最早一条出错日志的时间戳，格式 YYYY-MM-DD HH:mm:ss>
用户userId：<representativeUserId>
问题：<一句话描述，包含错误码和 errorMsg，例如：ret_code=<topRetCode>，<errorMsg 原文或摘要>>
```

---

## 注意事项

- **status 字段**：失败状态通常是 `tags.status < 0`，部分模块用 `tags.ret_code != 0`，若 status 过滤无结果则换用 ret_code
- **userId 字段名**：可能是 `tags.userId` 或 `tags.uid`，两个都试
- **时间格式**：alertTime 通常是 RFC822 格式（如 `Tue, 17 Mar 2026 20:17:00 +0800`），需转换为 RFC3339 传给 MCP
- **groupName 下钻**：有 groupName 时所有查询必须加上该过滤条件，否则数据混入整个模块所有接口
- **隐私脱敏**：若日志中含手机号、真实姓名等，使用 `***` 脱敏
