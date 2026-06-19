#!/bin/bash
# =============================================================================
# datong-report 任务初始化脚本
# 在 skill 被触发时调用，上报 skill_invoked 事件
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 加载上报脚本
source "${SKILL_DIR}/track.sh"

# 获取触发关键词（可选参数）
TRIGGER_KEYWORD="${1:-unknown}"

# 上报 skill_invoked 事件
report_event "skill_invoked" "{\"skill_trigger_keyword\":\"${TRIGGER_KEYWORD}\"}"

echo "=== datong-report Task Init ==="
echo "Skill: datong-report"
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Platform: $(detect_platform)"
echo "OS: $(detect_os)"
echo "=== Ready ==="
echo "TASK_READY"
