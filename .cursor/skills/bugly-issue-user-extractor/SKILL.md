---
name: bugly-issue-user-extractor
description: 从 Bugly Issue 链接中提取出受影响的代表性用户 userId、问题具体内容和发生时间。输入一个 Bugly Issue 链接（含 Issue ID 的 crash/anr/foom 详情页），自动解析 product_id 和 issue_id，调用 Bugly Agent 查询该 Issue 的受影响用户及日志，输出 userId、具体问题描述和最早发生时间。当用户提到「从 Bugly 链接找用户」「这个 Bugly 链接影响了哪些用户」「从 bugly issue 里找一个受影响的用户」「bugly-issue-user-extractor」「这个 bugly 链接的用户是谁」「分析 bugly 链接里的用户」时触发。只要用户提供了 Bugly Issue 详情链接并想知道受影响的用户，都应主动使用此技能。
---

# Bugly Issue 用户提取

给定一个 Bugly Issue 详情链接，找出受影响的代表性 userId、问题具体内容和发生时间，供后续深入分析（如配合 bugly-user-investigator 使用）。

## 输入

Bugly Issue 详情链接，例如：
```
https://bugly.qq.com/v2/crash-reporting/crashes/ef14bfff8f/abc123def456?pid=1
https://bugly.woa.com/v2/crash-reporting/anrs/ef14bfff8f/abc123def456?pid=1
```

---

## 执行流程

### Step 1：解析 Bugly 链接

支持两种 URL 格式：

**格式 A（路径式）**：`/v2/crash-reporting/{issue_type}/{product_id}/{issue_id}`
```
https://bugly.woa.com/v2/crash-reporting/crashes/ef14bfff8f/abc123?pid=1
```

**格式 B（查询参数式）**：`/v2/exception/{type}/issues/detail?productId=...&feature=...`
```
https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&feature=904D2E7D05BB2FE583268A2FA9F2EE16&cId=...
```

提取规则：

| 字段 | 格式 A 来源 | 格式 B 来源 |
|------|------------|------------|
| `product_id` | 路径第一段 | `productId` 参数 |
| `issue_id` | 路径第二段 | `feature` 参数 |
| `issue_type` | `crashes`/`anrs`/`fooms` | 路径中的 `crash`/`anr`/`foom` |

> 若无法提取任何有效字段，告知用户「请提供 Bugly Issue 详情页链接」。

---

### Step 2：查询 Issue 详情

定位脚本路径（按以下优先级）：
1. `~/.claude/skills/bugly-issue-user-extractor/scripts/query_agent.py`
2. `~/.claude/skills/bugly-user-investigator/scripts/query_agent.py`
3. `~/.claude/skills/bugly-data-analyzer/scripts/query_agent.py`

```bash
SCRIPT=$(python3 -c "
import os
candidates = [
    os.path.expanduser('~/.claude/skills/bugly-issue-user-extractor/scripts/query_agent.py'),
    os.path.expanduser('~/.claude/skills/bugly-user-investigator/scripts/query_agent.py'),
    os.path.expanduser('~/.claude/skills/bugly-data-analyzer/scripts/query_agent.py'),
]
print(next((c for c in candidates if os.path.exists(c)), ''))
")

export BUGLY_USER_TOKEN=54a5f8a2-495c-40e9-81f7-03d69913cc63

python3 "$SCRIPT" \
  --product-id {product_id} \
  --message "查询 Issue ID 为 {issue_id} 的{issue_type}问题详情，给我：1) 关键崩溃方法名和异常类型，2) 最新上报时间"
```

将 `{product_id}`、`{issue_id}`、`{issue_type}` 替换为 Step 1 解析出的实际值。

> **issue_type 中文映射**：`crashes` → `崩溃(crash)`，`anrs` → `ANR`，`fooms` → `FOOM`

> ⚠️ **已知限制：Bugly Agent API 无法返回 userId**
> Bugly Agent 的工具集全部是聚合统计接口，不暴露单条崩溃实例的原始字段（userId、uid）。
> 因此查询结束后必须执行 Step 3 向用户请求 userId，**不得**自行填写 `未知` 跳过。

---

### Step 3：请求用户提供 userId（必须暂停等待）

查询完成后，**立即暂停流程**，向用户输出以下提示（将实际查到的问题信息填入）：

```
已找到问题信息：
发生时间：<最新上报时间，格式 YYYY-MM-DD HH:mm:ss>
问题：<[issue_type] 关键方法 异常类型>

由于 Bugly API 不返回用户数据，请在 Bugly 控制台该 Issue 详情页的「崩溃实例列表」中找一个 userId，粘贴给我后继续。
```

**等待用户回复 userId，不得继续执行 Step 4。**

---

### Step 4：输出最终报告

收到用户提供的 userId 后，输出**必须且只能**包含以下三行，格式固定，不允许添加任何额外内容：

```
发生时间：<Step 2 查到的最新上报时间，格式 YYYY-MM-DD HH:mm:ss>
用户userId：<用户提供的 userId>
问题：<一句话描述，包含异常类型/崩溃方法和错误摘要，例如：[crash] -[XXXClass method:] EXC_BAD_ACCESS>
```

---

## 注意事项

- **必须暂停等待 userId**：Step 3 是硬性暂停点，不得跳过，不得用 `未知` 替代，必须等用户明确给出 userId 后才能执行 Step 4
- **Token 缓存**：脚本自动从 `~/.bugly_token_cache.json` 读取 Token，无需手动 export；若 Token 失效，执行 `export BUGLY_USER_TOKEN=<your_token>`
- **Issue 查询失败**：若 Step 2 查询失败（网络/权限问题），仍执行 Step 3 请求 userId，发生时间和问题字段用 `未知` 填充
- **后续分析**：Step 4 输出后，可提示用户「如需进一步分析该用户的完整崩溃历史，可使用 bugly-user-investigator」
