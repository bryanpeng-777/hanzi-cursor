---
name: bugly-user-investigator
description: 基于 userId 的 Bugly 异常查询专家。给定一个 userId，自动查询该用户指定日期的异常情况（支持 crash、anr、foom 三种类型），输出异常次数、堆栈信息、系统版本、手机型号、应用版本、Bugly 详情链接等关键信息。当用户说"帮我查一下这个用户的 bugly"、"这个用户 bugly 有没有崩溃"、"查一下 userId XXX 的 crash/anr/foom"、"bugly 查用户"、"这个用户崩溃了吗"、"查用户的 crash 情况"、"这个用户有没有 anr"、"查一下 foom"时触发。即使用户只说"查一下这个用户"并给出 userId 且上下文与 crash/bugly 相关，也应主动使用此技能。
---

# Bugly User Investigator — 基于 userId 的异常查询

根据 userId 从 Bugly 查询用户异常记录（Crash / ANR / FOOM），输出结构化的诊断报告。


---

## 输入信息

- **userId**（必填）：App 用户 ID，格式通常为纯数字字符串
- **日期**（可选）：默认今天（北京时间），支持"昨天"、"3月20日"等自然语言
- **问题类型**（可选）：crash（默认）/ anr / foom

---

## 前提条件

技能自带查询脚本（`scripts/query_agent.py`），会按以下优先级自动定位：

1. 技能自身目录：`<skill_dir>/scripts/query_agent.py`
2. bugly-data-analyzer 目录：`~/.claude/skills/bugly-data-analyzer/scripts/query_agent.py`
3. 本地绝对路径：`/Users/bryanpeng/.claude/skills/bugly-data-analyzer/scripts/query_agent.py`

**Token 自动从缓存读取**，无需每次 export。若遇到 Token 失效，执行：

```bash
export BUGLY_USER_TOKEN=<your_token>
```

---

## 固定配置

| 配置项 | 值 |
|--------|---|
| 王者营地 Product ID | `ef14bfff8f` |
| 默认 Agent ID | `12` |
| 脚本路径 | 动态查找（优先使用技能自带的 `scripts/query_agent.py`） |

---

## 执行流程

### Step 1：确认输入参数

收集以下信息（如用户未提供则询问或使用默认值）：

- `userId`：必填，如未提供则直接询问
- `date`：默认今天，格式转换为 `YYYY-MM-DD`（北京时间 UTC+8）
- `issue_type`：默认 `crash`

### Step 2：调用 Bugly Agent 查询

运行以下命令（自动定位脚本，兼容本地 Mac 和 Knot AnyDev 云端）：

```bash
SCRIPT=$(python3 -c "
import os
candidates = [
    os.path.join(os.path.dirname(os.path.abspath('$0')), 'scripts/query_agent.py'),
    os.path.expanduser('~/.claude/skills/bugly-user-investigator/scripts/query_agent.py'),
    os.path.expanduser('~/.claude/skills/bugly-data-analyzer/scripts/query_agent.py'),
    '/Users/bryanpeng/.claude/skills/bugly-data-analyzer/scripts/query_agent.py',
]
print(next((c for c in candidates if os.path.exists(c)), ''))
")

export BUGLY_USER_TOKEN=54a5f8a2-495c-40e9-81f7-03d69913cc63

python3 "$SCRIPT" \
  --product-id ef14bfff8f \
  --message "帮我查一下用户 {userId} 在 {date} 的{issue_type}情况，包括：异常总次数、每条异常的 Issue ID、异常类型（crash/anr/foom）、系统版本、手机型号、应用版本、关键堆栈（Key Method）、最后上报时间、处理状态，以及每条异常的详情链接"
```

将 `{userId}`、`{date}`、`{issue_type}` 替换为实际值。

**issue_type 取值说明**：
- `crash`（默认）：查崩溃
- `anr`：查 ANR（Application Not Responding）
- `foom`：查 FOOM（Front-of-Mind Out-of-Memory）
- 若用户未指定，默认查 crash；若用户说「全部」「所有问题」，则依次查询三种类型并合并结果

### Step 3：解析并格式化输出

将 Bugly Agent 返回的结果按以下模板整理输出：

---

## 输出报告模板

```
## Bugly 异常诊断报告

**用户 ID**：{userId}
**查询日期**：{date}
**问题类型**：{issue_type}（crash / anr / foom）
**产品**：王者营地 iOS（ef14bfff8f）

---

### 📊 总览

| 指标 | 数值 |
|------|------|
| 异常总次数 | X 次 |
| 影响设备数 | X 台 |

---

### 📋 异常详情

（每条异常一个卡片）

#### Issue：{issue_id}
🔗 详情链接：{bugly_link}

| 字段 | 内容 |
|------|------|
| **异常类型** | `{exception_type}`（crash / anr / foom） |
| **最后上报时间** | {time} |
| **系统版本** | {os_version} |
| **手机型号** | {device_model} |
| **应用版本** | {app_version} |
| **处理状态** | {status} |

**关键堆栈：**
\`\`\`
{key_stack}
\`\`\`

**初步判断**：{brief_analysis}

---

（如有多条异常，逐一列出）

---

### 💡 建议

{suggestions}
```

---

## 注意事项

- **无异常数据**：如返回 0 条异常，告知用户「该用户今天暂无{issue_type}记录」，并建议检查 userId 是否正确或尝试其他日期/问题类型
- **多条异常**：逐一展示每条异常的详情，不要合并
- **Token 缓存**：脚本自动从 `~/.bugly_token_cache.json` 读取 Token，无需手动 export
- **日期格式**：传给 Bugly Agent 的日期用 `YYYY-MM-DD`，自然语言由 AI 转换
- **ANR/FOOM**：若用户指定 anr 或 foom，在 message 中相应修改问题类型描述；ANR 堆栈通常包含主线程卡死信息，FOOM 堆栈可能包含内存分配信息
