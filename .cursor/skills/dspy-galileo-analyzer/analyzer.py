#!/usr/bin/env python3
"""
DSPy Universal Analyzer
支持多种分析任务：伽利略告警分析、Bugly Crash 分析。

使用方式：
  python3 analyzer.py --task galileo --alert "告警内容" [--logs "日志片段"]
  python3 analyzer.py --task bugly   --stack "崩溃堆栈" --version "1.2.3" [--count 100]

环境变量：
  DEEPSEEK_API_KEY - DeepSeek API Key
  DSPY_LM          - 自定义 LM 标识符，如 "openai/gpt-4o"
"""

import argparse
import os
import sys
import json
import subprocess
from datetime import datetime, timedelta

import dspy

# Bugly Agent 查询脚本路径
BUGLY_QUERY_SCRIPT = "/Users/bryanpeng/.claude/skills/bugly-data-analyzer/scripts/query_agent.py"
BUGLY_PRODUCT_ID   = "ef14bfff8f"


# ══════════════════════════════════════════════════════
# Signature 层：每个任务各自定义，互不影响
# ══════════════════════════════════════════════════════

class GalileoAlertAnalysis(dspy.Signature):
    """
    分析伽利略监控告警，定位根本原因并给出结构化处置建议。
    伽利略是一套移动端 APM 监控系统，moduleName 对应业务模块的监控指标名称。
    """
    # ── 输入（伽利略专属）──
    alert_text: str = dspy.InputField(desc="告警内容，含告警名称、错误信息、触发量级、阈值等")
    trace_logs: str = dspy.InputField(desc="相关 trace 日志片段（可为空）")

    # ── 输出（伽利略专属）──
    root_cause: str   = dspy.OutputField(desc="根本原因，格式：'[模块] 因 [原因] 导致 [现象]'")
    module_name: str  = dspy.OutputField(desc="最可能相关的伽利略 moduleName，如 'AutoLogin'、'Pay'")
    severity: str     = dspy.OutputField(desc="严重等级：P0（核心不可用）/ P1（功能受损）/ P2（体验下降）")
    impact_scope: str = dspy.OutputField(desc="影响范围，如 '影响全量用户登录' 或 '影响 iOS 15 以下'")
    action: str       = dspy.OutputField(desc="建议处置步骤，按优先级列出 2-3 条")
    need_code_fix: bool = dspy.OutputField(desc="True=需要 hotfix，False=配置/回滚可解决")
    sample_user_id: str = dspy.OutputField(desc="从日志中提取的一个受影响用户 userId，用于后续 trace 追查；若日志中无 userId 则返回空字符串")


class UserLogAnalysis(dspy.Signature):
    """
    分析伽利略中特定用户的日志和 trace，诊断用户遇到的问题根因。
    输入日志来自 userId + campUid 两个维度查询的并集，覆盖更完整的用户行为链路。
    营地 App 常见问题：登录失败（QQ accessToken 过期）、账号切换异常、快速登录死循环等。
    快速登录仅校验营地 token，不校验 QQ accessToken，可能导致 token 未刷新的死循环。
    """
    # ── 输入 ──
    user_id: str = dspy.InputField(desc="App userId，用于报告标识")
    camp_uid: str = dspy.InputField(desc="设备 campUid，与 userId 并集查询日志用的标识符")
    user_logs_text: str = dspy.InputField(desc="从伽利略拉取的用户全量日志和 trace 文本（userId + campUid 查询结果并集，按时间排序）")
    problem_description: str = dspy.InputField(desc="用户反馈的问题描述，如「切换账号后重启 App 自动登录失败」")

    # ── 输出 ──
    root_cause: str = dspy.OutputField(desc="根因，格式：'[模块] 因 [原因] 导致 [现象]'")
    issue_category: str = dspy.OutputField(desc="问题分类：auth_deadloop（认证死循环）/ token_expired（token过期）/ account_switch（账号切换异常）/ network（网络异常）/ unknown（未知）")
    auth_pattern: str = dspy.OutputField(desc="检测到的认证异常模式，如 '快速登录成功但 QQ accessToken 未刷新，导致下次自动登录失败'；无认证问题则返回 '无'")
    severity: str = dspy.OutputField(desc="严重等级：P0（核心功能不可用）/ P1（功能受损）/ P2（体验下降）")
    recommendation: str = dspy.OutputField(desc="修复建议，2-3 条，按优先级排列")
    needs_engineer_fix: bool = dspy.OutputField(desc="True=需要代码修复；False=用户操作或配置可解决")
    affected_accounts: str = dspy.OutputField(desc="受影响账号描述，如 '账号B campUid=xxx 的 QQ accessToken 过期'；不明确则返回 '待确认'")


