#!/usr/bin/env python3
"""
全量 Module 灰度保障每日巡检 - 脚本版
使用 Galileo CLI 系统性查询所有 module，确定性计算触发率和偏差，输出标准报告。

用法：
    python3 main.py                     # 默认分析昨天的数据
    python3 main.py --date 2026-05-27   # 指定分析日期
"""

import argparse
import json
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import date, timedelta
from typing import Optional

# ── 配置 ──────────────────────────────────────────────────────────
# 灰度版本最低 AutoLogin 量（按平台区分）：低于此视为内部/测试包，不识别为灰度
# iOS 灰度通常 ~200 用户 × 2 logins/day ≈ 400 AutoLogin；内部包通常 < 200 AutoLogin
# Android 灰度量级更大，用 1000 过滤噪音
GRAY_MIN_AUTOLOGIN: dict[str, int] = {
    "iOS.camp-app":             200,
    "Android.default.camp-app": 300,
}
ALERT_THRESHOLD = 0.50       # 触发率偏差告警阈值（50%）
MIN_COUNT_FOR_COMPARISON = 50  # 低于此数不计算偏差
MAX_WORKERS = 5              # 并行查询线程数（过高会触发伽利略限流）
MAX_RETRIES = 3              # 单条查询失败重试次数

PLATFORMS = {
    "iOS": "iOS.camp-app",
    "Android": "Android.default.camp-app",
}

# ── 模块知识库 ────────────────────────────────────────────────────
KNOWN_MODULES = {
    # AlwaysTriggered
    "AutoLogin":                           {"type": "AlwaysTriggered", "platform": "both"},
    "AppStart":                            {"type": "AlwaysTriggered", "platform": "both"},
    "AppUpgrade":                          {"type": "AlwaysTriggered", "platform": "both"},
    "InnerRouter":                         {"type": "AlwaysTriggered", "platform": "both"},
    "OutRouter":                           {"type": "AlwaysTriggered", "platform": "both"},
    "NetRequest":                          {"type": "AlwaysTriggered", "platform": "both"},
    "Hippy":                               {"type": "AlwaysTriggered", "platform": "both"},
    "AppExitReason":                       {"type": "AlwaysTriggered", "platform": "both"},
    "LoginMetric":                         {"type": "AlwaysTriggered", "platform": "ios"},
    "FlutterEngineCreateToFirstFrameInit": {"type": "AlwaysTriggered", "platform": "both"},
    "FlutterContainerLifeCycle":           {"type": "AlwaysTriggered", "platform": "both"},
    # UserAction-High
    "ManualLogin":                         {"type": "UserAction-High", "platform": "both"},
    "MultiGameAuth":                       {"type": "UserAction-High", "platform": "both"},
    "GameDownload":                        {"type": "UserAction-High", "platform": "android"},
    # ErrorOnly
    "Crash":                               {"type": "ErrorOnly", "platform": "both"},
    "BackGroundKill":                      {"type": "ErrorOnly", "platform": "ios"},
    "VideoPlayFail":                       {"type": "ErrorOnly", "platform": "both"},
    "ImageLoadFail":                       {"type": "ErrorOnly", "platform": "both"},
    "PAGLoadFail":                         {"type": "ErrorOnly", "platform": "both"},
    "XGPush":                              {"type": "ErrorOnly", "platform": "both"},
    "GameZoneLaunchOtherGameFail":         {"type": "ErrorOnly", "platform": "both"},
    "ZTParamMissing":                      {"type": "ErrorOnly", "platform": "ios"},
    "JumpSchemaWhitelist":                 {"type": "ErrorOnly", "platform": "ios"},
    "OneApi":                              {"type": "ErrorOnly", "platform": "both"},
    "ExchangeUrl":                         {"type": "ErrorOnly", "platform": "both"},
    "FlutterErrorReport":                  {"type": "ErrorOnly", "platform": "both"},
    "FlutterImageLoadFail":                {"type": "ErrorOnly", "platform": "both"},
    "FlutterVideoPlayError":               {"type": "ErrorOnly", "platform": "both"},
    "FlutterSSEError":                     {"type": "ErrorOnly", "platform": "both"},
    "FlutterDataParseError":               {"type": "ErrorOnly", "platform": "both"},
    "FlutterViewErrorShow":                {"type": "ErrorOnly", "platform": "both"},
    # UserAction-Low
    "Pay":                                 {"type": "UserAction-Low", "platform": "both"},
    "VideoPay":                            {"type": "UserAction-Low", "platform": "both"},
    "FeedBack":                            {"type": "UserAction-Low", "platform": "both"},
    "Register":                            {"type": "UserAction-Low", "platform": "both"},
    "QRScan":                              {"type": "UserAction-Low", "platform": "both"},
    "SplashAd":                            {"type": "UserAction-Low", "platform": "both"},
    "AppStoreUrlOpen":                     {"type": "UserAction-Low", "platform": "ios"},
    "BigImage":                            {"type": "UserAction-Low", "platform": "both"},
    "SelfFullUpdate":                      {"type": "UserAction-Low", "platform": "android"},
    "FlutterListLoad":                     {"type": "UserAction-Low", "platform": "both"},
    "FlutterConch":                        {"type": "UserAction-Low", "platform": "both"},
    "FlutterGestureRecognize":             {"type": "UserAction-Low", "platform": "both"},
}

