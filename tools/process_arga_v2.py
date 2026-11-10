#!/usr/bin/env python3
"""Integrasi aset Arga desain baru (zip fighter_arga.zip, 10 Nov 2026).

Mengganti attack_1/2/3, dead, hurt, jump dengan strip baru 256px (bersih,
tanpa ghost), walk baru dari sheet Gemini 1003x249 (10 pose langkah
kuda-kuda pencak silat), idle lama diregistrasi ulang (kaki ditanam agar
tidak melompat), run & shield dipertahankan apa adanya (bersih).

Registrasi per animasi:
- jangkar horizontal = centroid alpha pada pita atas 20% bbox (kepala+bahu,
  stabil saat lengan/kaki menjulur — beda dengan bbox-center yang membuat
  badan bergeser saat tendangan attack_3), disejajarkan ke median antar frame.
- kaki (bbox bawah) disejajarkan ke median antar frame, KECUALI jump
  (gerak vertikalnya adalah lompatannya) dan run (tidak disentuh).
- komponen kecil yang terpisah jauh dari badan utama dibuang (bintik artefak);
  komponen yang menyentuh bbox badan (mis. awan debu di dead f3) dipertahankan.

anim_fix dihitung ulang dengan rumus yang sama seperti normalize_anim_size.py
(faktor dari kesepakatan tinggi & luas vs idle, clamp [0.75, 1.35]) tapi
diukur dari SEMUA frame (strip baru tidak di-interpolasi).
"""
import math
import os
import re
from statistics import median

from PIL import Image

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NEW = "/tmp/arga/fighter_arga"
OUT_DIR = os.path.join(BASE, "assets", "fighters", "fighter_arga")
FGD = os.path.join(BASE, "fighters", "fighter.gd")
FRAME_H = 256

try:
    import numpy as np
    from scipy import ndimage
    HAVE_SCIPY = True
except Exception:
    HAVE_SCIPY = False

NEW_SPECS = {"attack_1": (5, 256), "attack_2": (5, 256), "attack_3": (8, 256),
             "dead": (8, 256), "hurt": (4, 256), "jump": (5, 256)}

# Batas potong sheet walk Gemini (dari deteksi kepala + lembah proyeksi kolom)
WALK_BOUNDS = [0, 132, 235, 333, 435, 531, 620, 710, 800, 898, 1003]
# Animasi yang kakinya disejajarkan ke median (jump tidak: vertikal = lompatan)
FEET_ALIGN = {"attack_1", "attack_2", "attack_3", "dead", "hurt", "walk", "idle"}


def components_mask(alpha_img):
    """Kembalikan label komponen terhubung (8-conn) pada alpha>10."""
    if HAVE_SCIPY:
        a = np.array(alpha_img) > 10
        lab, n = ndimage.label(a, structure=np.ones((3, 3), dtype=int))
        return lab, n
    # Fallback BFS murni Python
    w, h = alpha_img.size
    px = alpha_img.load()
    lab = [[0] * w for _ in range(h)]
    n = 0
    for y in range(h):
        for x in range(w):
            if px[x, y] > 10 and lab[y][x] == 0:
                n += 1
                stack = [(x, y)]
                lab[y][x] = n
                while stack:
                    cx, cy = stack.pop()
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1),
                                   (cx, cy - 1), (cx + 1, cy + 1), (cx - 1, cy - 1),
                                   (cx + 1, cy - 1), (cx - 1, cy + 1)):
                        if 0 <= nx < w and 0 <= ny < h and px[nx, ny] > 10 \
                                and lab[ny][nx] == 0:
                            lab[ny][nx] = n
                            stack.append((nx, ny))
    return lab, n


