---
name: bugly-auto-recorder（已被 bugly-assistant 取代）
description: 【已废弃】此技能已被 bugly-assistant 取代，请使用 bugly-assistant。原功能：Bugly 异常排查记录落表（userId / Bugly 链接 → 分析 → 写入腾讯文档）。触发词「bugly-auto-recorder」时仍可使用此技能，其他场景请统一走 bugly-assistant。
---

# Bugly小助手 — 异常排查结论自动落表

支持通过 **userId** 或 **Bugly 问题链接** 发起排查，覆盖 **Crash / ANR / FOOM** 三种问题类型，串联 `bugly-user-investigator`（或 `bugly-data-analyzer`）和 `bugly-assigner`，将排查结论自动写入腾讯文档「bugly任务记录」智能表格。

---

## 输入信息

支持两种输入方式（二选一）：

### 方式 A：userId

- **userId**（必填）：App 用户 ID
- **日期**（可选）：默认今天，支持「昨天」、「3月20日」等自然语言
- **问题类型**（可选）：crash（默认）/ anr / foom

### 方式 B：Bugly 问题链接

- **链接**（必填）：Bugly 平台的问题链接，常见格式包括：
  - `https://bugly.woa.com/v2/crash-reporting/crashes/{issueId}?pid={productId}`
  - `https://bugly.woa.com/v2/crash-reporting/anrs/{issueId}?pid={productId}`
  - `https://bugly.woa.com/v2/crash-reporting/blocks/{issueId}?pid={productId}`
  - 或其他包含 Bugly 域名 + issue 信息的 URL

**自动识别规则**：
- 用户输入包含 `bugly.woa.com` 或 `bugly.qq.com` 的 URL → 走方式 B
- 用户输入为纯数字或明确说「userId」→ 走方式 A
- 如果无法判断，询问用户

---

## 执行流程

### Step 1：获取问题详情

根据输入方式分两条路径：

#### 路径 A：通过 userId 查询（调用 bugly-user-investigator）

按照 `bugly-user-investigator` 技能的完整流程执行，传入用户指定的问题类型（crash / anr / foom），获取该用户的所有异常记录。

#### 路径 B：通过 Bugly 链接查询（调用 bugly-data-analyzer）

从链接中解析出关键信息，然后调用 `bugly-data-analyzer` 获取问题详情：

```bash
python3 /Users/bryanpeng/.claude/skills/bugly-data-analyzer/scripts/query_agent.py \
  --product-id {从链接解析或使用默认值 ef14bfff8f} \
  --message "帮我查一下问题 {issueId} 的详细信息，包括：Issue ID、异常类型（crash/anr/foom）、关键堆栈（Key Method）、影响设备数、最后上报时间、处理状态，以及该问题的详情链接"
```

**链接解析规则**：
- 从 URL path 中提取 `issueId`（通常是 path 的最后一段数字或 ID）
- 从 URL query 参数中提取 `pid`（productId），若无则使用王者营地默认值 `ef14bfff8f`
- 从 URL path 中推断问题类型：`crashes` → crash，`anrs` → anr，`blocks/foom` → foom

---

**两条路径统一输出**：从查询结果中提取每条问题的以下字段（每条后续单独处理）：

| 字段 | 来源 |
|------|------|
| `key_stack` | 关键堆栈（Key Method 段） |
| `bugly_link` | 详情链接 |
| `brief_analysis` | 初步判断 |
| `exception_type` | 异常类型：crash / anr / foom |
| `issue_id` | Issue ID（辅助信息） |

如果查询无结果（userId 无记录 / 链接对应的 issue 不存在），直接告知用户并结束，无需继续。

---

### Step 2：对每条问题调用 bugly-assigner 分配责任人

将 Step 1 中每条问题的 `key_stack` 传给 `bugly-assigner` 技能，执行完整的堆栈分析流程，得到：

| 字段 | 来源 |
|------|------|
| `assignee_name` | 推荐分配的开发者姓名 |
| `assignee_email` | 开发者邮箱 |
| `assign_reason` | 推荐理由（最近几次提交哪些文件） |

如果 bugly-assigner 找不到责任人（git 记录为空），`assignee_name` 标记为「待确认」。

> **ANR / FOOM 说明**：bugly-assigner 的堆栈分析逻辑对 ANR 和 FOOM 同样适用——核心都是从堆栈中提取文件路径和类名，匹配 git 提交记录。

---

### Step 3：整合输出结构化记录

将 Step 1 + Step 2 的结果合并，每条问题生成一行记录：

| 字段 | 内容来源 |
|------|---------|
| **问题类型** | `exception_type`（crash / anr / foom） |
| **关键堆栈** | `key_stack`（取前 5 帧，超出省略） |
| **处理人** | `assignee_name`（`assignee_email`） |
| **问题链接** | `bugly_link` |
| **根因分析** | `brief_analysis` + 「分配理由：`assign_reason`」 |

