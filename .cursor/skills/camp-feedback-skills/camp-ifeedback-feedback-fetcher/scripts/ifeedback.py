#!/usr/bin/env python3
"""camp-ifeedback-feedback-fetcher CLI。

子命令：
- locate  检索 ifeedback 反馈 → 写 feedback.json
- fetch   下载附件 → 解压 → 分类 → 写 manifest

退出码：0 成功 / 1 IO/参数 / 3 未命中 / 4 鉴权失败
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Any, Optional

SCRIPTS_DIR = Path(__file__).resolve().parent
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

from attachment_utils import (  # noqa: E402
    extract_urls_from_record,
    fetch_url,
    process_attachments,
    read_feedback_record,
    write_manifest,
)


def _log(msg: str) -> None:
    print(msg, file=sys.stderr)


# ============================================================
# iFeedback API 客户端（subprocess 调用官方 skill CLI）
# ============================================================

DEFAULT_MCP_URL = "https://ifeedback.mcp.it.woa.com"
DEFAULT_IFEEDBACK_CLI = (
    Path(__file__).resolve().parent.parent.parent / "ifeedback" / "scripts" / "ifeedback_api.py"
)
DEFAULT_TOKEN = "tai_pat_gU-Y99DGmY6boKJOQX2qV8h2nwDVuz9R-j6jmPtRXK8.hZ9Q6kDHJxEVHL-n9FNXmPzEiobMAAYSqdGDzAQ2lro"


class IFeedbackError(Exception):
    pass


def _load_token() -> str:
    """按优先级加载 token：环境变量 → .env → cache → 内置默认。"""
    # 环境变量
    token = (os.environ.get("IFEEDBACK_MCP_TOKEN") or "").strip()
    if token:
        return token
    # .env 文件
    for env_path in [Path.cwd() / ".env", Path(__file__).resolve().parent.parent / ".env", Path.home() / ".env"]:
        if env_path.is_file():
            try:
                for line in env_path.read_text(encoding="utf-8").splitlines():
                    line = line.strip()
                    if line.startswith("#") or "=" not in line:
                        continue
                    k, _, v = line.partition("=")
                    if k.strip() == "IFEEDBACK_MCP_TOKEN" and v.strip().strip("'\""):
                        return v.strip().strip("'\"")
            except OSError:
                continue
    # cache
    cache = Path.home() / ".ifeedback_token_cache.json"
    if cache.is_file():
        try:
            t = json.loads(cache.read_text(encoding="utf-8")).get("token", "").strip()
            if t:
                return t
        except (OSError, json.JSONDecodeError):
            pass
    return DEFAULT_TOKEN


def _run_ifeedback_cli(*args: str) -> dict[str, Any]:
    """调用 ifeedback skill CLI，返回解析后的 JSON。"""
    token = _load_token()
    cli = DEFAULT_IFEEDBACK_CLI
    if not cli.exists():
        raise IFeedbackError(f"ifeedback CLI 不存在: {cli}")

    env = os.environ.copy()
    env["IFEEDBACK_MCP_TOKEN"] = token
    env["IFEEDBACK_MCP_URL"] = os.environ.get("IFEEDBACK_MCP_URL", DEFAULT_MCP_URL)

    cmd = ["python3", str(cli), *args]
    try:
        proc = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=30, check=False)
    except subprocess.TimeoutExpired:
        raise IFeedbackError(f"ifeedback CLI 超时: {' '.join(args[:2])}")

    if proc.returncode != 0:
        raise IFeedbackError(f"退出码 {proc.returncode}: {proc.stderr.strip()[:300]}")
    if not proc.stdout.strip():
        raise IFeedbackError("输出为空")

    try:
        data = json.loads(proc.stdout.strip())
    except json.JSONDecodeError:
        raise IFeedbackError(f"非法 JSON: {proc.stdout[:200]}")

    if isinstance(data, str) and data.startswith("Error"):
        raise IFeedbackError(data)
    if isinstance(data, dict) and data.get("code") not in (0, None):
        raise IFeedbackError(f"业务错误: code={data.get('code')} msg={data.get('msg', '')}")
    return data


def _extract_feedbacks(data: dict[str, Any]) -> list[dict[str, Any]]:
    body = data.get("data") if isinstance(data, dict) else None
    if not isinstance(body, dict):
        return []
    feedbacks = body.get("feedbacks") or []
    if feedbacks:
        return list(feedbacks)
    clusters = body.get("clusters") or []
    return [c["center"] for c in clusters if isinstance(c, dict) and c.get("center")]


# ============================================================
# 字段归一化
# ============================================================

_FIELD_ALIASES: dict[str, tuple[str, ...]] = {
    "_id": ("_id",),
    "feedback_id": ("_id", "feedback_id"),
    "user_id": ("uin",),
    "system": ("system",),
    "version": ("clientVersion", "version"),
    "create_time": ("time", "create_time"),
    "device_model": ("device", "device_model"),
    "os_version": ("sysVersion", "os_version"),
    "content": ("comment", "content"),
    "logUrl": ("logUrl",),
    "picurllist": ("picurllist",),
    "xLogUid": ("xLogUid",),
}


def _rewrite_cos_url(url: str) -> str:
    if not url:
        return url
    return url.replace(".cos.ap-guangzhou.myqcloud.com", ".cos-internal.ap-guangzhou.tencentcos.cn")


def _normalize(raw: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(raw, dict):
        return raw
    out: dict[str, Any] = {"source": "ifeedback", "uin": ""}
    for canonical, candidates in _FIELD_ALIASES.items():
        for src_key in candidates:
            val = raw.get(src_key)
            if val not in (None, ""):
                out[canonical] = val
                break
    if out.get("logUrl"):
        out["logUrl"] = _rewrite_cos_url(out["logUrl"])
    if "picurllist" in out and "picUrl" not in out:
        out["picUrl"] = out["picurllist"]
    return out


# ============================================================
# CLI
# ============================================================

def _parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="ifeedback")
    sub = p.add_subparsers(dest="command", required=True)

    lc = sub.add_parser("locate")
    lc.add_argument("--workdir", default="")
    lc.add_argument("--ifeedback-url", default="")
    lc.add_argument("--feedback-id", default="")
    lc.add_argument("--uid", default="")
    lc.add_argument("--app-name", default="")
    lc.add_argument("--begin-time", default="")
    lc.add_argument("--end-time", default="")
    lc.add_argument("--max-results", type=int, default=10)
    lc.add_argument("--first", action="store_true")
    lc.add_argument("--json", action="store_true")

    ft = sub.add_parser("fetch")
    ft.add_argument("--workdir", required=True)
    ft.add_argument("--timeout", type=int, default=60)
    ft.add_argument("--no-download", action="store_true")
    ft.add_argument("--json", action="store_true")

    return p.parse_args(argv)


# ---------- locate ----------

def _run_locate(args: argparse.Namespace) -> int:
    if not (args.ifeedback_url or args.feedback_id or args.uid):
        _log("[ERROR] 至少需要 --ifeedback-url / --feedback-id / --uid")
        return 1

    if (args.feedback_id or args.uid) and (not args.app_name or not args.begin_time or not args.end_time):
        _log("[ERROR] --feedback-id/--uid 需要 --app-name + --begin-time + --end-time")
        return 1

    # 调 ifeedback CLI
    if args.ifeedback_url:
        data = _run_ifeedback_cli("search_by_url", "--url", args.ifeedback_url,
                                  "--size", str(args.max_results), "--return_fields", "[]")
        records = _extract_feedbacks(data)
    elif args.feedback_id:
        data = _run_ifeedback_cli("search", "--app_name", args.app_name,
                                  "--start_time", args.begin_time, "--end_time", args.end_time,
                                  "--size", str(args.max_results), "--return_fields", "[]",
                                  "--conditions", json.dumps([{"key": "_id", "relation": "等于", "value": args.feedback_id}]))
        records = _extract_feedbacks(data)
    else:
        data = _run_ifeedback_cli("search", "--app_name", args.app_name,
                                  "--start_time", args.begin_time, "--end_time", args.end_time,
                                  "--size", str(args.max_results), "--return_fields", "[]",
                                  "--conditions", json.dumps([{"key": "uin", "relation": "等于", "value": args.uid}]))
        records = _extract_feedbacks(data)

    if not records:
        _log("[ERROR] 未命中")
        return 3

    records = records[:args.max_results]
    if args.first:
        records = records[:1]

    # 输出
    if args.json:
        print(json.dumps([_normalize(r) for r in records], ensure_ascii=False))
    else:
        for r in records:
            n = _normalize(r)
            print(f"  - {n.get('_id', '?')} uid={n.get('user_id', '')} "
                  f"sys={n.get('system', '')} time={n.get('create_time', '')} "
                  f"log={'Y' if n.get('logUrl') else 'N'}")

    # 写 workdir
    if args.workdir:
        wd = Path(args.workdir).expanduser()
        wd.mkdir(parents=True, exist_ok=True)
        if args.first or len(records) == 1:
            (wd / "feedback.json").write_text(
                json.dumps(_normalize(records[0]), ensure_ascii=False, indent=2), encoding="utf-8")
            _log(f"[INFO] → {wd / 'feedback.json'}")
        else:
            (wd / "feedback_candidates.json").write_text(
                json.dumps([_normalize(r) for r in records], ensure_ascii=False, indent=2), encoding="utf-8")
            _log(f"[INFO] {len(records)} 条 → feedback_candidates.json")
    return 0


# ---------- fetch ----------

def _run_fetch(args: argparse.Namespace) -> int:
    wd = Path(args.workdir).expanduser().resolve()
    if not wd.exists():
        _log(f"[ERROR] workdir 不存在: {wd}")
        return 3

    try:
        record = read_feedback_record(wd)
    except FileNotFoundError as e:
        _log(f"[ERROR] {e}")
        return 3
    except (ValueError, json.JSONDecodeError) as e:
        _log(f"[ERROR] {e}")
        return 1

    extra: dict[str, Any] = {"source": record.get("source") or "ifeedback"}
    platform = (record.get("system") or "").strip().lower()
    if platform in ("android", "ios"):
        extra["platform"] = platform
    if record.get("_id"):
        extra["feedback_id"] = record["_id"]

    if args.no_download:
        result = process_attachments(wd)
        write_manifest(wd, result, extra=extra)
    else:
        attachments = wd / "attachments"
        attachments.mkdir(parents=True, exist_ok=True)
        log_urls, pic_urls = extract_urls_from_record(record)
        failures = [u for u in log_urls + pic_urls if fetch_url(u, attachments, timeout=args.timeout) is None]
        result = process_attachments(wd)
        result.download_failures = failures
        write_manifest(wd, result, extra=extra)

    c = {"logs": len(result.logs), "plain_logs": len(result.plain_logs),
         "screenshots": len(result.screenshots), "download_failures": len(result.download_failures)}
    if args.json:
        print(json.dumps({**result.to_dict(), "counts": c}, ensure_ascii=False))
    else:
        _log(f"[DONE] xlog={c['logs']} log={c['plain_logs']} pic={c['screenshots']} fail={c['download_failures']}")
    return 0


# ---------- main ----------

def run(argv: Optional[list[str]] = None) -> int:
    args = _parse_args(argv if argv is not None else sys.argv[1:])
    try:
        if args.command == "locate":
            return _run_locate(args)
        if args.command == "fetch":
            return _run_fetch(args)
    except IFeedbackError as e:
        _log(f"[ERROR] {e}")
        return 4 if "token" in str(e).lower() or "auth" in str(e).lower() else 1
    except (RuntimeError, OSError, ValueError) as e:
        _log(f"[ERROR] {e}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(run())
