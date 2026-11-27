"""
Script untuk men-generate semua scene .tscn karakter dan boss di fighters/
agar memiliki SpriteFrames lengkap yang terhubung langsung ke asetnya masing-masing.
Dengan ini, saat scene .tscn dibuka di Godot Editor, sprite karakter langsung
tampil kelihatan dengan ukuran (scale) dan posisi (position) yang sesuai.
"""

import os, re, ast

PROJECT = r"d:\RogueFightersArena"
FIGHTER_GD = os.path.join(PROJECT, "fighters", "fighter.gd")

GLOBAL_ANIM_SPEEDS = {
    "idle": 5.0, "walk": 10.0, "run": 12.0, "jump": 9.0,
    "attack_1": 14.0, "attack_2": 12.0, "attack_3": 10.0,
    "shield": 6.0, "hurt": 10.0, "dead": 6.0,
}

def get_uid_from_import(png_path):
    import_path = png_path + ".import"
    if os.path.exists(import_path):
        with open(import_path, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("uid="):
                    m = re.search(r'uid="(uid://[^"]+)"', line)
                    if m:
                        return m.group(1)
    return None

def parse_characters_dict():
    with open(FIGHTER_GD, "r", encoding="utf-8") as f:
        content = f.read()
    m = re.search(r'const CHARACTERS := (\{.*?\n\})', content, re.DOTALL)
    if not m:
        raise ValueError("Could not find CHARACTERS dict in fighter.gd")
    raw = m.group(1)
    lines = [re.sub(r'#.*$', '', line) for line in raw.splitlines()]
    cleaned = "\n".join(lines)
    return ast.literal_eval(cleaned)

def build_character_tscn(char_id, node_name, spec):
    folder_res = spec["folder"]
    folder_disk = os.path.join(PROJECT, folder_res.replace("res://", "").replace("/", "\\"))
    frame_h = spec.get("frame_h", 128)
    sprite_scale = float(spec.get("sprite_scale", 3.0))
    feet_y = float(spec.get("feet_y", frame_h))
    base_pos_y = -10.0 + (frame_h * sprite_scale) / 2.0 - feet_y * sprite_scale

    frames_dict = spec["frames"]
    anim_speeds = spec.get("anim_speeds", {})

    ext_resources = [
        '[ext_resource type="PackedScene" uid="uid://caueui2bcpaxy" path="res://scenes/fighter/fighter.tscn" id="1_base"]'
    ]

    ext_map = {}
    ext_idx = 2
    for anim_name in sorted(frames_dict.keys()):
        png_file = f"{anim_name}.png"
        png_disk = os.path.join(folder_disk, png_file)
        uid = get_uid_from_import(png_disk)
        uid_str = f' uid="{uid}"' if uid else ""
        ext_id = f"{ext_idx}_{anim_name}"
        ext_map[anim_name] = ext_id
        ext_resources.append(
            f'[ext_resource type="Texture2D"{uid_str} path="{folder_res}/{png_file}" id="{ext_id}"]'
        )
        ext_idx += 1

    atlas_subresources = []
    atlas_map = {}
    for anim_name, (count, frame_w) in frames_dict.items():
        ext_id = ext_map[anim_name]
        for i in range(count):
            sub_id = f"AtlasTexture_{anim_name}_{i}"
            atlas_map[(anim_name, i)] = sub_id
            atlas_subresources.append(f'[sub_resource type="AtlasTexture" id="{sub_id}"]')
            atlas_subresources.append(f'atlas = ExtResource("{ext_id}")')
            atlas_subresources.append(f'region = Rect2({i * frame_w}, 0, {frame_w}, {frame_h})')
            atlas_subresources.append("")

    sf_lines = ['[sub_resource type="SpriteFrames" id="SpriteFrames_char"]', 'animations = [{']
    anim_names = list(frames_dict.keys())
    for ai, anim_name in enumerate(anim_names):
        count = frames_dict[anim_name][0]
        speed = anim_speeds.get(anim_name, GLOBAL_ANIM_SPEEDS.get(anim_name, 8.0))
        loop = "true" if anim_name != "dead" else "false"

        sf_lines.append('"frames": [{')
        for i in range(count):
            sub_id = atlas_map[(anim_name, i)]
            sf_lines.append('"duration": 1.0,')
            sf_lines.append(f'"texture": SubResource("{sub_id}")')
            if i < count - 1:
                sf_lines.append('}, {')
            else:
                sf_lines.append('}],')
        sf_lines.append(f'"loop": {loop},')
        sf_lines.append(f'"name": &"{anim_name}",')
        sf_lines.append(f'"speed": {speed}')
        if ai < len(anim_names) - 1:
            sf_lines.append('}, {')
        else:
            sf_lines.append('}]')
    sf_lines.append("")

    scale_str = f"Vector2({sprite_scale}, {sprite_scale})"
    pos_str = f"Vector2(0, {base_pos_y:.2f})" if base_pos_y != 0 else "Vector2(0, 0)"

    node_lines = [
        f'[node name="{node_name}" instance=ExtResource("1_base")]',
        f'character_id = "{char_id}"',
        "",
        '[node name="Sprite" parent="." index="4" unique_id=1664117855]',
        f'position = {pos_str}',
        f'scale = {scale_str}',
        'sprite_frames = SubResource("SpriteFrames_char")',
        'animation = &"idle"',
        ""
    ]

    content = "[gd_scene format=3]\n\n"
    content += "\n".join(ext_resources) + "\n\n"
    content += "\n".join(atlas_subresources) + "\n"
    content += "\n".join(sf_lines) + "\n"
    content += "\n".join(node_lines)
    return content

def main():
    characters = parse_characters_dict()
    print(f"Loaded {len(characters)} character definitions.")

    # Target files mapping
    # 1. Playable characters
    playable_map = {
        "samurai": ("Samurai", os.path.join(PROJECT, "fighters", "characters", "samurai.tscn")),
        "shinobi": ("Shinobi", os.path.join(PROJECT, "fighters", "characters", "shinobi.tscn")),
        "arga": ("Arga", os.path.join(PROJECT, "fighters", "characters", "arga.tscn")),
        "marco": ("Marco", os.path.join(PROJECT, "fighters", "characters", "marco.tscn")),
        "dmitri": ("Dmitri", os.path.join(PROJECT, "fighters", "characters", "dmitri.tscn")),
        "lin": ("Lin", os.path.join(PROJECT, "fighters", "characters", "lin.tscn")),
        "nok": ("Nok", os.path.join(PROJECT, "fighters", "characters", "nok.tscn")),
        "sora": ("Sora", os.path.join(PROJECT, "fighters", "characters", "sora.tscn")),
        "tyrone": ("Tyrone", os.path.join(PROJECT, "fighters", "characters", "tyrone.tscn")),
        "han": ("Han", os.path.join(PROJECT, "fighters", "characters", "han.tscn")),
        "valeria": ("Valeria", os.path.join(PROJECT, "fighters", "characters", "valeria.tscn")),
        "anika": ("Anika", os.path.join(PROJECT, "fighters", "characters", "anika.tscn")),
    }

    # 2. Enemy characters
    enemy_map = {
        "buruh_bayaran": ("BuruhBayaran", os.path.join(PROJECT, "fighters", "characters", "buruh_bayaran.tscn")),
        "penyelundup": ("Penyelundup", os.path.join(PROJECT, "fighters", "characters", "penyelundup.tscn")),
        "geng_jalanan": ("GengJalanan", os.path.join(PROJECT, "fighters", "characters", "geng_jalanan.tscn")),
        "akrobat": ("Akrobat", os.path.join(PROJECT, "fighters", "characters", "akrobat.tscn")),
        "murid_dojo": ("MuridDojo", os.path.join(PROJECT, "fighters", "characters", "murid_dojo.tscn")),
        "pengawal_elit": ("PengawalElit", os.path.join(PROJECT, "fighters", "characters", "pengawal_elit.tscn")),
    }

    # 3. Boss characters
    boss_map = {
        "kapten_brak": ("BossKaptenBrak", os.path.join(PROJECT, "fighters", "BossKaptenBrak.tscn")),
        "alaric_voss": ("BossAlaricVoss", os.path.join(PROJECT, "fighters", "BossAlaricVoss.tscn")),
        "guru_sunyi": ("BossGuruSunyi", os.path.join(PROJECT, "fighters", "BossGuruSunyi.tscn")),
        "ular_neon": ("BossUlarNeon", os.path.join(PROJECT, "fighters", "BossUlarNeon.tscn")),
    }

    all_targets = {}
    all_targets.update(playable_map)
    all_targets.update(enemy_map)
    all_targets.update(boss_map)

    for char_id, (node_name, target_path) in all_targets.items():
        if char_id not in characters:
            print(f"WARNING: {char_id} not in CHARACTERS dict, skipping.")
            continue
        spec = characters[char_id]
        tscn_content = build_character_tscn(char_id, node_name, spec)
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        with open(target_path, "w", encoding="utf-8", newline="\n") as f:
            f.write(tscn_content)
        print(f"Generated {os.path.basename(target_path)} ({char_id}) -> {len(tscn_content)} bytes")

    print("\nSemua 22 scene fighter TSCN berhasil di-generate!")

if __name__ == "__main__":
    main()
