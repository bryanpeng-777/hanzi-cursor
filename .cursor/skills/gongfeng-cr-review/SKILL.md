---
name: gongfeng-cr-review
description: 抓取工蜂（Gongfeng）平台 MR 上 AI 提的 code review 意见并汇总展示。当用户提供工蜂 MR 链接（如 git.woa.com/.../merge_requests/XXXX）并希望查看 AI 的 code review 意见时触发。使用场景：(1) 用户说"看一下这个MR的CR意见"、"帮我看看工蜂AI的review"，(2) 用户直接粘贴工蜂 MR 链接并询问 code review 内容。
---

# 工蜂 MR Code Review 意见抓取

## 脚本分工

> **脚本处理**：URL 解析、生成 MCP 调用参数序列（`scripts/fetch_cr_notes.py`）
> **AI 处理**：执行 MCP 调用、过滤 AI 评论、格式化汇总输出

```bash
# 解析 MR URL，输出 MCP 调用参数
python3 scripts/fetch_cr_notes.py https://git.woa.com/<project>/-/merge_requests/<iid>
```

脚本输出 JSON，AI 读取后按 `mcp_call_sequence` 顺序执行 MCP 调用，无需再手动解析 URL。

---

## 工作流

### 1. 从链接中提取信息

解析用户提供的工蜂 MR 链接，格式通常为：
```
https://git.woa.com/{project_path}/-/merge_requests/{iid}
```

提取：
- `project_path`：如 `koh_social/social-ios`
- `iid`：MR 的页面序号（如 `9058`）

### 2. 查询 MR 的真实 ID

使用 MCP 工具 `user-gongfengStreamable` 的 `search_merge_request`，通过 `project_id` 和 `iid` 查询，获取 MR 的真实 `id`（非 iid）。

```json
{
  "project_id": "{project_path}",
  "iid": {iid数字}
}
```

### 3. 抓取 MR 评论

使用 `search_merge_request_notes`，传入真实 `merge_request_id`，获取非系统评论（`system: false`），按时间正序排列：

```json
{
  "project_id": "{project_path}",
  "merge_request_id": {真实id},
  "system": false,
  "sort": "created_asc",
  "per_page": 50
}
```

若结果为空或只有非 AI 的评论，说明 AI 评论尚未生成，告知用户稍后重试。

### 4. 识别 AI Code Review 意见

AI 的 code review 评论特征：
- `line_code` 字段不为 null（说明是行内评论）
- `file_path` 字段有具体文件路径
- `person_note_type` 为 1
- `risk` 字段有值（0=普通，1=低，2=中，3=高）

排除非 AI 评论：
- 「本次 Merge 由 xxx 提交」
- 「本次 Merge 不能自动合并」
- 纯系统通知类文本

### 5. 汇总输出

按以下格式输出所有 AI code review 意见：

```
## MR #{iid} Code Review 意见

共 {N} 条 AI 评论（已解决：X 条 / 未解决：Y 条）

---

### 1. [{风险等级}] {文件名}：第 {行号} 行
**文件**：`{file_path}`
**状态**：未解决 / 已解决

{意见内容}

---
### 2. ...
```

风险等级映射：
- `risk: 0` → 普通
- `risk: 1` → 低风险
- `risk: 2` → 中风险  
- `risk: 3` → 高风险

`resolve_state` 映射：
- `0` → 未解决
- `2` → 已解决

输出完成后，询问用户是否需要帮助处理某条意见。
