---
name: knowledge-assistant
description: 知识库小助手执行技能。管理多来源知识库的注册、缓存、懒更新、查询与全量刷新。支持腾讯文档（表格/文档）、Craft、iWiki、企业微信文档。
---

# 知识库小助手 — 执行技能

管理「来源注册 → MD 缓存 → 懒更新 → 查询注入」的完整生命周期。

---

## ⛔ 铁律（任何情况下不得违反）

1. **时间字段必须保留**：字段筛选（Step 2.5）时，无论用户如何选择，含「日期」「时间」「time」「date」「创建」「更新」「发现」等语义的字段**强制保留**，不得丢弃。
2. **增量更新以时间为准**：merge 模式下，增量识别的依据是**时间字段**（`time_field`），而非文本内容。只有 `time_field` 值比缓存中最新记录更新的行，才视为新增行追加。旧行状态变更（如「完成情况」从「进行中」→「已完成」）通过 merge_key 匹配后原地更新。

## 核心数据模型

### 路径常量

```
SKILL_DIR  = ~/.claude/skills/knowledge-assistant/
CACHE_DIR  = ~/.claude/skills/knowledge-assistant/cache/
REGISTRY   = ~/.claude/skills/knowledge-assistant/cache/_registry.json
```

### 缓存 MD 格式（每个来源一个文件）

```markdown
---
source_url: https://docs.qq.com/sheet/DXxxx
source_type: tencent-docs-sheet
scope: 活动配置
slug: docs-qq-DXxxx
title: 活动配置表
last_updated: 2026-04-27T10:00:00+08:00
ttl_days: 7
---

# 活动配置表

[从源拉取后转换的 Markdown 内容]
```

### Registry JSON 格式（`_registry.json`）

```json
{
  "活动配置": [
    {
      "slug": "docs-qq-DXxxx",
      "url": "https://docs.qq.com/sheet/DXxxx",
      "type": "tencent-docs-sheet",
      "title": "活动配置表",
      "cache_path": "活动配置/docs-qq-DXxxx.md",
      "last_updated": "2026-04-27T10:00:00+08:00",
      "ttl_days": 7,
      "update_mode": "overwrite",
      "merge_key": null
    }
  ],
  "camp": [
    {
      "slug": "iwiki-arch",
      "url": "https://iwiki.xxx.com/page/arch",
      "type": "iwiki",
      "title": "营地架构文档",
      "cache_path": "camp/iwiki-arch.md",
      "last_updated": "2026-04-20T10:00:00+08:00",
      "ttl_days": 7,
      "update_mode": "merge",
      "merge_key": "告警问题"
    }
  ]
}
```

**字段说明：**

| 字段 | 说明 |
|------|------|
| `update_mode` | `overwrite`（全量覆盖，默认）或 `merge`（按主键合并，适合大表） |
| `merge_key` | merge 模式下的行主键字段名（如「告警问题」），用于匹配新旧行。`overwrite` 时为 null |

---

## 来源适配器

| 来源类型 | 识别规则 | type 字段值 | 拉取方式 |
|---------|---------|------------|---------|
| 腾讯文档（表格） | URL 含 `docs.qq.com/sheet` | `tencent-docs-sheet` | tencent-docs MCP `get_content` |
| 腾讯文档（文档） | URL 含 `docs.qq.com/doc` | `tencent-docs-doc` | tencent-docs MCP `get_content` |
| 企业微信文档 | URL 含 `doc.weixin.qq.com` | `wecom-doc` | wecom-doc MCP `wecom_doc_fetch` |
| Craft 文档 | URL 含 `craft.do` 或用户说「Craft 文档/页面 xxx」 | `craft` | Craft MCP `blocks_get` |
| iWiki | URL 含 `iwiki` 或内网 wiki 域名 | `iwiki` | `WebFetch` 抓取 HTML 转 MD |
| 通用网页 | 其他 HTTP/HTTPS URL | `webpage` | `WebFetch` 抓取转 MD |

---

## Slug 生成规则

从 URL 中提取唯一标识：

1. 去掉协议头（`https://`）和 query string（`?xxx`）
2. 取路径最后一段作为 ID（如 `DXxxx`、`page/arch` → `arch`）
3. 前缀加来源类型缩写：
   - 腾讯文档 → `docs-qq-`
   - 企微文档 → `wecom-`
   - Craft → `craft-`
   - iWiki → `iwiki-`
   - 通用网页 → `web-`
