"""
Bugly 版本对比日报 - Knot Skill
查询王者营地现网最新版本 vs 大盘的 Crash/FOOM/ANR 对比数据
使用两轮对话：第一轮查指标，第二轮通过版本对比查最新版本独有的新增问题
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

QUERY_METRICS = (
    f"请查询产品ID为 {BUGLY_PRODUCT_ID} 的王者营地现网最新发布版本 vs 大盘所有版本，"
    "统计时间范围：仅昨天一天（今天的前一天，不含今天）的数据。\n\n"
    "分 Crash / FOOM / ANR 三段，每段包含：\n"
    "- 最新版本昨日指标、大盘昨日指标、趋势（好转/注意/持平）\n\n"
    "同时请告诉我最新发布版本的版本号。\n\n"
    "根据以下阈值对最新版本昨日指标进行检查，"
    "如有任何一项超出阈值，输出【⚠️ 需要关注】区块，列出超标项目和具体数值；"
    "如全部正常，输出【✅ 指标正常】：\n"
    "- Crash 率 > 0.05%\n"
    "- FOOM 率 > 0.02%\n"
    "- ANR 率 > 0.02%"
)

QUERY_NEW_ISSUES = (
    f"请对比产品ID为 {BUGLY_PRODUCT_ID} 的王者营地最新发布版本 vs 小于该版本的所有旧版本，"
    "统计时间范围：仅昨天一天（今天的前一天，不含今天）的数据。\n\n"
    "找出最新版本昨天的【新增问题】。\n"
    "新增问题的定义：该 Issue 仅在最新版本中出现，在之前所有旧版本中从未出现过。\n"
    "如果某个 Issue 在旧版本中也存在，则不算新增问题，必须排除。\n\n"
    "请分 Crash / FOOM / ANR 三类分别列出新增问题，每条包含：\n"
    "- Issue ID\n"
    "- 异常类型（Exception Type）\n"
    "- 影响设备数\n"
    "- 关键堆栈（Key Method，取最顶层 1-2 帧即可）\n"
    "- Bugly 详情链接\n\n"
    "如果某类型无新增问题，注明「无新增问题」即可。"
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
    print(f"📊 Bugly 日报 · {today}（统计昨日 {yesterday} 数据）\n")

    # ── 第一轮：查询指标对比 ──
    print("正在查询指标对比数据...\n")
    metrics_result, thread_id = query_bugly_agent(QUERY_METRICS)

    if metrics_result.startswith("[错误]"):
        print(metrics_result, file=sys.stderr)
        sys.exit(1)

    print("## 第一部分：指标对比\n")
    print(metrics_result)
    print()

    # ── 第二轮：通过版本对比查最新版本独有的新增问题 ──
    print("正在查询最新版本独有的新增问题...\n")
    issues_result, _ = query_bugly_agent(QUERY_NEW_ISSUES, thread_id=thread_id)

    if issues_result.startswith("[错误]"):
        print(issues_result, file=sys.stderr)
        sys.exit(1)

    print("## 第二部分：最新版本新增问题列表\n")
    print(issues_result)


if __name__ == "__main__":
    main()
