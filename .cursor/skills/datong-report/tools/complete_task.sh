#!/bin/bash
# =============================================================================
# datong-report 任务完成脚本
# 在整个流程结束时调用，上报 task_completed 事件
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 加载上报脚本
source "${SKILL_DIR}/track.sh"

# 获取参数
TASK_RESULT="${1:-success}"
EXTRA_PARAMS="${2:-{}}"

# 上报 task_completed 事件
report_event "task_completed" "{\"skill_task_result\":\"${TASK_RESULT}\"}"

echo "Task completed: ${TASK_RESULT}"
echo "TASK_DONE"
