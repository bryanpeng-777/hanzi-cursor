#!/usr/bin/env python3
"""
datong-report CodeBuddy Hook: task_completed
在 skill 任务结束时自动上报 task_completed 事件
"""
import json
import sys
import urllib.request
import subprocess
import platform
import hashlib
import os

APP_KEY = "0WEB06WZQ1DCDVGE"
SKILL_NAME = "datong-report"
BEACON_URL = "https://otheve.beacon.qq.com/analytics/v2_upload"


def get_device_fingerprint():
    """获取设备指纹"""
    try:
        if platform.system() == "Darwin":
            result = subprocess.run(
                ["ioreg", "-rd1", "-c", "IOPlatformExpertDevice"],
                capture_output=True, text=True, timeout=5
            )
            for line in result.stdout.splitlines():
                if "IOPlatformUUID" in line:
                    return line.split('"')[-2]
        elif platform.system() == "Linux":
            for path in ["/etc/machine-id", "/var/lib/dbus/machine-id"]:
                if os.path.exists(path):
                    with open(path) as f:
                        return f.read().strip()
    except Exception:
        pass
    return hashlib.md5(platform.node().encode()).hexdigest()


def detect_platform():
    """检测运行平台"""
    if os.environ.get("CODEBUDDY_ENV") or os.environ.get("CODEBUDDY_VERSION"):
        return "codebuddy"
    elif os.environ.get("OPENCLAW_ENV"):
        return "openclaw"
    elif os.environ.get("BOXAI_ENV"):
        return "boxai"
    return "unknown"


def report_event(event_code, params=None):
    """上报事件到大同"""
    import time
    timestamp_ms = str(int(time.time() * 1000))
    a2 = get_device_fingerprint()

    map_value = {
        "skill_name": SKILL_NAME,
        "skill_platform": detect_platform(),
        "skill_os": platform.system(),
        "skill_event_time": timestamp_ms,
    }
    if params:
        map_value.update(params)

    body = json.dumps({
        "appVersion": "1.0.0",
        "sdkId": "js",
        "sdkVersion": "4.7.6-api",
        "platformId": 3,
        "mainAppKey": APP_KEY,
        "common": {"A2": a2},
        "events": [{
            "eventCode": event_code,
            "eventTime": timestamp_ms,
            "mapValue": {k: str(v) for k, v in map_value.items()}
        }]
    }).encode("utf-8")

    req = urllib.request.Request(
        BEACON_URL, data=body,
        headers={"Content-Type": "application/json;charset=UTF-8"},
        method="POST"
    )
    try:
        urllib.request.urlopen(req, timeout=5)
    except Exception:
        pass


def main():
    """Hook 入口"""
    try:
        hook_data = json.loads(sys.stdin.read()) if not sys.stdin.isatty() else {}
    except Exception:
        hook_data = {}

    task_type = hook_data.get("task_type", "unknown")
    task_result = hook_data.get("task_result", "success")
    task_duration_ms = hook_data.get("task_duration_ms", "0")

    report_event("task_completed", {
        "skill_task_type": task_type,
        "skill_task_result": task_result,
        "skill_task_duration_ms": str(task_duration_ms),
    })


if __name__ == "__main__":
    main()
