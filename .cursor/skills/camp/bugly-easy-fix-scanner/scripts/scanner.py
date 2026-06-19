#!/usr/bin/env python3
"""
bugly-easy-fix-scanner
从王者营地 iOS Bugly 问题中找到可直接修复的业务代码 Crash / ANR。

Crash 筛选条件：
  ✅ 有业务类名（WEG/Camp/Smoba 等）
  ✅ 类名能在 iOS 代码库（social-ios/src）中 grep 到
  ❌ 排除多线程/竞态问题
  ❌ 排除三方库/系统库崩溃
  ❌ 排除需要改 Flutter 侧代码的 crash

ANR 筛选条件：
  ✅ 有业务类名（WEG/Camp/Smoba 等）
  ✅ 类名能在 iOS 代码库中 grep 到
  ✅ 主线程堆栈含耗时操作特征词（IO/锁/大量计算）
  ❌ 排除三方库/系统库 ANR
  ❌ 排除需要改 Flutter 侧代码的 ANR
  注：ANR 不排除多线程关键词（主线程阻塞恰是 ANR 根因）

参数：
  --limit        拉取 Top N 问题（默认50）
  --hours        拉取最近 N 小时内的问题（默认24）
  --max-results  最多返回 N 个可修复问题（默认1，巡检模式传3）
  --type         问题类型：crash / anr / both（默认 both）
  --dry-run      使用 mock 数据测试
  --json         以 JSON 格式输出结果（供其他脚本/agent 消费）
"""

import os
import sys
import json
import re
import subprocess
import datetime
import argparse
from pathlib import Path

# ─── 配置 ────────────────────────────────────────────────────────────────────

PRODUCT_ID = "ef14bfff8f"
BUGLY_DETAIL_URL = (
    "https://bugly.woa.com/v2/exception/crash/issues/detail"
    "?productId={product_id}&feature={issue_id}"
)

# 代码库搜索路径：只搜索 iOS 原生代码，Flutter 侧改动不在范围内
IOS_SEARCH_PATHS = [
    Path.home() / "work_tree_bugfix/social-ios/src",
]

# 业务代码类名前缀（命中至少一个才认为是可修复的业务 crash）
BUSINESS_PREFIXES = [
    "WEG", "Camp", "Smoba", "OE", "MTA", "Widget",
    "Quality", "Video", "Multiple", "WXApi", "TXPlayer",
]

# Flutter 侧崩溃关键词（命中则跳过，需要改 Dart/Flutter 代码）
FLUTTER_KEYWORDS = [
    "FlutterViewController", "FlutterEngine", "FlutterBinaryMessenger",
    "FlutterMethodChannel", "FlutterPlugin", "FlutterBoost",
    "WEGFlutter", "WEGFlutterVC",
    "dart::", "DartVM", "flutter::",
]

# 多线程关键词（命中则跳过，不是"简单"能修的）
MULTITHREAD_KEYWORDS = [
    "pthread", "dispatch_async", "dispatch_sync",
    "NSOperationQueue", "GCD", "thread", "race condition",
    "mutex", "deadlock", "semaphore",
    "__NSDictionaryM", "__NSArrayM",  # 多线程对容器的并发读写
]

# 三方库/系统库排除模式（正则）
THIRD_PARTY_PATTERNS = [
    r"Pods/",
    r"/usr/lib/",
    r"\bFoundation\b",
    r"\bUIKit\b",
    r"\blibsystem\b",
    r"\bHippyBridge\b",
    r"\bJSContext\b",
    r"\bHippyJSExecutor\b",
    r"\bWebKit\b",
    r"\bCoreGraphics\b",
    r"\bCoreData\b",
]

