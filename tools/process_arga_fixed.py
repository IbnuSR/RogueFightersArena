import os
import shutil
import zipfile
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

SRC_DIR = "/working_dir/c_80f076cb6dcddc81/arga_inspect/fighter_arga"
INTER_DIR = "/working_dir/c_80f076cb6dcddc81/artifacts/file_generation/ttl=63d/intermediate"
OUT_DIR = "/working_dir/c_80f076cb6dcddc81/artifacts/file_generation/ttl=63d/output"
ARGA_OUT_DIR = os.path.join(INTER_DIR, "fighter_arga_fixed", "assets", "fighters", "fighter_arga")
os.makedirs(ARGA_OUT_DIR, exist_ok=True)

CELL_W = 256
CELL_H = 256
GROUND_Y = 252
STD_HEIGHT = 204  # Consistent standing height across all animations

def clean_rgba_cell(cell_im, keep_dust=False):
    """Clean disconnected noise specks from a 256x256 RGBA cell."""
    arr = np.array(cell_im.convert("RGBA"))
    alpha = arr[:, :, 3]
    bin_a = alpha > 25
    labeled, num = ndimage.label(bin_a)
    if num == 0:
        return cell_im, (0, 0, 255, 255)
    sizes = ndimage.sum(bin_a, labeled, range(1, num + 1))
    biggest = 1 + int(np.argmax(sizes))
    if keep_dust:
        # Keep components with size > 45 px that are near the character, not border lines
        keep_mask = np.zeros_like(bin_a, dtype=bool)
        for idx in range(1, num + 1):
            comp = (labeled == idx)
            ys, xs = np.where(comp)
            # Filter out vertical/horizontal border line artifacts or tiny specks
            if idx == biggest or (sizes[idx - 1] > 45 and xs.min() > 15 and xs.max() < 245):
                keep_mask |= comp
    else:
        keep_mask = (labeled == biggest)
    arr[:, :, 3] = np.where(keep_mask, alpha, 0)
    ys, xs = np.where(keep_mask)
    bbox = (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))
    return Image.fromarray(arr), bbox

def extract_poses_from_jpg(jpg_path, min_area=5000):
    im = Image.open(jpg_path).convert("RGBA")
    arr = np.array(im)
    is_white = (arr[:, :, 0] > 230) & (arr[:, :, 1] > 230) & (arr[:, :, 2] > 230)
    bg_labeled, _ = ndimage.label(is_white)
    border_labels = (
        set(np.unique(bg_labeled[0, :]))
        | set(np.unique(bg_labeled[-1, :]))
        | set(np.unique(bg_labeled[:, 0]))
        | set(np.unique(bg_labeled[:, -1]))
    )
    border_labels.discard(0)
    bg_mask = np.isin(bg_labeled, list(border_labels))
    fg_mask = ~bg_mask
    labeled, num = ndimage.label(fg_mask)
    sizes = ndimage.sum(fg_mask, labeled, range(1, num + 1))
    poses = []
    for idx, sz in enumerate(sizes):
        if sz > min_area:
            comp_mask = (labeled == (idx + 1))
            ys, xs = np.where(comp_mask)
            x0, x1 = int(xs.min()), int(xs.max())
            y0, y1 = int(ys.min()), int(ys.max())
            crop_arr = arr[y0:y1+1, x0:x1+1].copy()
            crop_mask = comp_mask[y0:y1+1, x0:x1+1]
            # Remove internal white background holes (between legs/arms/sash) while preserving eye whites
            crop_white = (crop_arr[:, :, 0] > 232) & (crop_arr[:, :, 1] > 232) & (crop_arr[:, :, 2] > 232)
            hole_labeled, h_num = ndimage.label(crop_white & crop_mask)
            for h_idx in range(1, h_num + 1):
                h_mask = (hole_labeled == h_idx)
                h_ys, _ = np.where(h_mask)
                if h_ys.mean() > (y1 - y0) * 0.22 or h_mask.sum() > 250:
                    crop_mask[h_mask] = False
            # Soften 1px outer halo if any bright near-white fringe exists on outer boundary
            eroded = ndimage.binary_erosion(crop_mask)
            boundary = crop_mask & (~eroded)
            bright_edge = boundary & (crop_arr[:, :, 0] > 215) & (crop_arr[:, :, 1] > 215) & (crop_arr[:, :, 2] > 215)
            crop_mask[bright_edge] = False
            crop_arr[:, :, 3] = np.where(crop_mask, 255, 0)
            poses.append((x0, y0, x1, y1, Image.fromarray(crop_arr)))
    poses.sort(key=lambda t: t[0])
    return poses

