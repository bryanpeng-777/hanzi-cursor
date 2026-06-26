#!/usr/bin/env python3
"""
Knot 灯塔巡检批处理入口：串行拉取 → 校验 → 分析 → 生成报告分片。

AI 在 Knot 上完成 iWiki 写入与企微推送（需 user-iWiki / user-wework-bot MCP）。

用法:
  python3 run_knot_inspection.py --version 10.112.0603
  python3 run_knot_inspection.py --version 全量
  BEACON_VERSION=10.112.0603 python3 run_knot_inspection.py
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
BEACON_FETCHER_DIR = Path.home() / ".claude/skills/beacon-data-fetcher"
CONFIG = SKILL_DIR / "inspection_config.json"
DEFAULT_OUTPUT = Path("/tmp/beacon_inspector")


def _python() -> str:
    venv_py = BEACON_FETCHER_DIR / ".venv/bin/python"
    return str(venv_py) if venv_py.exists() else sys.executable


def _run(cmd: list[str], *, cwd: Path | None = None) -> None:
    print(f"\n>>> {' '.join(cmd)}", flush=True)
    subprocess.run(cmd, check=True, cwd=cwd or SKILL_DIR)


def load_dashboards() -> list[dict]:
    with open(CONFIG, encoding="utf-8") as f:
        return json.load(f)["dashboards"]


def fetch_all(version_label: str, output_dir: Path, output_all: Path) -> None:
    auth = BEACON_FETCHER_DIR / "runtime/beacon_auth_state.json"
    scrape = BEACON_FETCHER_DIR / "scripts/beacon_page_scrape.py"
    py = _python()
    if not auth.exists():
        raise SystemExit(
            f"灯塔登录态不存在: {auth}\n"
            "请先在 Knot 工作区执行 beacon-data-fetcher 登录流程，"
            "或将 beacon_auth_state.json 放到该路径。"
        )
    for d in load_dashboards():
        name = d["name"]
        for label, url_key, out_base in [
            ("version", "url", output_dir),
            ("all", "url_all", output_all),
        ]:
            url = d.get(url_key, "")
            if not url or url == "FILL_IN_ALL_VERSION_URL":
                print(f"[SKIP] {name} ({label}): 无 URL")
                continue
            out_dir = out_base / name
            out_dir.mkdir(parents=True, exist_ok=True)
            print(f"\n[FETCH] {name} ({label})")
            _run([py, str(scrape), "--auth", str(auth), "--url", url,
                  "--output-dir", str(out_dir), "--wait", "15"])


def main() -> int:
    parser = argparse.ArgumentParser(description="Knot 灯塔巡检批处理")
    parser.add_argument("--version", default=os.environ.get("BEACON_VERSION", "全量"),
                        help="版本号，如 10.112.0603；或 全量")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--skip-fetch", action="store_true", help="跳过拉取，仅分析+出报告")
    args = parser.parse_args()

    output_dir = args.output_dir
    output_all = Path(str(output_dir) + "_all")
    py = sys.executable
    scripts = SKILL_DIR / "scripts"

    if not args.skip_fetch:
        if output_dir.exists():
            import shutil
            shutil.rmtree(output_dir, ignore_errors=True)
            shutil.rmtree(output_all, ignore_errors=True)
        output_dir.mkdir(parents=True, exist_ok=True)
        output_all.mkdir(parents=True, exist_ok=True)
        fetch_all(args.version, output_dir, output_all)

    _run([py, str(scripts / "validate_inspection_data.py"), "csv",
          "--config", str(CONFIG), "--data-dir", str(output_dir),
          "--data-dir-all", str(output_all)])

    analysis = output_dir / "analysis_result.json"
    analyze_cmd = [py, str(scripts / "analyze_metrics.py"),
                   "--config", str(CONFIG), "--data-dir", str(output_dir),
                   "--version", args.version, "--output", str(analysis)]
    if args.version != "全量":
        analyze_cmd.extend(["--data-dir-all", str(output_all)])
    _run(analyze_cmd)

    _run([py, str(scripts / "validate_inspection_data.py"), "analysis",
          "--input", str(analysis)])

    report = output_dir / "inspection_report.md"
    _run([py, str(scripts / "generate_report.py"),
          "--input", str(analysis), "--output", str(report)])

    _run([py, str(scripts / "split_iwiki_parts.py"), str(report), "-o", str(output_dir)])

    with open(analysis, encoding="utf-8") as f:
        summary = json.load(f)
    print("\n=== KNOT_INSPECTION_DONE ===")
    print(json.dumps({
        "version": args.version,
        "run_time": summary.get("run_time"),
        "comparison": summary.get("comparison", {}),
        "total_immediate": summary.get("total_immediate", 0),
        "total_observe": summary.get("total_observe", 0),
        "output_dir": str(output_dir),
        "analysis_result": str(analysis),
        "inspection_report": str(report),
        "iwiki_parts": str(output_dir / "iwiki_parts.json"),
    }, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
