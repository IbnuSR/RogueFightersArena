#!/usr/bin/env python3
"""Render QA: tampilkan tiap animasi tiap karakter persis seperti di game
(skala + posisi dari anim_fix), dengan garis tanah. Untuk inspeksi visual."""
import re
import os
from PIL import Image, ImageDraw

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = open(os.path.join(BASE, "fighters", "fighter.gd")).read()

INTERP = {"walk", "run", "jump", "attack_1", "attack_2", "attack_3"}
ANIMS = ["idle", "walk", "run", "jump", "attack_1", "attack_2", "attack_3",
         "shield", "hurt", "dead"]


def get_info(cid):
    block = SRC.split('"%s": {' % cid)[1].split('\n\t},')[0]
    sc = float(re.search(r'"sprite_scale": ([\d.]+)', block).group(1)) \
        if '"sprite_scale"' in block else 3.0
    fh = int(re.search(r'"frame_h": (\d+)', block).group(1)) \
        if '"frame_h"' in block else 128
    folder = re.search(r'"folder": "res://([^"]+)"', block).group(1)
    frames = {}
    for m in re.finditer(r'"(\w+)": \[(\d+), (\d+)\]', block):
        frames[m.group(1)] = (int(m.group(2)), int(m.group(3)))
    fixes = {}
    m2 = re.search(r'"anim_fix": \{([^}]*)\}', block)
    if m2:
        for m in re.finditer(r'"(\w+)": \[([\d.]+), ([-\d.]+)\]', m2.group(1)):
            fixes[m.group(1)] = (float(m.group(2)), float(m.group(3)))
    feet_y = int(re.search(r'"feet_y": (\d+)', block).group(1)) \
        if '"feet_y"' in block else fh
    base_py = -10.0 + (fh * sc) / 2.0 - feet_y * sc
    return sc, fh, folder, frames, fixes, base_py


def render_char(cid, out_path):
    sc, fh, folder, frames, fixes, base_py = get_info(cid)
    CW, CH = 220, 360
    sheet = Image.new("RGB", (CW * len(ANIMS), CH + 28), (25, 25, 35))
    d = ImageDraw.Draw(sheet)
    for i, anim in enumerate(ANIMS):
        if anim not in frames:
            continue
        cnt, fw = frames[anim]
        ns, npy = fixes.get(anim, (sc, base_py))
        im = Image.open(os.path.join(BASE, folder, anim + ".png")).convert("RGBA")
        idx = 2 if (anim in INTERP and cnt > 4) else 0
        idx = min(idx, cnt - 1)
        f = im.crop((idx * fw, 0, (idx + 1) * fw, im.size[1]))
        nw, nh = max(1, int(f.size[0] * ns)), max(1, int(f.size[1] * ns))
        f = f.resize((nw, nh), Image.LANCZOS)
        gy = CH - 30
        top = int(gy + npy - nh / 2)
        try:
            sheet.paste(f, (i * CW + CW // 2 - nw // 2, top), f)
        except ValueError:
            pass
        d.line([(i * CW, gy), ((i + 1) * CW, gy)], fill=(120, 120, 140), width=2)
        d.text((i * CW + 6, CH + 4), "%s %.2f" % (anim[:7], ns / sc),
               fill=(255, 220, 100))
    d.text((8, 4), cid.upper(), fill=(255, 255, 255))
    sheet.save(out_path)


if __name__ == "__main__":
    import sys
    outdir = sys.argv[1] if len(sys.argv) > 1 else "/tmp/qa"
    os.makedirs(outdir, exist_ok=True)
    cids = re.findall(r'"(\w+)": \{\s*\n\t\t"folder":', SRC)
    for cid in cids:
        render_char(cid, os.path.join(outdir, "qa_%s.png" % cid))
        print("qa_%s.png" % cid)