poses_6f = extract_poses_from_jpg(os.path.join(SRC_DIR, "Gemini_Generated_Image_6fmvh86fmvh86fmv.jpg"))
poses_pc = extract_poses_from_jpg(os.path.join(SRC_DIR, "Gemini_Generated_Image_pc3trlpc3trlpc3t.jpg"))

def place_on_cell(crop_im, target_h, bottom_y=GROUND_Y, center_x=128):
    """Resize crop_im to target_h preserving aspect ratio and place on 256x256 cell."""
    w, h = crop_im.size
    sc = target_h / float(h)
    nw = max(1, int(round(w * sc)))
    nh = max(1, int(round(h * sc)))
    resized = crop_im.resize((nw, nh), Image.Resampling.LANCZOS)
    # Find torso/mass center X (middle 50% height of character so extended fists/ribbons don't skew center)
    arr = np.array(resized)
    alpha = arr[:, :, 3] > 30
    y_mid0 = int(nh * 0.25)
    y_mid1 = int(nh * 0.75)
    mid_slice = alpha[y_mid0:y_mid1, :]
    if mid_slice.any():
        _, xs = np.where(mid_slice)
        mass_cx = int(round(xs.mean()))
    else:
        mass_cx = nw // 2
    cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    px = center_x - mass_cx
    px = max(4, min(CELL_W - nw - 4, px))
    py = bottom_y - nh
    py = max(2, min(CELL_H - nh, py))
    cell.paste(resized, (px, py), resized)
    return cell

def save_sheet(cells, anim_name):
    sheet = Image.new("RGBA", (CELL_W * len(cells), CELL_H), (0, 0, 0, 0))
    for i, c in enumerate(cells):
        sheet.paste(c, (i * CELL_W, 0), c)
    out_path = os.path.join(ARGA_OUT_DIR, f"{anim_name}.png")
    sheet.save(out_path)
    print(f"[SAVED] {anim_name}.png -> {sheet.size} ({len(cells)} frames of {CELL_W}x{CELL_H})")
    return sheet

# 1. IDLE (6 frames): Smooth breathing & silat kuda-kuda stance from 6fmv poses [0, 1, 2, 1, 8, 9]
# Base scale factor from Pose 0 (height 768 -> 204)
base_sc_6f = STD_HEIGHT / 768.0
idle_indices = [0, 1, 2, 1, 8, 9]
idle_cells = []
for idx in idle_indices:
    _, y0, _, y1, pim = poses_6f[idx]
    th = int(round((y1 - y0 + 1) * base_sc_6f))
    idle_cells.append(place_on_cell(pim, th, bottom_y=GROUND_Y, center_x=128))
save_sheet(idle_cells, "idle")

# 2. WALK (6 frames): Grounded silat stepping footwork from 6fmv poses [0, 3, 4, 6, 7, 8]
walk_configs = [
    (0, GROUND_Y),
    (3, GROUND_Y),
    (4, GROUND_Y - 3),
    (6, GROUND_Y),
    (7, GROUND_Y),
    (8, GROUND_Y),
]
walk_cells = []
for idx, by in walk_configs:
    _, y0, _, y1, pim = poses_6f[idx]
    th = int(round((y1 - y0 + 1) * base_sc_6f))
    walk_cells.append(place_on_cell(pim, min(STD_HEIGHT + 4, th), bottom_y=by, center_x=128))
save_sheet(walk_cells, "walk")

