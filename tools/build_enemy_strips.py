#!/usr/bin/env python3
"""Ekstrak gambar AI Buruh Bayaran, Penyelundup, dan Murid Dojo menjadi strip animasi lengkap.

10 animasi per karakter:
- idle: 6 frame (breathing bob)
- walk: 8 frame (step bob & sway)
- run: 8 frame (forward lean & rapid stride)
- jump: 12 frame (sine jump arc)
- attack_1: 7 frame (jab / strike lunge + hit stretch)
- attack_2: 5 frame (hook / heavy swing lunge)
- attack_3: 3 frame (high strike / overhead lunge)
- shield: 2 frame (brace crouch / guard stance)
- hurt: 2 frame (knockback recoil & tilt)
- dead: 3 frame (collapse & fall prone)

Frame W=320, H=256, target_h=220px, feet_y=256 (konsisten dengan standar Boss / Karakter Baru RFA).
"""
import math
import os
import numpy as np
from PIL import Image

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIGHTERS_DIR = os.path.join(BASE, "assets", "fighters")
FRAME_W, FRAME_H = 320, 256
TARGET_H = 220
CENTER_X = 150

ANIMS = {
    "idle": 6, "walk": 8, "run": 8, "jump": 12,
    "attack_1": 7, "attack_2": 5, "attack_3": 3,
    "shield": 2, "hurt": 2, "dead": 3,
}

SOURCES = {
    "buruh_bayaran": {
        "folder": "fighter_buruh",
        "path": r"C:\Users\MyBook SAGA 10\.gemini\antigravity\brain\ffdac07d-441f-42eb-8da9-823a4bc396aa\buruh_bayaran_pixel_art_1794408158957.jpg",
        "key_thresh": (170, 120, 120)
    },
    "penyelundup": {
        "folder": "fighter_penyelundup",
        "path": r"C:\Users\MyBook SAGA 10\.gemini\antigravity\brain\ffdac07d-441f-42eb-8da9-823a4bc396aa\enemy_penyelundup_sprite_1794408217285.jpg",
        "key_thresh": (170, 120, 120)
    },
    "murid_dojo": {
        "folder": "fighter_murid",
        "path": r"C:\Users\MyBook SAGA 10\.gemini\antigravity\brain\ffdac07d-441f-42eb-8da9-823a4bc396aa\murid_dojo_sprite_1794408242194.jpg",
        "key_thresh": (170, 120, 120)
    }
}

def key_green(im: Image.Image, g_min=170, r_max=120, b_max=120) -> Image.Image:
    im = im.convert("RGBA")
    arr = np.array(im)
    mask = (arr[:, :, 1] > g_min) & (arr[:, :, 0] < r_max) & (arr[:, :, 2] < b_max)
    arr[:, :, 3][mask] = 0
    res = Image.fromarray(arr, "RGBA")
    bbox = res.getbbox()
    if bbox:
        res = res.crop(bbox)
    return res

def make_frame(body: Image.Image, dx=0, dy=0, rot=0, sx=1.0, sy=1.0):
    b = body
    if sx != 1.0 or sy != 1.0:
        new_w = max(1, int(b.width * sx))
        new_h = max(1, int(b.height * sy))
        b = b.resize((new_w, new_h), Image.LANCZOS)
    if rot != 0:
        b = b.rotate(rot, resample=Image.BICUBIC, expand=True)
    
    canvas = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    x = CENTER_X - b.width // 2 + dx
    y = FRAME_H - b.height + dy
    canvas.alpha_composite(b, (x, y))
    return canvas

