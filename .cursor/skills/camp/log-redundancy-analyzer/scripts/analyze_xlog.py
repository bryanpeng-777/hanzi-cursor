#!/usr/bin/env python3
"""
xlog 日志冗余性分析工具

日志格式:
  [LEVEL][TIMESTAMP][THREAD][TAG][FILE, METHOD, LINE][MESSAGE...]

聚类策略: 按调用位置 (file, method, line) 聚类，计算频次、消息模板多样性、突发强度。

用法:
  python analyze_xlog.py <log_file>
  python analyze_xlog.py <log_file> --top 50 --min-count 20 -o report.md
  python analyze_xlog.py <log_file> --filter OTTraceManager
"""

import re
import sys
import os
import argparse
from collections import defaultdict, Counter
from datetime import datetime

# ──────────────────────────────────────────────────────────────────────────────
# 正则
# ──────────────────────────────────────────────────────────────────────────────

# 匹配日志头部四个固定字段
HEADER_RE = re.compile(
    r'^\[([IDWEF])\]'    # [1] 日志级别
    r'\[([^\]]+)\]'      # [2] 时间戳
    r'\[([^\]]+)\]'      # [3] 进程/线程
    r'\[([^\]]+)\]'      # [4] Tag
    r'(.*)'              # [5] 剩余部分 (callsite + message)
)

# 从剩余部分提取调用位置: [CONTENT, LINE_NUM][MESSAGE...
# 使用贪婪匹配找到最后一个 ", 数字][" 组合（即 line number 之前的内容）
CALLSITE_RE = re.compile(
    r'^\[(.+),\s*(\d{1,6})\]\[(.*)',
    re.DOTALL
)

TIMESTAMP_RE = re.compile(r'(\d{4}-\d{2}-\d{2}) [+-]\d+ (\d{2}:\d{2}:\d{2})')

# ──────────────────────────────────────────────────────────────────────────────
# 消息模板归一化：把变量部分替换为占位符，保留结构
# ──────────────────────────────────────────────────────────────────────────────

