#!/usr/bin/env python3
"""Ekstrak gambar AI semua 6 Karakter Musuh menjadi strip animasi lengkap dengan frame halus (smooth frame counts).

10 animasi per karakter:
- idle: 8 frame
- walk: 12 frame
- run: 12 frame
- jump: 16 frame
- attack_1: 10 frame
- attack_2: 8 frame
- attack_3: 6 frame
- shield: 4 frame
- hurt: 4 frame
- dead: 5 frame

Frame W=320, H=256, target_h=220px, feet_y=256.
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
    "idle": 8,
    "walk": 12,
    "run": 12,
    "jump": 16,
    "attack_1": 10,
    "attack_2": 8,
    "attack_3": 6,
    "shield": 4,
    "hurt": 4,
    "dead": 5,
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
    },
    "geng_jalanan": {
        "folder": "fighter_geng",
        "path": r"C:\Users\MyBook SAGA 10\.gemini\antigravity\brain\ffdac07d-441f-42eb-8da9-823a4bc396aa\geng_jalanan_pixel_art_1794446102794.jpg",
        "key_thresh": (170, 120, 120)
    },
    "akrobat": {
        "folder": "fighter_akrobat",
        "path": r"C:\Users\MyBook SAGA 10\.gemini\antigravity\brain\ffdac07d-441f-42eb-8da9-823a4bc396aa\akrobat_enemy_sprite_1794446360192.jpg",
        "key_thresh": (170, 120, 120)
    },
    "pengawal_elit": {
        "folder": "fighter_pengawal",
        "path": r"C:\Users\MyBook SAGA 10\.gemini\antigravity\brain\ffdac07d-441f-42eb-8da9-823a4bc396aa\pengawal_elite_sprite_1794449011143.jpg",
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
    """Mengembalikan list tuple (dx, dy, rot, sx, sy) per frame yang halus"""
    if anim == "idle":
        # Pernapasan halus naik-turun (8 frames)
        return [(0, round(4 * math.sin(2 * math.pi * i / n)), 0, 1.0 + 0.015 * math.sin(2 * math.pi * i / n), 1.0 - 0.015 * math.sin(2 * math.pi * i / n)) for i in range(n)]
    
    if anim == "walk":
        # Langkah kaki melangkah maju mundur & bobbing halus (12 frames)
        res = []
        for i in range(n):
            sway = round(6 * math.sin(2 * math.pi * i / n))
            bob = -round(4 * abs(math.sin(2 * math.pi * i / n)))
            tilt = round(2 * math.sin(2 * math.pi * i / n))
            res.append((sway, bob, tilt, 1.0, 1.0))
        return res

    if anim == "run":
        # Lari cepat condong ke depan + hentakan kaki cepat (12 frames)
        res = []
        for i in range(n):
            bob = -round(7 * abs(math.sin(4 * math.pi * i / n)))
            tilt = -5 + round(2 * math.sin(4 * math.pi * i / n))
            res.append((0, bob, tilt, 1.05, 0.97))
        return res

    if anim == "jump":
        # Parabolik jump arc (16 frames)
        return [(0, -round(95 * math.sin(math.pi * i / (n - 1))), 0, 1.0, 1.0) for i in range(n)]

    if anim == "attack_1":
        # Jab / lunge cepat (10 frames)
        return [
            (0, 0, 0, 1.0, 1.0),
            (8, 0, -1, 1.03, 0.99),
            (25, 0, -2, 1.08, 0.97),
            (50, 0, -4, 1.15, 0.95),
            (65, 0, -6, 1.20, 0.93), # Peak hit
            (55, 0, -4, 1.15, 0.95),
            (35, 0, -2, 1.08, 0.97),
            (18, 0, -1, 1.04, 0.99),
            (6, 0, 0, 1.01, 1.0),
            (0, 0, 0, 1.0, 1.0)
        ][:n]

    if anim == "attack_2":
        # Hook / Heavy swing (8 frames)
        return [
            (0, 0, 0, 1.0, 1.0),
            (-10, 0, 2, 0.97, 1.02), # Wind up
            (20, 0, -2, 1.06, 0.97),
            (55, 0, -5, 1.14, 0.95),
            (70, 0, -7, 1.22, 0.92), # Hit
            (45, 0, -4, 1.10, 0.96),
            (15, 0, -1, 1.04, 0.99),
            (0, 0, 0, 1.0, 1.0)
        ][:n]

    if anim == "attack_3":
        # Overhead smash / High kick (6 frames)
        return [
            (0, -12, 4, 0.95, 1.06), # Angkat tinggi
            (30, -5, 0, 1.05, 1.0),
            (80, 5, -8, 1.22, 0.91), # Impact
            (50, 3, -5, 1.12, 0.95),
            (15, 0, -2, 1.03, 0.99),
            (0, 0, 0, 1.0, 1.0)
        ][:n]

    if anim == "shield":
        # Guard / pasang tangkisan kokoh (4 frames)
        return [
            (0, 3, 0, 1.04, 0.96),
            (0, 7, 0, 1.08, 0.92),
            (0, 8, 0, 1.10, 0.90),
            (0, 7, 0, 1.08, 0.92)
        ][:n]

    if anim == "hurt":
        # Terhentak mundur saat kena pukulan (4 frames)
        return [
            (-15, 0, 3, 0.97, 1.01),
            (-32, 0, 7, 0.92, 1.03), # Peak recoil
            (-20, 0, 4, 0.96, 1.02),
            (-6, 0, 1, 0.99, 1.0)
        ][:n]

    if anim == "dead":
        # Rebah roboh ke tanah (5 frames)
        return [
            (-10, 0, 8, 0.96, 1.0),
            (-22, 10, -30, 0.95, 0.96),
            (-35, 20, -65, 0.97, 0.93),
            (-45, 28, -88, 1.0, 0.90),
            (-48, 30, -90, 1.0, 0.88)
        ][:n]

    return [(0, 0, 0, 1.0, 1.0)] * n

def process_character(cid: str, data: dict):
    print(f"=== Memproses {cid} ===")
    im = Image.open(data["path"])
    body = key_green(im, *data["key_thresh"])
    
    # Scale badan ke target_h
    scale = TARGET_H / float(body.height)
    new_w = max(1, int(body.width * scale))
    body = body.resize((new_w, TARGET_H), Image.LANCZOS)
    
    out_dir = os.path.join(FIGHTERS_DIR, data["folder"])
    os.makedirs(out_dir, exist_ok=True)
    
    # Simpan base.png
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
        
    # Buat potret untuk UI (crop frame 0 idle)
    idle_strip = Image.open(os.path.join(out_dir, "idle.png"))
    frame0 = idle_strip.crop((0, 0, FRAME_W, FRAME_H))
    f0_bbox = frame0.getbbox()
    if f0_bbox:
        portrait = frame0.crop(f0_bbox)
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