# 修复建议关键词映射（标题含以下词时给出对应建议）
FIX_HINT_MAP = [
    (r"nil|reject:nil|null",        "nil 未判断，加 nil guard 或 NSError 兜底"),
    (r"unrecognized selector",      "类型错误（如 NSNumber 当 NSString 用），检查类型转换"),
    (r"objectAtIndex|insertObject", "数组越界或插入 nil，加越界/nil 检查"),
    (r"setObject|NSUserDefaults",   "字典插入 nil，过滤 nil 或用 NSNull 替代"),
    (r"NaN|position contains",      "布局计算出现 NaN，layoutSubviews 前加 isNaN 检查"),
    (r"removeObserver|KVO",         "KVO 未在 dealloc 前移除，加 removeObserver 防护"),
    (r"SIGSEGV",                    "野指针或 nil 访问，检查对象生命周期"),
    (r"length\]",                   "对非字符串对象调用 length，检查类型"),
]

BUGLY_TOKEN_FALLBACK = "54a5f8a2-495c-40e9-81f7-03d69913cc63"

# ANR 主线程耗时特征词（命中至少一个才认为是可定位根因的 ANR）
ANR_MAINTHREAD_KEYWORDS = [
    "dispatch_sync",          # 主线程同步等待子队列
    "pthread_mutex_lock",     # 加锁等待
    "semaphore_wait",         # 信号量等待
    "NSUserDefaults",         # 主线程同步写磁盘
    "writeToFile", "synchronize",  # 文件/plist 同步写
    "SQLite", "sqlite3",      # 主线程数据库操作
    "NSURLSession", "URLSession",  # 同步网络请求
    "waitUntilDone",          # performSelector:waitUntilDone:YES
    "readwrite", "fileManager",    # 主线程文件 IO
]

# ANR 修复建议关键词映射
ANR_FIX_HINT_MAP = [
    (r"dispatch_sync",              "主线程 dispatch_sync 等待子队列，改为 dispatch_async 或切换执行线程"),
    (r"pthread_mutex_lock|semaphore_wait", "主线程等锁/信号量，将加锁区域移到后台线程"),
    (r"NSUserDefaults|synchronize", "主线程同步写 NSUserDefaults，改用异步队列写入"),
    (r"writeToFile|fileManager",    "主线程文件 IO，移到后台队列（dispatch_async global）"),
    (r"SQLite|sqlite3",             "主线程数据库操作，移到专用串行队列"),
    (r"waitUntilDone",              "performSelector:waitUntilDone:YES 阻塞主线程，改为 NO 或回调方式"),
    (r"NSURLSession|URLSession",    "主线程同步网络请求，改为异步回调或 async/await"),
]

# ─── Token ───────────────────────────────────────────────────────────────────

def get_bugly_token() -> str:
    token = os.environ.get("BUGLY_USER_TOKEN", "")
    if token:
        return token
    cache_path = Path.home() / ".bugly_token_cache.json"
    if cache_path.exists():
        try:
            data = json.loads(cache_path.read_text())
            token = data.get("BUGLY_USER_TOKEN") or data.get("bugly_user_token") or data.get("token", "")
            if token:
                return token
        except Exception:
            pass
    if BUGLY_TOKEN_FALLBACK:
        return BUGLY_TOKEN_FALLBACK
    print("❌ 未找到 Bugly Token！")
    sys.exit(1)

# ─── Bugly Agent 调用 ─────────────────────────────────────────────────────────

def query_bugly_agent(message: str, thread_id: str, token: str) -> str:
    script_path = Path.home() / ".claude/skills/bugly-data-analyzer/scripts/query_agent.py"
    if not script_path.exists():
        print(f"❌ 未找到 query_agent.py: {script_path}")
        sys.exit(1)
    cmd = [
        sys.executable, str(script_path),
        "--product-id", PRODUCT_ID,
        "--base-url", "http://api.bugly.woa.com",
        "--thread-id", thread_id,
        "--message", message,
    ]
    env = os.environ.copy()
    env["BUGLY_USER_TOKEN"] = token
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120, env=env)
        return result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        print("❌ Bugly Agent 请求超时（>120s）")
        sys.exit(1)
    except Exception as e:
        print(f"❌ 调用 query_agent.py 失败: {e}")
        sys.exit(1)