SKIP_MODULES = {
    "galileoFirstTraceWithParams", "galileoFirstLogWithParams", "galileoFirstLog",
    "history", "cmd", "LogStatistic", "OneAPIResponse", "SpanStatistic",
    "DeviceInfo", "Shiply",
}


# ── Galileo CLI 封装 ──────────────────────────────────────────────
def galileo_analyze_tags(target: str, query: str, start: str, end: str,
                          tag: str) -> dict[str, int]:
    """
    调用 galileo logs analyze tags，返回 {tag_value: count} 字典。
    注意：版本号用 ':suffix' 分词匹配，不用 '=fullversion'。
    """
    input_json = json.dumps({
        "start": start,
        "end": end,
        "target": target,
        "namespace": "Production",
        "tags": [tag],
    })
    cmd = ["galileo", "logs", "analyze", "tags",
           "--query", query, "--input", input_json]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
        data = json.loads(result.stdout)
        counts = {}
        for item in data.get("template_datas", []):
            tag_val = item.get("tags", {}).get(tag, "")
            if tag_val:  # 跳过无 tag 的聚合桶
                counts[tag_val] = counts.get(tag_val, 0) + item["count"]
        return counts
    except Exception as e:
        print(f"  ⚠️  查询失败 [{target}] {query[:60]}...: {e}", file=sys.stderr)
        return {}


def version_key(v: str) -> tuple:
    """把版本号转为可比较的 tuple，如 '10.112.0520' → (10, 112, 520)"""
    return tuple(int(p) if p.isdigit() else 0 for p in re.split(r"[.\-]", v))


def version_suffix(v: str) -> str:
    """取版本号最后一段用于分词匹配，如 '10.112.0520' → '0520'"""
    return v.split(".")[-1]


# ── 版本识别 ──────────────────────────────────────────────────────
def identify_stable_version(target: str, date_str: str) -> Optional[str]:
    """
    识别现网稳定版本 = AutoLogin 量最大的版本。
    几乎不会出错，有数据就能找到。
    """
    gray_start = f"{date_str}T00:00:00+08:00"
    gray_end   = f"{date_str}T23:59:59+08:00"

    counts = galileo_analyze_tags(
        target=target,
        query="tags.moduleName=AutoLogin",
        start=gray_start, end=gray_end,
        tag="cClientVersionName",
    )
    if not counts:
        return None
    return max(counts, key=lambda v: counts[v])


