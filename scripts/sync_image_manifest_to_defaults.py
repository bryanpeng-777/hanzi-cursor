#!/usr/bin/env python3
"""
Sync CsImage config keys from the dev-time image manifest into bundled defaults.

Source of truth: ~/.claude/knowledge/ui-assistant/{project}/image_manifest.json
Target: <app>/assets/default_configs.json

This script is intentionally conservative:
- Only updates keys that exist in the manifest (grouped under pages.*.images).
- Never deletes unrelated keys in default_configs.json.

Usage:
  python3 scripts/sync_image_manifest_to_defaults.py --apply
  python3 scripts/sync_image_manifest_to_defaults.py --check
  python3 scripts/sync_image_manifest_to_defaults.py --bootstrap-missing-keys --apply
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any, Dict, Iterable, Tuple


def _default_manifest_path(project: str) -> Path:
    home = Path(os.path.expanduser("~"))
    return home / ".claude" / "knowledge" / "ui-assistant" / project / "image_manifest.json"


def _load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def _dump_json_pretty(path: Path, data: Any) -> None:
    text = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    path.write_text(text, encoding="utf-8")


def _iter_manifest_images(manifest: Dict[str, Any]) -> Iterable[Tuple[str, Dict[str, Any]]]:
    pages = manifest.get("pages") or {}
    if not isinstance(pages, dict):
        return
    for _, page in pages.items():
        if not isinstance(page, dict):
            continue
        images = page.get("images") or {}
        if not isinstance(images, dict):
            continue
        for key, meta in images.items():
            if isinstance(meta, dict):
                yield key, meta


def _is_cs_image_entry(v: Any) -> bool:
    return isinstance(v, dict) and "url" in v and "asset" in v


def _manifest_keys(manifest: Dict[str, Any]) -> set[str]:
    return {k for k, _ in _iter_manifest_images(manifest)}


def _bootstrap_manifest_pages_with_missing_keys(
    manifest: Dict[str, Any], defaults: Dict[str, Any]
) -> int:
    """Insert placeholder manifest entries for any CsImage-shaped keys missing from manifest."""
    existing = _manifest_keys(manifest)
    pages = manifest.setdefault("pages", {})
    if not isinstance(pages, dict):
        raise ValueError("manifest.pages must be an object")

    bucket = pages.setdefault("_imported_from_default_configs", {})
    if not isinstance(bucket, dict):
        raise ValueError("manifest page bucket must be an object")
    bucket.setdefault("title", "从 default_configs.json 自动补齐的图片 key")
    images = bucket.setdefault("images", {})
    if not isinstance(images, dict):
        raise ValueError("images must be an object")

    added = 0
    for key, val in defaults.items():
        if key in existing:
            continue
        if not _is_cs_image_entry(val):
            continue
        images[key] = {
            "description": f"自动导入：{key}（请在台账里补全描述/规格）",
            "aspect_ratio": "1:1",
            "suggested_size": "512x512",
            "format": "png",
            "asset_path": val.get("asset"),
            "image_url": val.get("url"),
            "status": "local"
            if val.get("asset")
            else ("remote" if val.get("url") else "placeholder"),
            "last_updated": date.today().isoformat(),
        }
        existing.add(key)
        added += 1

    # Recompute summary if present (avoid lying counters)
    summary = manifest.get("summary")
    if isinstance(summary, dict):
        totals = {"placeholder": 0, "local": 0, "remote": 0}
        for _, meta in _iter_manifest_images(manifest):
            st = (meta.get("status") or "").strip().lower()
            if st in {"remote", "url"}:
                totals["remote"] += 1
            elif st in {"local", "asset"}:
                totals["local"] += 1
            else:
                totals["placeholder"] += 1
        summary["total"] = sum(totals.values())
        summary["placeholder"] = totals["placeholder"]
        summary["local"] = totals["local"]
        summary["remote"] = totals["remote"]

    return added


def _expected_url_asset(meta: Dict[str, Any]) -> Tuple[Any, Any]:
    status = (meta.get("status") or "").strip().lower()
    asset_path = meta.get("asset_path")
    image_url = meta.get("image_url")

    if status in {"remote", "url"}:
        return image_url, None

    if status in {"local", "asset"}:
        return None, asset_path

    # placeholder / skip / unknown → force empty (CsImage should show placeholder)
    return None, None

@dataclass(frozen=True)
class Diff:
    key: str
    before_url: Any
    before_asset: Any
    after_url: Any
    after_asset: Any


def _compute_diffs(defaults: Dict[str, Any], manifest: Dict[str, Any]) -> list[Diff]:
    diffs: list[Diff] = []
    for key, meta in _iter_manifest_images(manifest):
        if key not in defaults:
            diffs.append(
                Diff(
                    key=key,
                    before_url="<missing>",
                    before_asset="<missing>",
                    after_url=_expected_url_asset(meta)[0],
                    after_asset=_expected_url_asset(meta)[1],
                )
            )
            continue

        cur = defaults[key]
        if not _is_cs_image_entry(cur):
            # Don't try to "fix" non-image dicts blindly.
            continue

        exp_url, exp_asset = _expected_url_asset(meta)
        before_url, before_asset = cur.get("url"), cur.get("asset")
        if before_url != exp_url or before_asset != exp_asset:
            diffs.append(
                Diff(
                    key=key,
                    before_url=before_url,
                    before_asset=before_asset,
                    after_url=exp_url,
                    after_asset=exp_asset,
                )
            )
    return diffs


def _apply(defaults: Dict[str, Any], manifest: Dict[str, Any]) -> list[Diff]:
    diffs = _compute_diffs(defaults, manifest)
    for d in diffs:
        if d.before_url == "<missing>":
            # Create a new image entry if the app expects this key but it isn't present yet.
            defaults[d.key] = {"url": d.after_url, "asset": d.after_asset}
            continue

        cur = defaults.get(d.key)
        if not _is_cs_image_entry(cur):
            continue
        cur["url"] = d.after_url
        cur["asset"] = d.after_asset
    return diffs


def _update_manifest_meta_inplace(manifest: Dict[str, Any]) -> None:
    """Lightweight bookkeeping so humans can tell the manifest was synced recently."""
    manifest["_last_updated"] = date.today().isoformat()
    if isinstance(manifest.get("summary"), dict):
        # Keep summary as declared by tools; we only bump last_updated here.
        pass


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--project",
        default=os.environ.get("HANZI_CEO_PROJECT", "hanzi"),
        help="Knowledge project folder name under ~/.claude/knowledge/ui-assistant/{project}/",
    )
    ap.add_argument(
        "--manifest",
        default=None,
        help="Path to image_manifest.json (default: ~/.claude/knowledge/ui-assistant/{project}/image_manifest.json)",
    )
    ap.add_argument(
        "--defaults",
        default=str(Path(__file__).resolve().parents[1] / "assets" / "default_configs.json"),
        help="Path to default_configs.json",
    )
    ap.add_argument("--apply", action="store_true", help="Write changes to default_configs.json")
    ap.add_argument(
        "--check",
        action="store_true",
        help="Exit non-zero if default_configs.json is not in sync with manifest",
    )
    ap.add_argument(
        "--bootstrap-missing-keys",
        action="store_true",
        help="Add missing CsImage keys from default_configs.json into manifest (placeholder) then continue",
    )
    args = ap.parse_args(argv)

    if args.apply and args.check:
        print("Use only one of --apply or --check", file=sys.stderr)
        return 2

    manifest_path = Path(args.manifest) if args.manifest else _default_manifest_path(str(args.project))
    defaults_path = Path(args.defaults)

    if not manifest_path.exists():
        print(f"Manifest not found: {manifest_path}", file=sys.stderr)
        return 1
    if not defaults_path.exists():
        print(f"default_configs.json not found: {defaults_path}", file=sys.stderr)
        return 1

    manifest = _load_json(manifest_path)
    defaults = _load_json(defaults_path)
    if not isinstance(manifest, dict) or not isinstance(defaults, dict):
        print("Invalid JSON structure", file=sys.stderr)
        return 1

    if args.bootstrap_missing_keys:
        added = _bootstrap_manifest_pages_with_missing_keys(manifest, defaults)
        if added:
            manifest["_last_updated"] = date.today().isoformat()
            _dump_json_pretty(manifest_path, manifest)
            print(f"BOOTSTRAP: added {added} missing image keys into manifest")

    if args.check:
        diffs = _compute_diffs(defaults, manifest)
        if diffs:
            print("image_manifest ↔ default_configs 未同步，请先运行：", file=sys.stderr)
            print(f"  python3 scripts/sync_image_manifest_to_defaults.py --apply", file=sys.stderr)
            print("", file=sys.stderr)
            for d in diffs[:50]:
                print(
                    f"- {d.key}: url {d.before_url!r} / asset {d.before_asset!r} "
                    f"→ url {d.after_url!r} / asset {d.after_asset!r}",
                    file=sys.stderr,
                )
            if len(diffs) > 50:
                print(f"... and {len(diffs) - 50} more", file=sys.stderr)
            return 1
        return 0

    if not args.apply:
        ap.print_help()
        return 2

    before_defaults_text = defaults_path.read_text(encoding="utf-8")
    before_manifest_text = manifest_path.read_text(encoding="utf-8")
    diffs = _apply(defaults, manifest)
    after_defaults_text = json.dumps(defaults, ensure_ascii=False, indent=2) + "\n"

    defaults_changed = after_defaults_text != before_defaults_text
    if defaults_changed:
        _dump_json_pretty(defaults_path, defaults)
        _update_manifest_meta_inplace(manifest)

    after_manifest_text = json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
    manifest_changed = after_manifest_text != before_manifest_text
    if manifest_changed:
        _dump_json_pretty(manifest_path, manifest)

    print(
        "OK: "
        f"synced {len(diffs)} manifest keys; "
        f"defaults_changed={defaults_changed}; "
        f"manifest_meta_changed={manifest_changed}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