# 3. RUN (6 frames): Dynamic agile silat rush/step cycle from 6fmv poses [2, 3, 4, 5, 6, 7]
run_configs = [
    (2, GROUND_Y),
    (3, GROUND_Y - 2),
    (4, GROUND_Y - 6),
    (5, GROUND_Y - 12),
    (6, GROUND_Y - 4),
    (7, GROUND_Y),
]
run_cells = []
for idx, by in run_configs:
    _, y0, _, y1, pim = poses_6f[idx]
    th = int(round((y1 - y0 + 1) * base_sc_6f))
    run_cells.append(place_on_cell(pim, min(STD_HEIGHT + 4, th), bottom_y=by, center_x=128))
save_sheet(run_cells, "run")

# 4. SHIELD (4 frames): Defensive silat low-stance guard from 6fmv poses [1, 2, 2, 1]
shield_configs = [
    (1, 0.98, 128),
    (2, 0.95, 126),
    (2, 0.94, 125),
    (1, 0.97, 127),
]
shield_cells = []
for idx, sc_mult, cx in shield_configs:
    _, y0, _, y1, pim = poses_6f[idx]
    th = int(round((y1 - y0 + 1) * base_sc_6f * sc_mult))
    shield_cells.append(place_on_cell(pim, th, bottom_y=GROUND_Y, center_x=cx))
save_sheet(shield_cells, "shield")

# 5. ATTACK_1 (5 frames): Clean & normalize from user's attack_1.png
im_atk1 = Image.open(os.path.join(SRC_DIR, "attack_1.png")).convert("RGBA")
atk1_cells = []
atk1_heights = [204, 200, 199, 198, 203]
for i in range(5):
    raw_cell = im_atk1.crop((i * 256, 0, (i + 1) * 256, 256))
    clean_c, bbox = clean_rgba_cell(raw_cell, keep_dust=False)
    cropped = clean_c.crop((bbox[0], bbox[1], bbox[2] + 1, bbox[3] + 1))
    atk1_cells.append(place_on_cell(cropped, atk1_heights[i], bottom_y=GROUND_Y, center_x=124))
save_sheet(atk1_cells, "attack_1")

# 6. ATTACK_2 (5 frames): Clean & normalize from user's attack_2.png (scale up from 191px to 204px)
im_atk2 = Image.open(os.path.join(SRC_DIR, "attack_2.png")).convert("RGBA")
atk2_cells = []
atk2_heights = [204, 200, 198, 196, 202]
for i in range(5):
    raw_cell = im_atk2.crop((i * 256, 0, (i + 1) * 256, 256))
    clean_c, bbox = clean_rgba_cell(raw_cell, keep_dust=False)
    cropped = clean_c.crop((bbox[0], bbox[1], bbox[2] + 1, bbox[3] + 1))
    atk2_cells.append(place_on_cell(cropped, atk2_heights[i], bottom_y=GROUND_Y, center_x=122))
save_sheet(atk2_cells, "attack_2")

# 7. ATTACK_3 (8 frames): Clean & normalize from user's attack_3.png (fix shrunk Frame 1 & align pivot)
im_atk3 = Image.open(os.path.join(SRC_DIR, "attack_3.png")).convert("RGBA")
atk3_cells = []
# Target heights for each frame of the high kick so body size stays consistent:
atk3_heights = [204, 192, 206, 206, 210, 196, 200, 202]
atk3_bottoms = [GROUND_Y, GROUND_Y, GROUND_Y, GROUND_Y, GROUND_Y, GROUND_Y - 8, GROUND_Y, GROUND_Y]
atk3_centers = [124, 124, 126, 126, 114, 124, 124, 124]
for i in range(8):
    raw_cell = im_atk3.crop((i * 256, 0, (i + 1) * 256, 256))
    clean_c, bbox = clean_rgba_cell(raw_cell, keep_dust=False)
    cropped = clean_c.crop((bbox[0], bbox[1], bbox[2] + 1, bbox[3] + 1))
    atk3_cells.append(place_on_cell(cropped, atk3_heights[i], bottom_y=atk3_bottoms[i], center_x=atk3_centers[i]))
