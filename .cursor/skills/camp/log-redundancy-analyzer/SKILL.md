---
name: log-redundancy-analyzer
description: >
  xlog 日志冗余性与必要性分析专家。通过 Python 脚本对 xlog 日志文件进行聚类扫描，
  识别高频重复日志、低信息量日志、短时突发日志，输出结构化分析报告，并给出清理建议。
  当用户提到"分析日志"、"日志冗余"、"哪些日志可以删"、"日志清理"、"log redundancy"、
  "哪些 log 打太多了"、"xlog 分析"、"日志优化"时触发。即使用户只说"帮我看看日志"
  并提供了 xlog 文件路径，也应主动使用此技能。
---

# Log Redundancy Analyzer

分析 xlog 日志文件，找出冗余日志、帮助决策哪些可以删除或降级。

## 支持的日志格式

**xlog 格式**（王者营地 App 使用）：
```
[LEVEL][TIMESTAMP +TZ HH:MM:SS.mmm][PID, THREAD*][TAG][FILE, METHOD, LINE][MESSAGE...]
```
- LEVEL: `I`(Info) / `D`(Debug) / `W`(Warning) / `E`(Error) / `F`(Fatal)
- 调用位置（callsite）为 ObjC 格式：`文件名, ObjC方法签名, 行号`
- Swift 日志的文件名和方法名字段可能为空

## 工作流程

### Step 1: 确认日志文件路径

如果用户没有提供路径，询问日志文件的完整路径。常见位置：
- `aiworkspace/` 下的 `.xlog.log` 文件
- 用户直接粘贴的路径

### Step 2: 运行分析脚本

脚本路径：`/Users/bryanpeng/.claude/skills/log-redundancy-analyzer/scripts/analyze_xlog.py`

**基础用法**：
```bash
python3 <SKILL_DIR>/scripts/analyze_xlog.py <LOG_FILE> -o /tmp/log_report.md
```

**常用参数**：
| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--top N` | 30 | 展示前 N 个冗余调用点 |
| `--min-count N` | 10 | 过滤出现次数 < N 的调用点 |
| `--window SEC` | 10 | 突发检测时间窗口（秒） |
| `--filter KEYWORD` | 无 | 只分析文件名含此关键字的调用点 |
| `-o FILE` | 终端输出 | 报告输出路径 |

**按模块分析示例**：
```bash
# 分析 OTTraceManager 相关日志
python3 <SKILL_DIR>/scripts/analyze_xlog.py <LOG_FILE> --filter OTTraceManager -o /tmp/trace_report.md

# 重点关注高频调用，调低阈值
python3 <SKILL_DIR>/scripts/analyze_xlog.py <LOG_FILE> --top 50 --min-count 50 -o /tmp/report.md
```

典型 158MB 的 xlog 文件（约 178 万行）处理耗时约 6-8 秒。

### Step 3: 解读报告，给出分析

报告包含三个主要部分，按以下逻辑解读：

#### 3.1 按文件统计
看哪些文件贡献了最多日志量。占比高的文件是重点清理对象。

#### 3.2 出现次数最多的调用点（表格）

关键指标解读：
- **次数**：该行代码在整个 session 中打日志的总次数
- **唯一模板数**：去掉变量后剩余多少种不同消息内容
- **冗余比**（次数 ÷ 唯一模板数）：
  - `> 100x`：几乎每次打的内容都一样，高度冗余
  - `10-100x`：中度冗余
  - `< 10x`：内容多样，信息量较高
- **10s突发**：10 秒内最多连续打了多少次（突发 > 50 说明在循环/高频回调中）

#### 3.3 冗余评分最高的调用点（详细）

提供每个高冗余调用点的：
- 消息模板（去掉变量后的内容，能看出日志的真实用途）
- 原始样例（一条实际日志内容）
- 具体数字

### Step 4: 给用户展示分析结论

读取报告后，向用户呈现以下内容（**不要把整个报告 dump 出来**，而是总结关键发现）：

```
## 分析结论

**文件概况**: 共 X 条日志，来自 N 个不同调用点

**TOP 冗余问题**（按严重程度）:

🔴 立即删除:
- `WEGGameConfig.m:414` — 同一内容打了 27,762 次（冗余比 27762x），是 BetaGameIdMap 缓存读取日志，每次读缓存都打，完全没必要
- `CampRequestPreloadManager.m:446` — 8,269 次，只有 2 种消息，"not preload url = ..."，可删

🟠 建议删除或降级:
- `OTTraceManager.m:393/397` — Span 开始/结束日志，共 5 万次，生产环境意义不大
- `WEGWebServiceHandler.m:273` — 每个请求都打 Encrypt 参数（含 token！），安全风险 + 冗余

🟡 限制频率:
- `TabBarViewController.m:2318` — 10s 突发最高 840 次，是 PAG 刷新通知监听，可加去抖

**文件占比分布**:
- OTTraceManager.m: 19.6%（81,598 条）
- WEGGameConfig.m: 7.2%（30,045 条）
- WebServiceManager.m: 5.8%（23,993 条）
```

## 注意事项

### 关于 `:0` 和 `:82` 这类条目
文件名或方法名为空（`(swift/unknown)` 类别）的条目是 Swift 日志或格式解析失败的行。这些日志混合了多个 Swift 调用位置，无法精确定位到具体代码行。可通过 `--filter` 参数配合关键字缩小范围。

### 关于"唯一模板数上限 500"
脚本限制每个调用点最多跟踪 500 种不同模板，超过时冗余比会偏低（实际可能更高）。

### 安全提醒
如果在高冗余调用点中发现消息内容含有 `token`、`key`、`userId`、`refreshToken` 等字样的日志 —— 这是**安全风险**，应优先删除，不只是"冗余"问题。

## 分析后的常见建议

| 场景 | 建议处置 |
|------|---------|
| 同一内容重复 > 100x（如配置读取日志） | 删除日志，或改为只在值变化时打 |
| Span 开始/结束框架日志 | 生产包删除，或改为 Verbose 级别 |
| 网络请求参数日志（含 token） | 立即删除（安全） |
| UI Cell 刷新日志（showtime 等） | 删除，可降为 Debug only |
| 突发 > 50/10s 的日志 | 加限频逻辑（如每 N 次或 T 秒打一次） |
| Shiply/RD SDK 内部日志 | 关闭 SDK 内部日志输出开关 |
