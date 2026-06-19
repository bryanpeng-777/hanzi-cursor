---
name: camp-feedback-analyzer
description: 营地反馈端到端分析的顶层编排 skill。给定反馈 id / 反馈链接 / iFeedback URL / 营地 uid + 时间窗，按版本路由分支串接无极或 ifeedback 检索 + xlog 解码 + lego 补拉子 skill，最终由主 LLM 写出根因分析报告。当用户需要分析单条营地反馈、出反馈根因报告时使用。触发关键词：营地反馈分析、反馈报告、根因报告、反馈链接分析、营地问题排查、ifeedback 反馈分析、wzyd 反馈定位、无极反馈。
---

# camp-feedback-analyzer

营地反馈端到端分析的**顶层编排** skill。**自身不实现业务逻辑**，只做一件事：

- **`init`** —— 创建工作目录骨架（`attachments/` / `decoded_logs/` / `analysis/`）

中间所有数据加工委托给独立的子 skill 按 workdir 文件契约串接；最终 `report.md` **由主 LLM 直接撰写**（不由本 skill 渲染），格式严格遵守下方"报告结构"。

## 反馈来源（**Step 1**）

- **路径 A（无极，新版本优先）** `camp-wuji-feedback-fetcher`：`client_version >= 10.112.0415` 的反馈优先走无极。通过"王者营地 MCP"的 `get_mgame_feedback_data_list` 接口拉取。无极未查到时降级走路径 B。
- **路径 B（iFeedback，老版本默认）** `camp-ifeedback-feedback-fetcher`：`client_version < 10.112.0415` 或用户提供 ifeedback URL / ifeedback `_id`

两条路径产出**完全相同的 `feedback.json + manifest.json` 契约**（`manifest.source` 字段标识来源）。下游 Step 2~4 共用。

> **版本路由规则**：
> - 已知版本 >= `10.112.0415` → 先无极，未命中再 ifeedback
> - 已知版本 < `10.112.0415` → 直接 ifeedback
> - 版本未知（用户只给 uid + 时间窗）→ 先无极，未命中再 ifeedback
> - 用户明确给 ifeedback URL → 直接 ifeedback

## 入口

```bash
python3 scripts/feedback_analyze.py <subcommand> [options]
```

| 子命令 | 用途 |
|---|---|
| `init` | 建工作目录骨架，输出 workdir 绝对路径（**自动缓存复用 + 自动清理**） |
| `init-direct` | **直传模式**（路径 C）：建 workdir + 从 URL 下载日志/截图 + 写 manifest。跳过 Step 1，从 Step 3 开始 |
| `init-local` | **本地文件模式**（路径 D）：建 workdir + 从本地路径导入日志/截图 + 智能分类 + 写 manifest。跳过 Step 0~1，从 Step 3 开始 |
| `cache-clean` | **批量清理**：按 TTL（默认 7 天）+ 容量上限（默认 2GB）LRU 淘汰旧 workdir |

### 缓存复用机制

`init` 会自动检查是否有相同反馈的已有 workdir（基于 feedback_id 哈希匹配）：

| 缓存状态 | 含义 | 主 LLM 行为 |
|----------|------|-------------|
| `full_hit` | decoded_logs 已存在 | **跳过 Step 1~3，直接从 Step 4 分析** |
| `partial_hit` | feedback.json 已有，缺 decoded_logs | 跳过 Step 1，从 Step 2/3 继续 |
| `miss` / `expired` | 无缓存或已过期 | 正常执行全流程 |

- 使用 `--no-cache` 强制跳过缓存复用
- 使用 `--force` 删除已有 workdir 重建

各子命令的详细参数、用法示例、智能分类机制见 [references/command_reference.md](references/command_reference.md)。

## 端到端工作流（**主 LLM 应按此顺序逐步执行**）

> 主 LLM 必须**逐条**调用 Step 0~4，每条执行完检查 exit code；**不要把整段 bash 一次性 shell exec**（条件分支 / 失败处理需要按 exit code 决定）；非 0 时按"故障处理"小节决定停或继续。