4. 示例：`https://docs.qq.com/sheet/DXabc123` → `docs-qq-DXabc123`

---

## Step 0：加载 Registry

每次执行任何操作前先读取 registry：

```bash
# 检查 registry 是否存在
ls ~/.claude/skills/knowledge-assistant/cache/_registry.json
```

- 若存在：读取并解析 JSON
- 若不存在：初始化为空对象 `{}`，后续操作时再创建文件

---

## Step 1：意图识别

根据用户输入识别意图，路由到对应 Step：

| 意图 | 关键词特征 | 走向 |
|------|-----------|------|
| **注册来源** | 含「注册」「挂载」「添加知识来源」「加入知识库」 + URL | → Step 2 |
| **查询知识** | 含「查」「知识库有没有」「xxx 的配置」「xxx 相关知识」 + scope 名 | → Step 3 |
| **列出来源** | 含「列出」「有哪些来源」「知识来源状态」「哪些知识库」 | → Step 4 |
| **刷新（指定）** | 含「刷新 xxx」「强制更新 xxx」「更新 xxx 知识库」 + scope 名 | → Step 5 |
| **全量刷新** | 含「刷新所有」「全量更新」「全部刷新」「update all」 | → Step 6 |
| **能力总览** | 意图不明确 | → 展示能力总览 |

---

## Step 2：注册来源

### 输入解析

从用户输入中提取：
- `scope`：任务名或项目名（如「活动配置」「camp」）
- `url`：知识来源的链接

若用户只提供 URL 没有 scope，询问：「请问这个知识来源属于哪个任务/项目？」

### 执行步骤

1. **识别来源类型**：根据 URL 特征匹配来源适配器表，确定 `type`

2. **拉取内容**（根据 type 选择方式）：

   **tencent-docs-sheet / tencent-docs-doc**：
   - 从 URL 提取 `file_id`（URL 中 `/doc/` 或 `/sheet/` 后的部分）
   - 调用 tencent-docs MCP `get_content({ file_id: "xxx" })`
   - 若 MCP 不可用，提示用户先授权：运行 `mcporter call "tencent-docs" "auth"`

   **wecom-doc**：
   - 先调用 `wecom_doc_status` 检查登录状态
   - 未登录则调用 `wecom_doc_login` 让用户扫码，登录后继续
   - 调用 `wecom_doc_fetch({ url: "xxx" })` 获取内容
   - **⚠️ smartsheet 大表处理**：当表格行数较多（如 500+ 行）时，MCP 不会报错，但返回内容会超过 token 限制，结果被写入临时文件（路径类似 `~/.claude-internal/projects/.../tool-results/mcp-wecom-doc-wecom_doc_fetch-xxx.txt`）。处理方式：
     1. **拉取时**：必须用独立的 `tab` 参数（`wecom_doc_fetch({ url: "...", tab: "BN9bzM" })`），**不要**把 tab 拼在 URL query string 里，否则 MCP 返回压缩数据无法解析
     2. **读取临时文件**：结果是 JSON 数组格式，用 python3 解析：
        ```bash
        cat <临时文件路径> | python3 -c "
        import sys, json
        data = json.load(sys.stdin)
        text = data[0]['text']
        # text 里是完整 markdown 表格，按行解析
        "
        ```
     3. **过滤字段**：按行解析表头和数据行，只保留 `keep_fields` 字段，过滤全空行
     4. **写入缓存**：python3 管道直接输出到缓存文件（`> cache/scope/slug.md`）

   **craft**：
   - 从 URL 提取 page ID（URL 最后路径段）
   - 调用 Craft MCP `blocks_get({ id: "xxx", format: "markdown" })`

   **iwiki / webpage**：
   - 调用 `WebFetch` 抓取页面，提示词：「提取页面正文内容，转换为干净的 Markdown，去掉导航栏、侧边栏、页脚等非正文部分」

