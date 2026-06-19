#!/usr/bin/env python3
"""camp-xlog-decoder CLI

子命令：
- decode      : workdir 模式，读 manifest.logs[] 解码到 decoded_logs/
- decode-file : 单文件模式（不依赖 workdir）
- inspect     : 打印 workdir 解码状态
- env         : 打印解码器环境状态
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

SCRIPTS_DIR = Path(__file__).resolve().parent
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

from decode_xlog import ParseFile  # noqa: E402


# ============================================================
# 平台 / 主进程识别
# ============================================================

_ANDROID_MAIN_RE = re.compile(
    r"^com\.tencent\.gamehelper\.smoba_\d+\.xlog$", re.IGNORECASE)
_IOS_MAIN_RE = re.compile(r"^smoba_\d+\.xlog$", re.IGNORECASE)


def detect_platform(name: str) -> str:
    """根据文件名启发式判断平台。"""
    if _ANDROID_MAIN_RE.match(name):
        return "android"
    if _IOS_MAIN_RE.match(name):
        return "ios"
    if name.startswith("com.tencent.gamehelper.smoba_"):
        return "android"
    return "unknown"


def is_main_process(name: str, platform: str) -> bool:
    """是否营地主进程日志。"""
    if platform == "android":
        return bool(_ANDROID_MAIN_RE.match(name))
    if platform == "ios":
        return bool(_IOS_MAIN_RE.match(name))
    return False


# ============================================================
# 数据结构
# ============================================================

@dataclass
class DecodeFailure:
    src: str
    reason: str


@dataclass
class DecodeResult:
    plain_logs: list[Path] = field(default_factory=list)
    failures: list[DecodeFailure] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)

    def as_dict(self) -> dict:
        return {
            "plain_logs": [str(p) for p in self.plain_logs],
            "decode_failures": [{"src": f.src, "reason": f.reason}
                                 for f in self.failures],
            "decode_skipped": self.skipped,
        }


# ============================================================
# 核心解码（直接调 decode_xlog.ParseFile，不走 subprocess）
# ============================================================

def _log(msg: str) -> None:
    print(msg, file=sys.stderr)


def decode_one(xlog_path: Path, *, output_dir: Path | None = None) -> Path:
    """解码单个 xlog 文件。成功返回输出路径；失败抛 RuntimeError。"""
    if not xlog_path.exists():
        raise FileNotFoundError(f"xlog 文件不存在: {xlog_path}")

    if output_dir:
        output_dir.mkdir(parents=True, exist_ok=True)
        out_path = output_dir / (xlog_path.name + ".log")
    else:
        out_path = xlog_path.with_suffix(xlog_path.suffix + ".log")

    ok = ParseFile(str(xlog_path), str(out_path))
    if not ok or not out_path.exists() or out_path.stat().st_size == 0:
        raise RuntimeError(f"解码失败或输出为空: {xlog_path.name}")

    return out_path


# ============================================================
# manifest 读写
# ============================================================

def _read_manifest(workdir: Path) -> dict:
    mf = workdir / "manifest.json"
    if not mf.exists():
        raise FileNotFoundError(f"manifest.json 不存在: {mf}")
    return json.loads(mf.read_text(encoding="utf-8"))


def _write_manifest(workdir: Path, patch: dict) -> None:
    mf = workdir / "manifest.json"
    base = json.loads(mf.read_text(encoding="utf-8")) if mf.exists() else {}
    for k, v in patch.items():
        if isinstance(v, list) and isinstance(base.get(k), list):
            seen = {json.dumps(x, sort_keys=True, default=str)
                    for x in base[k]}
            for x in v:
                key = json.dumps(x, sort_keys=True, default=str)
                if key not in seen:
                    base[k].append(x)
                    seen.add(key)
        else:
            base[k] = v
    mf.write_text(json.dumps(base, ensure_ascii=False, indent=2),
                  encoding="utf-8")


# ============================================================
# workdir 批量解码
# ============================================================

def decode_workdir(workdir: Path, *, all_logs: bool = False) -> DecodeResult:
    """读 manifest.logs[] 解码到 decoded_logs/。"""
    manifest = _read_manifest(workdir)
    logs = list(manifest.get("logs") or [])
    platform = (manifest.get("platform") or "").strip().lower()

    decoded_dir = workdir / "decoded_logs"
    decoded_dir.mkdir(parents=True, exist_ok=True)

    result = DecodeResult()
    for log_path in logs:
        p = Path(log_path)
        if not p.exists():
            result.failures.append(DecodeFailure(str(p), "文件不存在"))
            continue

        plat = platform if platform in ("android", "ios") \
            else detect_platform(p.name)

        if not all_logs and plat in ("android", "ios") \
                and not is_main_process(p.name, plat):
            result.skipped.append(f"{p.name}: non-main process")
            continue

        try:
            out = decode_one(p, output_dir=decoded_dir)
            result.plain_logs.append(out)
            _log(f"[OK] {p.name} → {out.name}")
        except (RuntimeError, FileNotFoundError) as e:
            result.failures.append(DecodeFailure(str(p), str(e)))
            _log(f"[FAIL] {p.name}: {e}")

    # 回写 manifest
    patch: dict[str, Any] = {
        "plain_logs": [str(p) for p in result.plain_logs],
    }
    if result.failures:
        patch["decode_failures"] = [
            {"src": f.src, "reason": f.reason} for f in result.failures
        ]
    if result.skipped:
        patch["decode_skipped"] = result.skipped
    _write_manifest(workdir, patch)

    return result


# ============================================================
# CLI
# ============================================================

def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="camp-xlog-decoder",
        description="mars xlog 解码（Android nocrypt + iOS ECC 统一脚本）",
    )
    sub = p.add_subparsers(dest="command", required=True)

    pd = sub.add_parser("decode", help="workdir 模式")
    pd.add_argument("--workdir", required=True)
    pd.add_argument("--all", action="store_true",
                    help="解码所有 xlog（含子进程）")
    pd.add_argument("--json", action="store_true")

    pf = sub.add_parser("decode-file", help="单文件模式")
    pf.add_argument("xlog", help="xlog 文件路径")
    pf.add_argument("--output", default="")

    pi = sub.add_parser("inspect", help="打印 workdir 解码状态")
    pi.add_argument("--workdir", required=True)

    sub.add_parser("env", help="打印解码器环境")

    return p


def _run_decode(args: argparse.Namespace) -> int:
    wd = Path(args.workdir).expanduser().resolve()
    if not wd.exists():
        _log(f"[ERROR] workdir 不存在: {wd}")
        return 3
    try:
        result = decode_workdir(wd, all_logs=args.all)
    except FileNotFoundError as e:
        _log(f"[ERROR] {e}")
        return 3

    summary = result.as_dict()
    summary["counts"] = {
        "plain_logs": len(result.plain_logs),
        "failures": len(result.failures),
        "skipped": len(result.skipped),
    }
    if args.json:
        print(json.dumps(summary, ensure_ascii=False))
    else:
        c = summary["counts"]
        _log(f"[DONE] 成功 {c['plain_logs']} / 失败 {c['failures']} / 跳过 {c['skipped']}")
        for p in result.plain_logs:
            print(p)
    return 0


def _run_decode_file(args: argparse.Namespace) -> int:
    xlog = Path(args.xlog).expanduser().resolve()
    if not xlog.exists():
        _log(f"[ERROR] xlog 不存在: {xlog}")
        return 3
    output = Path(args.output).expanduser() if args.output else None
    try:
        out = decode_one(xlog, output_dir=output.parent if output else None)
        if output and out != output:
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(out.read_bytes())
            out = output
    except (RuntimeError, FileNotFoundError) as e:
        _log(f"[ERROR] {e}")
        if "PRIV_KEY" in str(e):
            return 2
        return 1
    print(out)
    return 0


def _run_inspect(args: argparse.Namespace) -> int:
    wd = Path(args.workdir).expanduser().resolve()
    mf = wd / "manifest.json"
    if not mf.exists():
        _log(f"[ERROR] manifest.json 不存在: {mf}")
        return 3
    data = json.loads(mf.read_text(encoding="utf-8"))
    print(f"workdir       : {wd}")
    print(f"platform      : {data.get('platform', '?')}")
    print(f"logs (xlog)   : {len(data.get('logs') or [])}")
    print(f"plain_logs    : {len(data.get('plain_logs') or [])}")
    print(f"failures      : {len(data.get('decode_failures') or [])}")
    print(f"skipped       : {len(data.get('decode_skipped') or [])}")
    return 0


def _run_env(_args: argparse.Namespace) -> int:
    import os as _os
    from decode_xlog import PRIV_KEY
    print(f"[decoder] {SCRIPTS_DIR / 'decode_xlog.py'}")
    print(f"[priv_key] {'已配置' if PRIV_KEY else '未配置（ECC 日志无法解码）'}")
    print(f"[env] CAMP_XLOG_PRIV_KEY = {_os.environ.get('CAMP_XLOG_PRIV_KEY', '')!r}")
    return 0


def run(argv: list[str]) -> int:
    args = _build_parser().parse_args(argv)
    if args.command == "decode":
        return _run_decode(args)
    if args.command == "decode-file":
        return _run_decode_file(args)
    if args.command == "inspect":
        return _run_inspect(args)
    if args.command == "env":
        return _run_env(args)
    return 1


if __name__ == "__main__":
    sys.exit(run(sys.argv[1:]))