def identify_gray_version(target: str, date_str: str,
                           stable_version: str) -> Optional[str]:
    """
    在已知稳定版本的基础上，识别灰度版本：
    比稳定版本版本号更新，且 AutoLogin ≥ GRAY_MIN_AUTOLOGIN[target]。
    不存在则返回 None（当前无灰度，属正常阶段性状态）。
    """
    min_autologin = GRAY_MIN_AUTOLOGIN.get(target, 300)
    gray_start = f"{date_str}T00:00:00+08:00"
    gray_end   = f"{date_str}T23:59:59+08:00"

    counts = galileo_analyze_tags(
        target=target,
        query="tags.moduleName=AutoLogin",
        start=gray_start, end=gray_end,
        tag="cClientVersionName",
    )
    if not counts:
        return None

    gray_candidates = [
        v for v, c in counts.items()
        if version_key(v) > version_key(stable_version) and c >= min_autologin
    ]
    if not gray_candidates:
        return None
    return max(gray_candidates, key=version_key)


# ── 模块扫描 ──────────────────────────────────────────────────────
def scan_all_modules(target: str, gray_suffix: str, date_str: str) -> set[str]:
    """扫描灰度版本中所有上报过的 module，过滤跳过项。"""
    gray_start = f"{date_str}T00:00:00+08:00"
    gray_end   = f"{date_str}T23:59:59+08:00"
    counts = galileo_analyze_tags(
        target=target,
        query=f"tags.cClientVersionName:{gray_suffix}",
        start=gray_start, end=gray_end,
        tag="moduleName",
    )
    return set(counts.keys()) - SKIP_MODULES


# ── 单 module 查询 ────────────────────────────────────────────────
def query_module_count(target: str, module: str, suffix: str,
                        start: str, end: str) -> int:
    """
    查询某 module 在指定版本 + 时间窗口内的总上报量。
    直接使用响应中的 log_count，失败自动重试 MAX_RETRIES 次。
    """
    input_json = json.dumps({
        "start": start, "end": end, "target": target,
        "namespace": "Production", "tags": ["logName"],
    })
    cmd = ["galileo", "logs", "analyze", "tags",
           "--query", f"tags.moduleName={module} AND tags.cClientVersionName:{suffix}",
           "--input", input_json]
    for attempt in range(MAX_RETRIES):
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
            if not result.stdout.strip():
                raise ValueError("empty response")
            return json.loads(result.stdout).get("log_count", 0)
        except Exception as e:
            if attempt < MAX_RETRIES - 1:
                time.sleep(1 + attempt)  # 递增等待
            else:
                print(f"  ⚠️  查询失败 [{target}] {module} {suffix}: {e}", file=sys.stderr)
    return 0


def query_module_error_count(target: str, module: str, suffix: str,
                              start: str, end: str) -> int:
    """查询某 module 在指定版本 + 时间窗口内的错误上报量（status < 0），失败自动重试。"""
    input_json = json.dumps({
        "start": start, "end": end, "target": target,
        "namespace": "Production", "tags": ["status"],
    })
    cmd = ["galileo", "logs", "analyze", "tags",
           "--query", f"tags.moduleName={module} AND tags.cClientVersionName:{suffix} AND tags.status < 0",
           "--input", input_json]
    for attempt in range(MAX_RETRIES):
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
            if not result.stdout.strip():
                raise ValueError("empty response")
            return json.loads(result.stdout).get("log_count", 0)
        except Exception as e:
            if attempt < MAX_RETRIES - 1:
                time.sleep(1 + attempt)
            else:
                print(f"  ⚠️  错误查询失败 [{target}] {module} {suffix}: {e}", file=sys.stderr)
    return 0