def clean_frame(frame):
    """Buang komponen kecil yang terpisah dari badan utama (bintik artefak /
    serpihan pose tetangga dari sheet Gemini). Dipertahankan hanya komponen
    >= 5% luas badan utama — awan debu di dead f3 (~12%) lolos, serpihan
    kaki/tangan tetangga di walk (<= 4%) terbuang."""
    a = frame.split()[3]
    lab, n = components_mask(a)
    if n <= 1:
        return frame, 0
    w, h = a.size
    sizes = {}
    if HAVE_SCIPY:
        import numpy as np
        for i in range(1, n + 1):
            c = int(np.count_nonzero(lab == i))
            if c:
                sizes[i] = c
    else:
        for y in range(h):
            for x in range(w):
                v = lab[y][x]
                if v:
                    sizes[v] = sizes.get(v, 0) + 1
    main = max(sizes, key=sizes.get)
    keep = {i for i, s in sizes.items() if s >= 0.05 * sizes[main]}
    removed = sum(s for i, s in sizes.items() if i not in keep)
    if len(keep) == n:
        return frame, 0
    out = frame.copy()
    oa = out.split()[3]
    if HAVE_SCIPY:
        import numpy as np
        mask = np.isin(lab, list(keep))
        new_a = np.where(mask, np.array(oa), 0).astype("uint8")
        out.putalpha(Image.fromarray(new_a))
    else:
        op = oa.load()
        for y in range(h):
            for x in range(w):
                if lab[y][x] not in keep:
                    op[x, y] = 0
    return out, removed


def frame_metrics(frame):
    """bbox, anchor (centroid pita panggul 50-70% tinggi bbox — titik badan yang
    paling stabil: tidak ikut lengan menjulur, kaki menendang, atau kepala
    yang terlempar saat hurt), kaki (bbox bawah), luas."""
    a = frame.split()[3]
    bb = a.getbbox()
    if not bb:
        return None
    x0, y0, x1, y1 = bb
    bh = y1 - y0
    by0 = y0 + int(bh * 0.50)
    by1 = y0 + int(bh * 0.70)
    px = a.load()
    sx = cnt = 0
    for y in range(by0, min(y1, by1)):
        for x in range(x0, x1):
            if px[x, y] > 10:
                sx += x
                cnt += 1
    anchor = sx / cnt if cnt else (x0 + x1) / 2
    area = 0
    for y in range(y0, y1, 2):
        for x in range(x0, x1, 2):
            if px[x, y] > 10:
                area += 1
    return {"bb": bb, "anchor": anchor, "feet": y1,
            "h": bh, "w": x1 - x0, "area": area,
            "cx": (x0 + x1) / 2, "anchor_cx": (x0 + x1) / 2}


# Jangkar per animasi: "pelvis" (pita panggul, stabil saat anggota gerak
# menjulur) atau "cx" (tengah bbox — untuk idle yang kakinya melebar dan
# membuat pita panggul tidak stabil).
ANCHOR_MODE = {"idle": "cx"}


def register_frames(frames, anim):
    """Sejajarkan jangkar + kaki; kembalikan (strip, lebar_frame, info).
    Jangkar dipusatkan di tengah frame (game menggambar frame terpusat pada
    posisi sprite — kalau jangkar tidak di tengah, badan melompat kiri-kanan
    tiap ganti animasi). Yang ditempel hanya isi bbox (bukan gambar frame
    utuh) supaya tidak ada konten yang meluber ke frame tetangga."""
    cleaned = []
    for f in frames:
        cf, removed = clean_frame(f)
        cleaned.append(cf)
        if removed:
            print("    (bersihkan %d px artefak terpisah)" % removed)
    mets = [frame_metrics(f) for f in cleaned]
    akey = "anchor_cx" if ANCHOR_MODE.get(anim) == "cx" else "anchor"
    anchors = [m[akey] for m in mets]
    feet = [m["feet"] for m in mets]
    tgt_anchor = median(anchors)
    tgt_feet = median(feet) if anim in FEET_ALIGN else None
    print("  anchor(%s): %s -> %.1f | feet: %s%s" % (
        akey, [round(a, 1) for a in anchors], tgt_anchor, feet,
        (" -> %d" % tgt_feet) if tgt_feet is not None else " (tidak disejajarkan)"))
    # Lebar frame: jangkar di tengah, muat rentang konten terjauh dari jangkar.
    shifts = [int(round(tgt_anchor - a)) for a in anchors]
    left_ext = min(m["bb"][0] + s for m, s in zip(mets, shifts))
    right_ext = max(m["bb"][2] + s for m, s in zip(mets, shifts))
    half = max(tgt_anchor - left_ext, right_ext - tgt_anchor)
    fw = int(math.ceil(half * 2)) + 2  # +2px pengaman pembulatan
    strip = Image.new("RGBA", (fw * len(cleaned), FRAME_H), (0, 0, 0, 0))
    for i, (f, m, a) in enumerate(zip(cleaned, mets, anchors)):
        x0, y0, x1, y1 = m["bb"]
        dy = int(round(tgt_feet - m["feet"])) if tgt_feet is not None else 0
        # tempel hanya isi bbox; geser agar jangkar jatuh di tengah frame
        crop = f.crop((x0, y0, x1, y1))
        px = i * fw + int(round(fw / 2 - a)) + x0 + 1
        strip.alpha_composite(crop, (px, dy + y0))
    return strip, fw, {"anchor": tgt_anchor, "feet": tgt_feet, "mets": mets}


