#!/usr/bin/env python3
"""生成底部 Tab 导航图（256×256 PNG，透明底，低龄卡通配色）。"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

# 与 lib/utils/app_theme.dart 一致
ORANGE = (255, 107, 53, 255)
YELLOW = (255, 210, 63, 255)
GREEN = (76, 175, 80, 255)
BLUE = (33, 150, 243, 255)
PINK = (233, 145, 200, 255)
WHITE = (255, 255, 255, 255)


def _rounded_rect(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float, float, float],
    radius: float,
    fill: tuple[int, int, int, int],
) -> None:
    draw.rounded_rectangle(xy, radius=radius, fill=fill)


def draw_pinyin(out: Path) -> None:
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # 声波 + 字母感：圆角竖条 + 小圆点
    _rounded_rect(d, (88, 72, 112, 200), 18, ORANGE)
    _rounded_rect(d, (120, 56, 144, 216), 18, YELLOW)
    _rounded_rect(d, (152, 64, 176, 208), 18, ORANGE)
    d.ellipse((196, 100, 224, 128), fill=WHITE)
    d.ellipse((200, 140, 220, 160), fill=PINK)
    im.save(out, "PNG", optimize=True)


def draw_learn(out: Path) -> None:
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # 打开的绘本
    _rounded_rect(d, (56, 88, 122, 200), 14, BLUE)
    _rounded_rect(d, (134, 80, 200, 200), 14, GREEN)
    d.polygon([(120, 88), (136, 72), (152, 88)], fill=YELLOW)
    # 简单「一」字
    _rounded_rect(d, (92, 132, 164, 148), 8, WHITE)
    im.save(out, "PNG", optimize=True)


def draw_game(out: Path) -> None:
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # 圆润手柄
    _rounded_rect(d, (48, 100, 208, 168), 40, ORANGE)
    d.ellipse((72, 116, 104, 148), fill=WHITE)
    d.ellipse((152, 116, 184, 148), fill=WHITE)
    _rounded_rect(d, (112, 128, 144, 152), 10, YELLOW)
    im.save(out, "PNG", optimize=True)


def draw_vocab(out: Path) -> None:
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # 小笔记本
    _rounded_rect(d, (100, 96, 196, 184), 12, WHITE)
    _rounded_rect(d, (100, 96, 196, 112), 12, ORANGE)
    _rounded_rect(d, (112, 124, 184, 132), 4, PINK)
    _rounded_rect(d, (112, 144, 168, 152), 4, BLUE)
    # 星星
    cx, cy, r = 76, 112, 36
    pts = []
    for i in range(10):
        ang = i * 3.14159 / 5 - 3.14159 / 2
        rad = r if i % 2 == 0 else r * 0.45
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    d.polygon(pts, fill=YELLOW)
    im.save(out, "PNG", optimize=True)


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    out_dir = root / "assets" / "images"
    out_dir.mkdir(parents=True, exist_ok=True)
    spec = [
        ("img_nav_pinyin.png", draw_pinyin),
        ("img_nav_learn.png", draw_learn),
        ("img_nav_game.png", draw_game),
        ("img_nav_vocab.png", draw_vocab),
    ]
    for name, fn in spec:
        fn(out_dir / name)
        print(f"Wrote {out_dir / name}")


if __name__ == "__main__":
    main()