3. **字段筛选（Step 2.5）**：

   拉取内容后，**在写入缓存之前**，先与用户确认保留哪些字段：

   - 扫描内容，列出所有字段名（表格的列名、文档的段落标题等）
   - 分析每个字段对当前 scope 任务的参考价值，给出建议：
     - ✅ **建议保留**：对任务有直接参考价值的字段（如「告警问题」「原因」「完成情况」）
     - ❌ **建议丢弃**：对任务无参考价值的字段（如「伽利略链接」「问题截图」「tapd链接」等纯链接/附件字段）
   - 以对话形式向用户展示筛选方案，等待确认或调整
   - **确认后**将选定的字段列表写入 registry（`keep_fields`），后续刷新时只保留这些字段

   **输出格式示例**：
   ```
   📋 字段筛选（共 16 列）

   ✅ 建议保留（6 列）：
     · 待告警问题/其他问题  — 问题描述，核心参考字段
     · 处理人              — 责任人信息
     · 伽利略责任人        — 监控负责人
     · 发现日期            — 时间维度
     · 完成情况            — 当前状态
     · 没有告警原因/原因   — 根因分析，高价值

   ❌ 建议丢弃（10 列）：
     · 伽利略链接   — 长 URL，查询时无用
     · 问题截图     — 图片链接，无法使用
     · 原因截图     — 图片链接，无法使用
     · tapd链接     — 跳转链接，无用
     · 上线版本     — 对排查任务意义不大
     · 校验状态     — 发布流程字段，无用
     · 解决方案     — 通常为空
     · 解决日期     — 通常为空
     · 优先级       — 已含在完成情况上下文中
     · 问题类型     — 通常为空

   是否按此方案保留？可以说「确认」或指定调整（如「加上优先级」「去掉处理人」）
   ```

4. **生成 slug**：按 Slug 生成规则处理 URL

5. **生成缓存 MD**：
   ```
   CACHE_FILE = CACHE_DIR/{scope}/{slug}.md
   ```
   文件头部写入 frontmatter 元数据，正文写入拉取的内容

5. **检查是否已存在**：
   - 若 registry 中已有该 scope + slug 的记录 → 覆盖更新（视为刷新）
   - 若不存在 → 新增记录

6. **更新 registry**：
   - 读取现有 registry JSON
   - 在对应 scope 数组中 upsert 该来源记录（通过 slug 判断是更新还是新增）
   - 写回 `_registry.json`

7. **输出注册摘要**：
   ```
   ✅ 已注册知识来源
   - Scope（任务/项目）：活动配置
   - 来源标题：活动配置表
   - 来源类型：腾讯文档（表格）
   - 缓存路径：~/.claude/skills/knowledge-assistant/cache/活动配置/docs-qq-DXxxx.md
   - 有效期至：2026-05-04（7 天后）
   ```

---

## Step 3：加载知识（grep 查询）

### 设计原则：直接 grep 缓存文件，无需索引

缓存文件数据量有限（单文件通常 < 200KB），直接用 `grep` 按关键词搜索，比维护索引更简单可靠。

### 执行步骤

1. 从 registry 读取 `scope` 对应的所有来源列表

   若 registry 中没有该 scope：
   ```
   ⚠️ 「{scope}」暂无注册的知识来源。
   可以用「给 {scope} 注册知识来源 <URL>」添加。
   ```

2. **提取查询关键词**：从用户问题中提取接口名、模块名、人名、时间、状态等关键词

3. **grep 缓存文件**：
   ```bash
   grep -i "关键词" CACHE_DIR/{scope}/*.md
   ```
   - 有明确关键词（接口路径、人名、错误码等）→ grep 精准匹配，返回命中行
   - 无明确关键词（如「有什么未解决的问题」）→ 直接 Read 整个缓存文件

4. 基于匹配结果回答用户问题

5. **TTL 检查**：若缓存超过 `ttl_days`，静默刷新

---

## Step 4：列出来源

### 输入解析

- 若用户指定了 scope（如「列出活动配置的知识来源」）→ 只显示该 scope
- 若未指定（如「有哪些知识库」）→ 显示所有 scope

### 输出格式

```
📚 知识来源总览

【活动配置】（共 2 个）
① 腾讯表格 — 活动配置表
   URL: https://docs.qq.com/sheet/DXxxx
   缓存: cache/活动配置/docs-qq-DXxxx.md
   状态: ✅ 有效（3 天前更新，还剩 4 天）

② iWiki — 活动规范文档
   URL: https://iwiki.xxx.com/page/activity
   缓存: cache/活动配置/iwiki-activity.md
   状态: ⚠️ 已过期（10 天前更新，超期 3 天）

【camp】（共 1 个）
① iWiki — 营地架构文档
   URL: https://iwiki.xxx.com/page/arch
   缓存: cache/camp/iwiki-arch.md
   状态: ✅ 有效（1 天前更新，还剩 6 天）
```

