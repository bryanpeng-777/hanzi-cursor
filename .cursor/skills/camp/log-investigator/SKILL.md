---
name: local-issue-investigator
description: >-
  本地问题排查私人小助手。用户描述界面现象（如「推荐页 feeds 不加载」「点击按钮后崩溃」），
  先用脚本侦察日志（--stats），再根据现象推断需要提取的 API 或关键词，精准提取后喂给 LLM 分析，
  避免把几百 KB 原始日志全量输入。触发词：「本地问题排查」「日志分析」「分析这份日志」「从日志里找」
  「log-investigator」「本地排查小助手」，或用户提供 .log 文件路径并描述了 UI 现象时。
---

# 本地问题排查私人小助手

iOS camp xlog 分析的两步法：**先侦察，再精取，最后分析**。
每次分析节省 95%+ token。

## 脚本路径

```
~/.claude/skills/camp/log-investigator/scripts/extract_logs.py
```

## 工作流

### Step 0 — 确认输入

收集两个信息：
1. **日志文件路径**（用户未提供时询问）
2. **现象描述**：界面名称 + 做了什么操作 + 出现了什么异常

### Step 1 — Stats 侦察（必做，极低 token）

```bash
python3 ~/.claude/skills/camp/log-investigator/scripts/extract_logs.py \
  <log_file> --stats
```

输出示例（< 2KB）：
```
API 调用频率 (Top 25):
  onceBoolValue: 47 次
  /info/listinfov2: 3 次
  /user/getinfo: 5 次
  ...
错误条目 [E]: 2 条
Flutter 路由事件: 8 条
  路由示例:
    flutter: TRouter routerInfo：...
```

### Step 2 — 推断提取策略

根据现象描述 + stats 输出，选择一个或多个提取命令。

**UI 问题排查决策树：**

```
现象描述
  ├─ 涉及某个具体界面 / 进入页面后异常
  │    → --after "TRouter" --count 40   ← 找页面进入后的调用链
  │
  ├─ 涉及某个数据不加载（知道接口名）
  │    → --api /info/listinfov2          ← 看完整 request/response
  │
  ├─ stats 里期望接口出现 0 次
  │    → 说明请求根本没发出，UI 层问题
  │    → --after "TRouter" 看触发链
  │
  ├─ 涉及崩溃 / 错误弹窗
  │    → --errors                        ← 看所有 [E] entry
  │
  └─ 涉及某个内容 / 用户 / 业务字段
       → --keywords "关键词1,关键词2"
```

### Step 3 — 精准提取

按决策树运行一条或多条命令，Read 输出内容。

常用命令：

```bash
# 看页面进入后的完整调用链（UI 操作排查首选）
python3 ... --after "TRouter" --count 40

# 看特定接口的 request + response
python3 ... --api /info/listinfov2

# 只看最近一次该接口的调用
python3 ... --api /info/listinfov2 --last 1

# 看所有错误
python3 ... --errors

# 搜索含特定关键词的 entry
python3 ... --keywords "小鹿迷露,recommend,list"

# 缩小输出（大日志时用）
python3 ... --api /info/listinfov2 --max-kb 20
```

### Step 4 — 分析并回答

分析提取内容，重点检查：
- API response code 是否为 0（非 0 = 服务端返回错误）
- 期望字段（如 `list`）是否在 response data 中
- 是否有 `[E]` 错误 entry 出现在操作时间附近
- `--after TRouter` 的结果里，期望的接口是否被调用

如需补充上下文，追加新的提取命令（可多次迭代）。

---

## 模式速查

| 模式 | 命令 | 适用场景 | 典型输出大小 |
|---|---|---|---|
| 侦察 | `--stats` | 每次必做，了解日志全貌 | < 2KB |
| 页面调用链 | `--after "TRouter" --count 40` | UI 操作触发什么 API | 5~15KB |
| 接口详情 | `--api /info/listinfov2` | 看具体 request/response | 2~10KB |
| 错误排查 | `--errors` | 崩溃/弹框/异常 | 5~20KB |
| 关键词 | `--keywords "k1,k2"` | 搜索特定内容 | 可变 |

## 参数说明

| 参数 | 默认 | 说明 |
|---|---|---|
| `--max-kb N` | 40 | 输出大小上限，超出时截断 |
| `--count N` | 40 | `--after` 模式取多少条 entry |
| `--last N` | 全部 | `--api` 模式只取最近 N 次 |
| `--context N` | 3 | `--errors` 模式的上下文条数 |
| `--top N` | 25 | `--stats` 显示 Top N 接口 |
