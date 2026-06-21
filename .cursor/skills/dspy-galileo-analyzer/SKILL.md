---
name: dspy-galileo-analyzer
description: 基于 DSPy 框架的伽利略告警结构化分析器。用 Signature + ChainOfThought 替代手写 Prompt，输出根因、模块名、严重等级、影响范围和处置建议。当用户说「DSPy 分析这个告警」「用 DSPy 分析」「dspy-galileo-analyzer」，或在伽利略告警分析场景中希望获得结构化 JSON 输出时触发。
---

# DSPy 伽利略告警分析器

基于 DSPy Signature + ChainOfThought 的伽利略告警结构化分析工具。

## 核心优势（vs 手写 Prompt）

| 维度 | 手写 Prompt | DSPy Signature |
|-----|------------|----------------|
| 代码形式 | 字符串拼接，脆弱 | 声明式类定义，干净 |
| 跨模型迁移 | 每次换模型重写 | 只改 `dspy.configure(lm=...)` |
| 输出结构化 | 靠 Prompt 约束，不稳定 | OutputField 类型强制 |
| 未来可优化 | 手动调 | BootstrapFewShot / MIPROv2 自动优化 |

## 环境准备

```bash
# 激活 DSPy 虚拟环境
source ~/.venvs/dspy-env/bin/activate

# 设置 API Key
export OPENAI_API_KEY="sk-..."
```

## 使用方式

### 基础调用

```bash
source ~/.venvs/dspy-env/bin/activate

python3 ~/.claude/skills/dspy-galileo-analyzer/analyzer.py \
  --alert "告警名称：AutoLogin 登录失败率，当前值 15.3%，阈值 5%，持续 10 分钟" \
  --logs "ERROR AutoLogin: token_refresh failed, error_code=-10001, count=1203"
```

### JSON 输出（适合程序化处理）

```bash
python3 ~/.claude/skills/dspy-galileo-analyzer/analyzer.py \
  --alert "告警内容..." \
  --logs "日志片段..." \
  --json
```

### 指定其他模型

```bash
python3 ~/.claude/skills/dspy-galileo-analyzer/analyzer.py \
  --alert "告警内容..." \
  --model "openai/gpt-4o"
```

## Signature 设计（核心）

```python
class GalileoAlertAnalysis(dspy.Signature):
    """分析伽利略监控告警，定位根本原因并给出结构化处置建议。"""
    
    # 输入
    alert_text: str = dspy.InputField(desc="告警内容，含名称、错误信息、量级、阈值")
    trace_logs: str = dspy.InputField(desc="相关 trace 日志片段（可为空）")
    
    # 输出
    root_cause: str     # [模块] 因 [原因] 导致 [现象]
    module_name: str    # 伽利略 moduleName
    severity: str       # P0 / P1 / P2
    impact_scope: str   # 影响范围评估
    action: str         # 2-3 条处置建议
    need_code_fix: bool # 是否需要 hotfix
```

## 输出示例

```
==============================
🔍 伽利略告警分析结果
==============================

🔴 严重等级：P0
📦 涉及模块：AutoLogin
🎯 根本原因：[AutoLogin] 因 token_refresh 接口返回 -10001 错误码导致登录失败率飙升至 15.3%
🌐 影响范围：影响全量用户自动登录流程，需立即处置
🔧 需要代码修复

📋 建议处置：
1. 立即查看 token_refresh 接口后台日志，确认 -10001 错误码含义
2. 联系后台负责人确认是否有接口变更或上线操作
3. 若为后台问题，回滚接口；若为客户端问题，hotfix 处理

💭 推理过程：
根据告警显示 AutoLogin 失败率 15.3% 远超 5% 阈值...（ChainOfThought 推理）
```

## 用户日志诊断 Pipeline（user-log 任务）

给定 userId + campUid，自动完成日志聚合 → DSPy 分析 → 结构化报告。

### 完整 Pipeline 流程

