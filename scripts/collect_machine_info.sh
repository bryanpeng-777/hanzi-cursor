#!/usr/bin/env bash
# 收集 Cursor Cloud Agent 运行环境信息，供 Slack 自动化任务使用。
set -euo pipefail

TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
HOSTNAME_VAL="$(hostname 2>/dev/null || echo unknown)"
PUBLIC_IP="$(curl -s --max-time 5 ifconfig.me 2>/dev/null || echo N/A)"
MACHINE_ID="$(cat /etc/machine-id 2>/dev/null || echo N/A)"
CONVERSATION_ID="${CURSOR_CONVERSATION_ID:-N/A}"
AGENT_FLAG="${CURSOR_AGENT:-0}"
CPU_CORES="$(nproc 2>/dev/null || echo N/A)"
MEM_TOTAL="$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo N/A)"
DOCKER_ENV="no"
[[ -f /.dockerenv ]] && DOCKER_ENV="yes"

# ipinfo.io 提供云厂商与地域信息（失败时留空）
IPINFO_JSON="$(curl -s --max-time 5 ipinfo.io/json 2>/dev/null || echo '{}')"
CLOUD_ORG="$(echo "$IPINFO_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('org','N/A'))" 2>/dev/null || echo N/A)"
REGION="$(echo "$IPINFO_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('region','N/A'))" 2>/dev/null || echo N/A)"
CITY="$(echo "$IPINFO_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('city','N/A'))" 2>/dev/null || echo N/A)"
IPINFO_HOST="$(echo "$IPINFO_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('hostname','N/A'))" 2>/dev/null || echo N/A)"

OUTPUT_DIR="${1:-reports}"
mkdir -p "$OUTPUT_DIR"
REPORT_FILE="$OUTPUT_DIR/machine-check-latest.json"

python3 - <<PY
import json, os

report = {
    "timestamp_utc": "$TIMESTAMP",
    "hostname": "$HOSTNAME_VAL",
    "public_ip": "$PUBLIC_IP",
    "machine_id": "$MACHINE_ID",
    "cursor_conversation_id": "$CONVERSATION_ID",
    "cursor_agent": "$AGENT_FLAG",
    "cpu_cores": "$CPU_CORES",
    "memory_total": "$MEM_TOTAL",
    "docker": "$DOCKER_ENV",
    "cloud_org": "$CLOUD_ORG",
    "region": "$REGION",
    "city": "$CITY",
    "ipinfo_hostname": "$IPINFO_HOST",
    "workspace": os.getcwd(),
    "kernel": "$(uname -r 2>/dev/null || echo N/A)",
    "os": "$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '\"' || echo N/A)",
}

with open("$REPORT_FILE", "w", encoding="utf-8") as f:
    json.dump(report, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(json.dumps(report, ensure_ascii=False, indent=2))
PY

echo "Report written to $REPORT_FILE"