状态判断规则：
- `天数 ≤ ttl_days`：`✅ 有效（N 天前更新，还剩 M 天）`
- `天数 > ttl_days`：`⚠️ 已过期（N 天前更新，超期 M 天）`

---

## Step 5：手动刷新（指定 scope）

### 输入解析

从用户输入中识别要刷新的 `scope`。

### 执行步骤

1. 从 registry 读取 `scope` 对应的所有来源
2. 对每个来源：
   - 按来源类型调用对应适配器重新拉取内容
   - 覆盖缓存 MD 文件（更新 `last_updated`）
   - 记录是否成功
3. 批量更新 registry 中所有对应条目的 `last_updated`，写回 `_registry.json`
4. 输出刷新报告

```
🔄 刷新完成：「活动配置」（共 2 个来源）
✅ 活动配置表 (腾讯表格)   — 成功，内容已更新
❌ 活动规范文档 (iWiki)    — 失败：WebFetch 超时，保留旧缓存
```

---

## Step 6：全量刷新

触发词：「刷新所有知识库」「全量更新」「全部刷新」「update all knowledge」

### 执行步骤

1. 读取 registry，收集 **所有 scope 下所有来源**
2. 若 registry 为空或不存在：
   ```
   ℹ️ 暂无已注册的知识来源，无需刷新。
   可以用「给 xxx 注册知识来源 <URL>」开始注册。
   ```
3. 遍历每个来源（可并行调用）：
   - 按类型调用对应适配器重新拉取内容
   - 覆盖缓存 MD 文件（更新 `last_updated`）
   - 记录成功/失败状态
4. 批量更新 registry，写回 `_registry.json`
5. 输出全量刷新报告：

```
🔄 全量刷新完成（共 N 个来源）

✅ 活动配置 / 活动配置表 (腾讯表格)    — 成功
✅ 活动配置 / 活动规范 (iWiki)         — 成功  
✅ camp / 营地架构文档 (iWiki)         — 成功
❌ camp / 某 Craft 文档 (Craft)        — 失败：Craft MCP 调用异常

成功：3 / 4，失败：1 / 4
失败来源需手动检查，旧缓存保留不变。
```

---

## 能力总览（意图不明确时展示）

```
📚 知识库小助手能力总览

① 注册知识来源
   「给 xxx 任务注册知识来源 <URL>」
   支持：腾讯文档（表格/文档）、Craft、iWiki、企业微信文档

② 查询知识
   「xxx 任务的配置是什么」「查 xxx 知识库」
   自动懒更新：缓存超过 7 天时静默刷新

③ 列出来源
   「列出 xxx 的知识来源」「有哪些知识库」
   显示所有来源的状态和有效期

④ 刷新缓存
   「刷新 xxx 知识库」— 更新指定任务/项目的所有来源
   「刷新所有知识库」— 全量更新所有来源
```

---

## 错误处理

| 错误情况 | 处理方式 |
|---------|---------|
| registry 不存在 | 初始化为 `{}`，在操作中按需创建文件 |
| 腾讯文档 MCP 鉴权失败 | 提示：`mcporter call "tencent-docs" "auth"` |
| 企微文档未登录 | 调用 `wecom_doc_login` 让用户扫码 |
| Craft MCP 不可达 | 跳过该来源，保留旧缓存，在报告中标注失败 |
| iWiki/网页拉取超时 | 跳过该来源，保留旧缓存，在报告中标注失败 |
| scope 不存在 | 提示用户先注册来源 |
| 缓存文件损坏 | 强制重新拉取替换 |

---

## 注意事项

- **registry 原子更新**：每次更新时读取全量 JSON → 修改内存中的对象 → 写回全量，避免只写部分数据
- **cache 目录按需创建**：写入前先确保 `mkdir -p CACHE_DIR/{scope}/`
- **静默刷新不打扰用户**：Step 3 中的懒更新完全静默，不需要输出刷新日志，只输出查询结果
- **Craft 页面 ID 提取**：Craft URL 格式为 `https://www.craft.do/s/xxxxx` 或 `craft://...`，取最后路径段即为 pageId
- **腾讯文档 file_id 提取**：URL 格式 `https://docs.qq.com/doc/{file_id}` 或 `https://docs.qq.com/sheet/{file_id}`
- **TTL 默认 7 天**：注册时若用户未指定，默认使用 7 天；可在注册时说「这个来源每天更新」等自定义 TTL
