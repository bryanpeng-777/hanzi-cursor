#!/usr/bin/env bash
# pre_check.sh - 提交前机械检查（输出供 AI 做语义 review）
# 用法: ./scripts/pre_check.sh [--staged-only]

set -euo pipefail

STAGED_ONLY="${1:-}"

if [[ "$STAGED_ONLY" == "--staged-only" ]]; then
    DIFF_SRC="git diff --cached"
    echo "=== 提交前快速检查（staged 变更）==="
else
    DIFF_SRC="git diff HEAD"
    echo "=== 提交前快速检查（HEAD 全量变更）==="
fi

echo ""

echo "## 变更文件列表"
git status --short
echo ""

DIFF=$($DIFF_SRC 2>/dev/null || true)
if [[ -z "$DIFF" ]]; then
    echo "无变更内容，退出"
    exit 0
fi

echo "## 调试打印语句检测"
PRINT_HITS=$(echo "$DIFF" | grep -n '^\+' | grep -E 'print\(|debugPrint\(|NSLog\(|console\.log\(' | grep -v '^\+\+\+' || true)
if [[ -n "$PRINT_HITS" ]]; then
    echo "⚠️  发现调试打印语句："
    echo "$PRINT_HITS"
else
    echo "✅ 无调试打印"
fi
echo ""

echo "## TODO / FIXME 检测"
TODO_HITS=$(echo "$DIFF" | grep -n '^\+' | grep -E 'TODO:|FIXME:|HACK:|XXX:|待处理|待实现|待完成' | grep -v '^\+\+\+' || true)
if [[ -n "$TODO_HITS" ]]; then
    echo "⚠️  发现未完成标记："
    echo "$TODO_HITS"
else
    echo "✅ 无 TODO/FIXME"
fi
echo ""

echo "## 测试数据 / 本地地址检测"
MOCK_HITS=$(echo "$DIFF" | grep -n '^\+' | grep -E '127\.0\.0\.1|localhost|mockData|testData|fakeData|10\.0\.0\.' | grep -v '^\+\+\+' || true)
if [[ -n "$MOCK_HITS" ]]; then
    echo "⚠️  发现疑似测试数据/本地地址："
    echo "$MOCK_HITS"
else
    echo "✅ 无硬编码测试数据"
fi
echo ""

echo "## 强制解包检测（! 操作符）"
FORCE_HITS=$(echo "$DIFF" | grep -n '^\+' | grep -E '\b\w+!\.' | grep -v '^\+\+\+' | head -20 || true)
if [[ -n "$FORCE_HITS" ]]; then
    echo "ℹ️  发现强制解包（请 AI 确认是否安全）："
    echo "$FORCE_HITS"
else
    echo "✅ 无明显强制解包"
fi
echo ""

echo "## dart analyze（若项目含 Dart）"
if command -v dart &>/dev/null && [[ -f "pubspec.yaml" ]]; then
    dart analyze 2>&1 | tail -10 || true
else
    echo "⚠️  dart 未安装或当前目录无 pubspec.yaml，跳过"
fi
echo ""

echo "=== 快速检查完成 — 以上为机械扫描结果，语义级 review 请 AI 分析 ==="
