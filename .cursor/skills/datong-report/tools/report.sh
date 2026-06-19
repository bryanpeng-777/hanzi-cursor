#!/bin/bash
# =============================================================================
# report.sh - Unified reporting tool for skill tracking.
#
# Combines init, complete, event reporting, and debug link generation
# into a single script with subcommands.
#
# Usage:
#   bash ./tools/report.sh init [event_name] [json_data]
#   bash ./tools/report.sh complete <status> [json_data]
#   bash ./tools/report.sh event <event_name> [json_data]
#   bash ./tools/report.sh batch 'evt|json' 'evt|json' ...
#   bash ./tools/report.sh debug
#
# Examples:
#   bash ./tools/report.sh init
#   bash ./tools/report.sh complete success '{"output_type":"code"}'
#   bash ./tools/report.sh event code_generated '{"language":"python"}'
#   bash ./tools/report.sh debug
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# =============================================================================
# !! CONFIGURE THESE FOR YOUR SKILL !!
# =============================================================================
APP_KEY="0WEB06WZQ1DCDVGE"
SKILL_NAME="datong-report"
# =============================================================================

DATONG_APP_ID="dt_datong_report"
DATONG_BASE_URL="https://trackmate.woa.com/#/d/repRegistry-quality/debug/panel"

SUBCOMMAND="${1:-}"
shift 2>/dev/null || true

# =============================================================================
# Debug logging
# By default the script stays silent and only emits the sentinel strings
# (TASK_READY / TASK_DONE / EVENT_OK / BATCH_OK / DEBUG_READY) plus the
# user-facing debug link. Verbose diagnostics are gated behind
# DATONG_REPORT_DEBUG={1|true|yes|on}.
# =============================================================================
log_debug() {
    case "${DATONG_REPORT_DEBUG:-}" in
        1|true|TRUE|yes|YES|on|ON)
            echo "$@"
            ;;
    esac
}

# --- Shared helpers ---
_is_codebuddy() {
    [ -d "$SKILL_DIR/.codebuddy" ] || [ -d ".codebuddy" ] || [ -n "${CODEBUDDY_PROJECT_DIR:-}" ]
}

_track_bg() {
    local event="$1"
    local data="$2"
    if [ -f "$SKILL_DIR/track.sh" ]; then
        bash "$SKILL_DIR/track.sh" "$APP_KEY" "$SKILL_NAME" "$event" "$data" &>/dev/null &
    fi
}

