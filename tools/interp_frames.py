#!/usr/bin/env python3
"""Sisipkan frame peralihan (blend 50%) antar frame berurutan agar animasi mulus.
Pakai: python3 tools/interp_frames.py
Memproses semua karakter AI (yang punya feet_y) untuk animasi:
  walk, run (dengan wrap/lingkar) dan jump, attack_1/2/3 (tanpa wrap).
Tabel [jumlah, lebar] di fighter.gd diupdate otomatis.
"""
import re
import os
from PIL import Image

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FGD = os.path.join(BASE, "fighters", "fighter.gd")

LOOP_ANIMS = {"walk", "run"}          # blend frame terakhir -> pertama
INTERP_ANIMS = {"walk", "run", "jump", "attack_1", "attack_2", "attack_3"}


def parse_table(src):
    chars = {}
    for m in re.finditer(r'"(\w+)": \{\s*\n\t\t"folder": "([^"]+)",', src):
        cid = m.group(1)
        bs = m.start()
        be = src.index('\n\t},', bs)
        block = src[bs:be]
        if '"feet_y"' not in block:
            continue  # lewati samurai/shinobi (aset original)
        frames = {}
        for am in re.finditer(r'"(\w+)": \[(\d+), (\d+)\]', block):
            frames[am.group(1)] = [int(am.group(2)), int(am.group(3))]
        chars[cid] = {"block_start": bs, "block_end": be, "frames": frames,
                      "folder": m.group(2).replace("res://", "")}
    return chars


def interp_sheet(path, count, loop):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    fw = w // count
    cells = [im.crop((i * fw, 0, (i + 1) * fw, h)) for i in range(count)]
    out = []
    for i, c in enumerate(cells):
        out.append(c)
        j = (i + 1) % count if loop else i + 1
        if j < count:
            out.append(Image.blend(c, cells[j], 0.5))
    sheet = Image.new("RGBA", (fw * len(out), h), (0, 0, 0, 0))
    for i, c in enumerate(out):
        sheet.paste(c, (i * fw, 0), c)
    sheet.save(path)
    return len(out)


def main():
    src = open(FGD).read()
    chars = parse_table(src)
    # proses dari belakang agar offset blok tidak bergeser
    for cid in sorted(chars, key=lambda c: chars[c]["block_start"], reverse=True):
        info = chars[cid]
        marker = os.path.join(BASE, info["folder"], ".interp_done")
        if os.path.exists(marker):
            print("%-8s sudah di-interpolasi, lewati" % cid)
            continue
        changed = {}
        for anim in INTERP_ANIMS:
            if anim not in info["frames"]:
                continue
            cnt, fw = info["frames"][anim]
            # lewati yang sudah di-interpolasi (tandai via file .interp)
            path = os.path.join(BASE, info["folder"], anim + ".png")
            new_cnt = interp_sheet(path, cnt, anim in LOOP_ANIMS)
            changed[anim] = new_cnt
            print("%-8s %-10s %d -> %d frame" % (cid, anim, cnt, new_cnt))
        # update tabel di fighter.gd
        bs, be = info["block_start"], info["block_end"]
        block = src[bs:be]
        for anim, new_cnt in changed.items():
            cnt, fw = info["frames"][anim]
            block = block.replace('"%s": [%d, %d]' % (anim, cnt, fw),
                                  '"%s": [%d, %d]' % (anim, new_cnt, fw))
        src = src[:bs] + block + src[be:]
        open(marker, "w").write("ok")
    open(FGD, "w").write(src)
    print("fighter.gd updated")


if __name__ == "__main__":
    main()