# ── 状态判断 ──────────────────────────────────────────────────────
def get_status(behavior_type: str, gray_count: int, delta: Optional[float]) -> str:
    if gray_count == 0:
        if behavior_type == "AlwaysTriggered":
            return "❌ 异常（0条，需排查）"
        elif behavior_type == "UserAction-High":
            return "🟡 未触发（UserAction，可接受）"
        elif behavior_type == "ErrorOnly":
            return "✅ 正常（无错误上报）"
        else:
            return "✅ 正常（低频，未触发）"

    if 0 < gray_count < MIN_COUNT_FOR_COMPARISON:
        return "✅ 有触发（量级过低，不计偏差）"

    if delta is None:
        return "✅ 有上报（无现网基准）"

    if delta > ALERT_THRESHOLD:
        return f"⚠️ 触发率偏高 ({delta:+.1%})"
    elif delta < -ALERT_THRESHOLD:
        if behavior_type in ("UserAction-Low", "ErrorOnly"):
            return "✅ 正常"
        return f"⚠️ 触发率偏低 ({delta:+.1%})"
    return "✅ 正常"


# ── 平台报告生成 ──────────────────────────────────────────────────
def generate_platform_report(platform: str, target: str, date_str: str,
                              override_gray: Optional[str] = None) -> str:
    gray_start = f"{date_str}T00:00:00+08:00"
    gray_end   = f"{date_str}T23:59:59+08:00"
    prev_start = f"{date_str}T12:00:00+08:00"
    prev_end   = f"{date_str}T12:04:59+08:00"

    print(f"\n{'='*60}", file=sys.stderr)
    print(f"🔍 {platform} ({target})", file=sys.stderr)

    # Step 1：识别版本
    if override_gray:
        # 手动指定灰度版本时，stable = 除 gray 外 AutoLogin 最多的版本
        print(f"  [手动覆盖] 灰度版本：{override_gray}", file=sys.stderr)
        gray_start_tmp = f"{date_str}T00:00:00+08:00"
        gray_end_tmp   = f"{date_str}T23:59:59+08:00"
        all_counts = galileo_analyze_tags(
            target=target, query="tags.moduleName=AutoLogin",
            start=gray_start_tmp, end=gray_end_tmp, tag="cClientVersionName",
        )
        candidates = {v: c for v, c in all_counts.items() if v != override_gray}
        stable_version = max(candidates, key=lambda v: candidates[v]) if candidates else None
        gray_version   = override_gray if stable_version else None
    else:
        stable_version = identify_stable_version(target, date_str)
        gray_version   = identify_gray_version(target, date_str, stable_version) if stable_version else None

    emoji = "📱" if platform == "iOS" else "🤖"

    if not stable_version:
        return (f"## {emoji} {platform} 全量 Module 灰度巡检报告\n"
                f"**日期**：{date_str}\n\n"
                f"⚠️ 无法获取版本数据（AutoLogin 查询返回空），跳过本次巡检。\n")

    if not gray_version:
        min_autologin = GRAY_MIN_AUTOLOGIN.get(target, 300)
        return (f"## {emoji} {platform} 全量 Module 灰度巡检报告\n"
                f"**日期**：{date_str}\n"
                f"**现网稳定版本**：{stable_version}\n\n"
                f"ℹ️ 当前无灰度版本（未发现比 {stable_version} 更新且 AutoLogin ≥ {min_autologin} 的版本），本次跳过模块对比巡检。\n")

    gray_suffix = version_suffix(gray_version)
    prev_suffix = version_suffix(stable_version)
    print(f"  灰度版本：{gray_version}（suffix: {gray_suffix}）", file=sys.stderr)
    print(f"  现网版本：{stable_version}（suffix: {prev_suffix}）", file=sys.stderr)

    # Step 1：归一化基数
    print(f"  查询归一化基数...", file=sys.stderr)
    gray_autologin   = query_module_count(target, "AutoLogin",   gray_suffix, gray_start, gray_end)
    gray_manuallogin = query_module_count(target, "ManualLogin", gray_suffix, gray_start, gray_end)
    prev_autologin   = query_module_count(target, "AutoLogin",   prev_suffix, prev_start, prev_end)
    prev_manuallogin = query_module_count(target, "ManualLogin", prev_suffix, prev_start, prev_end)
    gray_base = gray_autologin + gray_manuallogin
    prev_base = prev_autologin + prev_manuallogin
    print(f"  灰度基数：{gray_base}  现网基数：{prev_base}", file=sys.stderr)

    # Step 1.5：扫描灰度版本全量 module
    print(f"  扫描灰度版本全量 module...", file=sys.stderr)
    all_modules  = scan_all_modules(target, gray_suffix, date_str)
    known_in_gray = {m for m in all_modules if m in KNOWN_MODULES}
    new_modules   = {m for m in all_modules if m not in KNOWN_MODULES}
    print(f"  发现 {len(all_modules)} 个 module（已知 {len(known_in_gray)}，新发现 {len(new_modules)}）", file=sys.stderr)

    # 确保基础 module 在查询列表中（即使 scan 没扫到）
    base_modules = {"AutoLogin", "ManualLogin"}
    modules_to_query = (all_modules - base_modules)  # base 已在 Step 1 查过

    # Step 2：并行查询所有 module × 2 版本
    print(f"  并行查询 {len(modules_to_query)} 个 module × 2 版本...", file=sys.stderr)
    gray_counts: dict[str, int] = {"AutoLogin": gray_autologin, "ManualLogin": gray_manuallogin}
    prev_counts: dict[str, int] = {"AutoLogin": prev_autologin, "ManualLogin": prev_manuallogin}
    gray_error_counts: dict[str, int] = {
        "AutoLogin":   query_module_error_count(target, "AutoLogin",   gray_suffix, gray_start, gray_end),
        "ManualLogin": query_module_error_count(target, "ManualLogin", gray_suffix, gray_start, gray_end),
    }
    prev_error_counts: dict[str, int] = {
        "AutoLogin":   query_module_error_count(target, "AutoLogin",   prev_suffix, prev_start, prev_end),
        "ManualLogin": query_module_error_count(target, "ManualLogin", prev_suffix, prev_start, prev_end),
    }

    def query_both(module: str) -> tuple[str, int, int, int, int]:
        g  = query_module_count(target, module, gray_suffix, gray_start, gray_end)
        p  = query_module_count(target, module, prev_suffix, prev_start, prev_end)
        ge = query_module_error_count(target, module, gray_suffix, gray_start, gray_end)
        pe = query_module_error_count(target, module, prev_suffix, prev_start, prev_end)
        return module, g, p, ge, pe

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(query_both, m): m for m in modules_to_query}
        for future in as_completed(futures):
            module, g, p, ge, pe = future.result()
            gray_counts[module]       = g
            prev_counts[module]       = p
            gray_error_counts[module] = ge
            prev_error_counts[module] = pe
            print(f"    ✓ {module}: 灰度={g:,}(err={ge:,}), 现网5min={p:,}(err={pe:,})", file=sys.stderr)

    # Step 3：计算触发率 + 偏差，生成行数据
    def make_row(module: str) -> dict:
        gray_count = gray_counts.get(module, 0)
        prev_count = prev_counts.get(module, 0)
        btype = KNOWN_MODULES.get(module, {}).get("type", "未知")

        gray_rate = gray_count / gray_base if gray_base > 0 else 0.0

        no_comparison = btype in ("UserAction-Low", "ErrorOnly")

        if no_comparison:
            prev_count_disp = "—"
            prev_rate_disp  = "—"
            delta_disp      = "—"
            delta           = None
        elif prev_base == 0:
            prev_count_disp = "—（现网无数据）"
            prev_rate_disp  = "—（现网无数据）"
            delta_disp      = "—"
            delta           = None
        else:
            prev_rate = prev_count / prev_base
            prev_count_disp = str(prev_count)
            prev_rate_disp  = f"{prev_rate:.3f}"
            if gray_count < MIN_COUNT_FOR_COMPARISON:
                delta_disp = "—（量级过低）"
                delta      = None
            elif prev_count == 0:
                delta_disp = "新增（无历史基准）"
                delta      = None
            else:
                delta = (gray_rate - prev_rate) / prev_rate
                delta_disp = f"{delta:+.1%}"

        status = get_status(btype, gray_count, delta if not no_comparison else None)

        return {
            "module":      module,
            "type":        btype,
            "gray_count":  f"{gray_count:,}",
            "gray_rate":   f"{gray_rate:.3f}",
            "prev_count":  prev_count_disp,
            "prev_rate":   prev_rate_disp,
            "delta":       delta_disp,
            "status":      status,
            "_delta_val":  delta,           # 原始值供统计用
            "_gray_count": gray_count,
        }

    # 已知模块按知识库顺序排列，新发现模块按灰度量降序
    known_rows = []
    for module in KNOWN_MODULES:
        if module in gray_counts:
            known_rows.append(make_row(module))

    new_rows = sorted(
        [make_row(m) for m in new_modules],
        key=lambda r: r["_gray_count"], reverse=True
    )

    # 错误率对比行（已知 + 新发现，过滤全 0）
    all_modules_in_report = list(KNOWN_MODULES.keys()) + sorted(new_modules)
    error_rows = [
        row for m in all_modules_in_report
        if m in gray_counts
        for row in [make_error_row(m)]
        if row is not None
    ]

    # Step 4：汇总结论
    anomalies = [r for r in known_rows if r["status"].startswith("❌")]
    warnings  = [r for r in known_rows if r["status"].startswith("⚠️")]
    zero_always = [r for r in known_rows
                   if r["type"] == "AlwaysTriggered" and r["_gray_count"] == 0]

    if anomalies:
        overall = f"❌ 有 {len(anomalies)} 个异常"
    elif warnings:
        overall = f"⚠️ 有 {len(warnings)} 个关注项"
    else:
        overall = "✅ 正常"

    # ── 表格渲染 ──
    # ── 错误率对比行 ──
    def make_error_row(module: str) -> Optional[dict]:
        gray_err  = gray_error_counts.get(module, 0)
        prev_err  = prev_error_counts.get(module, 0)
        if gray_err == 0 and prev_err == 0:
            return None  # 两侧均无错误，不展示

        gray_err_rate = gray_err / gray_base if gray_base > 0 else 0.0
        btype = KNOWN_MODULES.get(module, {}).get("type", "未知")
        no_comparison = btype in ("UserAction-Low",)

        if no_comparison or prev_base == 0:
            prev_err_disp      = "—"
            prev_err_rate_disp = "—"
            delta_disp         = "—"
            delta              = None
        else:
            prev_err_rate = prev_err / prev_base
            prev_err_disp = str(prev_err)
            prev_err_rate_disp = f"{prev_err_rate:.3f}"
            if gray_err < MIN_COUNT_FOR_COMPARISON:
                delta_disp = "—（量级过低）"
                delta      = None
            elif prev_err == 0:
                delta_disp = "新增（现网无错误）"
                delta      = None
            else:
                delta = (gray_err_rate - prev_err_rate) / prev_err_rate
                delta_disp = f"{delta:+.1%}"

        # 状态
        if gray_err == 0:
            status = "✅ 灰度无错误"
        elif prev_err == 0 and gray_err >= MIN_COUNT_FOR_COMPARISON:
            status = "⚠️ 灰度新增错误（现网无）"
        elif delta is not None and delta > ALERT_THRESHOLD:
            status = f"⚠️ 错误率偏高 ({delta:+.1%})"
        elif delta is not None and delta < -ALERT_THRESHOLD:
            status = f"✅ 错误率降低 ({delta:+.1%})"
        else:
            status = "✅ 正常"

        return {
            "module":          module,
            "gray_err":        f"{gray_err:,}",
            "gray_err_rate":   f"{gray_err_rate:.3f}",
            "prev_err":        prev_err_disp,
            "prev_err_rate":   prev_err_rate_disp,
            "delta":           delta_disp,
            "status":          status,
            "_delta_val":      delta,
            "_gray_err":       gray_err,
        }

    def render_error_table(rows: list[dict]) -> str:
        if not rows:
            return "_所有 Module 均无错误上报_\n"
        header = "| 模块 | 灰度错误上报量 | 灰度错误触发率 | 现网错误上报量(5min) | 现网错误触发率(5min) | 偏差 | 状态 |\n"
        sep    = "|------|-------------|-------------|-------------------|-------------------|------|------|\n"
        body   = "".join(
            f"| {r['module']} | {r['gray_err']} | {r['gray_err_rate']} "
            f"| {r['prev_err']} | {r['prev_err_rate']} | {r['delta']} | {r['status']} |\n"
            for r in rows
        )
        return header + sep + body
        if not rows:
            return "_无数据_\n"
        header = "| 模块 | 行为类型 | 灰度上报量 | 灰度触发率 | 现网上报量(5min) | 现网触发率(5min) | 偏差 | 状态 |\n"
        sep    = "|------|---------|-----------|-----------|----------------|----------------|------|------|\n"
        body   = "".join(
            f"| {r['module']} | {r['type']} | {r['gray_count']} | {r['gray_rate']} "
            f"| {r['prev_count']} | {r['prev_rate']} | {r['delta']} | {r['status']} |\n"
            for r in rows
        )
        return header + sep + body

    emoji = "📱" if platform == "iOS" else "🤖"
    report = f"""## {emoji} {platform} 全量 Module 灰度巡检报告
**日期**：{date_str}
**灰度版本**：{gray_version} | **对比现网版本**：{stable_version}
**扫描 Module 数**：{len(all_modules)} 个（知识库已知 {len(known_in_gray)}，新发现 {len(new_modules)}）
**归一化基数**：灰度 {gray_base:,} 条（AutoLogin {gray_autologin:,} + ManualLogin {gray_manuallogin:,}）| 现网 {prev_base:,} 条（AutoLogin {prev_autologin:,} + ManualLogin {prev_manuallogin:,}）

---

### 已知 Module 触发率对比

{render_table(known_rows)}
### 新发现 Module 触发率对比

{"_无新发现模块_" if not new_rows else render_table(new_rows)}

### 错误率对比

{render_error_table(error_rows)}

### 💡 {platform} 结论

- **整体状态**：{overall}
- **0条异常**：{', '.join(r['module'] for r in zero_always) if zero_always else '无'}
- **触发率异常**：{', '.join(r['module'] for r in warnings) if warnings else '无'}
- **新发现模块**：{', '.join(r['module'] for r in new_rows[:5]) + ('...' if len(new_rows) > 5 else '') if new_rows else '无'}
"""
    return report


# ── 主入口 ────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="全量 Module 灰度保障每日巡检")
    parser.add_argument("--date", default=None,
                        help="分析日期，格式 YYYY-MM-DD（默认昨天）")
    parser.add_argument("--gray-version", default=None,
                        help="手动指定灰度版本号，覆盖自动识别（如 10.112.0520）。"
                             "自动识别不准确时使用，两个平台统一指定同一版本。")
    args = parser.parse_args()

    if args.date:
        date_str = args.date
    else:
        date_str = (date.today() - timedelta(days=1)).strftime("%Y-%m-%d")

    print(f"🔬 全量 Module 灰度保障巡检 · {date_str}", file=sys.stderr)
    if args.gray_version:
        print(f"   ⚡ 手动指定灰度版本：{args.gray_version}", file=sys.stderr)

    reports = []
    for platform, target in PLATFORMS.items():
        reports.append(generate_platform_report(
            platform, target, date_str,
            override_gray=args.gray_version,
        ))

    print("\n" + "=" * 60 + "\n")
    print(f"# 全量 Module 灰度保障巡检报告 · {date_str}\n")
    for r in reports:
        print(r)
        print("---\n")


if __name__ == "__main__":
    main()
