---
name: galileo-record-writer
description: 伽利略告警记录落表专用技能。将伽利略告警的分析结论（问题描述、告警链接、根因分析、建议处理方式、项目名、建议处理人、告警示例trace）写入腾讯文档智能表格「伽利略任务记录」，也支持读取/查询表中的历史记录。通常由伽利略告警登记小助手（galileo-alert-recorder）在完成分析后自动调用；用户也可直接说「把这个告警记录落表」「写入伽利略记录」「查看历史伽利略记录」来触发。触发词：「galileo-record-writer」「伽利略落表」「写入告警记录」「记录到伽利略表格」「查伽利略记录」。
---

# galileo-record-writer — 伽利略告警记录读写

专门负责伽利略告警记录的腾讯文档智能表格读写，是告警分析流程的最后一步落表出口。

---

## 表格固定参数（无需运行时查询）

| 参数 | 值 |
|------|-----|
| `file_id` | `DTmJsR3Z0VVRUTnNU` |
| `sheet_id` | `t00i2h` |
| 表格链接 | https://docs.qq.com/smartsheet/DTmJsR3Z0VVRUTnNU?tab=t00i2h |

### 字段结构

| field_id | 字段名 | 类型 | 写入格式 |
|---------|--------|------|---------|
| `f3B4KQ` | 告警日期 | text | `[{"text": "yyyy-mm-dd", "type": "text"}]` |
| `fbr50B` | 告警问题描述 | text | `[{"text": "...", "type": "text"}]` |
| `f2AOBx` | 伽利略告警链接 | url | `[{"text": "告警链接", "type": "url", "link": "https://..."}]` |
| `f0wEro` | 问题原因分析 | text | `[{"text": "...", "type": "text"}]` |
| `fm8kHb` | 建议处理方式 | text | `[{"text": "建议屏蔽/修复 — ...", "type": "text"}]` |
| `faGEbd` | 项目 | text | `[{"text": "...", "type": "text"}]` |
| `fXDPYt` | 建议处理人 | text | `[{"text": "RTX 或姓名", "type": "text"}]` |
| `fytVKL` | 告警示例trace | url | `[{"text": "trace链接", "type": "url", "link": "https://..."}]` |
| `fgvaLM` | 代码位置 | text | `[{"text": "文件名 L行号: 方法名（说明）\n路径：完整路径", "type": "text"}]` |
| `fe14y1` | 告警原始标题 | text | `[{"text": "【新P1】【错误指标】...", "type": "text"}]` |

---

## 操作一：写入一条告警记录

### 输入参数

调用方（其他小助手或用户）需提供以下字段：

| 字段 | 必填 | 说明 |
|------|------|------|
| `alert_date` | ✅ | 告警触发日期，格式 `yyyy-mm-dd` |
| `problem_desc` | ✅ | 告警问题描述（模块 + 错误码 + 量级） |
| `alert_link` | 推荐 | 伽利略告警链接（`j.woa.com?alert_instance_id=...`） |
| `root_cause` | ✅ | 问题原因分析 |
| `suggestion` | ✅ | 建议处理方式（`建议屏蔽 — 原因` 或 `建议修复 — 原因`） |
| `project` | 推荐 | 项目名称（如 `营地`、`王者营地` 等，不填则留空） |
| `assignee` | 推荐 | 建议处理人（RTX 或姓名，来自主程小助手分析；无法确定时填「暂无」） |
| `trace_example` | 推荐 | 告警示例 trace 链接（来自伽利略分析；无法获取时填「暂无」） |
| `code_location` | 推荐 | 代码位置（文件名+行号+方法名，每个定位点一行，格式：`文件名 L行号: 方法名（说明）\n路径：完整路径`；无法定位时填「暂无」） |
| `alert_raw_title` | 推荐 | 告警原始标题，即伽利略告警策略的完整名称，如「【新P1】【错误指标】大流量-1h（>=6000）-单模块【start】量级对比前1m上涨5%」；无法获取时填「暂无」 |

### 执行步骤

**第一步：构造记录，直接调用 add_records**

字段参数已固定，无需运行时查询字段结构，直接写入：

