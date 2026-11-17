#!/usr/bin/env python3
"""Bangun strip animasi boss dari SATU gambar badan (AI / aset asli).

Cara kerja (jujur, lihat docs/ASSET_NOTES.md):
- Tiap boss punya 1 gambar badan (full-body, menghadap kanan).
  Ular Neon / Guru Sunyi / Alaric Voss: gambar AI di atas green-screen.
  Kapten Brak: frame 0 strip idle ASLI miliknya (10 frame, 2560x256).
- Gambar di-key (hijau murni -> transparan), di-crop ke badan, lalu
  10 animasi dibuat prosedural dari badan itu (bob, lunge, lompat,
  rebah). BUKAN animasi gambar-tangan per frame — tim artis bisa
  mengganti tiap strip dengan gambar tangan kapan saja.
- Geometri seragam per boss: kaki di y=256 (bawah frame), tinggi badan
  BODY_H px di frame 320x256. Karena semua animasi geometrinya sama,
  fighter.gd TIDAK butuh anim_fix untuk boss (pakai base_scale/pos).

Jalankan: python3 tools/build_boss_strips.py
"""
import math
import os

from PIL import Image

try:
    import numpy as np
    HAVE_NUMPY = True
except ImportError:
    HAVE_NUMPY = False

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BOSSES = os.path.join(BASE, "assets", "bosses")
BG = os.path.join(BASE, "assets", "backgrounds")
FRAME_W, FRAME_H = 320, 256
# Tinggi badan di frame (px). Brak harus sama dengan idle aslinya (115 px,
# bbox frame 0 strip idle) supaya idle 10-frame & animasi baru seukuran.
BODY_H = {"ular_neon": 220, "guru_sunyi": 220, "alaric_voss": 220, "kapten_brak": 115}
# Pusat horizontal badan di frame (sisakan ruang lunge ke kanan).
CENTER_X = 150

ANIMS = {
    "idle": 6, "walk": 8, "run": 8, "jump": 12,
    "attack_1": 7, "attack_2": 5, "attack_3": 3,
    "shield": 2, "hurt": 2, "dead": 3,
}


