#!/usr/bin/env python3
"""Proses sprite sheet karakter hasil generate AI menjadi file animasi Godot.
Pakai: python3 tools/process_char.py marco
(nama karakter harus ada di CONFIG di bawah; file sumber di ~/workspace/char_test
 dengan pola nama '<id>_<animasi>' pada nama file generate)

Langkah per animasi:
- potong grid seragam (1 baris x N kolom)
- putih -> transparan
- buang artefak terpisah (komponen terbesar saja)
- registrasi horizontal (samakan titik tengah antar frame)
- resize ke FRAME_H, satukan jadi strip, simpan ke assets/fighters/fighter_<id>/
- cetak tabel [jumlah_frame, lebar_frame] untuk CHARACTERS di fighter.gd
"""
import os
import sys
from PIL import Image

SRC_DIR = os.path.expanduser("~/workspace/char_test")
BASE_OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                        "assets", "fighters")
FRAME_H = 256

# id -> (jumlah frame per animasi, animasi yang jangkarnya frame 0)
CONFIG = {
    "marco":   ({"idle": 6, "walk": 6, "run": 6, "jump": 4, "attack_1": 6,
                 "attack_2": 6, "attack_3": 6, "shield": 4, "hurt": 4, "dead": 4}, {}),
    "dmitri":  ({"idle": 6, "walk": 6, "run": 6, "jump": 4, "attack_1": 6,
                 "attack_2": 6, "attack_3": 6, "shield": 4, "hurt": 4, "dead": 4}, {}),
    "lin":     ({"idle": 6, "walk": 6, "run": 6, "jump": 4, "attack_1": 6,
                 "attack_2": 6, "attack_3": 6, "shield": 4, "hurt": 4, "dead": 4}, {}),
    "nok":     ({"idle": 6, "walk": 6, "run": 6, "jump": 4, "attack_1": 6,
                 "attack_2": 6, "attack_3": 6, "shield": 4, "hurt": 4, "dead": 4}, {}),
    "sora":    ({"idle": 6, "walk": 6, "run": 6, "jump": 4, "attack_1": 6,
                 "attack_2": 6, "attack_3": 6, "shield": 4, "hurt": 4, "dead": 4}, {}),
    "tyrone":  ({"idle": 6, "walk": 6, "run": 6, "jump": 4, "attack_1": 6,
                 "attack_2": 6, "attack_3": 6, "shield": 4, "hurt": 4, "dead": 4}, {}),
    "han":     ({"idle": 6, "walk": 6, "run": 6, "jump": 4, "attack_1": 6,
                 "attack_2": 6, "attack_3": 6, "shield": 4, "hurt": 4, "dead": 4}, {}),
    "valeria": ({"idle": 6, "walk": 6, "run": 6, "jump": 4, "attack_1": 6,
                 "attack_2": 6, "attack_3": 6, "shield": 4, "hurt": 4, "dead": 4}, {}),
    "anika":   ({"idle": 6, "walk": 6, "run": 6, "jump": 4, "attack_1": 6,
                 "attack_2": 6, "attack_3": 6, "shield": 4, "hurt": 4, "dead": 4}, {}),
}


def find_file(char_id, anim):
    # cari file yang mengandung pola '<id>' dan '<anim>' (toleran variasi nama)
    cands = []
    for f in os.listdir(SRC_DIR):
        if not f.endswith(".png"):
            continue
        fl = f.lower().replace("_", "").replace("-", "")
        if char_id in fl and anim.replace("_", "") in fl:
            cands.append(os.path.join(SRC_DIR, f))
    if not cands:
        raise FileNotFoundError("%s %s" % (char_id, anim))
    # pilih yang terbaru bila ada beberapa
    cands.sort(key=os.path.getmtime)
    return cands[-1]


def white_to_transparent(im):
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if min(r, g, b) > 238:
                px[x, y] = (r, g, b, 0)
    return im


def keep_largest_component(im):
    w, h = im.size
    alpha = im.split()[3]
    px = alpha.load()
    seen = bytearray(w * h)
    best = []
    for y in range(h):
        for x in range(w):
            idx = y * w + x
            if px[x, y] > 10 and not seen[idx]:
                stack = [(x, y)]
                seen[idx] = 1
                comp = []
                while stack:
                    cx, cy = stack.pop()
                    comp.append((cx, cy))
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if 0 <= nx < w and 0 <= ny < h:
                            nidx = ny * w + nx
                            if px[nx, ny] > 10 and not seen[nidx]:
                                seen[nidx] = 1
                                stack.append((nx, ny))
                if len(comp) > len(best):
                    best = comp
    if not best:
        return im
    mask = Image.new("L", (w, h), 0)
    mp = mask.load()
    for cx, cy in best:
        mp[cx, cy] = 255
    out = im.copy()
    out.putalpha(Image.composite(alpha, Image.new("L", (w, h), 0), mask))
    return out


def process(char_id):
    anims, anchors = CONFIG[char_id]
    out_dir = os.path.join(BASE_OUT, "fighter_" + char_id)
    os.makedirs(out_dir, exist_ok=True)
    table = {}
    for anim, cols in anims.items():
        im = Image.open(find_file(char_id, anim)).convert("RGB")
        w, h = im.size
        cw = w / cols
        scale = FRAME_H / h
        cells = []
        for c in range(cols):
            x0 = int(c * cw)
            x1 = int((c + 1) * cw)
            cell = white_to_transparent(im.crop((x0, 0, x1, h)))
            nw = max(1, int(cell.size[0] * scale))
            cell = cell.resize((nw, FRAME_H), Image.LANCZOS)
            cells.append(keep_largest_component(cell))
        # registrasi horizontal
        def cb(im2):
            return im2.split()[3].getbbox()
        centers = []
        for cell in cells:
            bb = cb(cell)
            centers.append((bb[0] + bb[2]) / 2 if bb else cell.size[0] / 2)
        ref = centers[anchors[anim]] if anim in anchors else sorted(centers)[len(centers) // 2]
        shifts = [int(round(ref - cx)) for cx in centers]
        pad_l = max(0, -min(shifts))
        pad_r = max(0, max(s + c.size[0] for s, c in zip(shifts, cells)) - cells[0].size[0])
        reg = []
        for cell, s in zip(cells, shifts):
            canvas = Image.new("RGBA", (cell.size[0] + pad_l + pad_r, cell.size[1]), (0, 0, 0, 0))
            canvas.alpha_composite(cell, (pad_l + s, 0))
            reg.append(canvas)
        max_w = max(c.size[0] for c in reg)
        sheet = Image.new("RGBA", (max_w * len(reg), FRAME_H), (0, 0, 0, 0))
        for i, cell in enumerate(reg):
            sheet.paste(cell, (i * max_w, 0), cell)
        sheet.save(os.path.join(out_dir, anim + ".png"))
        table[anim] = [len(reg), max_w]
        print("%-10s frames=%d lebar=%d" % (anim, len(reg), max_w))
    print('\n"%s": {' % char_id)
    print('    "folder": "res://assets/fighters/fighter_%s",' % char_id)
    print('    "frame_h": 256, "sprite_scale": 1.15,')
    print('    "frames": {')
    for anim, (n, fw) in table.items():
        print('        "%s": [%d, %d],' % (anim, n, fw))
    print('    },')
    print('},')


if __name__ == "__main__":
    process(sys.argv[1])
