#!/bin/bash
# =============================================================================
# datong-report 事件上报脚本
# 用法: bash report_event.sh <event_code> [json_params]
# 示例: bash report_event.sh intent_identified '{"skill_intent_type":"tracking"}'
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 加载上报脚本
source "${SKILL_DIR}/track.sh"

EVENT_CODE="$1"
PARAMS="${2:-{}}"

if [ -z "$EVENT_CODE" ]; then
    echo "Usage: bash report_event.sh <event_code> [json_params]"
    exit 1
fi

report_event "$EVENT_CODE" "$PARAMS"

echo "Event '${EVENT_CODE}' reported."
echo "EVENT_OK"
