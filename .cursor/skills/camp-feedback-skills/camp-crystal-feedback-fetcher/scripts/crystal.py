#!/usr/bin/env python3
"""camp-crystal-feedback-fetcher CLI 入口：水晶反馈检索 + 附件下载。

子命令：
- locate    检索反馈记录（写入 <workdir>/feedback.json）
- fetch     读 feedback.json，下载 logUrl/picUrl 附件 → 解压 → 分类 → 写 manifest
- show      读取已缓存的 feedback.json 并打印（调试 / 链路下游）

环境变量：
- CRYSTAL_MCP_TOKEN  (必需，真实接口模式) 太湖个人令牌
- CRYSTAL_MCP_URL    (可选)             水晶 MCP/REST Server 地址
- CRYSTAL_RTX        (可选)             最终用户 RTX，二次校验用

注：fixture 模式不需要 token。
注：logUrl 可能是 COS 内网链接，后续可通过 lego MCP 服务转换+解密后再下载。

退出码：
  0 成功 / 1 IO/参数错误 / 3 反馈未命中或 feedback.json 缺失 / 4 鉴权失败
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

from crystal_client import (  # noqa: E402
    CrystalAPIError,
    CrystalNotConfiguredError,
    make_crystal_client,
    normalize_record,
)
from attachment_utils import (  # noqa: E402
    FetchResult,
    extract_urls_from_record,
    fetch_url,
    process_attachments,
    read_feedback_record,
    write_manifest,
)


def _log(msg: str) -> None:
    print(msg, file=sys.stderr)


def _parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(prog="crystal",
                                description="水晶反馈检索 CLI")
    sub = p.add_subparsers(dest="command", required=True)

    # locate
    lc = sub.add_parser("locate",
                        help="检索反馈记录（fixture 或真实接口）")
    lc.add_argument("--workdir", default="",
                    help="工作目录；命中后写入 <workdir>/feedback.json。"
                         "若不传则只 stdout 打印。")
    lc.add_argument("--feedback-id", default="",
                    help="反馈 id（形如 202605_12348）")
    lc.add_argument("--feedback-url", default="",
                    help="反馈详情链接（自动解析 id）")
    lc.add_argument("--user-id", default="",
                    help="营地数字用户 ID")
    lc.add_argument("--uin", default="",
                    help="OpenID（接口不支持，客户端筛）")
    lc.add_argument("--keywords", default="",
                    help="关键词（接口 content 字段，模糊匹配）")
    lc.add_argument("--begin-time", default="",
                    help="开始时间，YYYY-MM-DD HH:MM:SS")
    lc.add_argument("--end-time", default="",
                    help="结束时间，YYYY-MM-DD HH:MM:SS")
    lc.add_argument("--app-version", default="",
                    help="cClientVersionName，如 10.111.0401")
    lc.add_argument("--platform", default="",
                    help="android / ios，客户端筛")
    lc.add_argument("--max-results", type=int, default=10)
    lc.add_argument("--fixture-record", default="",
                    help="fixture 模式：本地 JSON 代替真实 API")
    lc.add_argument("--first", action="store_true",
                    help="只取第一条命中（写入 feedback.json 时用）")
    lc.add_argument("--json", action="store_true")

    # show
    sh = sub.add_parser("show",
                        help="打印 <workdir>/feedback.json 的关键字段")
    sh.add_argument("--workdir", required=True)
    sh.add_argument("--json", action="store_true")

    # fetch
    ft = sub.add_parser("fetch",
                        help="从 feedback.json 下载附件 → 解压 → 分类 → 写 manifest")
    ft.add_argument("--workdir", required=True)
    ft.add_argument("--timeout", type=int, default=60,
                    help="单个 URL 下载超时（秒）")
    ft.add_argument("--no-download", action="store_true",
                    help="跳过下载，只扫描已有 attachments/ 做分类")
    ft.add_argument("--json", action="store_true")

    return p.parse_args(argv)


# ---------- subcommand implementations ----------

def _filter_by_uin(records: list[dict[str, Any]], uin: str) -> list[dict[str, Any]]:
    uin = (uin or "").strip()
    if not uin:
        return records
    return [r for r in records if (r.get("uin") or "").strip() == uin]


def _run_locate(args: argparse.Namespace) -> int:
    # 参数校验先行（在构造 client / 加载 token 之前）
    if not (args.feedback_id or args.feedback_url
            or args.user_id or args.uin
            or args.keywords or args.app_version):
        _log("[ERROR] 至少需要 --feedback-id / --feedback-url / "
             "--user-id / --uin / --keywords / --app-version 之一")
        return 1

    client = make_crystal_client(
        fixture_path=(args.fixture_record or None),
    )

    # 1. 路由：feedback_id > feedback_url > 搜索
    records: list[dict[str, Any]] = []
    if args.feedback_id:
        try:
            rec = client.get_feedback_detail(args.feedback_id)
            records = [rec]
        except KeyError as e:
            _log(f"[ERROR] 反馈 ID 未匹配: {args.feedback_id}: {e}")
            return 3
    elif args.feedback_url:
        records = client.search_feedback(url=args.feedback_url,
                                         limit=max(args.max_results, 5))
    else:
        records = client.search_feedback(
            uin=args.user_id or None,    # 接口的 userId 字段
            date_from=args.begin_time or None,
            date_to=args.end_time or None,
            version=args.app_version or None,
            keywords=args.keywords or None,
            platform=args.platform or None,
            limit=max(args.max_results * 2, 10),
        )

    # 2. uin 客户端过滤
    records = _filter_by_uin(records, args.uin)

    if not records:
        _log("[ERROR] 没有命中任何反馈")
        return 3

    # 3. 截断到 max_results
    records = records[:args.max_results]
    if args.first:
        records = records[:1]

    # 4. 输出
    if args.json:
        print(json.dumps([normalize_record(r) for r in records],
                         ensure_ascii=False))
    else:
        for r in records:
            r = normalize_record(r)
            print(f"- {r.get('_id', '?')}\t"
                  f"userId={r.get('user_id', '')}\t"
                  f"uin={r.get('uin', '')}\t"
                  f"time={r.get('create_time', '')}\t"
                  f"ver={r.get('version', '')}\t"
                  f"platform={r.get('system', '')}")

    # 5. 写入 workdir
    if args.workdir:
        wd = Path(args.workdir).expanduser()
        wd.mkdir(parents=True, exist_ok=True)
        if args.first or len(records) == 1:
            target = wd / "feedback.json"
            target.write_text(
                json.dumps(normalize_record(records[0]),
                           ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            _log(f"[INFO] 已写入 → {target}")
        else:
            target = wd / "feedback_candidates.json"
            target.write_text(
                json.dumps([normalize_record(r) for r in records],
                           ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            _log(f"[INFO] 多条命中（{len(records)} 条），写入 → {target}")

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
        for k in ("_id", "user_id", "uin", "system", "version",
                  "device_model", "create_time", "content",
                  "logUrl", "picUrl", "xLogUid"):
            v = rec.get(k, "")
            if isinstance(v, str) and len(v) > 200:
                v = v[:200] + "..."
            print(f"{k}: {v}")
    return 0


def _run_fetch(args: argparse.Namespace) -> int:
    """从 feedback.json 提取 URL → 下载 → 解压 → 分类 → 写 manifest。

    COS 链接后续可通过 lego MCP 服务接口转换+解密后再下载（当前 stub 直下）。
    """
    wd = Path(args.workdir).expanduser().resolve()
    if not wd.exists():
        _log(f"[ERROR] workdir 不存在: {wd}")
        return 3

    if args.no_download:
        result = process_attachments(wd)
        target = write_manifest(wd, result)
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

        failures: list[str] = []
        for url in log_urls + pic_urls:
            # COS 链接直接下载（已验证内网可达）
            saved = fetch_url(url, attachments, timeout=args.timeout)
            if saved is None:
                failures.append(url)

        result = process_attachments(wd)
        result.download_failures = failures

        extra: dict = {}
        platform = (record.get("system") or "").strip().lower()
        if platform in ("android", "ios"):
            extra["platform"] = platform
        if record.get("_id"):
            extra["feedback_id"] = record["_id"]
        extra["source"] = "crystal"

        target = write_manifest(wd, result, extra=extra or None)

    data = result.to_dict()
    data["counts"] = {
        "logs": len(result.logs),
        "plain_logs": len(result.plain_logs),
        "screenshots": len(result.screenshots),
        "download_failures": len(result.download_failures),
    }

    if args.json:
        print(json.dumps(data, ensure_ascii=False))
    else:
        c = data["counts"]
        _log(f"[DONE] xlog={c['logs']} plain_log={c['plain_logs']} "
             f"screenshot={c['screenshots']} fail={c['download_failures']}")

    return 0


# ---------- main ----------

def run(argv: Optional[list[str]] = None) -> int:
    args = _parse_args(argv if argv is not None else sys.argv[1:])

    try:
        if args.command == "locate":
            return _run_locate(args)
        if args.command == "show":
            return _run_show(args)
        if args.command == "fetch":
            return _run_fetch(args)
    except CrystalNotConfiguredError as e:
        _log(f"[ERROR] {e}")
        return 4
    except CrystalAPIError as e:
        _log(f"[ERROR] 水晶 API 调用失败: {e}")
        return 1
    except (RuntimeError, OSError, ValueError) as e:
        _log(f"[ERROR] 运行失败: {e}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(run())