def build_query_message(issue_type: str, hours: int, limit: int) -> str:
    """根据类型拼装 Bugly Agent 查询消息。"""
    product_hint = f"产品ID为 {PRODUCT_ID}（王者营地 iOS）"
    if issue_type == "crash":
        return (
            f"查询{product_hint}的 Crash 问题列表，最近{hours}小时内新增或更新的，"
            f"按发生次数降序，取前{limit}条，"
            f"每条必须输出：issueId、关键崩溃方法名（类名+方法名，如 WEGProtobufRequest call:req:respType:）、发生次数。"
            f"不要只输出信号类型（SIGTRAP/SIGABRT等），要输出导致崩溃的具体类名和方法名。"
        )
    elif issue_type == "anr":
        return (
            f"查询{product_hint}的 ANR 问题列表，最近{hours}小时内新增或更新的，"
            f"按发生次数降序，取前{limit}条，"
            f"每条必须输出：issueId、ANR关键堆栈方法名（类名+方法名）、发生次数。"
        )
    else:  # both
        return (
            f"分别查询{product_hint}的 Crash 和 ANR 问题列表，各取最近{hours}小时内"
            f"按发生次数降序前{limit}条，"
            f"每条必须输出：issueId、关键方法名（类名+方法名，不要只写信号类型）、问题类型（crash/anr）、发生次数。"
        )

# ─── 解析 Crash 列表 ──────────────────────────────────────────────────────────

def _clean_title(raw: str) -> str:
    """清理 Bugly Agent 返回的标题中的 Markdown 链接、管道符、行号等噪音。"""
    # 去掉 Markdown 链接 [text](url) → text；纯链接 [](url) → ''
    raw = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', raw)
    # 去掉裸 URL
    raw = re.sub(r'https?://\S+', '', raw)
    # 去掉管道符和多余标点
    raw = re.sub(r'[|｜]+', ' ', raw)
    # 去掉行首行尾序号（如 "3 " 或 "| 3 |"）
    raw = re.sub(r'^\s*\d+\s+', '', raw)
    # 把 `req:respType:` 还原（空格是解析时引入的，不影响类名识别）
    raw = re.sub(r'\s+', ' ', raw).strip()
    return raw


def parse_crash_list(raw_output: str) -> list[dict]:
    crashes = []

    # 模式 1：JSON 数组
    json_match = re.search(r'\[(\s*\{.*?\}\s*,?\s*)+\]', raw_output, re.DOTALL)
    if json_match:
        try:
            data = json.loads(json_match.group(0))
            for item in data:
                issue_id = item.get("issueId") or item.get("issue_id") or item.get("id", "")
                title = item.get("title") or item.get("crashName") or item.get("name", "")
                count = int(item.get("count") or item.get("happenTimes") or item.get("times", 0))
                issue_type = item.get("issue_type") or item.get("type", "crash")
                if issue_id:
                    crashes.append({"issue_id": issue_id, "title": title, "count": count, "issue_type": issue_type})
            if crashes:
                return crashes
        except Exception:
            pass

    # 模式 2：表格行解析（优先，适配 Bugly Agent 返回 markdown 表格）
    issue_id_pattern = re.compile(r'\b([0-9A-Fa-f]{32})\b')
    anr_pattern = re.compile(r'\bANR\b', re.IGNORECASE)

    for line in raw_output.split("\n"):
        id_match = issue_id_pattern.search(line)
        if not id_match:
            continue
        current_id = id_match.group(1)

        # 尝试以 | 分割表格列，提取标题和次数
        if "|" in line:
            cols = [c.strip() for c in line.split("|") if c.strip()]
            # cols 顺序通常：行号, issueId（含链接）, 标题/方法名, 次数
            title_raw = ""
            count = 0
            for i, col in enumerate(cols):
                if current_id in col:
                    # 标题在下一列
                    if i + 1 < len(cols):
                        title_raw = cols[i + 1]
                    # 次数在再下一列或末列
                    for j in range(i + 2, len(cols)):
                        m = re.search(r'(\d[\d,]*)', cols[j])
                        if m:
                            count = int(m.group(1).replace(",", ""))
                            break
                    break
            if not title_raw:
                # issueId 在第一列且没有 | 之后，取整行剩余部分
                title_raw = line.replace(current_id, "")
            title = _clean_title(title_raw)
        else:
            # 无表格，直接处理整行
            title_raw = line.replace(current_id, "")
            title_raw = re.sub(r'issueId\s*[:：]?\s*', '', title_raw, flags=re.IGNORECASE)
            title = _clean_title(title_raw)
            count = 0
            c_match = re.search(r'(\d[\d,]*)\s*(?:次|times|count|happenTimes)', line, re.IGNORECASE)
            if c_match:
                count = int(c_match.group(1).replace(",", ""))

        issue_type = "anr" if anr_pattern.search(line) else "crash"
        crashes.append({"issue_id": current_id, "title": title, "count": count, "issue_type": issue_type})

    return crashes

