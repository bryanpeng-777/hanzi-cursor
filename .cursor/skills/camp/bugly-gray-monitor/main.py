"""
Bugly 灰度版本监控日报 - Knot Skill
监控王者营地 iOS 灰度版本（最新版本且用户数≥50）与现网稳定版本的 Crash/ANR 率对比
灰度版本任一指标较现网版本升高 ≥50% 时输出告警
"""

import json
import uuid
import sys
from datetime import date

import requests

# ── 配置 ──────────────────────────────────────────────────────────
BUGLY_PRODUCT_ID = "ef14bfff8f"
BUGLY_USER_TOKEN = "54a5f8a2-495c-40e9-81f7-03d69913cc63"
BUGLY_API_URL = "http://api.bugly.woa.com/agui/dynamic"
AGENT_ID = "12"

# 告警阈值：灰度版本指标较现网版本升高超过此比例则告警
ALERT_THRESHOLD = 0.5  # 50%

QUERY_VERSIONS = (
    f"请查询产品ID为 {BUGLY_PRODUCT_ID} 的王者营地各版本的用户数量，"
    "统计时间范围：仅昨天一天（今天的前一天，不含今天）的数据。\n\n"
    "找出以下两个版本：\n"
    "1. 灰度版本：版本号最新（数字最大）且用户数量 ≥50 人的版本\n"
    "2. 现网稳定版本：用户量最大的版本（主力版本，通常不是最新版）\n\n"
    "如果两者是同一个版本，说明当前没有灰度版本，请注明「当前无灰度版本」并结束。\n\n"
    "请输出：\n"
    "- 灰度版本号 + 用户数\n"
    "- 现网版本号 + 用户数\n"
    "- 两个版本各自的 Crash 率和 ANR 率\n\n"
    "同时请计算：灰度版本相比现网版本，Crash 率变化幅度（百分比）、ANR 率变化幅度（百分比）。\n"
    "变化幅度计算公式：(灰度值 - 现网值) / 现网值 × 100%，正数为升高，负数为下降。\n\n"
    f"告警规则：若任一指标升高幅度 ≥{int(ALERT_THRESHOLD * 100)}%，输出【⚠️ 灰度异常告警】区块，"
    "列出超标项目、具体数值和幅度；若全部正常，输出【✅ 灰度指标正常】。"
)

QUERY_NEW_ISSUES = (
    f"请对比产品ID为 {BUGLY_PRODUCT_ID} 的王者营地灰度版本（上一条消息中识别的最新版本）vs 现网稳定版本，"
    "统计时间范围：仅昨天一天（今天的前一天，不含今天）的数据。\n\n"
    "找出灰度版本的【新增问题】（仅在灰度版本中出现，在现网版本中从未出现过）。\n\n"
    "请分 Crash / ANR 两类分别列出新增问题，每条包含：\n"
    "- Issue ID\n"
    "- 异常类型（Exception Type）\n"
    "- 影响设备数\n"
    "- 关键堆栈（Key Method，取最顶层 1-2 帧即可）\n"
    "- Bugly 详情链接\n\n"
    "如果某类型无新增问题，注明「无新增问题」即可。\n"
    "如果上一步说明当前无灰度版本，此步骤跳过。"
)
# ──────────────────────────────────────────────────────────────────


def query_bugly_agent(message: str, thread_id: str | None = None) -> tuple[str, str]:
    """向 Bugly Agent 发送查询，返回 (结果文本, thread_id)。"""
    if thread_id is None:
        thread_id = uuid.uuid4().hex[:12]
    run_id = f"run-{uuid.uuid4().hex[:8]}"

    headers = {
        "Content-Type": "text/event-stream",
        "X-Bugly-User-Token": BUGLY_USER_TOKEN,
        "X-ProductId": BUGLY_PRODUCT_ID,
    }
    payload = {
        "threadId": thread_id,
        "runId": run_id,
        "messages": [{"role": "user", "content": message}],
        "forwardedProps": {"agent_id": AGENT_ID},
    }

    try:
        resp = requests.post(
            BUGLY_API_URL,
            headers=headers,
            json=payload,
            stream=True,
            timeout=300,
        )
        resp.raise_for_status()
        resp.encoding = "utf-8"
    except requests.exceptions.RequestException as e:
        return f"[错误] 请求 Bugly Agent 失败: {e}", thread_id

    text_parts: dict[str, list[str]] = {}
    final_texts: list[str] = []
    success = False

    for line in resp.iter_lines(decode_unicode=True):
        if not line or not line.startswith("data: "):
            continue
        try:
            event = json.loads(line[len("data: "):])
        except json.JSONDecodeError:
            continue

        t = event.get("type", "")
        if t == "TEXT_MESSAGE_START":
            text_parts[event.get("messageId", "")] = []
        elif t == "TEXT_MESSAGE_CONTENT":
            mid = event.get("messageId", "")
            if mid in text_parts:
                text_parts[mid].append(event.get("delta", ""))
        elif t == "TEXT_MESSAGE_END":
            mid = event.get("messageId", "")
            if mid in text_parts:
                text = "".join(text_parts[mid]).strip()
                if text:
                    final_texts.append(text)
        elif t == "RUN_FINISHED":
            success = True
        elif t == "RUN_ERROR":
            return f"[错误] Bugly Agent 返回错误: {event.get('message', '未知错误')}", thread_id

    if not success and not final_texts:
        return "[错误] Bugly Agent 未返回有效数据", thread_id

    full = "\n\n".join(final_texts)
    marker = "/*FINAL_ANSWER*/"
    if marker in full:
        return full.split(marker, 1)[1].strip(), thread_id
    for msg in reversed(final_texts):
        if "/*PLANNING*/" not in msg and "/*ACTION*/" not in msg:
            return msg.strip(), thread_id
    return full.strip(), thread_id


def main():
    today = date.today().strftime("%Y-%m-%d")
    yesterday = (date.today() - __import__('datetime').timedelta(days=1)).strftime("%Y-%m-%d")
    print(f"🔬 Bugly 灰度监控日报 · {today}（统计昨日 {yesterday} 数据）\n")

    # ── 第一轮：识别灰度版本和现网版本，对比指标 ──
    print("正在识别灰度版本和现网版本，查询对比数据...\n")
    versions_result, thread_id = query_bugly_agent(QUERY_VERSIONS)

    if versions_result.startswith("[错误]"):
        print(versions_result, file=sys.stderr)
        sys.exit(1)

    print("## 版本对比与告警\n")
    print(versions_result)
    print()

    # 如果没有灰度版本，无需查新增问题
    if "当前无灰度版本" in versions_result:
        print("✅ 当前无灰度版本，无需监控。")
        return

    # ── 第二轮：查灰度版本新增问题 ──
    print("正在查询灰度版本新增问题...\n")
    issues_result, _ = query_bugly_agent(QUERY_NEW_ISSUES, thread_id=thread_id)

    if issues_result.startswith("[错误]"):
        print(issues_result, file=sys.stderr)
        sys.exit(1)

    print("## 灰度版本新增问题\n")
    print(issues_result)


if __name__ == "__main__":
    main()
