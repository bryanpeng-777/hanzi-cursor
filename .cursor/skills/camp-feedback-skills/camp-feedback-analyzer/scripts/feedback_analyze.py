#!/usr/bin/env python3
"""camp-feedback-analyzer 顶层编排器。

子命令：init / init-direct / init-local / cache-clean
退出码：0 成功 / 1 IO/参数错误
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile as _tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from datetime import datetime
from pathlib import Path
from typing import Any, Optional


# ============================================================
# 基础工具
# ============================================================

def _log(msg: str) -> None:
    print(msg, file=sys.stderr)


# ============================================================
# 文件分类
# ============================================================

_XLOG_EXTS = {".xlog"}
_LOG_EXTS = {".log", ".txt"}
_IMG_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".gif"}
_ZIP_EXTS = {".zip"}
_ZIP_MAGIC = (b"PK\x03\x04", b"PK\x05\x06", b"PK\x07\x08")
_XLOG_MAGIC_BYTES = {0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09}


def _probe_xlog_magic(path: Path) -> bool:
    try:
        return path.stat().st_size > 0 and path.read_bytes()[:1][0] in _XLOG_MAGIC_BYTES
    except (OSError, IndexError):
        return False


def _is_plaintext(path: Path) -> bool:
    try:
        if path.stat().st_size < 1:
            return False
        sample = path.read_bytes()[:512]
        sample.decode("utf-8")
        return b"\n" in sample
    except (OSError, UnicodeDecodeError):
        return False


def _classify_file(path: Path) -> str:
    """分类：'xlog' / 'log' / 'screenshot' / 'zip' / 'unknown'"""
    ext = path.suffix.lower()
    if ext in _XLOG_EXTS:
        return "log" if (not _probe_xlog_magic(path) and _is_plaintext(path)) else "xlog"
    if ext in _LOG_EXTS:
        return "xlog" if _probe_xlog_magic(path) else "log"
    if ext in _IMG_EXTS:
        return "screenshot"
    if ext in _ZIP_EXTS:
        return "zip"
    # 无扩展名：magic 探测
    if _probe_xlog_magic(path):
        return "xlog"
    try:
        if path.stat().st_size > 4 and any(path.read_bytes()[:4].startswith(p) for p in _ZIP_MAGIC):
            return "zip"
    except OSError:
        pass
    if _is_plaintext(path):
        return "log"
    return "unknown"


# ============================================================
# 公共：解压 + 分类 + 写 manifest
# ============================================================

def _unzip_all(attachments: Path) -> None:
    """解压 attachments/ 下所有 zip 文件。"""
    for f in list(attachments.rglob("*")):
        if not f.is_file():
            continue
        if _classify_file(f) == "zip":
            target_sub = attachments / (f.stem + "_extracted")
            target_sub.mkdir(parents=True, exist_ok=True)
            try:
                with zipfile.ZipFile(f) as zf:
                    zf.extractall(target_sub)
            except (zipfile.BadZipFile, OSError):
                pass


def _classify_all(workdir: Path) -> tuple[list[str], list[str], list[str]]:
    """分类 attachments/ 下所有文件，返回 (logs, plain_logs, screenshots)。"""
    attachments = workdir / "attachments"
    decoded_dir = workdir / "decoded_logs"
    logs: list[str] = []
    plain_logs: list[str] = []
    screenshots: list[str] = []

    for f in sorted(attachments.rglob("*")):
        if not f.is_file():
            continue
        kind = _classify_file(f)
        if kind == "zip":
            continue
        elif kind == "xlog":
            logs.append(str(f))
        elif kind == "log":
            decoded_dir.mkdir(parents=True, exist_ok=True)
            target = decoded_dir / (f.name if f.suffix else f.name + ".log")
            if not target.exists():
                try:
                    target.symlink_to(f.resolve())
                except OSError:
                    shutil.copy2(f, target)
            plain_logs.append(str(target))
        elif kind == "screenshot":
            screenshots.append(str(f))

    return logs, plain_logs, screenshots


def _write_manifest(workdir: Path, source: str, feedback_id: str,
                    logs: list[str], plain_logs: list[str], screenshots: list[str],
                    *, platform: str = "", failures: list[str] | None = None) -> None:
    manifest: dict[str, Any] = {
        "source": source,
        "feedback_id": feedback_id,
        "logs": logs,
        "plain_logs": plain_logs,
        "screenshots": screenshots,
    }
    if platform:
        manifest["platform"] = platform
    if failures:
        manifest["download_failures"] = failures
    (workdir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


def _write_feedback_json(workdir: Path, source: str, feedback_id: str,
                         create_time: str, *, content: str = "",
                         user_id: str = "", platform: str = "",
                         log_urls: list[str] | None = None,
                         pic_urls: list[str] | None = None) -> None:
    record: dict[str, Any] = {
        "source": source, "_id": feedback_id, "feedback_id": feedback_id,
        "user_id": user_id, "uin": "",
        "system": platform, "version": "",
        "create_time": create_time, "content": content,
        "logUrl": log_urls or [], "picUrl": pic_urls or [],
        "xLogUid": "", "device_model": "",
    }
    (workdir / "feedback.json").write_text(
        json.dumps(record, ensure_ascii=False, indent=2), encoding="utf-8")


# ============================================================
# 工作目录
# ============================================================

def _ensure_workdir(root: Path, feedback_id: str, create_time: str | None, *, force: bool = False) -> Path:
    sid = re.sub(r"[^A-Za-z0-9_\-]", "_", str(feedback_id))[:64]
    ts = "unknown"
    if create_time:
        try:
            ts = datetime.strptime(create_time.strip(), "%Y-%m-%d %H:%M:%S").strftime("%Y%m%d_%H%M%S")
        except (ValueError, TypeError):
            pass
    wd = root / f"{sid}_{ts}"
    if force and wd.exists():
        shutil.rmtree(wd)
    wd.mkdir(parents=True, exist_ok=True)
    for sub in ("attachments", "decoded_logs", "analysis"):
        (wd / sub).mkdir(exist_ok=True)
    return wd


def _detect_work_root() -> Path:
    skill_dir = Path(__file__).resolve().parent.parent
    if ".agent" in str(skill_dir):
        ws = skill_dir
        while ws.name != ".agent" and ws != ws.parent:
            ws = ws.parent
        if ws.name == ".agent":
            cache_dir = ws.parent / ".cache" / "camp-feedback"
            try:
                cache_dir.mkdir(parents=True, exist_ok=True)
                return cache_dir
            except OSError:
                pass
    local_output = skill_dir.parent / "output"
    try:
        local_output.mkdir(parents=True, exist_ok=True)
        return local_output
    except OSError:
        pass
    return Path(_tempfile.gettempdir()) / "camp-feedback"


DEFAULT_WORK_ROOT = _detect_work_root()

# 缓存/清理配置
_CACHE_MAX_AGE_DAYS = 7
_CACHE_MAX_SIZE_MB = 2048
_AUTO_CLEAN_THRESHOLD_MB = 1024  # output 目录超过此值时触发自动清理


# ============================================================
# 缓存复用
# ============================================================

def _compute_cache_key(feedback_id: str = "", ifeedback_url: str = "",
                       uid: str = "", create_time: str = "") -> str | None:
    """基于反馈特征生成缓存键（16 位 hex）。"""
    if feedback_id and feedback_id not in ("", "direct_", "local_"):
        raw = f"fid:{feedback_id}"
    elif ifeedback_url:
        parsed = urllib.parse.parse_qs(urllib.parse.urlparse(ifeedback_url).query)
        _id = parsed.get("_id", [""])[0]
        raw = f"ifb:{_id}" if _id else f"url:{ifeedback_url}"
    elif uid and create_time:
        hour = create_time.strip()[:13]
        raw = f"uid:{uid}@{hour}"
    else:
        return None
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


def _find_cached_workdir(root: Path, cache_key: str) -> Path | None:
    """在 root 下查找已有 workdir 是否命中缓存。"""
    index_file = root / ".cache_index.json"
    if not index_file.exists():
        return None
    try:
        index = json.loads(index_file.read_text(encoding="utf-8"))
        cached_path = index.get(cache_key)
        if cached_path and Path(cached_path).exists():
            return Path(cached_path)
    except (json.JSONDecodeError, OSError):
        pass
    return None


def _register_cache(root: Path, cache_key: str, workdir: Path) -> None:
    """注册 workdir 到缓存索引。"""
    index_file = root / ".cache_index.json"
    index: dict[str, str] = {}
    if index_file.exists():
        try:
            index = json.loads(index_file.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            pass
    index[cache_key] = str(workdir)
    try:
        index_file.write_text(json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8")
    except OSError:
        pass


def _check_cache_completeness(workdir: Path) -> str:
    """检查缓存完整性：full_hit / partial_hit / expired / miss。"""
    manifest_file = workdir / "manifest.json"
    if not manifest_file.exists():
        return "miss"

    # 检查时效性（基于 manifest 文件修改时间）
    mtime = manifest_file.stat().st_mtime
    age_days = (time.time() - mtime) / 86400
    if age_days > _CACHE_MAX_AGE_DAYS:
        return "expired"

    # 检查完整性
    has_feedback = (workdir / "feedback.json").exists()
    decoded_dir = workdir / "decoded_logs"
    has_decoded = decoded_dir.exists() and any(decoded_dir.iterdir())

    if has_feedback and has_decoded:
        return "full_hit"
    elif has_feedback:
        return "partial_hit"
    return "miss"


# ============================================================
# 自动清理
# ============================================================

def _get_dir_size_mb(path: Path) -> float:
    """获取目录总大小（MB）。"""
    total = 0
    try:
        for f in path.rglob("*"):
            if f.is_file():
                total += f.stat().st_size
    except OSError:
        pass
    return total / 1048576


def _auto_clean(root: Path) -> None:
    """自动清理策略：当 root 目录超过阈值时，按 LRU 淘汰旧 workdir。"""
    total_mb = _get_dir_size_mb(root)
    if total_mb < _AUTO_CLEAN_THRESHOLD_MB:
        return

    # 收集所有 workdir（含 manifest.json 或 feedback.json 的子目录）
    workdirs: list[tuple[float, Path]] = []
    for d in root.iterdir():
        if not d.is_dir() or d.name.startswith("."):
            continue
        # 用最近修改时间作为 LRU 依据
        mtime = 0.0
        for marker in ("manifest.json", "feedback.json", "report.md"):
            marker_file = d / marker
            if marker_file.exists():
                mtime = max(mtime, marker_file.stat().st_mtime)
        if mtime > 0:
            workdirs.append((mtime, d))

    # 按时间升序排列（最老的在前）
    workdirs.sort(key=lambda x: x[0])

    # 淘汰最老的，直到总大小低于阈值的 80%
    target_mb = _AUTO_CLEAN_THRESHOLD_MB * 0.8
    for mtime, wd in workdirs:
        if total_mb <= target_mb:
            break
        # 超过 TTL 的直接删
        age_days = (time.time() - mtime) / 86400
        if age_days > _CACHE_MAX_AGE_DAYS:
            freed = _get_dir_size_mb(wd)
            shutil.rmtree(wd, ignore_errors=True)
            total_mb -= freed
            _log(f"[AUTO-CLEAN] 删除过期 workdir: {wd.name} (已 {age_days:.0f} 天, 释放 {freed:.1f} MB)")

    # 若仍超阈值，继续 LRU 淘汰（不管是否过期）
    for mtime, wd in workdirs:
        if total_mb <= target_mb:
            break
        if not wd.exists():
            continue
        freed = _get_dir_size_mb(wd)
        shutil.rmtree(wd, ignore_errors=True)
        total_mb -= freed
        _log(f"[AUTO-CLEAN] LRU 淘汰 workdir: {wd.name} (释放 {freed:.1f} MB)")

    # 清理缓存索引中的失效条目
    _clean_cache_index(root)


def _clean_cache_index(root: Path) -> None:
    """清理缓存索引中指向已删除目录的条目。"""
    index_file = root / ".cache_index.json"
    if not index_file.exists():
        return
    try:
        index = json.loads(index_file.read_text(encoding="utf-8"))
        cleaned = {k: v for k, v in index.items() if Path(v).exists()}
        if len(cleaned) < len(index):
            index_file.write_text(json.dumps(cleaned, ensure_ascii=False, indent=2), encoding="utf-8")
    except (json.JSONDecodeError, OSError):
        pass


# ============================================================
# 下载
# ============================================================

def _rewrite_cos_url(url: str) -> str:
    return url.replace(".cos.ap-guangzhou.myqcloud.com", ".cos-internal.ap-guangzhou.tencentcos.cn")


def _fetch_url(url: str, target_dir: Path, timeout: int = 60) -> Optional[Path]:
    target_dir.mkdir(parents=True, exist_ok=True)
    filename = urllib.parse.unquote(Path(urllib.parse.urlparse(url).path).name or "download.bin")
    target = target_dir / filename
    if target.exists() and target.stat().st_size > 0:
        return target
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "camp-analyzer/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            target.write_bytes(resp.read())
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError, OSError):
        return None
    return target


# ============================================================
# CLI 参数
# ============================================================

def _parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="feedback_analyze")
    sub = p.add_subparsers(dest="command", required=True)

    # init
    it = sub.add_parser("init")
    it.add_argument("--feedback-id", required=True)
    it.add_argument("--create-time", default="")
    it.add_argument("--root", default=str(DEFAULT_WORK_ROOT))
    it.add_argument("--force", action="store_true")
    it.add_argument("--no-cache", action="store_true", help="禁用缓存复用")
    it.add_argument("--json", action="store_true")

    # init-direct
    dr = sub.add_parser("init-direct")
    dr.add_argument("--content", required=True)
    dr.add_argument("--log-url", action="append", default=[])
    dr.add_argument("--pic-url", action="append", default=[])
    dr.add_argument("--user-id", default="")
    dr.add_argument("--create-time", default="")
    dr.add_argument("--feedback-id", default="")
    dr.add_argument("--platform", default="")
    dr.add_argument("--root", default=str(DEFAULT_WORK_ROOT))
    dr.add_argument("--force", action="store_true")
    dr.add_argument("--timeout", type=int, default=60)
    dr.add_argument("--json", action="store_true")

    # init-local
    lo = sub.add_parser("init-local")
    lo.add_argument("--file", action="append", default=[], dest="files")
    lo.add_argument("--dir", action="append", default=[], dest="dirs")
    lo.add_argument("--content", default="")
    lo.add_argument("--user-id", default="")
    lo.add_argument("--create-time", default="")
    lo.add_argument("--feedback-id", default="")
    lo.add_argument("--platform", default="")
    lo.add_argument("--root", default=str(DEFAULT_WORK_ROOT))
    lo.add_argument("--force", action="store_true")
    lo.add_argument("--json", action="store_true")

    # cache-clean
    cc = sub.add_parser("cache-clean")
    cc.add_argument("--root", default=str(DEFAULT_WORK_ROOT))
    cc.add_argument("--max-age", type=int, default=_CACHE_MAX_AGE_DAYS, help="最大保留天数")
    cc.add_argument("--max-size", type=int, default=_CACHE_MAX_SIZE_MB, help="最大容量 MB")
    cc.add_argument("--dry-run", action="store_true", help="预览不执行")
    cc.add_argument("--json", action="store_true")

    return p.parse_args(argv)


# ============================================================
# 子命令
# ============================================================

def _run_init(args: argparse.Namespace) -> int:
    root = Path(args.root).expanduser()

    # 自动清理（每次 init 时检查）
    _auto_clean(root)

    # 缓存复用检查
    cache_key = None
    if not args.force and not args.no_cache:
        cache_key = _compute_cache_key(feedback_id=args.feedback_id,
                                       create_time=args.create_time)
        if cache_key:
            cached_wd = _find_cached_workdir(root, cache_key)
            if cached_wd:
                status = _check_cache_completeness(cached_wd)
                if status == "full_hit":
                    out = {"workdir": str(cached_wd), "feedback_id": args.feedback_id,
                           "cache": "full_hit", "message": "缓存命中，decoded_logs 已就绪，可直接从 Step 4 开始"}
                    if args.json:
                        print(json.dumps(out, ensure_ascii=False))
                    else:
                        _log(f"[CACHE] full_hit: {cached_wd}")
                        _log("[CACHE] decoded_logs 已存在，可跳过 Step 1~3 直接分析")
                        print(str(cached_wd))
                    return 0
                elif status == "partial_hit":
                    out = {"workdir": str(cached_wd), "feedback_id": args.feedback_id,
                           "cache": "partial_hit", "message": "部分命中，feedback.json 已有，需从 Step 2/3 继续"}
                    if args.json:
                        print(json.dumps(out, ensure_ascii=False))
                    else:
                        _log(f"[CACHE] partial_hit: {cached_wd}")
                        _log("[CACHE] feedback.json 已有，跳过 Step 1，从 decode 继续")
                        print(str(cached_wd))
                    return 0
                # expired 或 miss → 继续新建

    # 新建 workdir
    wd = _ensure_workdir(root, args.feedback_id, args.create_time or None, force=args.force)

    # 注册缓存
    if cache_key:
        _register_cache(root, cache_key, wd)

    out = {"workdir": str(wd), "feedback_id": args.feedback_id,
           "cache": "miss", "subdirs": ["attachments", "decoded_logs", "analysis"]}
    if args.json:
        print(json.dumps(out, ensure_ascii=False))
    else:
        _log(f"[INFO] workdir: {wd}")
        print(str(wd))
    return 0


def _run_init_direct(args: argparse.Namespace) -> int:
    now_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    create_time = args.create_time or datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    feedback_id = args.feedback_id or f"direct_{now_str}"
    platform = (args.platform or "").strip().lower()

    wd = _ensure_workdir(Path(args.root).expanduser(), feedback_id, create_time, force=args.force)
    attachments = wd / "attachments"

    # 写 feedback.json
    _write_feedback_json(wd, "direct", feedback_id, create_time,
                         content=args.content, user_id=args.user_id,
                         platform=platform, log_urls=args.log_url, pic_urls=args.pic_url)

    # 下载
    failures: list[str] = []
    for url in args.log_url:
        if _fetch_url(_rewrite_cos_url(url), attachments, timeout=args.timeout) is None:
            failures.append(url)
    for url in args.pic_url:
        if _fetch_url(url, attachments, timeout=args.timeout) is None:
            failures.append(url)

    # 解压 + 分类
    _unzip_all(attachments)
    logs, plain_logs, screenshots = _classify_all(wd)
    _write_manifest(wd, "direct", feedback_id, logs, plain_logs, screenshots,
                    platform=platform, failures=failures or None)

    # 输出
    out = {"workdir": str(wd), "feedback_id": feedback_id,
           "logs": len(logs), "plain_logs": len(plain_logs),
           "screenshots": len(screenshots), "download_failures": len(failures)}
    if args.json:
        print(json.dumps(out, ensure_ascii=False))
    else:
        _log(f"[INFO] direct 完成: xlog={len(logs)} log={len(plain_logs)} "
             f"pic={len(screenshots)} fail={len(failures)}")
        print(str(wd))
    return 0


def _run_init_local(args: argparse.Namespace) -> int:
    now_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    create_time = args.create_time or datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    feedback_id = args.feedback_id or f"local_{now_str}"
    platform = (args.platform or "").strip().lower()

    # 收集文件
    local_files = _collect_local_files(args.files, args.dirs)
    if not local_files:
        _log("[ERROR] 未找到文件。请指定 --file 或 --dir。")
        return 1

    wd = _ensure_workdir(Path(args.root).expanduser(), feedback_id, create_time, force=args.force)
    attachments = wd / "attachments"

    # 复制到 attachments/
    for src in local_files:
        dst = attachments / src.name
        if dst.exists():
            dst = attachments / f"{src.stem}_{now_str}{src.suffix}"
        shutil.copy2(src, dst)

    # 解压 + 分类
    _unzip_all(attachments)
    logs, plain_logs, screenshots = _classify_all(wd)

    # 写 feedback.json + manifest
    _write_feedback_json(wd, "local", feedback_id, create_time,
                         content=args.content, user_id=args.user_id, platform=platform)
    _write_manifest(wd, "local", feedback_id, logs, plain_logs, screenshots, platform=platform)

    # 输出
    out = {"workdir": str(wd), "feedback_id": feedback_id,
           "logs": len(logs), "plain_logs": len(plain_logs),
           "screenshots": len(screenshots), "imported_files": len(local_files)}
    if args.json:
        print(json.dumps(out, ensure_ascii=False))
    else:
        _log(f"[INFO] local 完成: 导入={len(local_files)} xlog={len(logs)} "
             f"log={len(plain_logs)} pic={len(screenshots)}")
        print(str(wd))
    return 0


def _collect_local_files(files: list[str], dirs: list[str]) -> list[Path]:
    result: list[Path] = []
    seen: set[str] = set()
    for f in files:
        p = Path(f).expanduser().resolve()
        if p.is_file() and str(p) not in seen:
            result.append(p)
            seen.add(str(p))
    for d in dirs:
        dp = Path(d).expanduser().resolve()
        if dp.is_dir():
            for p in sorted(dp.rglob("*")):
                if p.is_file() and str(p) not in seen and _classify_file(p) != "unknown":
                    result.append(p)
                    seen.add(str(p))
    return result


def _run_cache_clean(args: argparse.Namespace) -> int:
    """手动缓存清理：按 max-age 和 max-size 淘汰。"""
    root = Path(args.root).expanduser()
    if not root.exists():
        _log(f"[INFO] 目录不存在: {root}")
        return 0

    # 收集所有 workdir
    workdirs: list[tuple[float, Path, float]] = []
    for d in root.iterdir():
        if not d.is_dir() or d.name.startswith("."):
            continue
        mtime = 0.0
        for marker in ("manifest.json", "feedback.json", "report.md"):
            marker_file = d / marker
            if marker_file.exists():
                mtime = max(mtime, marker_file.stat().st_mtime)
        if mtime > 0:
            size_mb = _get_dir_size_mb(d)
            workdirs.append((mtime, d, size_mb))

    workdirs.sort(key=lambda x: x[0])
    total_mb = sum(s for _, _, s in workdirs)

    to_remove: list[tuple[Path, float, str]] = []

    # 按 age 淘汰
    for mtime, wd, size_mb in workdirs:
        age_days = (time.time() - mtime) / 86400
        if age_days > args.max_age:
            to_remove.append((wd, size_mb, f"过期 {age_days:.0f} 天"))

    # 按 size LRU 淘汰
    remaining_mb = total_mb - sum(s for _, s, _ in to_remove)
    for mtime, wd, size_mb in workdirs:
        if remaining_mb <= args.max_size:
            break
        if any(wd == r[0] for r in to_remove):
            continue
        to_remove.append((wd, size_mb, "LRU 淘汰"))
        remaining_mb -= size_mb

    # 输出
    result = {
        "total_workdirs": len(workdirs),
        "total_mb": round(total_mb, 1),
        "to_remove": len(to_remove),
        "to_free_mb": round(sum(s for _, s, _ in to_remove), 1),
        "details": [{"path": str(p), "size_mb": round(s, 1), "reason": r} for p, s, r in to_remove],
    }

    if args.dry_run:
        result["dry_run"] = True
        if args.json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        else:
            _log(f"[DRY-RUN] 共 {len(workdirs)} 个 workdir，{total_mb:.1f} MB")
            for p, s, r in to_remove:
                _log(f"  待删: {p.name} ({s:.1f} MB, {r})")
            _log(f"  预计释放: {result['to_free_mb']} MB")
    else:
        for p, s, r in to_remove:
            shutil.rmtree(p, ignore_errors=True)
            _log(f"[CLEAN] 删除 {p.name} ({s:.1f} MB, {r})")
        _clean_cache_index(root)
        if args.json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        else:
            _log(f"[CLEAN] 完成，释放 {result['to_free_mb']} MB")

    return 0


# ============================================================
# main
# ============================================================

def run(argv: Optional[list[str]] = None) -> int:
    args = _parse_args(argv if argv is not None else sys.argv[1:])
    try:
        if args.command == "init":
            return _run_init(args)
        if args.command == "init-direct":
            return _run_init_direct(args)
        if args.command == "init-local":
            return _run_init_local(args)
        if args.command == "cache-clean":
            return _run_cache_clean(args)
    except (RuntimeError, OSError, ValueError, json.JSONDecodeError) as e:
        _log(f"[ERROR] {e}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(run())