# ─── 过滤函数 ─────────────────────────────────────────────────────────────────

def has_business_prefix(title: str) -> bool:
    """标题是否含业务代码类名前缀。"""
    return any(prefix.lower() in title.lower() for prefix in BUSINESS_PREFIXES)


def has_multithread_issue(title: str) -> bool:
    """标题是否含多线程关键词。"""
    return any(kw.lower() in title.lower() for kw in MULTITHREAD_KEYWORDS)


def is_third_party_or_system(title: str) -> bool:
    """标题是否匹配三方库/系统库排除模式。"""
    return any(re.search(pat, title, re.IGNORECASE) for pat in THIRD_PARTY_PATTERNS)


def extract_class_name(title: str) -> str | None:
    """
    从 Crash 标题中提取业务类名（最长的符合命名规则的 token）。
    优先取含业务前缀的 token。
    """
    tokens = re.findall(r'[A-Za-z][A-Za-z0-9_]+', title)
    for token in tokens:
        if any(token.startswith(prefix) for prefix in BUSINESS_PREFIXES) and len(token) > 5:
            return token
    # fallback：取第一个大写开头、长度 > 5 的 token
    for token in tokens:
        if token[0].isupper() and len(token) > 5:
            return token
    return None


def has_flutter_crash(title: str) -> bool:
    """标题是否含 Flutter 侧关键词（需改 Flutter/Dart 代码，排除）。"""
    return any(kw.lower() in title.lower() for kw in FLUTTER_KEYWORDS)


def has_anr_mainthread_signal(title: str) -> bool:
    """ANR 标题是否含主线程耗时特征词（正向过滤，至少命中一个才认为可定位根因）。"""
    return any(kw.lower() in title.lower() for kw in ANR_MAINTHREAD_KEYWORDS)


