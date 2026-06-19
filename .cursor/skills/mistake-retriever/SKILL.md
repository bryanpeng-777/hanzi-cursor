---
name: mistake-retriever
deprecated: true
description: "[DEPRECATED] 已被 knowledge-retriever 替代。查询错误知识库索引，快速找到历史踩坑经验和可复用结论。优先查询轻量索引，命中后按需读取详情文档。当用户说「参考知识库」、「查一下错题集」、「有没有类似的经验」、「查历史记录」、「知识库有没有」、「knowledge base」时触发。也可被其他技能（bugfix、production-risk-checker 等）内部调用。
---

> **DEPRECATED**: 本技能已被 knowledge-retriever 替代。请使用 `/Users/bryanpeng/.claude/skills/knowledge-retriever/SKILL.md`。
> knowledge-retriever 提供统一检索入口，覆盖通用知识和错误经验。

# 错误知识库检索技能（已废弃）

快速扫描总索引，按关键词匹配历史踩坑经验，命中后输出可复用结论，必要时再读取详情文档。

## 知识库位置

```
Growth-AI-错题集/                   ← Craft 文件夹，folderId: 8fc1e9f2-9dcb-f392-9712-76eccdb94afa
├── 错误知识库索引                    ← 总索引，pageId: 5fef4a3b-d203-7a19-0f81-d8f5a72a1280
├── 2026-03 错题详情                 ← 月度详情文档
└── ...
```

---

## 工作流

### Step 1：提取检索关键词

从用户输入或调用方传入的上下文中，提取 2-5 个检索关键词。

**关键词来源**：
- 用户描述的问题现象（如「初始化失败」、「回调丢失」）
- 涉及的技术模块（如 `ZTSDK`, `Galileo`, `WKWebView`）
- 技术栈标签（如 `iOS`, `Flutter`, `多线程`）

**示例**：
- 用户描述「ZTSDK 初始化后没有回调」→ 关键词：`ZTSDK`, `初始化`, `回调`
- 用户描述「伽利略指标数据丢失」→ 关键词：`Galileo`, `伽利略`, `数据丢失`, `campType`

### Step 2：搜索索引

**策略**：先用 `documents_search` 精确搜索索引文档，避免全量读取。如果记录少（索引刚建立），回退到 `blocks_get` 全量读取。

**首选方式**（索引超过 10 条时）：对每个关键词调用 `document_search` 在索引文档内搜索：

```
document_search({
  blockId: "5fef4a3b-d203-7a19-0f81-d8f5a72a1280",
  pattern: "ZTSDK|初始化",
  caseSensitive: false,
  beforeBlockCount: 0,
  afterBlockCount: 0
})
```

将多个关键词用 `|` 拼成正则，一次调用返回所有匹配行及上下文。

**回退方式**（索引少于 10 条、或搜索工具调用失败时）：

```
blocks_get({
  id: "5fef4a3b-d203-7a19-0f81-d8f5a72a1280",
  format: "markdown"
})
```

然后人工扫描索引表格的「关键词」列，进行**模糊匹配**：
- 关键词包含关系（「初始化」匹配「ZTSDK, 初始化」）
- 同义词匹配（「伽利略」匹配「Galileo」）
- 技术模块名匹配（「ZTSDK」匹配「ZTSDKManager」）

### Step 3：输出匹配结果

**如果有命中记录**，按相关度排序，输出：

```
📚 发现 N 条相关历史记录：

【命中 1】关键词: ZTSDK, 初始化
  坑: ZTSDK 在非主线程调用 init 会导致回调丢失
  ✅ 结论: ZTSDK 所有初始化必须在主线程执行
  详情: [[2026-03 错题详情]]（如需查看完整分析）

【命中 2】...
```

**如果无命中**，直接告知：
```
📭 知识库中未找到相关历史记录，建议此次解决后用 mistake-collector 记录。
```

### Step 4：按需读取详情（可选）

如果用户需要查看完整分析，或 AI 判断「可复用结论」不足以解决当前问题，则：

1. 调用 `documents_list` 在 Growth-AI-错题集 文件夹下查找对应月度文档
2. 调用 `blocks_get` 读取该文档，找到对应标题的条目
3. 返回完整的「根因分析」和「解决方案」

---

## 被其他技能调用时的简化输出

当由 bugfix、production-risk-checker 等技能内部调用时，输出更简洁：

```
[知识库检索] 关键词: {xxx}
→ 命中 N 条，最相关结论：{可复用结论}（详情见 [[YYYY-MM 错题详情]]）
→ 无命中，继续正常流程
```

---

## 注意事项

- **不要因为索引为空就跳过**：索引为空时，直接输出「暂无记录」并提示用 mistake-collector 记录
- **索引读取失败时不阻塞**：如果 Craft MCP 调用失败，跳过检索步骤，不影响主流程
- **避免过度读取详情**：索引中的「可复用结论」足够时，不需要打开详情文档，减少工具调用次数
