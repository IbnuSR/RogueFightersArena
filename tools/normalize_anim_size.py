#!/usr/bin/env python3
"""Normalisasi ukuran badan per animasi agar konsisten.
Mengukur luas piksel badan tiap animasi (tahan terhadap perbedaan pose),
hitung faktor = sqrt(luas_idle / luas_anim), clamp [0.75, 1.35],
lalu simpan skala & posisi Y per animasi ke tabel fighter.gd ("anim_fix").
Juga mengembalikan run ke 6 frame asli (hapus interpolasi yang ghosting).
"""
import re
import os
import math
from PIL import Image
from statistics import median

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FGD = os.path.join(BASE, "fighters", "fighter.gd")

FIX_ANIMS = ["walk", "run", "jump", "attack_1", "attack_2", "attack_3",
             "shield", "hurt", "dead"]
FMIN, FMAX = 0.75, 1.35


def parse(src):
    chars = {}
    for m in re.finditer(r'"(\w+)": \{\s*\n\t\t"folder": "([^"]+)",', src):
        cid = m.group(1)
        bs = m.start()
        be = src.index('\n\t},', bs)
        block = src[bs:be]
        if '"feet_y"' not in block:
            continue
        frames = {}
        for am in re.finditer(r'"(\w+)": \[(\d+), (\d+)\]', block):
            frames[am.group(1)] = [int(am.group(2)), int(am.group(3))]
        sc = float(re.search(r'"sprite_scale": ([\d.]+)', block).group(1))
        fh = int(re.search(r'"frame_h": (\d+)', block).group(1))
        chars[cid] = {"bs": bs, "be": be, "frames": frames, "sc": sc,
                      "fh": fh, "folder": m.group(2).replace("res://", "")}
    return chars


def orig_indices(cnt, anim):
    # frame asli ada di indeks genap untuk anim yang di-interpolasi
    if anim in ("walk", "run", "jump", "attack_1", "attack_2", "attack_3"):
        return list(range(0, cnt, 2))
    return list(range(cnt))


def measure(path, cnt, fw, anim):
    im = Image.open(path).convert("RGBA")
    a = im.split()[3]
    areas, heights, feet = [], [], []
    for i in orig_indices(cnt, anim):
        f = a.crop((i * fw, 0, (i + 1) * fw, im.size[1]))
        bb = f.getbbox()
        if not bb:
            continue
        px = f.load()
        c = sum(1 for y in range(bb[1], bb[3], 2)
                for x in range(bb[0], bb[2], 2) if px[x, y] > 10)
        areas.append(c)
        heights.append(bb[3] - bb[1])
        feet.append(bb[3])
    return median(areas), median(heights), median(feet)


def main():
    src = open(FGD).read()
    chars = parse(src)
    for cid in sorted(chars, key=lambda c: chars[c]["bs"], reverse=True):
        info = chars[cid]
        folder = os.path.join(BASE, info["folder"])
        # 1. Kembalikan run ke 6 frame asli (hapus blend ghosting)
        if "run" in info["frames"]:
            cnt, fw = info["frames"]["run"]
            if cnt == 12:
                im = Image.open(os.path.join(folder, "run.png")).convert("RGBA")
                w, h = im.size
                sheet = Image.new("RGBA", (fw * 6, h), (0, 0, 0, 0))
                for i in range(6):
                    sheet.paste(im.crop((i * 2 * fw, 0, (i * 2 + 1) * fw, h)),
                                (i * fw, 0))
                sheet.save(os.path.join(folder, "run.png"))
                info["frames"]["run"] = [6, fw]
                print("%-8s run: 12 -> 6 frame (interpolasi dihapus)" % cid)
        # 2. Ukur idle sebagai acuan (luas + tinggi)
        cnt, fw = info["frames"]["idle"]
        idle_area, idle_h, _ = measure(os.path.join(folder, "idle.png"),
                                       cnt, fw, "idle")
        fixes = {}
        for anim in FIX_ANIMS:
            if anim not in info["frames"]:
                continue
            cnt, fw = info["frames"][anim]
            area, h, feet_y = measure(os.path.join(folder, anim + ".png"),
                                      cnt, fw, anim)
            h_factor = idle_h / h
            a_factor = math.sqrt(idle_area / area)
            # Koreksi hanya jika tinggi & luas SEPAKAT (keduanya >5% searah).
            # Kalau tidak sepakat = perbedaan pose, jangan dikoreksi.
            agree_up = h_factor > 1.05 and a_factor > 1.05
            agree_dn = h_factor < 0.95 and a_factor < 0.95
            if agree_up or agree_dn:
                factor = math.sqrt(h_factor * a_factor)
            else:
                factor = 1.0
            # run: koreksi ringan saja (pose sprint memang jongkok)
            lo, hi = (0.90, 1.15) if anim == "run" else (FMIN, FMAX)
            factor = max(lo, min(hi, factor))
            ns = info["sc"] * factor
            npy = -10.0 + (info["fh"] * ns) / 2.0 - feet_y * ns
            fixes[anim] = [round(ns, 3), round(npy, 1)]
        # 3. Tulis ke tabel
        bs, be = info["bs"], info["be"]
        block = src[bs:be]
        # update run count jika berubah
        block = re.sub(r'"run": \[12, (\d+)\]', r'"run": [6, \1]', block)
        # hapus anim_fix lama jika ada
        block = re.sub(r'\n\t\t"anim_fix": \{[^}]*\},', '', block)
        fix_str = ", ".join('"%s": [%s, %s]' % (a, f[0], f[1])
                            for a, f in fixes.items())
        block = block.replace('"frames": {',
                              '"anim_fix": {%s},\n\t\t"frames": {' % fix_str)
        src = src[:bs] + block + src[be:]
        print("%-8s anim_fix: %d animasi" % (cid, len(fixes)))
    open(FGD, "w").write(src)
    print("fighter.gd updated")


if __name__ == "__main__":
    main()
