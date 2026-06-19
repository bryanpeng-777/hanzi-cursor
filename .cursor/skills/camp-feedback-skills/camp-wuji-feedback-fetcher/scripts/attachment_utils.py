"""附件下载 / 解压 / 分类 / manifest 写入工具。

不做跨 skill import —— 各 skill 独立。
"""
from __future__ import annotations

import json
import shutil
import urllib.parse
import urllib.request
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Optional
from urllib.error import HTTPError, URLError


XLOG_EXTS = {".xlog"}
ZIP_EXTS = {".zip"}
LOG_EXTS = {".log", ".txt"}
IMG_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".gif"}
ZIP_MAGIC_PREFIXES = (b"PK\x03\x04", b"PK\x05\x06", b"PK\x07\x08")


@dataclass
class FetchResult:
    logs: list[str] = field(default_factory=list)
    plain_logs: list[str] = field(default_factory=list)
    screenshots: list[str] = field(default_factory=list)
    others: list[str] = field(default_factory=list)
    unresolved_logs: list[str] = field(default_factory=list)
    download_failures: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {k: v for k, v in {
            "logs": self.logs,
            "plain_logs": self.plain_logs,
            "screenshots": self.screenshots,
            "others": self.others,
            "unresolved_logs": self.unresolved_logs,
            "download_failures": self.download_failures,
        }.items() if v}


def classify_file(path: Path) -> str:
    ext = path.suffix.lower()
    if ext in XLOG_EXTS:
        return "xlog"
    if ext in ZIP_EXTS:
        return "zip"
    if ext in LOG_EXTS:
        return "log"
    if ext in IMG_EXTS:
        return "screenshot"
    if path.is_file():
        try:
            with path.open("rb") as fh:
                head = fh.read(8)
        except OSError:
            return "other"
        if any(head.startswith(p) for p in ZIP_MAGIC_PREFIXES):
            return "zip"
    return "other"


def unzip(zip_path: Path, target_root: Path) -> list[Path]:
    stem = zip_path.stem or "archive"
    if stem == zip_path.name:
        stem = stem + "_extracted"
    target_dir = target_root / stem
    target_dir.mkdir(parents=True, exist_ok=True)
    extracted: list[Path] = []
    try:
        with zipfile.ZipFile(zip_path) as zf:
            zf.extractall(target_dir)
        for p in target_dir.rglob("*"):
            if p.is_file():
                extracted.append(p)
    except (zipfile.BadZipFile, OSError):
        pass
    return extracted


def process_attachments(workdir: Path) -> FetchResult:
    """扫描 <workdir>/attachments/ 递归解压并分类。"""
    attachments = workdir / "attachments"
    decoded = workdir / "decoded_logs"
    result = FetchResult()
    if not attachments.exists():
        return result

    seen: set[Path] = set()
    worklist: list[Path] = sorted(p for p in attachments.rglob("*") if p.is_file())

    while worklist:
        f = worklist.pop(0)
        rf = f.resolve()
        if rf in seen:
            continue
        seen.add(rf)
        kind = classify_file(f)
        if kind == "zip":
            for inner in unzip(f, attachments):
                if inner.resolve() not in seen:
                    worklist.append(inner)
            continue
        _route_file(f, result, decoded)
    return result


def _route_file(f: Path, result: FetchResult, decoded_dir: Path) -> None:
    kind = classify_file(f)
    if kind == "xlog":
        result.logs.append(str(f))
    elif kind == "log":
        decoded_dir.mkdir(parents=True, exist_ok=True)
        target = decoded_dir / f.name
        if not target.exists():
            try:
                target.symlink_to(f.resolve())
            except OSError:
                shutil.copy2(f, target)
        result.plain_logs.append(str(target))
    elif kind == "screenshot":
        result.screenshots.append(str(f))
    else:
        result.others.append(str(f))


def fetch_url(url: str, target_dir: Path, *, timeout: int = 60) -> Optional[Path]:
    """下载 URL 到 target_dir，缓存命中直接返回。"""
    target_dir.mkdir(parents=True, exist_ok=True)
    parsed = urllib.parse.urlparse(url)
    filename = urllib.parse.unquote(Path(parsed.path).name or "download.bin")
    target = target_dir / filename
    if target.exists() and target.stat().st_size > 0:
        return target
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "camp-fetcher/1.0"})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            target.write_bytes(resp.read())
    except (HTTPError, URLError, TimeoutError, OSError):
        return None
    return target


def write_manifest(workdir: Path, result: FetchResult,
                   *, extra: Optional[dict[str, Any]] = None) -> Path:
    target = workdir / "manifest.json"
    existing: dict[str, Any] = {}
    if target.exists():
        try:
            existing = json.loads(target.read_text(encoding="utf-8")) or {}
        except (json.JSONDecodeError, OSError):
            pass
    merged = {**existing, **result.to_dict()}
    if extra:
        merged.update(extra)
    target.write_text(json.dumps(merged, ensure_ascii=False, indent=2),
                      encoding="utf-8")
    return target


def read_feedback_record(workdir: Path) -> dict[str, Any]:
    fp = workdir / "feedback.json"
    if not fp.exists():
        raise FileNotFoundError(f"feedback.json 不存在: {fp}")
    data = json.loads(fp.read_text(encoding="utf-8"))
    if isinstance(data, list):
        if not data:
            raise ValueError("feedback.json 是空数组")
        return data[0]
    if not isinstance(data, dict):
        raise ValueError(f"feedback.json 顶层必须是 dict 或 list")
    return data


def extract_urls_from_record(record: dict[str, Any]) -> tuple[list[str], list[str]]:
    """从 feedback record 提取 log URLs 和 screenshot URLs。"""
    def _coerce(value: Any) -> list[str]:
        if not value:
            return []
        if isinstance(value, list):
            return [str(u).strip() for u in value if u]
        if isinstance(value, str):
            # 支持逗号分隔（MCP 新格式）和竖线分隔（旧格式）
            sep = "," if "," in value else "|"
            return [u.strip() for u in value.split(sep) if u.strip()]
        return []

    log_urls: list[str] = []
    pic_urls: list[str] = []
    seen: set[str] = set()
    for k in ("logUrl", "log_url", "logUrlList"):
        for u in _coerce(record.get(k)):
            if u and u not in seen:
                log_urls.append(u)
                seen.add(u)
    for k in ("picUrl", "pic_url", "picurllist", "picUrlList"):
        for u in _coerce(record.get(k)):
            if u and u not in seen:
                pic_urls.append(u)
                seen.add(u)
    return log_urls, pic_urls