class BuglyAnalysis(dspy.Signature):
    """
    分析 Bugly 上报的 iOS/Android 崩溃堆栈，定位根因并给出修复建议。
    王者营地是一款社交 App，主要技术栈为 iOS OC/Swift + Flutter。
    """
    # ── 输入（Bugly 专属）──
    crash_stack: str  = dspy.InputField(desc="完整崩溃堆栈，含线程信息和调用链")
    app_version: str  = dspy.InputField(desc="发生崩溃的 App 版本号，如 '10.111.0318'")
    crash_count: str  = dspy.InputField(desc="崩溃次数和影响用户数（可为空）")

    # ── 输出（Bugly 专属）──
    root_cause: str     = dspy.OutputField(desc="崩溃根因，一句话描述是什么触发了崩溃")
    crash_type: str     = dspy.OutputField(desc="崩溃类型：NullPointer / OutOfBounds / Deadlock / OOM / 其他")
    fix_file: str       = dspy.OutputField(desc="最可能需要修改的文件路径或类名")
    fix_suggestion: str = dspy.OutputField(desc="具体修复建议，包含代码层面的处理方向")
    assignee: str       = dspy.OutputField(desc="建议分配给哪个模块的负责人，基于堆栈中的文件路径判断")
    severity: str       = dspy.OutputField(desc="严重等级：P0（影响核心功能）/ P1（影响部分用户）/ P2（偶发）")


# ══════════════════════════════════════════════════════
# 路由表：任务名 → (analyzer, 输入字段映射, 格式化函数)
# 新增任务只需在这里加一行，基础设施不用动
# ══════════════════════════════════════════════════════

def format_galileo(pred) -> str:
    emoji = {"P0": "🔴", "P1": "🟡", "P2": "🟢"}.get(pred.severity, "⚪")
    fix   = "🔧 需要代码修复" if pred.need_code_fix else "⚙️ 配置/回滚可解决"
    user_line = f"👤 样本用户：{pred.sample_user_id}\n" if getattr(pred, "sample_user_id", "") else ""
    return f"""
{'='*60}
🔍 伽利略告警分析结果
{'='*60}
{emoji} 严重等级：{pred.severity}
📦 涉及模块：{pred.module_name}
🎯 根本原因：{pred.root_cause}
🌐 影响范围：{pred.impact_scope}
{user_line}{fix}

📋 建议处置：
{pred.action}

💭 推理过程：
{getattr(pred, 'reasoning', '（无）')}
{'='*60}
"""

def format_user_log(pred) -> str:
    emoji = {"P0": "🔴", "P1": "🟡", "P2": "🟢"}.get(pred.severity, "⚪")
    fix = "🔧 需要代码修复" if pred.needs_engineer_fix else "👤 用户操作可解决"
    auth_line = (f"🔑 认证模式：{pred.auth_pattern}\n"
                 if getattr(pred, "auth_pattern", "无") not in ("无", "", "（未提供）")
                 else "")
    return f"""
{'='*60}
👤 用户日志诊断报告
{'='*60}
{emoji} 严重等级：{pred.severity}
📂 问题分类：{pred.issue_category}
🎯 根本原因：{pred.root_cause}
{auth_line}👥 受影响账号：{getattr(pred, 'affected_accounts', '待确认')}
{fix}

📋 修复建议：
{pred.recommendation}

💭 推理过程：
{getattr(pred, 'reasoning', '（无）')}
{'='*60}
"""


