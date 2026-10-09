#!/usr/bin/env python3
"""Proses sprite sheet Arga (hasil generate AI) menjadi file animasi Godot.
Metode: potong grid seragam (rows x cols) per animasi, karena layout
sheet AI sudah cukup rapi. Putih -> transparan, resize ke FRAME_H.
"""
import os
from PIL import Image

SRC_DIR = os.path.expanduser("~/workspace/char_test")
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "assets", "fighters", "fighter_arga")
os.makedirs(OUT_DIR, exist_ok=True)

FRAME_H = 256

# animasi -> (pola_file, rows, cols, baris_yang_dipakai, even_split)
# baris_yang_dipakai: None = semua baris (dibaca berurutan)
# even_split: True = bagi tinggi gambar rata (untuk baris yang rapet)
ANIMS = {
    "idle":     ("arga-idle-test", 1, 6, None, False),
    "walk":     ("arga-walk",      1, 6, None, False),
    "run":      ("arga-run2",      1, 6, None, False),
    "jump":     ("arga-jump2",     1, 4, None, False),
    "attack_1": ("arga-attack1",   1, 6, None, False),
    "attack_2": ("arga-attack2",   1, 6, None, False),
    "attack_3": ("arga-attack3",   1, 6, None, False),
    "shield":   ("arga-shield",    1, 4, None, False),
    "hurt":     ("arga-hurt",      1, 4, None, False),
    "dead":     ("arga-dead",      1, 4, None, False),
}


def find_file(pattern):
    for f in os.listdir(SRC_DIR):
        if f.endswith(".png") and pattern in f:
            return os.path.join(SRC_DIR, f)
    raise FileNotFoundError(pattern)


def row_bands(im):
    """Deteksi pita baris yang berisi konten -> list (y0, y1)."""
    w, h = im.size
    px = im.load()
    rows = []
    for y in range(h):
        cnt = 0
        for x in range(0, w, 4):
            if min(px[x, y][:3]) < 235:
                cnt += 1
                if cnt > 3:
                    break
        rows.append(cnt > 3)
    bands = []
    start = None
    for y, c in enumerate(rows):
        if c and start is None:
            start = y
        elif not c and start is not None:
            if y - start > 20:
                bands.append((start, y - 1))
            start = None
    if start is not None:
        bands.append((start, h - 1))
    return bands


def keep_largest_component(im):
    """Hapus artefak kecil yang terpisah dari badan utama (sisa frame tetangga)."""
    w, h = im.size
    alpha = im.split()[3]
    px = alpha.load()
    seen = bytearray(w * h)
    best = []
    for y in range(h):
        for x in range(w):
            idx = y * w + x
            if px[x, y] > 10 and not seen[idx]:
                # flood fill
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
    mask = Image.new("L", (w, h), 0)
    mp = mask.load()
    for cx, cy in best:
        mp[cx, cy] = 255
    out = im.copy()
    out.putalpha(Image.composite(alpha, Image.new("L", (w, h), 0), mask))
    return out


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


table = {}
for anim, (pattern, rows, cols, use_rows, even_split) in ANIMS.items():
    im = Image.open(find_file(pattern)).convert("RGB")
    w, h = im.size
    if even_split:
        bands = [(i * h // rows, (i + 1) * h // rows - 1) for i in range(rows)]
    else:
        bands = row_bands(im)
        assert len(bands) == rows, "%s: terdeteksi %d baris, ekspektasi %d" % (anim, len(bands), rows)
    if use_rows is None:
        use_rows = list(range(rows))
    cells = []
    max_w = 0
    for r in use_rows:
        y0, y1 = bands[r]
        band_h = y1 - y0 + 1
        cell_w_src = w / cols
        scale = FRAME_H / band_h
        for c in range(cols):
            x0 = int(c * cell_w_src)
            x1 = int((c + 1) * cell_w_src)
            cell = im.crop((x0, y0, x1, y1))
            cell = white_to_transparent(cell)
            nw = max(1, int(cell.size[0] * scale))
            cell = cell.resize((nw, FRAME_H), Image.LANCZOS)
            cells.append(cell)
            max_w = max(max_w, nw)
    # bersihkan artefak terpisah, lalu registrasi horizontal
    cells = [keep_largest_component(c) for c in cells]
    # samakan titik tengah bbox konten antar frame (jangkar: frame 0 untuk dead)
    def content_bbox(im):
        a = im.split()[3]
        return a.getbbox()
    centers = []
    for cell in cells:
        bb = content_bbox(cell)
        centers.append((bb[0] + bb[2]) / 2 if bb else cell.size[0] / 2)
    anchor_idx = {"dead": 0}.get(anim, None)
    median_cx = centers[anchor_idx] if anchor_idx is not None else sorted(centers)[len(centers) // 2]
    shifts = [int(round(median_cx - cx)) for cx in centers]
    # lebarkan kanvas bila ada konten yang terdorong keluar
    pad_l = max(0, -min(shifts))
    pad_r = max(0, max(s + c.size[0] for s, c in zip(shifts, cells)) - cells[0].size[0])
    reg_cells = []
    for cell, s in zip(cells, shifts):
        canvas = Image.new("RGBA", (cell.size[0] + pad_l + pad_r, cell.size[1]), (0, 0, 0, 0))
        canvas.alpha_composite(cell, (pad_l + s, 0))
        reg_cells.append(canvas)
    n = len(reg_cells)
    max_w = max(c.size[0] for c in reg_cells)
    sheet = Image.new("RGBA", (max_w * n, FRAME_H), (0, 0, 0, 0))
    for i, cell in enumerate(reg_cells):
        sheet.paste(cell, (i * max_w, 0), cell)
    out = os.path.join(OUT_DIR, anim + ".png")
    sheet.save(out)
    table[anim] = [n, max_w]
    print("%-10s frames=%d lebar=%d -> %s" % (anim, n, max_w, out))

print("\nTabel untuk fighter.gd:")
print('"arga": {')
print('    "folder": "res://assets/fighters/fighter_arga",')
print('    "frame_h": %d, "sprite_scale": 1.5,' % FRAME_H)
print('    "frames": {')
for anim, (n, fw) in table.items():
    print('        "%s": [%d, %d],' % (anim, n, fw))
print('    },')
print('},')