def split_walk_sheet():
    im = Image.open(os.path.join(
        NEW, "Gemini_Generated_Image_6fmvh86fmvh86fmv-removebg-preview.png")).convert("RGBA")
    w, h = im.size
    scale = FRAME_H / h
    frames = []
    for i in range(len(WALK_BOUNDS) - 1):
        cell = im.crop((WALK_BOUNDS[i], 0, WALK_BOUNDS[i + 1], h))
        nw = max(1, int(round(cell.size[0] * scale)))
        frames.append(cell.resize((nw, FRAME_H), Image.LANCZOS))
    return frames


def load_strip(anim, cnt, fw):
    im = Image.open(os.path.join(NEW, anim + ".png")).convert("RGBA")
    return [im.crop((i * fw, 0, (i + 1) * fw, im.size[1])) for i in range(cnt)]


def load_repo(anim, cnt, fw):
    im = Image.open(os.path.join(OUT_DIR, anim + ".png")).convert("RGBA")
    return [im.crop((i * fw, 0, (i + 1) * fw, im.size[1])) for i in range(cnt)]


def main():
    table = {}
    all_mets = {}
    # 1. Strip baru
    for anim, (cnt, fw) in NEW_SPECS.items():
        print("%-9s strip baru %d frame" % (anim, cnt))
        strip, nfw, info = register_frames(load_strip(anim, cnt, fw), anim)
        strip.save(os.path.join(OUT_DIR, anim + ".png"))
        table[anim] = [cnt, nfw]
        all_mets[anim] = info["mets"]
        print("  -> %s lebar frame %d" % (anim + ".png", nfw))
    # 2. Walk dari sheet Gemini
    print("walk      sheet Gemini 10 pose")
    strip, nfw, info = register_frames(split_walk_sheet(), "walk")
    strip.save(os.path.join(OUT_DIR, "walk.png"))
    table["walk"] = [10, nfw]
    all_mets["walk"] = info["mets"]
    print("  -> walk.png lebar frame %d" % nfw)
    # sebaran kaki walk (untuk cek foot-sliding): rentang x kaki di pita bawah
    walk_frames = split_walk_sheet()
    spans = []
    for f, m in zip(walk_frames, info["mets"]):
        a = f.split()[3]
        px = a.load()
        xs = [x for y in range(m["feet"] - 30, m["feet"])
              for x in range(f.size[0]) if px[x, y] > 10]
        spans.append((min(xs), max(xs)) if xs else (0, 0))
    print("  walk: tinggi badan %s" % [m["h"] for m in info["mets"]])
    print("  walk: rentang kaki (x min-max pita bawah) %s" % spans)
    lead = [s[1] for s in spans]
    print("  walk: kaki terdepan bergerak %.0f px antar frame (rentang %.0f)"
          % (max(lead) - min(lead), max(lead) - min(lead)))
    # 3. Idle lama: registrasi ulang (tanam kaki)
    print("idle      repo lama, registrasi ulang kaki")
    strip, nfw, info = register_frames(load_repo("idle", 6, 134), "idle")
    strip.save(os.path.join(OUT_DIR, "idle.png"))
    table["idle"] = [6, nfw]
    all_mets["idle"] = info["mets"]
    print("  -> idle.png lebar frame %d" % nfw)
    # 4. run & shield tidak disentuh: pakai tabel lama
    table["run"] = [6, 140]
    table["shield"] = [4, 165]

    # 5. Hitung anim_fix (rumus normalize_anim_size.py, semua frame)
    idle_mets = all_mets["idle"]
    idle_area = median([m["area"] for m in idle_mets])
    idle_h = median([m["h"] for m in idle_mets])
    print("\nidle acuan: area~%d tinggi %d" % (idle_area, idle_h))
    sc = 0.949
    fh = 256
    fixes = {}
    # ukur run & shield dari file repo (tidak diubah)
    for anim in ["walk", "run", "jump", "attack_1", "attack_2", "attack_3",
                 "shield", "hurt", "dead"]:
        if anim in all_mets:
            mets = all_mets[anim]
        else:
            cnt, fw = table[anim]
            mets = [frame_metrics(f) for f in load_repo(anim, cnt, fw)]
        area = median([m["area"] for m in mets])
        h = median([m["h"] for m in mets])
        feet_y = median([m["feet"] for m in mets])
        h_factor = idle_h / h
        a_factor = math.sqrt(idle_area / area)
        agree_up = h_factor > 1.05 and a_factor > 1.05
        agree_dn = h_factor < 0.95 and a_factor < 0.95
        factor = math.sqrt(h_factor * a_factor) if (agree_up or agree_dn) else 1.0
        lo, hi = (0.90, 1.15) if anim == "run" else (0.75, 1.35)
        factor = max(lo, min(hi, factor))
        ns = sc * factor
        npy = -10.0 + (fh * ns) / 2.0 - feet_y * ns
        fixes[anim] = [round(ns, 3), round(npy, 1)]
        print("%-9s area~%4d h=%3d feet=%3d h_f=%.2f a_f=%.2f f=%.3f -> [%s, %s]"
              % (anim, area, h, feet_y, h_factor, a_factor, factor,
                 fixes[anim][0], fixes[anim][1]))

    # 6. Tulis fighter.gd: frames + feet_y + anim_fix + anim_speeds (Arga saja)
    feet_idle = median([m["feet"] for m in idle_mets])
    src = open(FGD).read()
    m = re.search(r'"arga": \{.*?\n\t\},', src, re.S)
    block = m.group(0)
    new_block = block
    new_block = re.sub(r'"feet_y": \d+', '"feet_y": %d' % int(feet_idle), new_block)
    fix_str = ", ".join('"%s": [%s, %s]' % (a, f[0], f[1])
                        for a, f in fixes.items())
    new_block = re.sub(r'"anim_fix": \{[^}]*\},',
                       '"anim_fix": {%s},' % fix_str, new_block)
    # frames
    for anim, (cnt, fw) in table.items():
        new_block = re.sub(r'"%s": \[\d+, \d+\]' % anim,
                           '"%s": [%d, %d]' % (anim, cnt, fw), new_block, count=1)
    # anim_speeds khusus Arga (walk 12fps, attack_3 13fps, jump 7fps)
    new_block = re.sub(r'\n\t\t"anim_speeds": \{[^}]*\},', '', new_block)
    new_block = new_block.replace('"frames": {',
                                  '"anim_speeds": {"walk": 12.0, "attack_3": 13.0, "jump": 7.0},\n\t\t"frames": {',
                                  1)
    src = src[:m.start()] + new_block + src[m.end():]
    open(FGD, "w").write(src)
    print("\nfeet_y Arga: 256 -> %d (median kaki idle setelah registrasi)" % int(feet_idle))
    print("Tabel frames Arga:", table)
    print("fighter.gd diperbarui (arga saja)")


if __name__ == "__main__":
    main()
