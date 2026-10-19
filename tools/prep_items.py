#!/usr/bin/env python3
"""Turn the generated item art into game-ready transparent sprites.

The generator gave each item a pink *gradient* backdrop with a soft ground
shadow and a small corner watermark. A flat colour key can't cope, so this:

  1. flood-fills inward from the border with a neighbour tolerance, which
     follows the gradient AND the shadow (each step compares to its neighbour),
     while a global cap stops the fill leaking through the item
  2. floods the corner watermark blob into the mask, size-guarded
  3. feathers the alpha and trims to the item, then resizes

Originals are copied to assets/ui/_raw/ on first run.

    python3 tools/prep_items.py
"""
from __future__ import annotations
import os, shutil, sys
from collections import deque
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
UI = os.path.normpath(os.path.join(HERE, "..", "assets", "ui"))
RAW = os.path.join(UI, "_raw")

ITEMS = [
    "item_toilet_cleaner", "item_bleach", "item_bug_spray", "item_battery",
    "item_thinner", "item_weed_killer", "item_fertilizer", "item_lab_acid",
    "item_paint_solvent", "item_dish_soap", "item_soap", "item_toothpaste",
    "item_water_bottle", "item_cooking_oil", "item_milk",
]
TARGET = (420, 420)

# Tightened from 34/165: the looser values let the fill bridge across the soft
# gradient where a pale item body meets the pink backdrop, eating holes into the
# bottle. Lower tolerances keep the fill on the true background.
STEP_TOL = 22.0      # max per-step neighbour drift that still counts as bg
GLOBAL_TOL = 120.0   # max drift from the border colour overall (leak guard)
WM_BOX = (0.24, 0.30)
WM_MAX_AREA = 0.05


def flood_bg(rgb: np.ndarray) -> np.ndarray:
    h, w, _ = rgb.shape
    flat = rgb.reshape(-1, 3).astype(np.int16)
    mask = np.zeros(h * w, dtype=bool)
    q: deque[int] = deque()
    border = ([y * w for y in range(h)] + [y * w + w - 1 for y in range(h)]
              + [x for x in range(w)] + [(h - 1) * w + x for x in range(w)])
    seed = np.median(flat[border], axis=0)
    for i in border:
        if not mask[i]:
            mask[i] = True
            q.append(i)
    while q:
        i = q.popleft()
        ci = flat[i]
        y, x = divmod(i, w)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if ny < 0 or ny >= h or nx < 0 or nx >= w:
                continue
            j = ny * w + nx
            if mask[j]:
                continue
            cj = flat[j]
            if abs(int(cj[0]) - int(ci[0])) + abs(int(cj[1]) - int(ci[1])) \
                    + abs(int(cj[2]) - int(ci[2])) > STEP_TOL:
                continue
            if abs(cj - seed).sum() > GLOBAL_TOL:
                continue
            mask[j] = True
            q.append(j)
    return mask.reshape(h, w)


def lift_watermark(rgb: np.ndarray, bg: np.ndarray) -> np.ndarray:
    h, w, _ = rgb.shape
    flat = rgb.reshape(-1, 3).astype(np.int16)
    bx = int(w * (1 - WM_BOX[0]))
    by = int(h * (1 - WM_BOX[1]))
    seeds = [y * w + x for y in range(by, h) for x in range(bx, w) if not bg[y, x]]
    if not seeds:
        return bg
    got = np.zeros(h * w, dtype=bool)
    q = deque()
    for i in seeds:
        if not got[i]:
            got[i] = True
            q.append(i)
    limit = int(h * w * WM_MAX_AREA)
    count = len(seeds)
    while q:
        i = q.popleft()
        ci = flat[i]
        y, x = divmod(i, w)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if ny < 0 or ny >= h or nx < 0 or nx >= w:
                continue
            j = ny * w + nx
            if got[j] or bg[ny, nx]:
                continue
            if abs(flat[j] - ci).sum() > 96:
                continue
            got[j] = True
            count += 1
            if count > limit:
                return bg      # leaked into the art - leave it
            q.append(j)
    return bg | got.reshape(h, w)


def process(name: str) -> bool:
    src = os.path.join(UI, name + ".png")
    if not os.path.exists(src):
        print(f"  -- {name}: missing")
        return False
    os.makedirs(RAW, exist_ok=True)
    keep = os.path.join(RAW, name + ".png")
    if not os.path.exists(keep):
        shutil.copy2(src, keep)

    img = Image.open(keep).convert("RGB")
    work = img.copy()
    work.thumbnail((1000, 1000), Image.LANCZOS)
    rgb = np.asarray(work)

    bg = flood_bg(rgb)
    bg = lift_watermark(rgb, bg)

    # Only background that is actually connected to the frame edge should be
    # transparent. Keep the largest edge-touching background blob, then fill any
    # holes inside the item so a light label area or a bridge the flood squeezed
    # through can't leave the bottle see-through.
    fg = ~bg
    fg = ndimage.binary_fill_holes(fg)
    # drop stray freckles of foreground left in the corners (watermark remnants)
    lab, n = ndimage.label(fg)
    if n > 1:
        sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
        keep = int(np.argmax(sizes)) + 1
        fg = lab == keep
    bg = ~fg

    alpha = Image.fromarray((fg * 255).astype(np.uint8), "L") \
        .filter(ImageFilter.GaussianBlur(0.8))
    out = work.convert("RGBA")
    out.putalpha(alpha)
    arr = np.asarray(out).copy()
    arr[arr[..., 3] == 0] = (0, 0, 0, 0)
    out = Image.fromarray(arr, "RGBA")

    box = out.getbbox()
    if box:
        out = out.crop(box)
    out.thumbnail(TARGET, Image.LANCZOS)
    canvas = Image.new("RGBA", TARGET, (0, 0, 0, 0))
    canvas.paste(out, ((TARGET[0] - out.width) // 2, (TARGET[1] - out.height) // 2), out)
    canvas.save(src)
    print(f"  ok {name:24s} bg removed {100.0 * bg.mean():.0f}%")
    return True


def main() -> int:
    done = 0
    for n in ITEMS:
        if process(n):
            done += 1
    print(f"\n{done}/{len(ITEMS)} processed. Originals in assets/ui/_raw/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