save_sheet(atk3_cells, "attack_3")

# 8. HURT (4 frames): Build from high-res pc3t poses [0, 1, 2, 3] for maximum sharpness & zero noise
hurt_heights = [202, 203, 206, 204]
hurt_cells = []
for i in range(4):
    _, _, _, _, pim = poses_pc[i]
    hurt_cells.append(place_on_cell(pim, hurt_heights[i], bottom_y=GROUND_Y, center_x=126))
save_sheet(hurt_cells, "hurt")

# 9. DEAD (8 frames): Clean & normalize from user's dead.png (fix Frame 0/1 shrunk scale -> 204px)
im_dead = Image.open(os.path.join(SRC_DIR, "dead.png")).convert("RGBA")
dead_cells = []
dead_heights = [202, 206, 154, 148, 96, 86, 102, 44]
dead_bottoms = [GROUND_Y, GROUND_Y - 2, GROUND_Y, GROUND_Y, GROUND_Y, GROUND_Y, GROUND_Y, GROUND_Y]
for i in range(8):
    raw_cell = im_dead.crop((i * 256, 0, (i + 1) * 256, 256))
    clean_c, bbox = clean_rgba_cell(raw_cell, keep_dust=(i == 3))
    cropped = clean_c.crop((bbox[0], bbox[1], bbox[2] + 1, bbox[3] + 1))
    dead_cells.append(place_on_cell(cropped, dead_heights[i], bottom_y=dead_bottoms[i], center_x=128))
save_sheet(dead_cells, "dead")

# 10. JUMP (5 frames): Clean artifacts & normalize from user's jump.png
im_jump = Image.open(os.path.join(SRC_DIR, "jump.png")).convert("RGBA")
jump_cells = []
jump_heights = [176, 178, 148, 178, 152]
jump_bottoms = [GROUND_Y, 224, 192, 232, GROUND_Y]
for i in range(5):
    raw_cell = im_jump.crop((i * 256, 0, (i + 1) * 256, 256))
    clean_c, bbox = clean_rgba_cell(raw_cell, keep_dust=False)
    cropped = clean_c.crop((bbox[0], bbox[1], bbox[2] + 1, bbox[3] + 1))
    jump_cells.append(place_on_cell(cropped, jump_heights[i], bottom_y=jump_bottoms[i], center_x=128))
save_sheet(jump_cells, "jump")

# Create a master visual verification sheet of all 10 animations
anim_order = ["idle", "walk", "run", "jump", "attack_1", "attack_2", "attack_3", "shield", "hurt", "dead"]
master = Image.new("RGBA", (256 * 8 + 20, len(anim_order) * 280 + 20), (35, 38, 46, 255))
mdraw = ImageDraw.Draw(master)
for row_idx, aname in enumerate(anim_order):
    sh = Image.open(os.path.join(ARGA_OUT_DIR, f"{aname}.png")).convert("RGBA")
    n_f = sh.width // 256
    y_top = row_idx * 280 + 28
    mdraw.text((12, row_idx * 280 + 6), f"{aname}.png ({sh.width}x{sh.height}, {n_f} frames @ 256x256)", fill=(255, 230, 90, 255))
    # Draw ground line at y_top + GROUND_Y
    mdraw.line([(10, y_top + GROUND_Y), (10 + sh.width, y_top + GROUND_Y)], fill=(80, 220, 120, 160), width=1)
    master.paste(sh, (10, y_top), sh)
    for f_idx in range(n_f):
        x_left = 10 + f_idx * 256
        mdraw.rectangle([x_left, y_top, x_left + 255, y_top + 255], outline=(90, 130, 180, 140), width=1)
        # center tick
        mdraw.line([(x_left + 128, y_top + 245), (x_left + 128, y_top + 255)], fill=(255, 100, 100, 180), width=1)

master_preview_path = os.path.join(INTER_DIR, "arga_all_10_animations_preview.png")
master.save(master_preview_path)
print("Saved master preview:", master_preview_path)