输出格式：

```
📋 Bugly 排查记录（共 N 条问题）

━━━━━━━━━━━━━━━━━━━━━━━
📌 记录 1／N  [Issue: {issue_id}]  [{exception_type}]

关键堆栈：
{key_stack 前5帧}

处理人：{assignee_name}（{assignee_email}）

问题链接：{bugly_link}

根因分析：
{brief_analysis}
分配理由：{assign_reason}

━━━━━━━━━━━━━━━━━━━━━━━
（多条问题逐一列出）

✅ 结构化记录整理完毕，准备写入腾讯文档...
```

---

### Step 4：写入腾讯文档「bugly任务记录」

使用 `tencent-docs` 技能（通过 `mcporter` CLI）将记录写入智能表格。

#### 4.1 查找或创建表格

```bash
mcporter call "tencent-docs" "manage.search_file" --args '{"search_key": "bugly任务记录"}'
```

- **找到**：取第一条匹配 `title == "bugly任务记录"` 的 `file_id`，继续 4.2
- **未找到**：新建智能表格：

```bash
mcporter call "tencent-docs" "manage.create_file" \
  --args '{"title": "bugly任务记录", "file_type": "smartsheet"}'
```

取返回的 `file_id` 和 `url`，继续 4.2

> 已知固定值（首次创建后缓存，避免重复搜索）：
> - `file_id`: `NNIyzgGUiymZ`
> - `sheet_id`: `t00i2h`
> - 表格链接: https://docs.qq.com/smartsheet/DTk5JeXpnR1VpeW1a

#### 4.2 获取工作表 ID

```bash
mcporter call "tencent-docs" "smartsheet.list_tables" \
  --args '{"file_id": "<file_id>"}'
```

取 `sheets[0].sheet_id`。

#### 4.3 检查并补全表头字段

```bash
mcporter call "tencent-docs" "smartsheet.list_fields" \
  --args '{"file_id": "<file_id>", "sheet_id": "<sheet_id>"}'
```

对比已有 `field_title`，找出缺失字段，补充创建：

| 字段名 | field_type | 备注 |
|--------|-----------|------|
| 问题类型 | 1（文本） | crash / anr / foom |
| 关键堆栈 | 1（文本） | |
| 处理人 | 1（文本） | |
| 问题链接 | 8（超链接） | `property_url: {"type": 1}` |
| 根因分析 | 1（文本） | |

如有缺失字段：

```bash
mcporter call "tencent-docs" "smartsheet.add_fields" --args '{
  "file_id": "<file_id>",
  "sheet_id": "<sheet_id>",
  "fields": [
    {"field_title": "问题类型", "field_type": 1, "property_text": {}},
    {"field_title": "关键堆栈", "field_type": 1, "property_text": {}},
    {"field_title": "处理人",   "field_type": 1, "property_text": {}},
    {"field_title": "问题链接", "field_type": 8, "property_url": {"type": 1}},
    {"field_title": "根因分析", "field_type": 1, "property_text": {}}
  ]
}'
```

#### 4.4 批量写入记录

多条问题一次放入同一 records 数组：

```bash
mcporter call "tencent-docs" "smartsheet.add_records" --args '{
  "file_id": "<file_id>",
  "sheet_id": "<sheet_id>",
  "records": [
    {
      "field_values": {
        "问题类型": [{"text": "<exception_type>", "type": "text"}],
        "关键堆栈": [{"text": "<key_stack 前5帧>", "type": "text"}],
        "处理人":   [{"text": "<assignee_name>（<assignee_email>）", "type": "text"}],
        "问题链接": [{"text": "<issue_id>", "type": "url", "link": "<bugly_link>"}],
        "根因分析": [{"text": "<brief_analysis>\n分配理由：<assign_reason>", "type": "text"}]
      }
    }
  ]
}'
```

#### 4.5 输出结果

```
✅ 已将 N 条问题记录写入腾讯文档「bugly任务记录」
📎 表格链接：https://docs.qq.com/smartsheet/DTk5JeXpnR1VpeW1a
```

---

## 注意事项

- **多条问题**：一个 userId 可能有多条异常记录，每条单独走 Step 2，生成独立的一行记录
- **链接输入**：直接传 Bugly 链接时通常只有一条问题，流程更简单
- **bugly-assigner 对全类型适用**：ANR 和 FOOM 的堆栈同样可提取文件路径和类名进行 git 匹配
- **bugly-assigner 需要 git 仓库**：确保在 `social-ios` 或 `flutter_module` 目录下有 git 历史，否则无法找到责任人
- **key_stack 截断**：表格中只保留前 5 帧，完整堆栈通过问题链接访问
- **根因分析字段**：当前为 AI 初步判断 + 分配理由，实际根因需排查后人工补充
- **表格字段兼容**：新增了「问题类型」字段，旧记录该字段为空不影响使用