# --- Generate stable device fingerprint (A2) ---
generate_a2() {
    local raw_hostname=""
    local raw_username=""
    local device_id=""

    raw_hostname=$(hostname 2>/dev/null || echo "unknown-host")
    raw_username=$(whoami 2>/dev/null || echo "unknown-user")

    if [ -z "$device_id" ] && [ -f /etc/machine-id ]; then
        device_id=$(cat /etc/machine-id 2>/dev/null | tr -d '[:space:]')
    fi
    if [ -z "$device_id" ] && [ -f /var/lib/dbus/machine-id ]; then
        device_id=$(cat /var/lib/dbus/machine-id 2>/dev/null | tr -d '[:space:]')
    fi
    if [ -z "$device_id" ] && command -v reg.exe &>/dev/null; then
        device_id=$(reg.exe query "HKLM\\SOFTWARE\\Microsoft\\Cryptography" /v MachineGuid 2>/dev/null \
            | grep -i "MachineGuid" | awk '{print $NF}' | tr -d '[:space:]')
    fi
    if [ -z "$device_id" ] && command -v ioreg &>/dev/null; then
        device_id=$(ioreg -rd1 -c IOPlatformExpertDevice 2>/dev/null \
            | grep IOPlatformUUID | sed 's/.*= "//;s/"//' | tr -d '[:space:]')
    fi
    if [ -z "$device_id" ]; then
        local raw_mac=""
        if command -v ifconfig &>/dev/null; then
            raw_mac=$(ifconfig 2>/dev/null | grep -oE '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
        elif command -v ip &>/dev/null; then
            raw_mac=$(ip link 2>/dev/null | grep -oE '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -1)
        elif command -v getmac &>/dev/null; then
            raw_mac=$(getmac /FO CSV /NH 2>/dev/null | head -1 | cut -d',' -f1 | tr -d '"' | tr '-' ':')
        fi
        if [ -z "$raw_mac" ] && [ -d /sys/class/net ]; then
            for iface in /sys/class/net/*/address; do
                local addr=""
                addr=$(cat "$iface" 2>/dev/null | tr -d '[:space:]')
                if [ -n "$addr" ] && [ "$addr" != "00:00:00:00:00:00" ]; then
                    raw_mac="$addr"
                    break
                fi
            done
        fi
        [ -n "$raw_mac" ] && device_id=$(echo "$raw_mac" | tr '[:upper:]' '[:lower:]')
    fi
    if [ -z "$device_id" ]; then
        local did_dir="$HOME/.skill-tracker"
        local did_file="$did_dir/device-id"
        if [ -f "$did_file" ]; then
            device_id=$(cat "$did_file" 2>/dev/null | tr -d '[:space:]')
        fi
        if [ -z "$device_id" ]; then
            local new_did=""
            if command -v uuidgen &>/dev/null; then
                new_did=$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]')
            elif command -v python3 &>/dev/null; then
                new_did=$(python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null)
            elif [ -f /proc/sys/kernel/random/uuid ]; then
                new_did=$(cat /proc/sys/kernel/random/uuid 2>/dev/null)
            fi
            if [ -n "$new_did" ]; then
                mkdir -p "$did_dir" 2>/dev/null && echo "$new_did" > "$did_file" 2>/dev/null
                device_id="$new_did"
            fi
        fi
    fi
    [ -z "$device_id" ] && device_id="no-device-id"

    local fingerprint="${raw_hostname}:${raw_username}:${device_id}"
    if command -v md5sum &>/dev/null; then
        echo -n "$fingerprint" | md5sum | cut -c1-32
    elif command -v md5 &>/dev/null; then
        echo -n "$fingerprint" | md5 -q
    elif command -v openssl &>/dev/null; then
        echo -n "$fingerprint" | openssl md5 | sed 's/.*= //'
    elif command -v python3 &>/dev/null; then
        echo -n "$fingerprint" | python3 -c "import hashlib,sys; print(hashlib.md5(sys.stdin.buffer.read()).hexdigest())" 2>/dev/null
    else
        local ck
        ck=$(echo -n "$fingerprint" | cksum | awk '{print $1}')
        printf '%032s' "$ck" | tr ' ' '0'
    fi
}

# =============================================================================
# Subcommand: init
# =============================================================================
cmd_init() {
    local event_name="${1:-skill_invoked}"
    local custom_data="${2:-}"

    # On CodeBuddy, Hook handles this; on other platforms, track.sh
    if ! _is_codebuddy; then
        _track_bg "$event_name" "$custom_data"
    fi

    log_debug "=== Task Context ==="
    log_debug "Skill: $SKILL_NAME"
    log_debug "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    log_debug "OS: $(uname -s) $(uname -m)"
    log_debug "User: $(whoami 2>/dev/null || echo 'unknown')"
    log_debug "Working Directory: $(pwd)"
    log_debug ""

    log_debug "=== Workspace Files ==="
    if command -v find &>/dev/null; then
        while IFS= read -r line; do
            log_debug "$line"
        done < <(find . -maxdepth 2 -type f \
            ! -path './.git/*' \
            ! -path './node_modules/*' \
            ! -path './__pycache__/*' \
            ! -path './.venv/*' \
            2>/dev/null | head -20)
    fi
    log_debug ""

    log_debug "=== Project Info ==="
    if [ -f "package.json" ]; then
        log_debug "Type: Node.js"
        log_debug "Name: $(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' package.json 2>/dev/null | head -1)"
    elif [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        log_debug "Type: Python"
    elif [ -f "go.mod" ]; then
        log_debug "Type: Go"
        log_debug "Module: $(head -1 go.mod 2>/dev/null)"
    elif [ -f "Cargo.toml" ]; then
        log_debug "Type: Rust"
    elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        log_debug "Type: Java"
    else
        log_debug "Type: Unknown"
    fi
    log_debug ""

    local a2
    a2=$(generate_a2)
    log_debug "=== Debug Info ==="
    log_debug "A2: $a2"
    log_debug "Debug Link: ${DATONG_BASE_URL}?debugId=${a2}&appId=${DATONG_APP_ID}&showHistory=0&autoRegistDeviceId=1"
    log_debug ""

    log_debug "=== Ready ==="
    echo "TASK_READY"
}

# =============================================================================
# Subcommand: complete
# =============================================================================
cmd_complete() {
    local status="${1:-success}"
    local custom_data="${2:-}"

    local event_data="{\"status\":\"$status\""
    if [ -n "$custom_data" ]; then
        local stripped
        stripped=$(echo "$custom_data" | sed 's/^[[:space:]]*{//;s/}[[:space:]]*$//')
        if [ -n "$stripped" ]; then
            event_data="$event_data,$stripped"
        fi
    fi
    event_data="$event_data}"

    if ! _is_codebuddy; then
        _track_bg "task_completed" "$event_data"
    fi

    log_debug "=== Task Complete ==="
    log_debug "Status: $status"
    log_debug "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "TASK_DONE"
}

# =============================================================================
# Subcommand: event
# =============================================================================
cmd_event() {
    local event_name="${1:-custom_event}"
    local custom_data="${2:-}"

    if ! _is_codebuddy; then
        _track_bg "$event_name" "$custom_data"
    fi

    log_debug "Event '$event_name' recorded."
    echo "EVENT_OK"
}

# =============================================================================
# Subcommand: batch  (report multiple events in one call)
# Usage: bash report.sh batch 'evt1|json1' 'evt2|json2' ...
# Each argument is "event_name|json_data" (pipe-separated).
# If no pipe, the whole argument is treated as event_name with empty data.
# =============================================================================
cmd_batch() {
    local count=0
    for item in "$@"; do
        local event_name=""
        local custom_data=""
        if [[ "$item" == *"|"* ]]; then
            event_name="${item%%|*}"
            custom_data="${item#*|}"
        else
            event_name="$item"
        fi
        if [ -z "$event_name" ]; then
            continue
        fi
        if ! _is_codebuddy; then
            _track_bg "$event_name" "$custom_data"
        fi
        count=$((count + 1))
        log_debug "  [$count] '$event_name' recorded."
    done
    echo "BATCH_OK ($count events)"
}

# =============================================================================
# Subcommand: debug
# =============================================================================
cmd_debug() {
    local a2
    a2=$(generate_a2)
    local debug_url="${DATONG_BASE_URL}?debugId=${a2}&appId=${DATONG_APP_ID}&showHistory=0&autoRegistDeviceId=1"

    echo "=== datong-report Debug ==="
    echo "Skill:    $SKILL_NAME"
    echo "A2:       $a2"
    echo ""
    echo "Click the link below to start debugging on Datong platform:"
    echo ""
    echo "  $debug_url"
    echo ""
    echo "DEBUG_READY"
}

# =============================================================================
# Dispatcher
# =============================================================================
case "$SUBCOMMAND" in
    init)     cmd_init "$@" ;;
    complete) cmd_complete "$@" ;;
    event)    cmd_event "$@" ;;
    batch)    cmd_batch "$@" ;;
    debug)    cmd_debug "$@" ;;
    *)
        echo "Usage: bash report.sh <init|complete|event|debug|batch> [args...]" >&2
        echo "" >&2
        echo "Subcommands:" >&2
        echo "  init [event_name] [json_data]     Initialize task + report" >&2
        echo "  complete <status> [json_data]      Report task completion" >&2
        echo "  event <event_name> [json_data]     Report custom event" >&2
        echo "  batch 'evt|json' 'evt|json' ...    Report multiple events" >&2
        echo "  debug                              Generate debug link" >&2
        exit 1
        ;;
esac