def format_bugly(pred) -> str:
    emoji = {"P0": "🔴", "P1": "🟡", "P2": "🟢"}.get(pred.severity, "⚪")
    return f"""
{'='*60}
🐛 Bugly Crash 分析结果
{'='*60}
{emoji} 严重等级：{pred.severity}
💥 崩溃类型：{pred.crash_type}
🎯 根本原因：{pred.root_cause}
📄 相关文件：{pred.fix_file}
👤 建议分配：{pred.assignee}

🔧 修复建议：
{pred.fix_suggestion}

💭 推理过程：
{getattr(pred, 'reasoning', '（无）')}
{'='*60}
"""

# 路由表（新增任务：加一个 key 即可）
TASKS = {
    "galileo": {
        "analyzer":  dspy.ChainOfThought(GalileoAlertAnalysis),
        "formatter": format_galileo,
        "args":      ["alert", "logs"],
        "input_map": {"alert_text": "alert",
                      "trace_logs": "logs"},
    },
    "user-log": {
        "analyzer":  dspy.ChainOfThought(UserLogAnalysis),
        "formatter": format_user_log,
        "args":      ["userid", "campuid", "logs", "problem"],
        "input_map": {"user_id":            "userid",
                      "camp_uid":           "campuid",
                      "user_logs_text":     "logs",
                      "problem_description":"problem"},
    },
    "bugly": {
        "analyzer":  dspy.ChainOfThought(BuglyAnalysis),
        "formatter": format_bugly,
        "args":      ["stack", "version", "count"],
        "input_map": {"crash_stack":  "stack",
                      "app_version":  "version",
                      "crash_count":  "count"},
    },
}


# ══════════════════════════════════════════════════════
# 基础设施层：完全通用，跟具体任务无关
# ══════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="DSPy 通用分析器")

    # 通用参数
    parser.add_argument("--task",  required=True, choices=TASKS.keys(), help="分析任务类型")
    parser.add_argument("--model", default=os.getenv("DSPY_LM", "openai/gpt-4o-mini"))
    parser.add_argument("--json",  action="store_true", help="输出 JSON 格式")

    # 各任务的输入参数（全部可选，由路由表决定哪个任务用哪些）
    parser.add_argument("--alert",   default="", help="[galileo] 告警内容")
    parser.add_argument("--logs",    default="", help="[galileo/user-log] 日志文本")
    parser.add_argument("--stack",   default="", help="[bugly] 崩溃堆栈")
    parser.add_argument("--version", default="", help="[bugly] App 版本号")
    parser.add_argument("--count",   default="", help="[bugly] 崩溃次数")
    parser.add_argument("--userid",  default="", help="[user-log] 用户 userId")
    parser.add_argument("--campuid", default="", help="[user-log] 用户 campUid（设备ID）")
    parser.add_argument("--problem", default="账号切换后自动登录失败", help="[user-log] 问题描述")
    args = parser.parse_args()

    # ── 配置 LM（通用，跟任务无关）──
    try:
        lm_kwargs = {}
        deepseek_key = os.getenv("DEEPSEEK_API_KEY", "")
        if deepseek_key and "deepseek" in args.model:
            lm_kwargs["api_key"] = deepseek_key
            lm_kwargs["api_base"] = "https://api.deepseek.com/v1"
        dspy.configure(lm=dspy.LM(args.model, **lm_kwargs))
    except Exception as e:
        print(f"❌ LM 配置失败：{e}", file=sys.stderr)
        sys.exit(1)

    # ── 路由到对应任务（通用，新增任务不用改这里）──
    task   = TASKS[args.task]
    inputs = {sig_field: getattr(args, cli_arg, "") or "（未提供）"
              for sig_field, cli_arg in task["input_map"].items()}

    # ── 执行分析（通用）──
    try:
        pred = task["analyzer"](**inputs)
    except Exception as e:
        print(f"❌ 分析失败：{e}", file=sys.stderr)
        sys.exit(1)

    # ── 输出结果（通用）──
    if args.json:
        print(json.dumps(
            {k: getattr(pred, k, "") for k in task["input_map"].keys()},
            ensure_ascii=False, indent=2
        ))
    else:
        print(task["formatter"](pred))

    # ── Auto-Flow：Crash 模块自动触发 Bugly 查询 ──
    auto_flow(pred, args.task)