```bash
# 子 skill 路径（调试期均在项目根目录下）：
#   ../camp-ifeedback-feedback-fetcher/  路径 B：iFeedback 反馈检索（老版本默认）
#   ../camp-xlog-decoder/                mars xlog 解码
#   ../camp-wuji-feedback-fetcher/    路径 A：无极反馈检索（新版本优先，MCP 模式）
#   ../camp-lego-log-fetcher/            lego 日志补拉（manifest.logs 为空时兜底）

# === Step 0: 准备工作目录 ===
WD=$(python3 scripts/feedback_analyze.py init \
    --feedback-id 202605_12352 \
    --create-time "2026-05-11 20:35:56")

# === Step 1: 检索反馈 + 下载附件（路径 A/B 按版本路由） ===

# 路径 A：无极（新版本 >= 10.112.0415 优先）
# 主 LLM 先调 MCP get_mgame_feedback_data_list，然后：
python3 ../camp-wuji-feedback-fetcher/scripts/wuji.py init-mcp \
    --data-file <MCP返回的JSON文件> --workdir $WD --first
python3 ../camp-wuji-feedback-fetcher/scripts/wuji.py fetch --workdir $WD
# 无极未命中 → 降级路径 B

# 路径 B：iFeedback（老版本 / 降级 / 用户给 ifeedback URL）
python3 ../camp-ifeedback-feedback-fetcher/scripts/ifeedback.py locate \
    --ifeedback-url "https://ifeedback.qq.com/feedback/?app_id=772&...&_id=xxx" \
    --workdir $WD --first
python3 ../camp-ifeedback-feedback-fetcher/scripts/ifeedback.py fetch --workdir $WD

# === Step 2:（条件）lego 补拉日志 ===
# 无论路径 A / B，只要 manifest.logs 为空就走 lego 兜底
# 主 LLM 调 MCP：lego.queryLogs → lego.convertAndDecrypt → 拿到下载 URL：
python3 ../camp-lego-log-fetcher/scripts/lego.py download --url <URL> --workdir $WD
# 无现成日志 → 调 MCP lego.createFetchTask（fire-and-forget）→ 继续分析

# === Step 3: 解码 mars xlog（camp-xlog-decoder） ===
python3 ../camp-xlog-decoder/scripts/decode.py decode --workdir $WD
# 默认只解主进程；解所有（含 phoenix/widgetProvider 子进程）：--all

# === Step 4: 主 LLM 按"分析方法"小节写报告 ===

# === Step 5:（可选）分析完成后删除 attachments/ 释放空间 ===
# rm -rf $WD/attachments
```

### 故障处理

| 步骤失败 | 处理 |
|---|---|
| Step 1 `locate`/`init-mcp` 失败 | 无极未命中 → 降级 ifeedback；都失败则停止（exit 3） |
| Step 1 `fetch` 部分失败 | **继续**（manifest 记 `download_failures[]`，报告标注） |
| Step 2 lego 失败/无日志 | **继续**（fail-soft：拿不到 ≡ 没有补充日志） |
| Step 3 `decode` 部分失败 | **继续**（进 `decode_failures[]`，报告标注"未解码"，不要 grep 原始 xlog） |

## Step 4 分析方法（**主 LLM 必读**）

**核心原则：按 Tag 缩小范围 → 按时间精确定位 → 按级别分层读取。**

分析步骤：

1. **按 Tag 定位**：从用户描述推断问题模块，只在对应 Tag 的日志行中搜索
2. **按时间过滤**：`create_time` 前 1~10 分钟为问题窗口，组合 `时间 + Tag` 双重过滤
3. **按级别分层**：先看 `[E]`/`[F]` → 再看 `[W]` → 最后 `[I]`（仅错误行附近 ±30 行）
4. **识别高价值模式**：状态变化、错误码、耗时超限、重试计数、时间跳跃（>3s）
5. **规模控制**：单文件 >50000 行禁止整文件 read，先时间窗口截取再 grep；主进程日志优先

> **详细参考**（Tag 映射表、真实 grep 示例、噪声 Tag 列表、文件命名规则、决策树）见 [references/log-analysis-strategy.md](references/log-analysis-strategy.md)。

### Step 4.5 自验证（**写报告前必须执行**）

报告初稿形成后，**必须**进行以下验证再输出最终版本：

#### 1. 证据链验证

对报告"四、根因分析"中的每条结论，逆向检查：
- 每条结论是否有**日志行号+时间戳+原文摘录**支撑？
- 推理是否存在跳跃（A→C，缺少 B）？
- 存在跳跃时：补充中间环节，或降级为"⚠️ 推测"

#### 2. 备选假设检查

