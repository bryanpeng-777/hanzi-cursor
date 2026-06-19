---
name: galileo-auto-recorder（已被伽利略告警登记小助手取代）
description: 【已废弃】此技能已被伽利略告警登记小助手（galileo-alert-recorder）取代，请使用伽利略告警登记小助手。原功能：伽利略告警排查记录落表。触发词「galileo-auto-recorder」时仍可使用此技能，其他场景请统一走伽利略告警登记小助手。
---

# 伽利略小助手 — 告警排查结论自动落表

接收伽利略告警信息，分析根因，将排查结论自动写入腾讯文档「伽利略任务记录」智能表格。

---

## 输入信息

- **告警链接**（优先）：`j.woa.com?alert_instance_id=...` 格式的告警链接
- **告警描述**（备选）：用自然语言描述的告警现象、模块名、错误信息等
- 二者至少提供其一

---

## 执行流程

### Step 1：分析告警内容（含代码关联分析）

若用户提供了告警链接（含 `alert_instance_id`），按照 `galileo-alert-stat-analyzer` 技能的**完整流程**执行（包含其中的步骤 4.5 代码关联分析），获取：

| 字段 | 说明 |
|------|------|
| `problem_desc` | 告警问题描述（模块 + 错误码 + 量级） |
| `alert_link` | 伽利略告警链接（原始链接） |
| `root_cause` | 根因分析结论（**必须包含代码关联分析结果**，见下方） |

**`root_cause` 字段必须包含三层内容**：
1. **数据层**：错误码分布 + 版本分布 + Trace 中的 errorMsg
2. **代码层**：调用 `camp/code-locator` 定位涉事业务代码，提取文件路径 + 关键代码片段（≤10行） + 代码与告警的关系说明
3. **结论层**：综合以上两层，给出一句话根因判断

示例 `root_cause` 格式：
```
【数据分析】错误码 -3 占比 78%（版本 0402 集中），Trace errorMsg: "getABConfig timeout"
【代码定位】social-ios/src/GameApp/ABTest/WEGABTestManager.m:L234
  if (!response) { return [self defaultConfig]; }  ← 超时时未上报 end，导致 end 量级归零
【根因结论】ABTest 配置拉取超时时缺少 end 上报降级处理，与量级归零告警吻合
```

若用户只提供文字描述（无告警链接），则：
- `problem_desc` = 用户描述
- `alert_link` = 「无」
- `root_cause` = 基于描述进行初步分析 + 尝试用关键词调用 code-locator 定位相关代码（说明为 AI 推断，需人工确认）

分析完成后，直接整合 Step 2 的结构化记录，无需等待用户确认（数据充足即可继续）。

---

### Step 2：整合输出结构化记录

将 Step 1 的结果整理为一行记录：

| 字段 | 内容 |
|------|------|
| **告警日期** | `alert_date`：告警触发日期，格式 `yyyy-mm-dd` |
| **告警问题描述** | `problem_desc` |
| **伽利略告警链接** | `alert_link` |
| **问题原因分析** | `root_cause` |
| **建议处理方式** | `suggestion`：「建议屏蔽」或「建议修复」+ 一句话说明理由 |

输出格式：

```
📋 伽利略排查记录

━━━━━━━━━━━━━━━━━━━━━━━
告警日期：{alert_date}

告警问题描述：{problem_desc}

伽利略告警链接：{alert_link}

问题原因分析：
{root_cause}

建议处理方式：{suggestion}
━━━━━━━━━━━━━━━━━━━━━━━

✅ 结构化记录整理完毕，准备写入腾讯文档...
```

---

### Step 3：写入腾讯文档「伽利略任务记录」

使用 `tencent-docs` 技能（通过 `mcporter` CLI）将记录写入智能表格。

#### 3.1 查找或创建表格

> 已知固定值（直接使用，无需重复搜索）：
> - `file_id`: `NblGvtUTTNsT`
> - `sheet_id`: `t00i2h`
> - 表格链接: https://docs.qq.com/smartsheet/DTmJsR3Z0VVRUTnNU

若需重新搜索（如表格被删除）：

```bash
mcporter call "tencent-docs" "manage.search_file" --args '{"search_key": "伽利略任务记录"}'
```

- **找到**：取第一条匹配 `title == "伽利略任务记录"` 的 `file_id`，继续 3.2
- **未找到**：新建智能表格：

```bash
mcporter call "tencent-docs" "manage.create_file" \
  --args '{"title": "伽利略任务记录", "file_type": "smartsheet"}'
```

取返回的 `file_id` 和 `url`，继续 3.2

#### 3.2 获取工作表 ID

```bash
mcporter call "tencent-docs" "smartsheet.list_tables" \
  --args '{"file_id": "<file_id>"}'
```

取 `sheets[0].sheet_id`。

#### 3.3 检查并补全表头字段

```bash
mcporter call "tencent-docs" "smartsheet.list_fields" \
  --args '{"file_id": "<file_id>", "sheet_id": "<sheet_id>"}'
```

对比已有 `field_title`，找出缺失字段，按需补充创建：

| 字段名 | field_type | 备注 |
|--------|-----------|------|
| 告警日期 | 1（文本） | 格式 `yyyy-mm-dd`，如 `2026-03-23` |
| 告警问题描述 | 1（文本） | |
| 伽利略告警链接 | 8（超链接） | `property_url: {"type": 1}` |
| 问题原因分析 | 1（文本） | |
| 建议处理方式 | 1（文本） | |

如有缺失字段：

```bash
mcporter call "tencent-docs" "smartsheet.add_fields" --args '{
  "file_id": "<file_id>",
  "sheet_id": "<sheet_id>",
  "fields": [
    {"field_title": "告警日期",       "field_type": 1, "property_text": {}},
    {"field_title": "告警问题描述",   "field_type": 1, "property_text": {}},
    {"field_title": "伽利略告警链接", "field_type": 8, "property_url": {"type": 1}},
    {"field_title": "问题原因分析",   "field_type": 1, "property_text": {}},
    {"field_title": "建议处理方式",   "field_type": 1, "property_text": {}}
  ]
}'
```

#### 3.4 写入记录

```bash
mcporter call "tencent-docs" "smartsheet.add_records" --args '{
  "file_id": "<file_id>",
  "sheet_id": "<sheet_id>",
  "records": [
    {
      "field_values": {
        "告警日期":       [{"text": "<alert_date>", "type": "text"}],
        "告警问题描述":   [{"text": "<problem_desc>", "type": "text"}],
        "伽利略告警链接": [{"text": "告警链接", "type": "url", "link": "<alert_link>"}],
        "问题原因分析":   [{"text": "<root_cause>", "type": "text"}],
        "建议处理方式":   [{"text": "<suggestion>", "type": "text"}]
      }
    }
  ]
}'
```

`suggestion` 的值从分析结论中提炼，格式为：
- `建议屏蔽 — <一句话原因>` （如：错误率未恶化，量级放量误报）
- `建议修复 — <一句话原因>` （如：新版本引入失败率明显上升）

若 `alert_link` 为「无」，则 `伽利略告警链接` 字段写入空文本：
```json
{"text": "", "type": "text"}
```

#### 3.5 输出结果

```
✅ 已将排查记录写入腾讯文档「伽利略任务记录」
📎 表格链接：<url>
```

---

## 注意事项

- **优先使用告警链接**：有链接时走 `galileo-alert-stat-analyzer` 完整分析流程，结论更准确
- **无链接时说明**：纯文字描述生成的根因为 AI 推断，在记录中注明「待人工确认」
- **根因分析字段**：记录 AI 分析结论，实际根因确认后人工在表格中补充更新
