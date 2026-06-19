#!/usr/bin/env python3
"""camp-lego-log-fetcher CLI。

子命令：
- download  下载 lego 日志 zip → 解压分类 → 写 manifest
- status    读 manifest.lego_status 打印上次结果

退出码（fail-soft）：
  0 成功/failed（不阻塞流水线）
  1 IO/参数错误 / --strict 模式下非 done
  3 依赖文件不存在
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Optional

SCRIPTS_DIR = Path(__file__).resolve().parent
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

from attachment_utils import (  # noqa: E402
    process_attachments,
    write_manifest,
)

DEFAULT_TIMEOUT_SEC = 120


def _log(msg: str) -> None:
    print(msg, file=sys.stderr)


# ============================================================
# 下载
# ============================================================

def _download_zip(url: str, download_dir: Path, timeout: int = DEFAULT_TIMEOUT_SEC) -> tuple[str, Optional[Path], str]:
    """下载 URL 到 download_dir。返回 (status, zip_path, message)。"""
    download_dir.mkdir(parents=True, exist_ok=True)
    parsed = urllib.parse.urlparse(url)
    filename = urllib.parse.unquote(Path(parsed.path).name or "lego_logs.zip")
    target = download_dir / filename

    try:
        _log(f"[lego] 下载: {url[:100]}...")
        req = urllib.request.Request(url, headers={"User-Agent": "camp-lego-fetcher/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            target.write_bytes(resp.read())
        _log(f"[lego] 下载成功: {target.name} ({target.stat().st_size} bytes)")
        return "done", target, f"下载完成: {target.name}"
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        _log(f"[lego] 下载失败: {e}")
        return "failed", None, f"下载失败: {e}"


# ============================================================
# CLI
# ============================================================

def _parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="lego", description="lego 日志补拉 CLI")
    sub = p.add_subparsers(dest="command", required=True)

    dl = sub.add_parser("download", help="下载 lego 日志 zip 到 workdir")
    dl.add_argument("--url", required=True, help="zip 下载链接（来自 lego.convertAndDecrypt）")
    dl.add_argument("--workdir", required=True, help="工作目录")
    dl.add_argument("--task-id", default="", help="lego 任务 ID（写入 manifest）")
    dl.add_argument("--strict", action="store_true")
    dl.add_argument("--json", action="store_true")

    st = sub.add_parser("status", help="读 manifest.lego_status")
    st.add_argument("--workdir", required=True)
    st.add_argument("--json", action="store_true")

    return p.parse_args(argv)


def _merge_manifest(workdir: Path, fields: dict[str, Any]) -> None:
    mp = workdir / "manifest.json"
    existing: dict[str, Any] = {}
    if mp.exists():
        try:
            existing = json.loads(mp.read_text(encoding="utf-8")) or {}
        except (json.JSONDecodeError, OSError):
            pass
    mp.write_text(json.dumps({**existing, **fields}, ensure_ascii=False, indent=2),
                  encoding="utf-8")


# ---------- download ----------

def _run_download(args: argparse.Namespace) -> int:
    wd = Path(args.workdir).expanduser()
    wd.mkdir(parents=True, exist_ok=True)

    status, zip_path, message = _download_zip(args.url, wd / "attachments")

    _merge_manifest(wd, {
        "lego_status": status,
        "lego_task_id": args.task_id or None,
        "lego_zip_path": str(zip_path) if zip_path else None,
        "lego_message": message,
    })

    # 下载成功则解压分类
    if status == "done" and zip_path:
        result = process_attachments(wd)
        write_manifest(wd, result)
        _log(f"[INFO] 解压: xlog={len(result.logs)} plain_log={len(result.plain_logs)}")

    out = {"status": status, "zip_path": str(zip_path) if zip_path else None, "message": message}
    if args.json:
        print(json.dumps(out, ensure_ascii=False))
    else:
        _log(f"[DONE] status={status}")

    if args.strict and status != "done":
        return 1
    return 0


# ---------- status ----------

def _run_status(args: argparse.Namespace) -> int:
    wd = Path(args.workdir).expanduser()
    mp = wd / "manifest.json"
    if not mp.exists():
        _log(f"[ERROR] manifest.json 不存在: {mp}")
        return 3
    try:
        data = json.loads(mp.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as e:
        _log(f"[ERROR] {e}")
        return 1

    out = {k: data.get(k) for k in ("lego_status", "lego_task_id", "lego_zip_path", "lego_message")}
    if args.json:
        print(json.dumps(out, ensure_ascii=False))
    else:
        for k, v in out.items():
            print(f"{k}: {v}")
    return 0


# ---------- main ----------

def run(argv: Optional[list[str]] = None) -> int:
    args = _parse_args(argv if argv is not None else sys.argv[1:])
    try:
        if args.command == "download":
            return _run_download(args)
        if args.command == "status":
            return _run_status(args)
    except (RuntimeError, OSError, ValueError) as e:
        _log(f"[ERROR] {e}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(run())