def auto_flow(pred, task_name: str):
    """分析结果后自动触发下游动作。目前支持：
    - galileo 任务：module_name == 'Crash' 时自动查 Bugly
    - user-log 任务：issue_category 为认证类问题时输出专项处置指南
    """
    if task_name == "user-log":
        _auto_flow_user_log(pred)
        return

    if task_name != "galileo":
        return

    module_name    = getattr(pred, "module_name",    "")
    sample_user_id = getattr(pred, "sample_user_id", "")

    if module_name.lower() != "crash":
        return

    if not sample_user_id or sample_user_id.strip() in ("", "（未提供）"):
        print("\n⚠️  [Auto-Flow] 检测到 Crash 模块，但无 sample_user_id，跳过 Bugly 查询。")
        return

    today = datetime.now().strftime("%Y-%m-%d")
    seven_days_ago = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")
    print(f"\n🔁 [Auto-Flow] 检测到 module_name=Crash，自动查询 Bugly 用户崩溃...")
    print(f"   userId={sample_user_id}  范围=最近7天（{seven_days_ago} ~ {today}）")
    print("=" * 60)

    msg = (
        f"帮我查一下用户 {sample_user_id} 最近7天内的crash情况，"
        "包括：异常总次数、每条异常的 Issue ID、异常类型（crash/anr/foom）、"
        "系统版本、手机型号、应用版本、关键堆栈（Key Method）、最后上报时间、"
        "处理状态，以及每条异常的详情链接"
    )

    result = subprocess.run(
        ["python3", BUGLY_QUERY_SCRIPT,
         "--product-id", BUGLY_PRODUCT_ID,
         "--message", msg],
        capture_output=True, text=True
    )

    if result.returncode != 0:
        print(f"❌ [Auto-Flow] Bugly 查询失败：{result.stderr.strip()}")
    else:
        print(result.stdout)


def _auto_flow_user_log(pred):
    """user-log 任务：认证类问题自动输出专项处置指南。"""
    issue_category  = getattr(pred, "issue_category",    "unknown")
    needs_fix       = getattr(pred, "needs_engineer_fix", False)
    auth_pattern    = getattr(pred, "auth_pattern",       "无")
    severity        = getattr(pred, "severity",           "P2")

    auth_issues = {"auth_deadloop", "token_expired", "account_switch"}
    if issue_category not in auth_issues:
        return

    print(f"\n🔁 [Auto-Flow] 检测到认证类问题（{issue_category}），专项处置指南：")
    print("=" * 60)
    print("排查步骤：")
    print("  1. 确认「快速登录」流程是否跳过了 QQ accessToken 刷新")
    print("  2. 检查 AutoLogin 模块在账号切换时是否触发 token 续签逻辑")
    print("  3. 查看 AutoLogin/QuickLogin 伽利略日志中 step=token_refresh 是否出现")
    print("\n临时用户解决方案：")
    print("  → 在登录页手动重新授权 QQ，触发 accessToken 刷新")
    print("  → 或清除 App 缓存后重新登录")
    if needs_fix:
        print(f"\n⚠️  [P{severity}] 需要代码修复：")
        print("  → 快速登录成功后应同步检查并刷新 QQ accessToken")
        print("  → 可在 QuickLogin 完成回调中补充 token 刷新调用")
    print("=" * 60)


if __name__ == "__main__":
    main()
