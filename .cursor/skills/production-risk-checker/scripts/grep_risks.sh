#!/usr/bin/env bash
# grep_risks.sh - 上线前机械风险扫描（输出疑点供 AI 做业务裁决）
# 用法: ./scripts/grep_risks.sh [--staged-only] [-- <file_or_dir>...]

set -euo pipefail

STAGED_ONLY=""
PATHS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --staged-only) STAGED_ONLY="--cached"; shift ;;
        --) shift; PATHS=("$@"); break ;;
        *) echo "未知参数: $1  用法: $0 [--staged-only] [-- <path>...]"; exit 1 ;;
    esac
done

DIFF_CMD="git diff ${STAGED_ONLY:-HEAD}"
[[ ${#PATHS[@]} -gt 0 ]] && DIFF_CMD="$DIFF_CMD -- ${PATHS[*]}"

DIFF=$($DIFF_CMD 2>/dev/null || true)
if [[ -z "$DIFF" ]]; then
    echo "无变更内容，退出"
    exit 0
fi

echo "=== 现网风险快速扫描 ==="
echo ""

echo "## [P0] 测试域名 / 硬编码 URL"
URL_HITS=$(echo "$DIFF" | grep -n '^\+' | grep -Ei 'test\.|dev\.|staging\.|localhost|127\.0\.0\.1|10\.0\.0\.' | grep -v '^\+\+\+' || true)
if [[ -n "$URL_HITS" ]]; then
    echo "🚨 发现疑似测试域名（高风险，请 AI 确认是否会在正式环境生效）："
    echo "$URL_HITS"
else
    echo "✅ 无测试域名"
fi
echo ""

echo "## [P0] 调试打印语句"
PRINT_HITS=$(echo "$DIFF" | grep -n '^\+' | grep -E 'print\(|debugPrint\(|NSLog\(|os_log\(|console\.log\(' | grep -v '^\+\+\+' || true)
if [[ -n "$PRINT_HITS" ]]; then
    echo "⚠️  发现调试打印："
    echo "$PRINT_HITS" | head -30
else
    echo "✅ 无调试打印"
fi
echo ""

echo "## [P1] 硬编码 debug 判断"
HARDCODE_HITS=$(echo "$DIFF" | grep -n '^\+' | grep -E '(isDebug|kDebugMode|BuildConfig\.DEBUG|#if DEBUG)\s*[=!]=\s*(true|false|1|0)' | grep -v '^\+\+\+' || true)
if [[ -n "$HARDCODE_HITS" ]]; then
    echo "⚠️  发现硬编码 debug 条件："
    echo "$HARDCODE_HITS"
else
    echo "✅ 无硬编码 debug 判断"
fi
echo ""

echo "## [P1] 强制解包（Crash 隐患）"
FORCE_HITS=$(echo "$DIFF" | grep -n '^\+' | grep -E '\b\w+!\.' | grep -v '^\+\+\+' | head -20 || true)
if [[ -n "$FORCE_HITS" ]]; then
    echo "ℹ️  发现强制解包（请 AI 评估风险等级）："
    echo "$FORCE_HITS"
else
    echo "✅ 无明显强制解包"
fi
echo ""

echo "## [P2] TODO / 未完成标记"
TODO_HITS=$(echo "$DIFF" | grep -n '^\+' | grep -E 'TODO:|FIXME:|HACK:|待处理|待实现' | grep -v '^\+\+\+' || true)
if [[ -n "$TODO_HITS" ]]; then
    echo "ℹ️  发现 TODO（评估是否应在上线前完成）："
    echo "$TODO_HITS"
else
    echo "✅ 无 TODO"
fi
echo ""

echo "## [P2] 测试数据 / Mock 数据"
MOCK_HITS=$(echo "$DIFF" | grep -n '^\+' | grep -E 'mockData|testData|fakeData|"test_|\"test_' | grep -v '^\+\+\+' || true)
if [[ -n "$MOCK_HITS" ]]; then
    echo "⚠️  发现疑似测试数据："
    echo "$MOCK_HITS"
else
    echo "✅ 无 Mock 数据"
fi
echo ""

echo "=== 机械扫描完成 — 语义/业务层面请 AI 进一步分析 ==="