TEMPLATE_SUBS = [
    # 超长 base64/二进制数据（先处理，避免被后面规则误处理）
    (re.compile(r'[A-Za-z0-9+/]{80,}={0,2}'), '<DATA>'),
    # UUID
    (re.compile(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'), '<UUID>'),
    # URL（含路径）
    (re.compile(r'https?://[^\s,\]\'\"}{]+'), '<URL>'),
    # IP 地址
    (re.compile(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'), '<IP>'),
    # 长十六进制字符串（如 TraceId、token）
    (re.compile(r'\b[0-9a-fA-F]{12,}\b'), '<HEX>'),
    # 长引号字符串（token、key 等）
    (re.compile(r'"[^"]{40,}"'), '<QSTR>'),
    # 大 JSON/Dict 块
    (re.compile(r'\{[^{}]{100,}\}'), '<JSON>'),
    # 大括号嵌套结构（如 NSDictionary 打印输出）
    (re.compile(r'\{[\s\S]{200,?}\}'), '<DICT>'),
    # 长数字（8位以上，如 userId、timestamp）
    (re.compile(r'\b\d{8,}\b'), '<NUM>'),
    # 文件系统路径
    (re.compile(r'/(?:[A-Za-z0-9_\-\.]+/){2,}[A-Za-z0-9_\-\.]*'), '<PATH>'),
    # 短数字（保留语义上有价值的短数字，只去掉 4-7 位）
    (re.compile(r'\b\d{4,7}\b'), '<N>'),
]


def normalize_template(msg: str) -> str:
    """提取消息模板：保留结构，去掉变量部分。"""
    msg = msg[:600]  # 限制处理长度，避免超长消息拖慢速度
    for pattern, replacement in TEMPLATE_SUBS:
        msg = pattern.sub(replacement, msg)
    # 合并连续空白
    msg = re.sub(r'\s+', ' ', msg)
    return msg.strip()


def parse_ts_to_seconds(ts_str: str):
    """将时间戳字符串转换为 Unix 秒数，用于突发检测。"""
    m = TIMESTAMP_RE.search(ts_str)
    if m:
        try:
            dt = datetime.strptime(f"{m.group(1)} {m.group(2)}", "%Y-%m-%d %H:%M:%S")
            return dt.timestamp()
        except Exception:
            pass
    return None


# ──────────────────────────────────────────────────────────────────────────────
# 核心解析：流式读取，逐条日志 yield
# ──────────────────────────────────────────────────────────────────────────────

def stream_log_entries(path: str, show_progress: bool = True):
    """
    逐行读取 xlog 文件，yield (level, ts_sec, tag, filename, method, line_num, raw_line_count, message)。
    多行消息会被合并到 message 字段，raw_line_count 记录该条日志实际占用的文件行数。
    """
    file_size = os.path.getsize(path)
    processed_bytes = 0
    total_lines = 0

    current_meta = None   # (level, ts_sec, tag, filename, method, line_num)
    current_msg_parts = []
    current_raw_lines = 0  # 当前日志条目占用的文件行数

    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        for raw_line in f:
            total_lines += 1
            processed_bytes += len(raw_line)

            if show_progress and total_lines % 200000 == 0:
                pct = processed_bytes / file_size * 100
                elapsed = (datetime.now() - _start_time).total_seconds()
                speed = total_lines / elapsed / 1000 if elapsed > 0 else 0
                print(f"  进度 {pct:.1f}%  ({total_lines:,} 行,  {speed:.0f}k 行/s)", file=sys.stderr)

            hm = HEADER_RE.match(raw_line)
            if hm:
                # 先 yield 前一条日志
                if current_meta is not None:
                    yield (*current_meta, current_raw_lines, '\n'.join(current_msg_parts))

                level = hm.group(1)
                ts_str = hm.group(2)
                tag = hm.group(4)
                rest = hm.group(5)

                ts_sec = parse_ts_to_seconds(ts_str)

                # 解析调用位置
                cm = CALLSITE_RE.match(rest)
                if cm:
                    callsite_raw = cm.group(1)
                    line_num = cm.group(2)
                    first_msg = cm.group(3).strip()

                    # 拆分 callsite 为 filename + method
                    comma_idx = callsite_raw.find(',')
                    if comma_idx >= 0:
                        filename = callsite_raw[:comma_idx].strip()
                        method = callsite_raw[comma_idx + 1:].strip()
                    else:
                        filename = callsite_raw.strip()
                        method = ''

                    current_meta = (level, ts_sec, tag, filename, method, line_num)
                    current_msg_parts = [first_msg] if first_msg else []
                else:
                    # 无法解析 callsite，归入 unknown
                    current_meta = (level, ts_sec, tag, '', '', '0')
                    current_msg_parts = [rest.strip()]

                current_raw_lines = 1
            else:
                # 续行（属于上一条日志的 message）
                if current_meta is not None:
                    stripped = raw_line.rstrip()
                    if stripped:
                        current_msg_parts.append(stripped)
                    current_raw_lines += 1

        # 最后一条
        if current_meta is not None:
            yield (*current_meta, current_raw_lines, '\n'.join(current_msg_parts))

    if show_progress:
        elapsed = (datetime.now() - _start_time).total_seconds()
        print(f"  解析完成: {total_lines:,} 行, 耗时 {elapsed:.1f}s", file=sys.stderr)


_start_time = datetime.now()


# ──────────────────────────────────────────────────────────────────────────────
# 突发检测
# ──────────────────────────────────────────────────────────────────────────────

def max_burst_in_window(ts_list, window_sec: float = 10.0) -> int:
    """计算在 window_sec 秒窗口内的最大出现次数（滑动窗口）。"""
    if len(ts_list) < 2:
        return len(ts_list)
    ts_sorted = sorted(ts_list)
    max_b = 1
    left = 0
    for right in range(1, len(ts_sorted)):
        while ts_sorted[right] - ts_sorted[left] > window_sec:
            left += 1
        max_b = max(max_b, right - left + 1)
    return max_b


# ──────────────────────────────────────────────────────────────────────────────
# 主分析逻辑
# ──────────────────────────────────────────────────────────────────────────────

MAX_TIMESTAMPS = 3000   # 每个调用点最多存储的时间戳数量
MAX_TEMPLATES = 500     # 每个调用点最多跟踪的 unique template 数量


def analyze(path: str, filter_keyword: str = None, sample_n: int = 3,
            show_progress: bool = True):
    """
    流式分析日志文件，按调用位置聚类。
    返回: (callsite_stats dict, total_entry_count)
    """
    global _start_time
    _start_time = datetime.now()

    # key: "filename|method|line_num"
    stats = defaultdict(lambda: {
        'count': 0,
        'line_count': 0,        # 实际占用的文件行数（含续行）
        'levels': Counter(),
        'templates': Counter(),
        'timestamps': [],
        'ts_count': 0,          # 实际时间戳总数（用于说明采样情况）
        'samples': [],
        'file': '',
        'method': '',
        'line': '',
        'tag': '',
    })

    total = 0

    for level, ts_sec, tag, filename, method, line_num, raw_line_count, message in \
            stream_log_entries(path, show_progress=show_progress):

        # 按文件名关键字过滤
        if filter_keyword and filter_keyword.lower() not in filename.lower():
            continue

        total += 1
        key = f"{filename}|{method}|{line_num}"
        s = stats[key]
        s['count'] += 1
        s['line_count'] += raw_line_count
        s['levels'][level] += 1
        s['file'] = filename
        s['method'] = method
        s['line'] = line_num
        s['tag'] = tag

        # 模板（只跟踪前 MAX_TEMPLATES 个 unique）
        if len(s['templates']) < MAX_TEMPLATES or normalize_template(message) in s['templates']:
            tmpl = normalize_template(message)
            s['templates'][tmpl] += 1

        # 时间戳（蓄水池采样）
        if ts_sec is not None:
            s['ts_count'] += 1
            if len(s['timestamps']) < MAX_TIMESTAMPS:
                s['timestamps'].append(ts_sec)
            else:
                # 简单丢弃（不影响突发检测的大体准确性，因为我们已经有 MAX_TIMESTAMPS 个样本）
                pass

        # 样例消息
        if len(s['samples']) < sample_n:
            s['samples'].append(message[:400])

    return dict(stats), total


# ──────────────────────────────────────────────────────────────────────────────
# 冗余评分
# ──────────────────────────────────────────────────────────────────────────────

def redundancy_score(s: dict, window_sec: float = 10.0) -> float:
    """
    综合冗余评分（越高越冗余）。
    = count × repetition_rate × (1 + burst_bonus)

    repetition_rate: 1 表示每次消息完全相同，0 表示每次完全不同
    burst_bonus:     10s 内突发 ≥ 20 次时显著加分
    """
    count = s['count']
    unique_t = len(s['templates'])
    repetition = 1.0 - (unique_t / count)   # 0~1，越高越重复

    burst = max_burst_in_window(s['timestamps'], window_sec) if s['timestamps'] else 1
    burst_bonus = max(0.0, (burst - 5) / 20.0)   # 突发 >5 次才计入

    return count * repetition * (1.0 + burst_bonus)


# ──────────────────────────────────────────────────────────────────────────────
# 报告生成
# ──────────────────────────────────────────────────────────────────────────────

def format_report(stats: dict, total_entries: int, path: str,
                  top_n: int = 30, min_count: int = 5,
                  window_sec: float = 10.0) -> str:
    out = []

    filtered = {k: v for k, v in stats.items() if v['count'] >= min_count}

    by_count = sorted(filtered.values(), key=lambda s: s['count'], reverse=True)
    by_score = sorted(filtered.values(), key=lambda s: redundancy_score(s, window_sec), reverse=True)
    by_lines = sorted(filtered.values(), key=lambda s: s['line_count'], reverse=True)

    total_file_lines = sum(s['line_count'] for s in stats.values())

    # 文件级汇总
    file_totals: Counter = Counter()
    file_line_totals: Counter = Counter()
    for s in stats.values():
        file_totals[s['file']] += s['count']
        file_line_totals[s['file']] += s['line_count']

    # ── 头部汇总 ──────────────────────────────────────────────────
    out.append("# xlog 日志冗余性分析报告\n")
    out.append(f"- **日志文件**: `{os.path.basename(path)}`")
    out.append(f"- **分析时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    out.append(f"- **总日志条数**: {total_entries:,}")
    out.append(f"- **总文件行数（含续行）**: {total_file_lines:,}")
    out.append(f"- **唯一调用点数**: {len(stats):,}")
    out.append(f"- **出现 ≥{min_count} 次的调用点**: {len(filtered):,}")
    out.append(f"- **突发检测窗口**: {window_sec:.0f}s\n")

    # ── 按文件统计 ────────────────────────────────────────────────
    out.append("## 📁 按文件统计（Top 20，按行数排序）\n")
    out.append("| # | 文件 | 行数 | 行数占比 | 条数 | 条数占比 | 均行/条 |")
    out.append("|---|------|------|--------|------|--------|--------|")
    for i, (fname, lc) in enumerate(file_line_totals.most_common(20), 1):
        cnt = file_totals[fname]
        lpct = lc / total_file_lines * 100 if total_file_lines else 0
        cpct = cnt / total_entries * 100 if total_entries else 0
        avg = lc / cnt if cnt else 0
        out.append(f"| {i} | `{fname or '(swift/unknown)'}` | {lc:,} | {lpct:.1f}% | {cnt:,} | {cpct:.1f}% | {avg:.1f} |")

    # ── 行数 Top N ────────────────────────────────────────────────
    out.append(f"\n## 🔥 占用行数最多的调用点（Top {min(top_n, len(by_lines))}）\n")
    out.append("| # | 文件:行 | 方法（截断） | 行数 | 行数占比 | 条数 | 均行/条 | 冗余比 |")
    out.append("|---|---------|------------|------|--------|------|-------|--------|")
    for i, s in enumerate(by_lines[:top_n], 1):
        unique_t = len(s['templates'])
        ratio = s['count'] / max(unique_t, 1)
        lpct = s['line_count'] / total_file_lines * 100 if total_file_lines else 0
        avg_lines = s['line_count'] / s['count'] if s['count'] else 0
        method_short = (s['method'][:50] + '…') if len(s['method']) > 50 else s['method']
        out.append(
            f"| {i} | `{s['file']}:{s['line']}` | `{method_short}` "
            f"| {s['line_count']:,} | {lpct:.1f}% | {s['count']:,} | {avg_lines:.1f} | {ratio:.1f}x |"
        )

    # ── 出现次数 Top N ────────────────────────────────────────────
    out.append(f"\n## 📊 出现次数最多的调用点（Top {min(top_n, len(by_count))}）\n")
    out.append("| # | 文件:行 | 方法（截断） | 次数 | 行数 | 唯一模板 | 冗余比 | 10s突发 |")
    out.append("|---|---------|------------|------|------|---------|--------|--------|")
    for i, s in enumerate(by_count[:top_n], 1):
        unique_t = len(s['templates'])
        ratio = s['count'] / max(unique_t, 1)
        burst = max_burst_in_window(s['timestamps'], window_sec) if s['timestamps'] else 0
        method_short = (s['method'][:50] + '…') if len(s['method']) > 50 else s['method']
        out.append(
            f"| {i} | `{s['file']}:{s['line']}` | `{method_short}` "
            f"| {s['count']:,} | {s['line_count']:,} | {unique_t} | {ratio:.1f}x | {burst} |"
        )

    # ── 冗余评分 Top N（详细版） ───────────────────────────────────
    out.append(f"\n## ⚠️ 冗余评分最高的调用点（详细，Top {min(top_n, len(by_score))}）\n")
    out.append("> **冗余评分** = 次数 × 重复率 × (1 + 突发加成)。重复率越高（消息内容几乎相同）、突发越强，分越高。\n")

    for i, s in enumerate(by_score[:top_n], 1):
        unique_t = len(s['templates'])
        ratio = s['count'] / max(unique_t, 1)
        burst = max_burst_in_window(s['timestamps'], window_sec) if s['timestamps'] else 0
        score = redundancy_score(s, window_sec)

        top_tmpl, top_tmpl_cnt = ('', 0)
        if s['templates']:
            top_tmpl, top_tmpl_cnt = s['templates'].most_common(1)[0]

        level_str = '  '.join(f"`{l}`×{c:,}" for l, c in s['levels'].most_common())

        lpct = s['line_count'] / total_file_lines * 100 if total_file_lines else 0
        avg_lines = s['line_count'] / s['count'] if s['count'] else 0

        out.append(f"\n### {i}. `{s['file']}:{s['line']}`")
        out.append(f"**冗余分**: {score:,.0f}  |  **方法**: `{s['method']}`")
        out.append(f"")
        out.append(f"| 指标 | 值 |")
        out.append(f"|------|-----|")
        out.append(f"| 总次数 | {s['count']:,} |")
        out.append(f"| 实际占用行数 | {s['line_count']:,}（占全文件 {lpct:.1f}%，均 {avg_lines:.1f} 行/条） |")
        out.append(f"| 唯一消息模板数 | {unique_t} |")
        out.append(f"| 冗余比（次数/模板数） | {ratio:.1f}x |")
        out.append(f"| 10s 窗口最大突发 | {burst} 次 |")
        out.append(f"| 日志级别分布 | {level_str} |")
        out.append(f"")

        if top_tmpl:
            out.append(f"**最高频消息模板**（出现 {top_tmpl_cnt:,} 次）：")
            out.append(f"```")
            out.append(top_tmpl[:500])
            out.append(f"```")

        if s['samples']:
            out.append(f"**原始样例**：")
            out.append(f"```")
            out.append(s['samples'][0][:500])
            out.append(f"```")

    # ── 行数节省估算 ──────────────────────────────────────────────
    out.append("\n---\n")
    out.append("## 📉 如果清理 Top N 冗余调用点，可节省多少行数？\n")
    out.append("| 清理 Top N | 节省行数 | 节省比例 |")
    out.append("|-----------|---------|---------|")
    cumulative_lines = 0
    for n in [5, 10, 15, 20, 30]:
        cumulative_lines = sum(s['line_count'] for s in by_score[:n])
        pct = cumulative_lines / total_file_lines * 100 if total_file_lines else 0
        out.append(f"| Top {n} | {cumulative_lines:,} | {pct:.1f}% |")

    # ── 优化建议 ─────────────────────────────────────────────────
    out.append("\n## 💡 清理建议\n")

    # 找几个典型的冗余分类给出建议
    high_score_sites = by_score[:5]
    for s in high_score_sites:
        unique_t = len(s['templates'])
        ratio = s['count'] / max(unique_t, 1)
        burst = max_burst_in_window(s['timestamps'], window_sec) if s['timestamps'] else 0

        if ratio > 50 and burst > 30:
            tag = "🔴 **立即删除**"
            reason = f"冗余比 {ratio:.0f}x，突发达 {burst} 次/10s，信息量极低"
        elif ratio > 20:
            tag = "🟠 **建议删除或降为 Verbose**"
            reason = f"冗余比 {ratio:.0f}x，相同内容大量重复，几乎没有诊断价值"
        elif burst > 50:
            tag = "🟡 **限制频率**"
            reason = f"短时间突发 {burst} 次，建议加限频（每 N 次打一次或每 T 秒打一次）"
        else:
            tag = "🔵 **可考虑优化**"
            reason = f"出现 {s['count']:,} 次，可评估是否仍有必要"

        out.append(f"- {tag}: `{s['file']}:{s['line']}` — {reason}")

    out.append(f"\n### 通用优化原则\n")
    out.append("1. **高冗余比 (>20x)**：同一调用点打出几乎相同的消息 → 删除或改为只打一次")
    out.append("2. **短时间高突发 (>30次/10s)**：循环/回调中的日志 → 加限频条件或删除")
    out.append("3. **框架内部状态日志**：如 Span 开始/结束、cache miss/hit → 生产包中删除")
    out.append("4. **加密/网络请求参数 log**：含 token/key 等敏感数据 → 必须删除（安全风险）")
    out.append("5. **UI 刷新日志**：每个 cell 渲染都打 → 删除（对性能也有影响）")

    return '\n'.join(out)


# ──────────────────────────────────────────────────────────────────────────────
# CLI 入口
# ──────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description='分析 xlog 日志文件的冗余性与聚类',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python analyze_xlog.py smoba.xlog.log
  python analyze_xlog.py smoba.xlog.log --top 50 --min-count 20 -o report.md
  python analyze_xlog.py smoba.xlog.log --filter OTTraceManager --window 5
        """
    )
    parser.add_argument('log_file', help='xlog 日志文件路径（支持 .log 或 .xlog.log）')
    parser.add_argument('--top', type=int, default=30, metavar='N',
                        help='展示 Top N 冗余调用点（默认: 30）')
    parser.add_argument('--min-count', type=int, default=10, metavar='N',
                        help='过滤出现次数 < N 的调用点（默认: 10）')
    parser.add_argument('--sample', type=int, default=2, metavar='N',
                        help='每个调用点保留 N 条原始样例（默认: 2）')
    parser.add_argument('--window', type=float, default=10.0, metavar='SEC',
                        help='突发检测时间窗口（秒，默认: 10）')
    parser.add_argument('--filter', metavar='KEYWORD',
                        help='只分析文件名包含此关键字的调用点（如: OTTraceManager）')
    parser.add_argument('-o', '--output', metavar='FILE',
                        help='输出报告到文件（默认: 打印到终端）')
    parser.add_argument('--no-progress', action='store_true',
                        help='不显示进度信息')

    args = parser.parse_args()

    if not os.path.exists(args.log_file):
        print(f"❌ 文件不存在: {args.log_file}", file=sys.stderr)
        sys.exit(1)

    size_mb = os.path.getsize(args.log_file) / 1024 / 1024
    print(f"\n🔍 开始分析: {args.log_file}  ({size_mb:.1f} MB)", file=sys.stderr)
    if args.filter:
        print(f"   过滤模式: 只分析文件名含 '{args.filter}' 的调用点", file=sys.stderr)

    stats, total_entries = analyze(
        args.log_file,
        filter_keyword=args.filter,
        sample_n=args.sample,
        show_progress=not args.no_progress,
    )

    report = format_report(
        stats,
        total_entries,
        args.log_file,
        top_n=args.top,
        min_count=args.min_count,
        window_sec=args.window,
    )

    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(report)
        print(f"\n✅ 报告已保存: {args.output}", file=sys.stderr)
    else:
        print('\n' + report)


if __name__ == '__main__':
    main()
