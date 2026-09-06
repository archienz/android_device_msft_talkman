#!/usr/bin/env python3
"""X-phone void wall: stars + planetary horizon (home-mockup scene, no chrome)."""
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageChops

DIR = Path(__file__).resolve().parent
SEED = "talkman-xphone-void-20260905"


def scene(w, h, cx=None):
    rng = random.Random(SEED)
    if cx is None:
        cx = w / 2.0
    img = Image.new("RGB", (w, h), (1, 1, 3))
    px = img.load()

    n = int(w * h / 1800)
    for _ in range(n):
        x = rng.randint(0, w - 1)
        y = rng.randint(0, int(h * 0.78))
        fall = 1.0 - (y / h) * 0.35
        b = int(rng.choice([70, 110, 150, 200, 255]) * fall)
        s = 1 if rng.random() > 0.08 else 2
        for dy in range(s):
            for dx in range(s):
                xx, yy = x + dx, y + dy
                if 0 <= xx < w and 0 <= yy < h:
                    px[xx, yy] = (b, b, min(255, b + 8))

    glow = Image.new("RGB", (w, h), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cy = h * 1.08
    rx = w * 0.92
    ry = h * 0.42
    for i in range(70, 0, -1):
        t = i / 70.0
        v = int(210 * (t ** 1.6))
        gd.ellipse(
            [cx - rx * (0.55 + t * 0.55), cy - ry * (0.55 + t * 0.55),
             cx + rx * (0.55 + t * 0.55), cy + ry * (0.55 + t * 0.55)],
            outline=(v, v, min(255, v + 12)),
        )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=max(8, w // 180)))
    img = ImageChops.lighter(img, Image.blend(img, glow, 0.75))

    draw = ImageDraw.Draw(img)
    steps = 360
    pts = []
    for i in range(steps + 1):
        a = math.pi * (0.18 + 0.64 * i / steps)
        x = cx + math.cos(a) * rx * 0.78
        y = cy - math.sin(a) * ry * 0.78
        pts.append((x, y))
    draw.line(pts, fill=(220, 220, 228), width=max(2, w // 700))

    for i in range(0, steps, 12):
        a = math.pi * (0.18 + 0.64 * i / steps)
        c, s = math.cos(a), math.sin(a)
        x0 = cx + c * rx * 0.78
        y0 = cy - s * ry * 0.78
        x1 = cx + c * rx * 0.805
        y1 = cy - s * ry * 0.805
        draw.line([(x0, y0), (x1, y1)], fill=(90, 90, 96), width=1)

    return img


def main():
    wall1440 = scene(1440, 2560)
    wall2880 = scene(2880, 2560, cx=1440)
    wall1440.save(DIR / "default_wallpaper.png", "PNG")
    wall1440.save(DIR / "default_wallpaper_1440.png", "PNG")
    wall2880.save(DIR / "default_wallpaper_2880.png", "PNG")
    print("wrote", DIR / "default_wallpaper.png", wall1440.size)
    print("wrote", DIR / "default_wallpaper_2880.png", wall2880.size)


if __name__ == "__main__":
    main()