**强制执行，不可跳过**：
- 基于相同日志现象，列出至少 **1~2 个备选假设**
- 对每个备选假设，尝试在日志中找支持/反对证据
- 能排除的标注排除理由；不能排除的在报告中承认"存在其他可能"

#### 3. 置信度判定

| 置信度 | 条件 |
|--------|------|
| **高** | 每条结论有日志证据 + 推理无跳跃 + 备选假设可排除 |
| **中** | 有日志证据但推理链含合理假设，或备选假设未完全排除 |
| **低** | 证据不足 / 推理有跳跃 / 多个假设均无法排除 |

置信度在报告开头标注，影响修复建议的确定性表述。

## 报告输出

主 LLM 撰写的报告需**同时**：
1. 写入 `$WD/report.md` 文件（持久化，供后续审计/追溯）
2. **直接输出到当前对话**（用户立即看到）

报告 **必须**包含以下章节：

```markdown
# 营地反馈分析报告

> 置信度：{高/中/低}
> 生成时间：{timestamp}
> 反馈来源：{wuji / ifeedback / direct / local}

## 一、反馈基础信息
（id / userId / uin / 平台 / 版本 / 机型 / 时间 / 用户描述 / 反馈链接）
**必须**根据 `manifest.source` 标注反馈来源："无极（wuji）" 或 "iFeedback" 或 "direct" 或 "local"

## 二、日志与附件概览
（日志来源 / 文件清单 / 解码状态 / 截图列表 / 日志时间范围 / 行数；
 标注 download_failures / decode_failures / lego_status 等失败项）

## 三、截图分析
（嵌入截图 + 解读截图内容，与日志证据交叉验证）

## 四、根因分析
（证据链：每条结论标注日志行号+时间戳+原文摘录）
（触发路径 / 问题归属：客户端 vs 服务端 vs 用户）
（无日志证据的推测必须标注 ⚠️ 推测）

## 五、修复建议
（分 P0/P1/P2，按服务端/客户端/客服角色给建议）
（置信度为"低"时，建议措辞须使用"可能"/"建议排查"等非断言表述）

## 六、验证与置信度
（自验证摘要：证据链完整性 / 备选假设及排除理由 / 不确定点清单）
（如有无法排除的备选假设，在此列出）

## 七、附录
（工作目录路径 / 生成时间 / grep 命中摘要）
```

### 硬性约束

1. **每条结论必须标注日志证据**（行号 + 时间戳 + 原文摘录）
2. **没有日志证据的推测必须明确标注 "⚠️ 推测"**
3. **不编造不存在的日志内容**
4. **截图解读必须与日志证据交叉验证**
5. **grep 关键词从反馈内容自主提取**，不依赖预定义列表
6. **截图不清晰或与当前结论无关时标注 "⚠️ 截图不清晰" 或 "⚠️ 截图无关"**，不要强行解读

## 工作目录契约与 manifest schema

workdir 目录结构、`manifest.json` 全字段说明、`analysis/notes.md` 写入规范详见 [references/manifest_schema.md](references/manifest_schema.md)。

## 日志分析详细策略

关键词映射表、grep 具体示例、营地日志标签速查详见 [references/log-analysis-strategy.md](references/log-analysis-strategy.md)。

## CI / JSON 输出

CI 场景加 `--json` 拿 workdir，详见 [references/command_reference.md](references/command_reference.md)。

## 退出码

| 码 | 含义 |
|---|---|
| 0 | 成功 |
| 1 | IO / 参数错误 |

## 限制

- **不实现业务逻辑**，纯编排：所有数据加工在子 skill 中完成
- **不渲染最终报告**：`report.md` 由主 LLM 按"报告结构"小节自行撰写，本 skill 不提供 `report` 子命令
- **不自动调子 skill**：由主 LLM 按 SKILL.md 工作流主动 chain 各 CLI
- **目录命名规则**：`<sanitized_feedback_id>_<YYYYMMDD_HHMMSS>`（缺 create_time 时为 `_unknown`）
- 子 skill 必需性：
  - `camp-wuji-feedback-fetcher` **或** `camp-ifeedback-feedback-fetcher`（**Step 1 二选一**，至少接入一条）
  - `camp-xlog-decoder` 推荐（ECC 加密日志可选 `$CAMP_XLOG_PRIV_KEY`）
  - `camp-lego-log-fetcher` 可选（两条路径下 `manifest.logs` 为空时均可走 lego 兜底，按 uid 拉）