def key_green(im: Image.Image) -> Image.Image:
    """Hijau murni (0,255,0) -> transparan. Neon lime (R>60) aman."""
    im = im.convert("RGBA")
    if HAVE_NUMPY:
        a = np.array(im)
        mask = (a[:, :, 1] > 240) & (a[:, :, 0] < 60) & (a[:, :, 2] < 60)
        a[:, :, 3][mask] = 0
        return Image.fromarray(a, "RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, _a = px[x, y]
            if g > 240 and r < 60 and b < 60:
                px[x, y] = (0, 0, 0, 0)
    return im


def load_body(boss: str) -> Image.Image:
    if boss == "kapten_brak":
        strip = Image.open(os.path.join(BOSSES, "boss_kapten_brak", "kapten_brak_idle.png"))
        frame0 = strip.crop((0, 0, 256, 256)).convert("RGBA")
        body = frame0.crop(frame0.getbbox())
    else:
        src = {
            "ular_neon": "media-generation-ular-neon-0-5a5b98b6-7c34-4779-bff7-01b1ca1d90a9.png",
            "guru_sunyi": "media-generation-guru-sunyi-0-a81fc58c-1e7b-40b3-9a70-9eda5f1be6f4.png",
            "alaric_voss": "media-generation-alaric-voss-0-12c32303-b8b0-4850-b9bd-ddcaefe082e2.png",
        }[boss]
        body = key_green(Image.open(os.path.join(BOSSES, src)))
        body = body.crop(body.getbbox())
    target_h = BODY_H[boss]
    w = max(1, int(body.width * target_h / body.height))
    body = body.resize((w, target_h), Image.LANCZOS)
    print(f"{boss}: badan {body.size}, target_h={target_h}")
    return body


def make_frame(body, dx=0, dy=0, rot=0, sy=1.0):
    b = body
    if sy != 1.0:
        b = b.resize((b.width, max(1, int(b.height * sy))), Image.LANCZOS)
    if rot:
        b = b.rotate(rot, resample=Image.BICUBIC, expand=True)
    canvas = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    x = CENTER_X - b.width // 2 + dx
    y = FRAME_H - b.height + dy
    canvas.alpha_composite(b, (x, y))
    return canvas


def transforms(anim: str, n: int):
    """Daftar (dx, dy, rot, sy) per frame."""
    if anim == "idle":
        return [(0, d, 0, 1.0) for d in [0, 3, 3, 0, -3, -3][:n]]
    if anim == "walk":
        return [(d, -b, 0, 1.0) for d, b in
                [(0, 0), (2, 2), (4, 4), (2, 2), (0, 0), (2, 2), (4, 4), (2, 2)][:n]]
    if anim == "run":
        return [(0, d, -4, 1.0) for d in [0, -3, -6, -3, 0, -3, -6, -3][:n]]
    if anim == "jump":
        return [(0, -round(90 * math.sin(math.pi * i / (n - 1))), 0, 1.0)
                for i in range(n)]
    if anim == "attack_1":
        return list(zip([0, 10, 30, 55, 45, 20, 0], [0] * 7,
                        [0, 0, -2, -4, -2, 0, 0], [1.0] * 7))[:n]
    if anim == "attack_2":
        return list(zip([0, 20, 50, 25, 0], [0] * 5,
                        [0, -2, -5, -2, 0], [1.0] * 5))[:n]
    if anim == "attack_3":
        return list(zip([0, 70, 0], [0] * 3, [0, -6, 0], [1.0] * 3))[:n]
    if anim == "shield":
        return [(0, 6, 0, 0.94)] * n
    if anim == "hurt":
        return [(-25, 0, 5, 1.0), (-10, 0, 2, 1.0)][:n]
    if anim == "dead":
        return [(0, 0, 0, 1.0), (0, 10, -45, 1.0), (0, 18, -85, 1.0)][:n]
    return [(0, 0, 0, 1.0)] * n


def build_boss(boss: str):
    body = load_body(boss)
    folder = os.path.join(BOSSES, "boss_" + boss)
    os.makedirs(folder, exist_ok=True)
    # Simpan badan hasil keying sebagai referensi (base.png).
    body.save(os.path.join(folder, "base.png"))
    for anim, n in ANIMS.items():
        # Idle Kapten Brak tetap strip aslinya (10 frame) — jangan timpa.
        if boss == "kapten_brak" and anim == "idle":
            print(f"{boss}/{anim}: pakai strip asli, dilewati")
            continue
        strip = Image.new("RGBA", (FRAME_W * n, FRAME_H), (0, 0, 0, 0))
        for i, (dx, dy, rot, sy) in enumerate(transforms(anim, n)):
            strip.alpha_composite(make_frame(body, dx, dy, rot, sy), (i * FRAME_W, 0))
        strip.save(os.path.join(folder, anim + ".png"))
        print(f"{boss}/{anim}.png {strip.size}")


def build_menara():
    src = os.path.join(BG, "media-generation-menara-voss-0-1045c07c-ab2c-4fb5-a592-4f6fb217fa62.png")
    im = Image.open(src).convert("RGB").resize((3840, 2160), Image.LANCZOS)
    im.save(os.path.join(BG, "menara_voss.png"))
    print("menara_voss.png", im.size)
    thumb = im.resize((640, 360), Image.LANCZOS)
    os.makedirs(os.path.join(BASE, "assets", "ui", "thumbs"), exist_ok=True)
    thumb.save(os.path.join(BASE, "assets", "ui", "thumbs", "ch4.png"))
    print("thumbs/ch4.png", thumb.size)
    os.remove(src)


if __name__ == "__main__":
    for boss in ["kapten_brak", "ular_neon", "guru_sunyi", "alaric_voss"]:
        build_boss(boss)
    build_menara()
    # Hapus file staging hasil generate (sudah jadi strip/base).
    for f in os.listdir(BOSSES):
        if f.startswith("media-generation-"):
            os.remove(os.path.join(BOSSES, f))
    for f in os.listdir(BG):
        if f.startswith("media-generation-") and f.endswith(".json"):
            os.remove(os.path.join(BG, f))
    print("SELESAI")