def get_transforms(anim: str, n: int):
    """Mengembalikan list tuple (dx, dy, rot, sx, sy) per frame"""
    if anim == "idle":
        # Breathing / bobbing
        return [(0, d, 0, 1.0, 1.0) for d in [0, 3, 4, 2, -2, -3][:n]]
    if anim == "walk":
        # Langkah kaki maju-mundur dan bob
        return [(d, -b, 0, 1.0, 1.0) for d, b in
                [(0, 0), (3, 3), (6, 5), (3, 3), (0, 0), (-3, 3), (-6, 5), (-3, 3)][:n]]
    if anim == "run":
        # Lari condong ke depan + getaran cepat
        return [(0, d, -5, 1.05, 0.98) for d in [0, -4, -7, -4, 0, -4, -7, -4][:n]]
    if anim == "jump":
        # Busur lompatan parabolik
        return [(0, -round(95 * math.sin(math.pi * i / (n - 1))), 0, 1.0, 1.0)
                for i in range(n)]
    if anim == "attack_1":
        # Lunge cepat pukulan/tusukan
        return [
            (0, 0, 0, 1.0, 1.0),
            (12, 0, -1, 1.05, 0.98),
            (35, 0, -3, 1.12, 0.96),
            (60, 0, -5, 1.18, 0.95), # Peak hit
            (45, 0, -3, 1.10, 0.97),
            (20, 0, -1, 1.03, 0.99),
            (0, 0, 0, 1.0, 1.0)
        ][:n]
    if anim == "attack_2":
        # Heavy swing / kick
        return [
            (0, 0, 0, 1.0, 1.0),
            (25, 0, -2, 1.08, 0.96),
            (55, 0, -6, 1.15, 0.94),
            (30, 0, -3, 1.06, 0.97),
            (0, 0, 0, 1.0, 1.0)
        ][:n]
    if anim == "attack_3":
        # High strike / overhead
        return [
            (0, -10, 3, 0.96, 1.06),
            (75, 5, -8, 1.20, 0.92),
            (0, 0, 0, 1.0, 1.0)
        ][:n]
    if anim == "shield":
        # Menunduk menangkis / guard
        return [
            (0, 6, 0, 1.08, 0.92),
            (0, 8, 0, 1.10, 0.90)
        ][:n]
    if anim == "hurt":
        # Terpelanting mundur saat kena pukul
        return [
            (-28, 0, 6, 0.94, 1.02),
            (-12, 0, 3, 0.98, 1.01)
        ][:n]
    if anim == "dead":
        # Rebah roboh ke belakang
        return [
            (-10, 0, 10, 0.95, 1.0),
            (-25, 15, -45, 0.95, 0.95),
            (-35, 25, -90, 1.0, 0.90)
        ][:n]
    return [(0, 0, 0, 1.0, 1.0)] * n

def process_character(cid: str, data: dict):
    print(f"=== Memproses {cid} ===")
    im = Image.open(data["path"])
    body = key_green(im, *data["key_thresh"])
    
    # Resize badan ke skala target_h
    scale = TARGET_H / float(body.height)
    new_w = max(1, int(body.width * scale))
    body = body.resize((new_w, TARGET_H), Image.LANCZOS)
    
    out_dir = os.path.join(FIGHTERS_DIR, data["folder"])
    os.makedirs(out_dir, exist_ok=True)
    
    # Simpan base
    body.save(os.path.join(out_dir, "base.png"))
    
    for anim, n in ANIMS.items():
        strip = Image.new("RGBA", (FRAME_W * n, FRAME_H), (0, 0, 0, 0))
        t_list = get_transforms(anim, n)
        for i, (dx, dy, rot, sx, sy) in enumerate(t_list):
            frame = make_frame(body, dx, dy, rot, sx, sy)
            strip.alpha_composite(frame, (i * FRAME_W, 0))
        out_path = os.path.join(out_dir, anim + ".png")
        strip.save(out_path)
        print(f"  {anim}.png: {strip.size}")
        
    # Buat juga potret untuk UI (crop frame 0 idle)
    idle_strip = Image.open(os.path.join(out_dir, "idle.png"))
    frame0 = idle_strip.crop((0, 0, FRAME_W, FRAME_H))
    f0_bbox = frame0.getbbox()
    if f0_bbox:
        portrait = frame0.crop(f0_bbox)
        # Scale to 200px height for portraits
        p_scale = 200.0 / float(portrait.height)
        pw = max(1, int(portrait.width * p_scale))
        portrait = portrait.resize((pw, 200), Image.LANCZOS)
        p_dir = os.path.join(BASE, "assets", "ui", "portraits")
        os.makedirs(p_dir, exist_ok=True)
        portrait.save(os.path.join(p_dir, f"{cid}.png"))
        print(f"  Portrait UI disimpan: {pw}x200")

if __name__ == "__main__":
    for cid, data in SOURCES.items():
        process_character(cid, data)
    print("Semua strip selesai dibuat!")
