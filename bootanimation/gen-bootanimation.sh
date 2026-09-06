#!/usr/bin/env bash
# Build talkman X-phone bootanimation.zip (1440x2560, stored).
# Replaces vendor/lineage generated LineageOS animation via TARGET_BOOTANIMATION.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$DIR/bootanimation.zip"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

W=1440
H=2560
FPS=30
LOGO_W=980
SHIFT="+0-80"

rsvg-convert -w "$LOGO_W" -f png "$DIR/mark.svg" -o "$STAGE/mark.png"
mkdir -p "$STAGE/part0" "$STAGE/part1"

# part0: 36-frame ease-in fade, 12-frame hold
python3 - "$STAGE" "$W" "$H" "$SHIFT" <<'PY'
import math, os, subprocess, sys
stage, w, h, shift = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
mark = os.path.join(stage, "mark.png")

def frame(path, pct):
    subprocess.check_call([
        "magick", "-size", f"{w}x{h}", "xc:black", mark,
        "-gravity", "center", "-geometry", shift,
        "-compose", "dissolve", "-define", f"compose:args={pct}",
        "-composite", "-depth", "8", f"PNG8:{path}",
    ])

n_fade, n_hold = 36, 12
for i in range(n_fade):
    t = i / (n_fade - 1)
    pct = int(round(100 * (t ** 1.65)))
    frame(os.path.join(stage, "part0", f"{i:05d}.png"), pct)
for i in range(n_hold):
    frame(os.path.join(stage, "part0", f"{n_fade + i:05d}.png"), 100)

# part1: 60-frame breathe (loop until boot completes)
n_loop = 60
for i in range(n_loop):
    t = i / n_loop
    pct = int(round(58 + 42 * (0.5 + 0.5 * math.cos(2 * math.pi * t))))
    frame(os.path.join(stage, "part1", f"{i:05d}.png"), pct)
PY

printf '%s %s %s\nc 1 0 part0\nc 0 0 part1\n' "$W" "$H" "$FPS" > "$STAGE/desc.txt"
rm -f "$OUT"
# Android bootanim requires stored (no deflate).
( cd "$STAGE" && zip -0 -X "$OUT" desc.txt part0/*.png part1/*.png )
ls -l "$OUT"
unzip -l "$OUT" | tail -5