```
输入：userId + 问题描述（campUid 通过 Step 0 自动获取）

Step 0 [必须先做]  探查 campUid：
  get_log_data(
    target="iOS.camp-app",
    filters="tags.userId={userId}",
    return_tags=["campUid", "userId"]
  )
  → 从返回的 sample_logs[0].tags.campUid 提取设备维度 ID
  → 同时观察初步日志模板，获取问题线索（如 LoginMetric-start 异常高频）

Step 1 [AI + Galileo MCP]  并行拉取 4 路日志（取并集）：
  ├── get_log_data(filters="tags.userId={userId}")
  ├── get_log_data(filters="tags.campUid={campUid}")      ← Step 0 拿到后才能查
  ├── get_trace_data(filters="userId={userId}")
  └── get_trace_data(filters="campUid={campUid}")         ← Step 0 拿到后才能查

  ⚠️  不能跳过 Step 0 直接进 Step 1：campUid 维度数据覆盖设备级别行为，
      对多设备/多账号切换场景至关重要，缺失会导致 account_switch 类问题漏判。

Step 2 [Python]  合并去重（按 traceID+时间戳去重，时间升序）：
  python3 fetch_user_logs.py \
    --userid 123456 --campuid abc-def-xxx \
    --logs-uid logs_uid.txt --logs-cuid logs_cuid.txt \
    --traces-uid traces_uid.txt --traces-cuid traces_cuid.txt \
    --output merged_logs.txt

Step 3 [Python + DSPy]  结构化分析：
  python3 analyzer.py --task user-log \
    --userid 123456 --campuid abc-def-xxx \
    --logs "$(cat merged_logs.txt)" \
    --problem "账号B切换后重启App自动登录失败"
```

### 快捷调用（AI 直接传合并后的日志文本）

```bash
python3 ~/.claude/skills/dspy-galileo-analyzer/analyzer.py \
  --task user-log \
  --userid "428930738" \
  --campuid "a1b2c3d4-xxxx" \
  --logs "2026-04-01T10:12:04 QuickLogin end status=0 skipQQTokenRefresh=true
2026-04-01T10:15:31 AutoLogin step status=-1 errorCode=-10001 desc=QQ_accessToken_expired
2026-04-01T10:15:31 AutoLogin end status=-1 errorMsg=auto_login_failed" \
  --problem "切换账号B后杀掉App，重启后自动登录失败，重复操作持续复现"
```

### UserLogAnalysis Signature 设计

```python
Input:
  user_id:            userId（报告标识）
  camp_uid:           campUid，设备维度日志标识
  user_logs_text:     userId + campUid 查询结果的并集日志文本
  problem_description: 用户问题描述

Output:
  root_cause:         根因（[模块] 因 [原因] 导致 [现象]）
  issue_category:     auth_deadloop / token_expired / account_switch / network / unknown
  auth_pattern:       检测到的认证异常模式（如「快速登录跳过 QQ token 刷新」）
  severity:           P0 / P1 / P2
  recommendation:     2-3 条修复建议
  needs_engineer_fix: 是否需要代码修复
  affected_accounts:  受影响账号描述
```

### Auto-Flow：认证类问题自动输出专项处置指南

当 `issue_category` 为 `auth_deadloop` / `token_expired` / `account_switch` 时，
自动输出认证排查步骤 + 临时用户解决方案 + 代码修复建议。

---

## 落地路径

```
当前（Zero-shot）：Signature + ChainOfThought，无需训练数据
           ↓ 积累 10-20 条真实用户问题 + 告警分析样本
Phase 2：BootstrapFewShot，自动生成 Few-shot 示例
  运行：python3 ~/work_tree_bugfix/aiworkspace/train_optimizer.py
           ↓ 积累 100+ 样本
Phase 3：MIPROv2，全自动优化 Prompt，准确率提升 10-20%
```

## 文件结构

```
~/.claude/skills/dspy-galileo-analyzer/
├── SKILL.md                  ← 本文件
├── analyzer.py               ← DSPy 程序主体（galileo / user-log / bugly 三任务）
├── fetch_user_logs.py        ← 用户日志聚合脚本（userId + campUid 并集去重）
├── galileo_optimized.json    ← GalileoAlertAnalysis 优化结果（BootstrapFewShot 产出）
└── user_log_optimized.json   ← UserLogAnalysis 优化结果（BootstrapFewShot 产出）

~/work_tree_bugfix/aiworkspace/
└── train_optimizer.py        ← 训练脚本（含 GalileoAlertAnalysis + UserLogAnalysis 两套训练集）
```