def search_in_codebase(class_name: str) -> list[str]:
    """
    在 iOS 原生代码库中 grep 类名，返回命中的文件路径列表。
    只搜索 .m / .mm / .swift 文件（不搜 Flutter 的 .dart）。
    """
    results = []
    for search_path in IOS_SEARCH_PATHS:
        if not search_path.exists():
            continue
        try:
            cmd = [
                "grep", "-rl",
                "--include=*.m", "--include=*.mm", "--include=*.swift",
                class_name, str(search_path),
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
            if result.returncode == 0:
                for line in result.stdout.strip().splitlines():
                    if line:
                        results.append(line)
        except Exception:
            pass
    return results

# ─── 修复建议 ─────────────────────────────────────────────────────────────────

def generate_fix_hint(title: str, issue_type: str = "crash") -> str:
    hint_map = ANR_FIX_HINT_MAP if issue_type == "anr" else FIX_HINT_MAP
    for pattern, hint in hint_map:
        if re.search(pattern, title, re.IGNORECASE):
            return hint
    if issue_type == "anr":
        return "主线程阻塞，定位耗时操作后移到后台队列"
    return "查看堆栈上下文，定位 nil/越界/类型错误后加 guard"

# ─── 输出 ─────────────────────────────────────────────────────────────────────

def format_found(crash: dict, class_name: str, matched_files: list[str], index: int = 1) -> dict:
    """返回结构化结果 dict，可用于文本输出或 JSON 输出。"""
    issue_type = crash.get("issue_type", "crash")
    url = BUGLY_DETAIL_URL.format(product_id=PRODUCT_ID, issue_id=crash["issue_id"])
    hint = generate_fix_hint(crash["title"], issue_type)
    file_display = matched_files[0] if matched_files else ""
    return {
        "index": index,
        "issue_type": issue_type,
        "issue_id": crash["issue_id"],
        "title": crash["title"],
        "count": crash["count"],
        "class_name": class_name,
        "matched_files": matched_files,
        "file_display": file_display,
        "fix_hint": hint,
        "url": url,
    }


def print_found_item(item: dict, total: int):
    extra = f"（共 {len(item['matched_files'])} 处）" if len(item["matched_files"]) > 1 else ""
    issue_type = item.get("issue_type", "crash").upper()
    print()
    print(f"✅ 可修复 {issue_type} [{item['index']}/{total}]")
    print()
    print(f"📋 {issue_type} 信息")
    print(f"  issueId : {item['issue_id']}")
    print(f"  标题    : {item['title']}")
    print(f"  次数    : {item['count']:,} 次")
    print()
    print("📂 代码定位")
    print(f"  类名    : {item['class_name']}")
    print(f"  文件    : {item['file_display']}{extra}")
    print()
    print("🔧 修复方向")
    print(f"  {item['fix_hint']}")
    print()
    print(f"🔗 Bugly 链接：{item['url']}")
    print()


def print_not_found(stats: dict):
    print()
    print("⚠️  本次未找到满足条件的可修复 Crash / ANR")
    print("原因统计：")
    for reason, count in stats.items():
        print(f"  - {reason}：{count} 条")
    print("建议：适当放宽过滤条件或增加扫描数量（--limit 100）")
    print()

# ─── 主流程 ───────────────────────────────────────────────────────────────────

MOCK_DATA = """
issueId: 37224C7189B0DE44C01CFC046961AEAD  WEGProtobufRequest FBLPromise reject nil  5995次
issueId: 3AB2D4434687EB6A81DBBB012B09AFAA  HippyAnimatedImage imageAtFrame nil  71次
issueId: AF460D225196B9F3E04FF131FCA59553  WEGSyncTask -[__NSCFBoolean length]  70次
issueId: C2936082161FB0DE3D76827D77E90FE6  VideoTrimmer NaN position  66次
issueId: C7E00240D6808E43DC2C1C3EE03821E1  QualityDataUploader nil插入字典  56次
issueId: 0BC182C61B1CF5353B98BE3EA3975A0C  MTAManager currentGameRole pthread_mutex  68次
issueId: 9D28377CF5A264DB384431CE93C44567  HippyJSExecutor callScript EXC_BAD_ACCESS  65次
issueId: 8DBE1F6A6EE054B08F483170BF333E76  WidgetDataBridge assert update  51次
issueId: FF222E7F6A5E16DB06DF4A5A4982E92F  WEGLogHelper XloggerAppender SIGSEGV  91次
issueId: D52B67187E5F21F210B64B61B2800730  MultipleChatMessageViewController _myAppUser nil  43次
ANR issueId: A1b2C3d4E5f6A1b2C3d4E5f6A1b2C3d4  WEGRoomViewController dispatch_sync NSUserDefaults  ANR 38次
ANR issueId: F1e2D3c4B5a6F1e2D3c4B5a6F1e2D3c4  CampHomeViewController writeToFile sqlite3  ANR 22次
"""


def main():
    parser = argparse.ArgumentParser(description="Bugly Easy Fix Scanner - 找可修复 Crash / ANR")
    parser.add_argument("--limit", type=int, default=50, help="拉取 Top N 问题（默认50）")
    parser.add_argument("--hours", type=int, default=24, help="拉取最近 N 小时内的问题（默认24）")
    parser.add_argument("--max-results", type=int, default=1, dest="max_results",
                        help="最多返回 N 个可修复问题（默认1，巡检模式传3）")
    parser.add_argument("--type", default="both", choices=["crash", "anr", "both"],
                        help="问题类型：crash / anr / both（默认 both）")
    parser.add_argument("--dry-run", action="store_true", help="使用 mock 数据测试")
    parser.add_argument("--json", action="store_true", help="以 JSON 格式输出结果")
    args = parser.parse_args()

    token = get_bugly_token()

    if args.dry_run:
        print("⚠️  Dry-run 模式，使用 mock 数据")
        raw_output = MOCK_DATA
    else:
        type_label = {"crash": "Crash", "anr": "ANR", "both": "Crash + ANR"}[args.type]
        print(f"🔍 正在调用 Bugly Agent 拉取最近 {args.hours}h Top {args.limit} {type_label}...")
        thread_id = f"easy-fix-scan-{datetime.datetime.now().strftime('%Y%m%d%H%M')}"
        message = build_query_message(args.type, args.hours, args.limit)
        raw_output = query_bugly_agent(message, thread_id, token)

    all_issues = parse_crash_list(raw_output)

    # 按 --type 过滤：only keep relevant types
    if args.type != "both":
        all_issues = [i for i in all_issues if i.get("issue_type", "crash") == args.type]

    print(f"✅ 解析到 {len(all_issues)} 条问题，开始筛选（目标：最多 {args.max_results} 个）...")

    if not all_issues:
        print("❌ 未能解析到任何问题数据，请检查 Bugly Agent 输出")
        print(raw_output[:2000])
        sys.exit(1)

    stats = {
        "非业务代码": 0,
        "Flutter 侧代码": 0,
        "多线程问题（仅 Crash）": 0,
        "ANR 无主线程特征": 0,
        "三方库/系统": 0,
        "代码库未找到": 0,
    }

    found_items = []

    for issue in all_issues:
        if len(found_items) >= args.max_results:
            break

        title = issue.get("title", "")
        issue_type = issue.get("issue_type", "crash")

        # 1. 必须含业务前缀
        if not has_business_prefix(title):
            stats["非业务代码"] += 1
            continue

        # 2. 排除 Flutter 侧问题
        if has_flutter_crash(title):
            stats["Flutter 侧代码"] += 1
            continue

        # 3. Crash：排除多线程问题；ANR：改为正向过滤需含主线程耗时特征词
        if issue_type == "crash":
            if has_multithread_issue(title):
                stats["多线程问题（仅 Crash）"] += 1
                continue
        else:  # anr
            if not has_anr_mainthread_signal(title):
                stats["ANR 无主线程特征"] += 1
                continue

        # 4. 排除三方库/系统库
        if is_third_party_or_system(title):
            stats["三方库/系统"] += 1
            continue

        # 5. 提取类名并在代码库中搜索
        class_name = extract_class_name(title)
        if not class_name:
            stats["代码库未找到"] += 1
            continue

        matched_files = search_in_codebase(class_name)
        if not matched_files:
            stats["代码库未找到"] += 1
            continue

        # 通过所有筛选，记录结果
        item = format_found(issue, class_name, matched_files, index=len(found_items) + 1)
        found_items.append(item)

    if found_items:
        if args.json:
            print(json.dumps(found_items, ensure_ascii=False, indent=2))
        else:
            type_label = {"crash": "Crash", "anr": "ANR", "both": "Crash / ANR"}[args.type]
            print(f"\n🎯 共找到 {len(found_items)} 个可修复 {type_label}：")
            for item in found_items:
                print_found_item(item, total=len(found_items))
    else:
        if args.json:
            print(json.dumps([], ensure_ascii=False))
        else:
            print_not_found(stats)


if __name__ == "__main__":
    main()
