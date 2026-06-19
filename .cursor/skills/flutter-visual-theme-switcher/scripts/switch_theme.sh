#!/usr/bin/env bash
# switch_theme.sh - 一键切换 Flutter 视觉主题
# 用法: ./scripts/switch_theme.sh <theme-name> [project-root]
#   theme-name: fresh-minimal | cartoon | nature
#   project-root: 项目根目录（默认当前目录）

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
THEME="${1:?用法: $0 <theme-name> [project-root]  可用: fresh-minimal | cartoon | nature}"
PROJECT_ROOT="${2:-$PWD}"

# 枚举值映射表
declare -A ENUM_MAP=(
    ["fresh-minimal"]="freshMinimal"
    ["cartoon"]="cartoon"
    ["nature"]="nature"
)

# 验证主题名
if [[ -z "${ENUM_MAP[$THEME]+_}" ]]; then
    echo "错误：不支持的主题 '$THEME'"
    echo "可用主题：$(ls "$SKILL_DIR/references/" 2>/dev/null | sed 's/\.md//' | tr '\n' ' ')"
    exit 1
fi

ENUM_VALUE="${ENUM_MAP[$THEME]}"
THEME_FILE="$PROJECT_ROOT/cs_ui/lib/src/theme/cs_app_theme.dart"

# 验证文件存在
if [[ ! -f "$THEME_FILE" ]]; then
    echo "错误：找不到主题文件 $THEME_FILE"
    echo "请确认 project-root 参数正确（当前：$PROJECT_ROOT）"
    exit 1
fi

# 显示当前值
OLD_LINE=$(grep "static const CsThemeStyle activeStyle" "$THEME_FILE" || true)
echo "当前：$OLD_LINE"

# macOS sed 需要 -i ''，Linux sed 用 -i
if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/static const CsThemeStyle activeStyle = CsThemeStyle\.[a-zA-Z]*/static const CsThemeStyle activeStyle = CsThemeStyle.$ENUM_VALUE/" "$THEME_FILE"
else
    sed -i "s/static const CsThemeStyle activeStyle = CsThemeStyle\.[a-zA-Z]*/static const CsThemeStyle activeStyle = CsThemeStyle.$ENUM_VALUE/" "$THEME_FILE"
fi

NEW_LINE=$(grep "static const CsThemeStyle activeStyle" "$THEME_FILE" || true)
echo "修改后：$NEW_LINE"
echo ""

# 运行 dart analyze
echo "运行 dart analyze cs_ui/lib/ ..."
if dart analyze "$PROJECT_ROOT/cs_ui/lib/" 2>&1; then
    echo ""
    echo "✅ 主题已切换为 [$THEME]（$ENUM_VALUE）"
    echo "   Hot Reload: 终端按 r，或重新运行 flutter run"
else
    echo ""
    echo "⚠️  dart analyze 发现问题，请检查"
    exit 1
fi
