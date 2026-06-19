#!/usr/bin/env python3
"""Post-process a raw GenerateImage output into a pinyin quiz icon."""
from __future__ import annotations

import json
import sys
from datetime import date
from pathlib import Path

from PIL import Image


def process(
    raw_path: Path,
    config_key: str,
    asset_filename: str,
    *,
    threshold: int = 240,
    size: int = 256,
    app_dir: Path | None = None,
) -> Path:
    app_dir = app_dir or Path(__file__).resolve().parent.parent
    out_path = app_dir / "assets/images/pinyin_icons" / asset_filename
    out_path.parent.mkdir(parents=True, exist_ok=True)

    im = Image.open(raw_path).convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if r >= threshold and g >= threshold and b >= threshold:
                px[x, y] = (r, g, b, 0)

    scale = max(size / w, size / h)
    new_w, new_h = int(w * scale), int(h * scale)
    im = im.resize((new_w, new_h), Image.LANCZOS)
    left, top = (new_w - size) // 2, (new_h - size) // 2
    im = im.crop((left, top, left + size, top + size))
    im.save(out_path, "PNG", optimize=True)

    rel = f"assets/images/pinyin_icons/{asset_filename}"
    cfg_path = app_dir / "assets/default_configs.json"
    with open(cfg_path, encoding="utf-8") as f:
        cfg = json.load(f)
    cfg[config_key] = {"url": None, "asset": rel}
    with open(cfg_path, "w", encoding="utf-8") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)
        f.write("\n")

    manifest_path = (
        Path.home()
        / ".claude/knowledge/ui-assistant/hanzi/image_manifest.json"
    )
    with open(manifest_path, encoding="utf-8") as f:
        manifest = json.load(f)
    meta = manifest["pages"]["pinyin_exercise_icons"]["images"][config_key]
    meta.update(
        {
            "asset_path": rel,
            "status": "local",
            "format": "png",
            "last_updated": date.today().isoformat(),
        }
    )
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
        f.write("\n")

    return out_path


if __name__ == "__main__":
    process(
        Path(sys.argv[1]),
        sys.argv[2],
        sys.argv[3],
    )
    print(f"OK {sys.argv[3]}")