> ⚠️ **重要**：`field_values` 必须用**数组格式**（与 `list_records` 返回结构一致），不能用对象 map 格式，否则字段会写入空值。
> - text 字段用 `"text_value": {"items": [{"text": "...", "type": "text"}]}`
> - url 字段用 `"url_value": {"items": [{"text": "...", "type": "url", "link": "https://..."}]}`

```bash
mcporter call "tencent-docs" "smartsheet.add_records" --args '{
  "file_id": "DTmJsR3Z0VVRUTnNU",
  "sheet_id": "t00i2h",
  "records": [
    {
      "field_values": [
        {"field": "告警日期",       "text_value": {"items": [{"text": "<alert_date>", "type": "text"}]}},
        {"field": "告警问题描述",   "text_value": {"items": [{"text": "<problem_desc>", "type": "text"}]}},
        {"field": "伽利略告警链接", "url_value":  {"items": [{"text": "告警链接", "type": "url", "link": "<alert_link>"}]}},
        {"field": "问题原因分析",   "text_value": {"items": [{"text": "<root_cause>", "type": "text"}]}},
        {"field": "建议处理方式",   "text_value": {"items": [{"text": "<suggestion>", "type": "text"}]}},
        {"field": "项目",           "text_value": {"items": [{"text": "<project>", "type": "text"}]}},
        {"field": "建议处理人",     "text_value": {"items": [{"text": "<assignee>", "type": "text"}]}},
        {"field": "告警示例trace",  "url_value":  {"items": [{"text": "trace链接", "type": "url", "link": "<trace_example>"}]}},
        {"field": "代码位置",       "text_value": {"items": [{"text": "<code_location>", "type": "text"}]}},
        {"field": "告警原始标题",   "text_value": {"items": [{"text": "<alert_raw_title>", "type": "text"}]}}
      ]
    }
  ]
}'
```

> 若 `alert_link` 为空，`伽利略告警链接` 字段改用 `"text_value": {"items": [{"text": "", "type": "text"}]}`（文本类型降级）。  
> 若 `trace_example` 为空或为「暂无」，`告警示例trace` 字段改用 `"text_value": {"items": [{"text": "暂无", "type": "text"}]}`（文本类型降级）。  
> 若 `alert_raw_title` 为空或为「暂无」，省略该字段对象或填写「暂无」。  
> 若 `project`、`assignee` 为空，省略对应字段对象。
> 
> ✅ 全部字段 field_id 已确认（`建议处理人: fXDPYt`，`告警示例trace: fytVKL`），可直接按字段名写入。  
> ⚠️ `告警原始标题` 字段需先在腾讯文档智能表格中手动新建该列，field_id 确认后更新此文档。

**第二步：输出结果**

```
✅ 已写入伽利略记录表
📎 表格链接：https://docs.qq.com/smartsheet/DTmJsR3Z0VVRUTnNU?tab=t00i2h
📝 写入内容：
  - 告警日期：{alert_date}
  - 项目：{project}
  - 问题描述：{problem_desc}（前50字）
  - 建议处理：{suggestion}
```

---

## 操作二：读取历史记录

### 读取所有记录

```bash
mcporter call "tencent-docs" "smartsheet.list_records" --args '{
  "file_id": "DTmJsR3Z0VVRUTnNU",
  "sheet_id": "t00i2h",
  "limit": 100,
  "sort": [{"field_title": "告警日期", "desc": true}]
}'
```

> 若 `has_more: true`，继续用 `offset` 翻页。

### 按项目筛选记录

当前表格无原生过滤接口，读取所有记录后在本地按 `项目` 字段值过滤。

### 输出格式

读取结果按日期降序排列，每条记录输出：

```
📅 {告警日期} | 📁 {项目} | 🔗 {告警链接}
问题：{告警问题描述}
根因：{问题原因分析}
建议：{建议处理方式}
────────────────────────
```

---

## 错误处理

| 错误 | 处理方式 |
|------|---------|
| `400006` Token 鉴权失败 | 提示用户重新授权腾讯文档 MCP |
| 写入失败（超链接格式） | 改用文本类型降级写入链接，标注 `[纯文本链接]` |
| 字段不匹配 | 调用 `smartsheet.list_fields` 重新确认字段结构，更新映射 |
