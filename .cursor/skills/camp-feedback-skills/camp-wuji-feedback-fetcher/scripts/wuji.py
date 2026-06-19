#!/usr/bin/env python3
"""camp-wuji-feedback-fetcher CLI。

子命令：
- init-mcp  解析 MCP 返回的 JSON 数据 → 写入 workdir
- fetch     读 feedback.json，下载附件 → 解压 → 分类 → 写 manifest
- show      打印 feedback.json 关键字段（调试用）

退出码：
  0 成功 / 1 IO/参数错误 / 3 反馈未命中或 feedback.json 缺失 / 4 数据解析失败
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Optional

# 同目录模块
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


# ============================================================
# MCP 数据解析 + 字段归一化
# ============================================================

class WujiAPIError(Exception):
    """MCP 返回业务错误。"""


_FIELD_ALIASES: dict[str, tuple[str, ...]] = {
    "_id": ("id", "feedback_id", "feedbackId", "_id"),
    "feedback_id": ("feedback_id", "feedbackId", "id"),
    "system": ("system_type", "cSystem", "system"),
    "version": ("client_version", "cClientVersionName", "version"),
    "create_time": ("create_time", "createTime", "time"),
    "uin": ("uin",),
    "user_id": ("user_id", "userId"),
    "device_model": ("device_model", "cDeviceModel"),
    "os_version": ("system_version", "system_version_name", "cSystemVersionCode", "os_version"),
    "content": ("content", "description"),
    "logUrl": ("log_url", "logUrl", "logUrlList"),
    "picUrl": ("pic_url", "picUrl", "picurllist", "picUrlList"),
    "xlog_uid": ("xLogUid", "xlog_uid"),
    "game_id": ("game_id", "gameId"),
    "req_source": ("req_source", "reqSource"),
}


def _normalize(raw: dict[str, Any]) -> dict[str, Any]:
    """归一化单条记录：保留原字段 + 补齐下游约定键。"""
    if not isinstance(raw, dict):
        return raw
    out = dict(raw)
    for canonical, candidates in _FIELD_ALIASES.items():
        if out.get(canonical):
            continue
        for src_key in candidates:
            val = raw.get(src_key)
            if val:
                out[canonical] = val
                break
    return out


def _parse_mcp_data(data: Any) -> list[dict[str, Any]]:
    """解析 MCP get_mgame_feedback_data_list 返回数据。"""
    if isinstance(data, list):
        return [_normalize(r) for r in data if isinstance(r, dict)]

    if not isinstance(data, dict):
        raise WujiAPIError(f"无法解析：期望 dict 或 list，得到 {type(data).__name__}")

    if data.get("isError"):
        raise WujiAPIError(f"MCP 返回错误: {data.get('message', '未知')}")

    # 优先 structuredContent
    sc = data.get("structuredContent")
    if isinstance(sc, dict):
        return _parse_structured(sc)

    # fallback: content 字段（嵌套 JSON 字符串）
    content = data.get("content")
    if isinstance(content, str):
        return _parse_content_string(content)

    # 直接有 feedback_list
    if "feedback_list" in data:
        return _parse_structured(data)

    raise WujiAPIError("找不到 structuredContent、content 或 feedback_list")


def _parse_structured(sc: dict[str, Any]) -> list[dict[str, Any]]:
    if not sc.get("success", True):
        raise WujiAPIError(f"MCP 业务失败: {sc.get('message', '未知')}")
    feedback_list = sc.get("feedback_list", [])
    if not isinstance(feedback_list, list):
        raise WujiAPIError(f"feedback_list 不是数组")
    return [_normalize(r) for r in feedback_list if isinstance(r, dict)]


def _parse_content_string(content: str) -> list[dict[str, Any]]:
    """解析 content 字段（MCP text array 嵌套 JSON）。"""
    try:
        parsed = json.loads(content)
    except json.JSONDecodeError:
        raise WujiAPIError("content 字段 JSON 解析失败")

    if isinstance(parsed, list):
        for item in parsed:
            if isinstance(item, dict) and item.get("type") == "text":
                try:
                    inner = json.loads(item.get("text", ""))
                    if isinstance(inner, dict) and "feedback_list" in inner:
                        return _parse_structured(inner)
                except json.JSONDecodeError:
                    continue

    if isinstance(parsed, dict) and "feedback_list" in parsed:
        return _parse_structured(parsed)

    raise WujiAPIError("content 中未找到有效的 feedback_list")


def _parse_mcp_file(filepath: Path) -> list[dict[str, Any]]:
    """从文件加载并解析 MCP 返回数据。"""
    if not filepath.exists():
        raise FileNotFoundError(f"MCP 数据文件不存在: {filepath}")
    data = json.loads(filepath.read_text(encoding="utf-8"))
    return _parse_mcp_data(data)


# ============================================================
# CLI
# ============================================================

def _log(msg: str) -> None:
    print(msg, file=sys.stderr)


def _parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="wuji",
                                description="无极反馈 CLI")
    sub = p.add_subparsers(dest="command", required=True)

    # init-mcp
    im = sub.add_parser("init-mcp",
                        help="解析 MCP 返回的 JSON → 写入 workdir")
    im.add_argument("--data-file", required=True,
                    help="MCP 返回的 JSON 文件路径")
    im.add_argument("--workdir", required=True,
                    help="工作目录")
    im.add_argument("--feedback-id", default="",
                    help="指定 feedback_id 只取单条")
    im.add_argument("--user-id", default="",
                    help="按 user_id 过滤")
    im.add_argument("--first", action="store_true",
                    help="只取第一条")
    im.add_argument("--json", action="store_true")

    # show
    sh = sub.add_parser("show",
                        help="打印 feedback.json 的关键字段")
    sh.add_argument("--workdir", required=True)
    sh.add_argument("--json", action="store_true")

    # fetch
    ft = sub.add_parser("fetch",
                        help="下载附件 → 解压 → 分类 → 写 manifest")
    ft.add_argument("--workdir", required=True)
    ft.add_argument("--timeout", type=int, default=60,
                    help="单个 URL 下载超时（秒）")
    ft.add_argument("--no-download", action="store_true",
                    help="跳过下载，只对已有 attachments/ 重新分类")
    ft.add_argument("--json", action="store_true")

    return p.parse_args(argv)


# ---------- subcommands ----------

def _run_init_mcp(args: argparse.Namespace) -> int:
    data_file = Path(args.data_file).expanduser()
    if not data_file.exists():
        _log(f"[ERROR] 数据文件不存在: {data_file}")
        return 1

    try:
        records = _parse_mcp_file(data_file)
    except (WujiAPIError, json.JSONDecodeError, FileNotFoundError) as e:
        _log(f"[ERROR] 解析失败: {e}")
        return 1

    if not records:
        _log("[ERROR] MCP 数据中没有反馈记录")
        return 3

    # 过滤
    if args.feedback_id:
        fid = args.feedback_id.strip()
        records = [r for r in records
                   if str(r.get("_id", "")) == fid
                   or str(r.get("feedback_id", "")) == fid
                   or str(r.get("id", "")) == fid]
        if not records:
            _log(f"[ERROR] 未找到 feedback_id={fid}")
            return 3

    if args.user_id:
        uid = args.user_id.strip()
        records = [r for r in records if str(r.get("user_id", "")).strip() == uid]
        if not records:
            _log("[ERROR] 过滤后无匹配记录")
            return 3

    if args.first:
        records = records[:1]

    # 写入 workdir
    wd = Path(args.workdir).expanduser()
    wd.mkdir(parents=True, exist_ok=True)

    target = wd / "feedback.json"
    target.write_text(
        json.dumps(records[0], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    if len(records) > 1:
        candidates = wd / "feedback_candidates.json"
        candidates.write_text(
            json.dumps(records, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        _log(f"[INFO] {len(records)} 条，candidates → {candidates}")

    _log(f"[INFO] → {target} "
         f"(uid={records[0].get('user_id', '?')} "
         f"platform={records[0].get('system', '?')})")

    if args.json:
        print(json.dumps(records, ensure_ascii=False))
    else:
        for r in records[:5]:
            print(f"  - id={r.get('_id', '?')} "
                  f"uid={r.get('user_id', '')} "
                  f"platform={r.get('system', '')} "
                  f"time={r.get('create_time', '')} "
                  f"content={str(r.get('content', ''))[:60]}")
        if len(records) > 5:
            print(f"  ... 共 {len(records)} 条")

    return 0


def _run_show(args: argparse.Namespace) -> int:
    wd = Path(args.workdir).expanduser()
    fp = wd / "feedback.json"
    if not fp.exists():
        _log(f"[ERROR] feedback.json 不存在: {fp}")
        return 3
    rec = json.loads(fp.read_text(encoding="utf-8"))
    if isinstance(rec, list):
        if not rec:
            _log("[ERROR] feedback.json 是空数组")
            return 3
        rec = rec[0]
    if args.json:
        print(json.dumps(rec, ensure_ascii=False))
    else:
        for k in ("_id", "user_id", "game_id", "req_source", "system", "version",
                  "device_model", "create_time", "content",
                  "logUrl", "picUrl"):
            v = rec.get(k, "")
            if isinstance(v, str) and len(v) > 200:
                v = v[:200] + "..."
            print(f"{k}: {v}")
    return 0


def _rewrite_cos_url(url: str) -> str:
    """COS 公网域名 → cos-internal（绕过 403）。"""
    if not url:
        return url
    return url.replace(
        ".cos.ap-guangzhou.myqcloud.com",
        ".cos-internal.ap-guangzhou.tencentcos.cn",
    )


def _run_fetch(args: argparse.Namespace) -> int:
    wd = Path(args.workdir).expanduser().resolve()
    if not wd.exists():
        _log(f"[ERROR] workdir 不存在: {wd}")
        return 3

    if args.no_download:
        result = process_attachments(wd)
        write_manifest(wd, result)
    else:
        try:
            record = read_feedback_record(wd)
        except FileNotFoundError as e:
            _log(f"[ERROR] {e}")
            return 3
        except (ValueError, json.JSONDecodeError) as e:
            _log(f"[ERROR] feedback.json 解析失败: {e}")
            return 1

        attachments = wd / "attachments"
        attachments.mkdir(parents=True, exist_ok=True)
        log_urls, pic_urls = extract_urls_from_record(record)
        log_urls = [_rewrite_cos_url(u) for u in log_urls]

        failures: list[str] = []
        for url in log_urls + pic_urls:
            if fetch_url(url, attachments, timeout=args.timeout) is None:
                failures.append(url)

        result = process_attachments(wd)
        result.download_failures = failures

        extra: dict = {"source": "wuji"}
        platform = (record.get("system") or "").strip().lower()
        if platform in ("android", "ios"):
            extra["platform"] = platform
        if record.get("_id"):
            extra["feedback_id"] = record["_id"]

        write_manifest(wd, result, extra=extra)

    c = {
        "logs": len(result.logs),
        "plain_logs": len(result.plain_logs),
        "screenshots": len(result.screenshots),
        "download_failures": len(result.download_failures),
    }
    if args.json:
        print(json.dumps({**result.to_dict(), "counts": c}, ensure_ascii=False))
    else:
        _log(f"[DONE] xlog={c['logs']} plain_log={c['plain_logs']} "
             f"screenshot={c['screenshots']} fail={c['download_failures']}")

    return 0


# ---------- main ----------

def run(argv: Optional[list[str]] = None) -> int:
    args = _parse_args(argv if argv is not None else sys.argv[1:])
    try:
        if args.command == "init-mcp":
            return _run_init_mcp(args)
        if args.command == "show":
            return _run_show(args)
        if args.command == "fetch":
            return _run_fetch(args)
    except WujiAPIError as e:
        _log(f"[ERROR] MCP 数据解析失败: {e}")
        return 4
    except (RuntimeError, OSError, ValueError) as e:
        _log(f"[ERROR] {e}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(run())
