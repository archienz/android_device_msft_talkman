#!/usr/bin/env python3
"""White X-phone mark, pulsing chromatic glitch, then Doom-style 8-bit column melt."""
import math
import os
import random
import subprocess
import zipfile
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance

DIR = Path(__file__).resolve().parent
W, H = 720, 1280
FPS = 30
LOGO_W = 520
SHIFT = (0, -40)
COL = 8  # 8-bit column / block size
STAGE = Path("/tmp/xba-melt")
OUT = DIR / "bootanimation.zip"


def render_mark():
    STAGE.mkdir(parents=True, exist_ok=True)
    svg = DIR / "mark.svg"
    raw = STAGE / "mark.png"
    subprocess.check_call(
        ["rsvg-convert", "-w", str(LOGO_W), "-f", "png", str(svg), "-o", str(raw)]
    )
    mark = Image.open(raw).convert("RGBA")
    canvas = Image.new("RGB", (W, H), (0, 0, 0))
    x = (W - mark.size[0]) // 2 + SHIFT[0]
    y = (H - mark.size[1]) // 2 + SHIFT[1]
    canvas.paste(mark, (x, y), mark)
    return canvas


def pixelate(im, block=COL):
    small = im.resize((W // block, H // block), Image.NEAREST)
    return small.resize((W, H), Image.NEAREST)


def ca_split(base, off_x, off_y=0, g_off=0):
    """Hard RGB split. White overlap stays; fringes go red/cyan."""
    if off_x == 0 and off_y == 0 and g_off == 0:
        return base
    r, g, b = base.split()
    if off_x or off_y:
        r = ImageChops.offset(r, off_x, off_y)
        b = ImageChops.offset(b, -off_x, -off_y)
    if g_off:
        g = ImageChops.offset(g, g_off, 0)
    return Image.merge("RGB", (r, g, b))


def slice_shift(im, rng, n_slices, max_dx):
    """Horizontal tears: copy a scan band and shove it sideways."""
    if n_slices <= 0 or max_dx <= 0:
        return im
    out = im.copy()
    for _ in range(n_slices):
        hgt = rng.randint(1, 14)
        y = rng.randint(0, max(1, H - hgt))
        dx = rng.randint(-max_dx, max_dx)
        if dx == 0:
            continue
        band = out.crop((0, y, W, y + hgt))
        # RGB-split the torn band a bit more so tears look like bad signal
        extra = rng.randint(2, 8)
        r, g, b = band.split()
        band = Image.merge(
            "RGB",
            (
                ImageChops.offset(r, extra, 0),
                g,
                ImageChops.offset(b, -extra, 0),
            ),
        )
        out.paste((0, 0, 0), (0, y, W, y + hgt))
        out.paste(band, (dx, y))
    return out


def smear_streaks(im, rng, n, length):
    """Thin RGB streaks off the logo, like the CA keyframe."""
    if n <= 0 or length <= 0:
        return im
    out = im.copy()
    px = out.load()
    # sample near the logo band (center)
    y0, y1 = H // 3, (2 * H) // 3
    for _ in range(n):
        y = rng.randint(y0, y1)
        x = rng.randint(W // 5, (4 * W) // 5)
        src = px[x, y]
        if src == (0, 0, 0):
            continue
        direction = rng.choice((-1, 1))
        streak = rng.randint(length // 3, length)
        # pick a fringe color
        color = rng.choice(
            (
                (src[0], 0, 0),
                (0, src[1], src[2]),
                (src[0], 0, src[2]),
            )
        )
        for i in range(streak):
            xx = x + direction * i
            if xx < 0 or xx >= W:
                break
            # fade the streak
            fade = 1.0 - (i / streak)
            if fade < 0.15:
                break
            cur = px[xx, y]
            px[xx, y] = (
                min(255, int(cur[0] + color[0] * fade * 0.85)),
                min(255, int(cur[1] + color[1] * fade * 0.85)),
                min(255, int(cur[2] + color[2] * fade * 0.85)),
            )
    return out


def pulse_phase(i, n):
    """0..1 envelope: ~1.2 Hz sine plus a faster flutter."""
    t = i / n
    slow = 0.5 + 0.5 * math.sin(2 * math.pi * t)
    flutter = 0.5 + 0.5 * math.sin(6 * math.pi * t + 0.4)
    return 0.72 * slow + 0.28 * flutter


def glitch_logo(base, pulse, rng, spike=False):
    """pulse 0..1: CA width, tear count, brightness."""
    off = int(round(4 + 14 * pulse))
    if spike:
        off += rng.randint(10, 26)
    off_y = rng.choice((0, 0, 0, 0, 1, -1, 2, -2)) if pulse > 0.55 else 0
    g_off = rng.choice((0, 0, 0, -1, 1)) if rng.random() < 0.25 else 0
    frame = ca_split(base, off, off_y, g_off)
    n_slices = 2 + int(pulse * 9)
    if spike:
        n_slices += rng.randint(3, 7)
    frame = slice_shift(frame, rng, n_slices, max_dx=int(10 + 32 * pulse))
    n_smear = 4 + int(pulse * 14)
    if spike:
        n_smear += 8
    frame = smear_streaks(frame, rng, n_smear, int(18 + 48 * pulse))
    # Pulse brightness — never drop out, never sit at 1.0 the whole time
    bri = 0.74 + 0.26 * pulse
    if spike:
        bri = min(1.15, bri + 0.12)
    return ImageEnhance.Brightness(frame).enhance(bri)


def save(im, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, "PNG", optimize=True)


def fade_in(base, n=32):
    rng = random.Random(104541)
    frames = []
    for i in range(n):
        t = i / (n - 1)
        e = t ** 1.45
        # CA ramps after the mark is visible
        ca = max(0.0, (t - 0.20) / 0.80)
        pulse = 0.15 + 0.55 * ca
        spike = t > 0.55 and rng.random() < 0.18
        frame = glitch_logo(base, pulse, rng, spike=spike)
        frame = ImageEnhance.Brightness(frame).enhance(e)
        frames.append(frame)
    return frames


def pulse_loop(base, n=60):
    """Hold that used to be static white — now a pulsing glitch."""
    rng = random.Random(950)
    frames = []
    for i in range(n):
        pulse = pulse_phase(i, n)
        # Regular spikes so it does not look like a smooth breathe
        spike = (i % 11 == 0) or (i % 17 == 3) or (rng.random() < 0.08)
        frames.append(glitch_logo(base, pulse, rng, spike=spike))
    return frames


def doom_melt(src, n=48):
    """Classic Doom wipe: staggered 8px columns fall, uncovering black."""
    rng = random.Random(950)
    ncols = W // COL
    delays = [rng.randint(0, 8)]
    for _ in range(1, ncols):
        delays.append(max(0, min(16, delays[-1] + rng.choice((-1, 0, 0, 1)))))
    speeds = [COL + (i * 5) % (COL * 2) for i in range(ncols)]
    chunky = pixelate(src, COL)
    frames = []
    for f in range(n):
        out = Image.new("RGB", (W, H), (0, 0, 0))
        done = True
        for c in range(ncols):
            if f <= delays[c]:
                yoff = 0
                done = False
            else:
                yoff = (f - delays[c]) * speeds[c]
            if yoff < H:
                done = False
            col = chunky.crop((c * COL, 0, (c + 1) * COL, H))
            out.paste(col, (c * COL, yoff))
        frames.append(out)
        if done:
            frames.append(Image.new("RGB", (W, H), (0, 0, 0)))
            break
    return frames


def write_part(frames, name):
    d = STAGE / name
    d.mkdir(parents=True, exist_ok=True)
    for i, im in enumerate(frames):
        save(im, d / f"{i:05d}.png")
    return d


def main():
    if STAGE.exists():
        for p in STAGE.rglob("*"):
            if p.is_file():
                p.unlink()
    STAGE.mkdir(parents=True, exist_ok=True)
    base = render_mark()
    save(base, STAGE / "master-white.png")
    p0 = fade_in(base, 32)
    p1 = pulse_loop(base, 60)
    # Melt the last pulsed frame so the wipe starts from a glitched mark
    p2 = doom_melt(p1[-1], 52)
    write_part(p0, "part0")
    write_part(p1, "part1")
    write_part(p2, "part2")
    desc = STAGE / "desc.txt"
    # part1 is p (interruptible) so boot-complete can reach the melt.
    # part2 is c so the melt still runs after service.bootanim.exit.
    desc.write_text(f"{W * 2} {H * 2} {FPS}\nc 1 0 part0\np 0 0 part1\nc 1 0 part2\n")
    if OUT.exists():
        OUT.unlink()
    with zipfile.ZipFile(OUT, "w", compression=zipfile.ZIP_STORED) as z:
        z.write(desc, "desc.txt")
        for part in ("part0", "part1", "part2"):
            for png in sorted((STAGE / part).glob("*.png")):
                z.write(png, f"{part}/{png.name}")
    print(OUT, OUT.stat().st_size, "p0", len(p0), "p1", len(p1), "p2", len(p2))


if __name__ == "__main__":
    main()
