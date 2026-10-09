#!/usr/bin/env python3
"""Proses batch 99 sheet baru dari /tmp/raw_<id>/ menjadi sprite game-ready.
- Putih -> transparan, slice N frame, resize tinggi 256px,
- registrasi horizontal (konten di tengah cell), bersihkan noise,
- simpan ke assets/fighters/fighter_<id>/<anim>.png
- Update tabel frames di fighter.gd (jumlah frame & lebar cell).
"""
import re
import os
import glob
from PIL import Image
from scipy import ndimage
import numpy as np

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FGD = os.path.join(BASE, "fighters", "fighter.gd")

CHARS = ["arga", "marco", "dmitri", "lin", "nok",
         "sora", "tyrone", "han", "valeria", "anika"]
ANIM_FRAMES = {
    "idle": 6, "walk": 6, "run": 6, "jump": 4,
    "attack_1": 6, "attack_2": 6, "attack_3": 6,
    "shield": 4, "hurt": 4, "dead": 4,
}
FRAME_H = 256
# valeria_dead: pakai yang lama (generate baru ditolak)
SKIP = {("valeria", "dead")}


def find_raw(cid, anim):
    d = "/tmp/raw_%s" % cid
    # dmitri pakai subfolder final/
    for sub in [d + "/final", d]:
        if not os.path.isdir(sub):
            continue
        # 1. nama sederhana: han_attack_1.png
        simple = os.path.join(sub, "%s_%s.png" % (cid, anim))
        if os.path.exists(simple):
            return simple
        # 2. pola webp dengan UUID
        pat = anim.replace("_", "-")
        cands = []
        for ext in ("*.webp", "*.png"):
            for f in glob.glob(os.path.join(sub, ext)):
                bn = os.path.basename(f)
                if ("-%s-" % pat in bn or pat in bn
                        or bn.startswith("%s_%s" % (cid, anim))):
                    cands.append(f)
        cands = [f for f in cands if not f.endswith(".json")]
        if cands:
            cands.sort(key=lambda f: os.path.getsize(f), reverse=True)
            return cands[0]
    return None


def white_to_transparent(im):
    im = im.convert("RGBA")
    arr = np.array(im)
    # putih (semua channel > 240) -> transparan
    mask = (arr[:, :, 0] > 240) & (arr[:, :, 1] > 240) & (arr[:, :, 2] > 240)
    arr[mask, 3] = 0
    return Image.fromarray(arr)


def largest_component(alpha):
    arr = np.array(alpha)
    bin_arr = arr > 10
    labeled, n = ndimage.label(bin_arr)
    if n == 0:
        return bin_arr
    sizes = ndimage.sum(bin_arr, labeled, range(1, n + 1))
    biggest = 1 + int(np.argmax(sizes))
    return labeled == biggest


def process_sheet(path, n_frames, out_path):
    im = white_to_transparent(Image.open(path))
    w, h = im.size
    # samakan tinggi frame ke 256 (pertahankan aspek)
    sc0 = FRAME_H / h
    im = im.resize((int(round(w * sc0)), FRAME_H), Image.LANCZOS)
    w, h = im.size
    fw_src = w / n_frames
    cells = []
    max_cw = 0
    for i in range(n_frames):
        x0 = int(round(i * fw_src))
        x1 = int(round((i + 1) * fw_src))
        cell = im.crop((x0, 0, x1, h))
        # bersihkan komponen kecil (noise)
        a = cell.split()[3]
        keep = largest_component(a)
        cell_arr = np.array(cell)
        cell_arr[:, :, 3] = np.where(keep, cell_arr[:, :, 3], 0)
        cell = Image.fromarray(cell_arr)
        bb = cell.split()[3].getbbox()
        if bb:
            pad = 6
            cw = (bb[2] - bb[0]) + pad * 2
            max_cw = max(max_cw, cw)
            cells.append((cell, bb))
        else:
            cells.append((cell, None))
    if max_cw == 0:
        raise ValueError("sheet kosong: %s" % path)
    # bangun sheet: cell seragam, konten digeser horizontal agar di tengah
    # (posisi vertikal dipertahankan untuk grounding)
    sheet = Image.new("RGBA", (max_cw * n_frames, FRAME_H), (0, 0, 0, 0))
    for i, (cell, bb) in enumerate(cells):
        if bb is None:
            continue
        pad = 6
        content_cx = (bb[0] + bb[2]) / 2
        cell_cx_src = cell.size[0] / 2
        shift_x = int(round((max_cw / 2) - content_cx))
        # tempel cell dengan offset agar konten di tengah
        tmp = Image.new("RGBA", (max_cw, FRAME_H), (0, 0, 0, 0))
        # crop area konten + pad, tempel di tengah
        x0b = max(0, bb[0] - pad)
        x1b = min(cell.size[0], bb[2] + pad)
        cropped = cell.crop((x0b, 0, x1b, FRAME_H))
        dx = (max_cw - cropped.size[0]) // 2
        tmp.paste(cropped, (dx, 0), cropped)
        sheet.paste(tmp, (i * max_cw, 0), tmp)
    sheet.save(out_path)
    return max_cw


def main():
    src = open(FGD).read()
    for cid in CHARS:
        outdir = os.path.join(BASE, "assets", "fighters", "fighter_" + cid)
        os.makedirs(outdir, exist_ok=True)
        for anim, n in ANIM_FRAMES.items():
            if (cid, anim) in SKIP:
                print("%-8s %-10s SKIP (pakai lama)" % (cid, anim))
                continue
            raw = find_raw(cid, anim)
            if not raw:
                print("%-8s %-10s RAW TIDAK KETEMU!" % (cid, anim))
                continue
            out = os.path.join(outdir, anim + ".png")
            # backup yang lama
            if os.path.exists(out):
                os.rename(out, out + ".bak")
            try:
                cw = process_sheet(raw, n, out)
                print("%-8s %-10s ok (cell %dpx)" % (cid, anim, cw))
                # update tabel
                pat = r'("%s": \{\s*\n\t\t"folder": "[^"]+",\n(?:.*\n)*?\t\t"frames": \{[^}]*?)("%s": )\[\d+, \d+\]' % (cid, anim)
                # cara sederhana: ganti dalam blok karakter
                bs = src.index('"%s": {' % cid)
                be = src.index('\n\t},', bs)
                block = src[bs:be]
                block2, nn = re.subn(r'"%s": \[\d+, \d+\]' % anim,
                                     '"%s": [%d, %d]' % (anim, n, cw),
                                     block, count=1)
                if nn == 1:
                    src = src[:bs] + block2 + src[be:]
                else:
                    print("  !! tabel %s/%s tidak ketemu" % (cid, anim))
            except Exception as e:
                print("%-8s %-10s GAGAL: %s" % (cid, anim, e))
                if os.path.exists(out + ".bak"):
                    os.rename(out + ".bak", out)
    open(FGD, "w").write(src)
    print("selesai, fighter.gd updated")


if __name__ == "__main__":
    main()
