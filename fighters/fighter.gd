extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal got_hit(damage: int)
signal did_block()

@export var body_color: Color = Color(0.2, 0.4, 1.0)
@export var walk_speed: float = 300.0
@export var jump_velocity: float = -900.0
@export var gravity: float = 2400.0
@export var max_health: int = 100
var dmg_mult: float = 1.0
var spd_mult: float = 1.0
@export var character_id: String = "samurai"

# Data sprite per karakter: [jumlah_frame, lebar_frame_px] untuk tiap animasi.
# (Dihitung dari file PNG aslinya, cocok dengan potongan di scene.)
const CHARACTERS := {
	"samurai": {
		"folder": "res://assets/fighters/fighter_samurai",
		"frames": {
			"attack_1": [7, 110], "attack_2": [5, 102], "attack_3": [3, 128],
			"dead": [3, 128], "hurt": [2, 128], "idle": [6, 128],
			"jump": [12, 128], "run": [8, 128], "shield": [2, 128], "walk": [8, 128],
		},
	},
	"shinobi": {
		"folder": "res://assets/enemies/enemy_shinobi",
		"frames": {
			"attack_1": [5, 128], "attack_2": [4, 96], "attack_3": [4, 128],
			"dead": [4, 128], "hurt": [2, 128], "idle": [6, 128],
			"jump": [12, 128], "run": [8, 128], "shield": [4, 128], "walk": [8, 128],
		},
	},
	"arga": {
		"folder": "res://assets/fighters/fighter_arga",
		# Skala 1.273 (10 Nov 2026): tinggi badan median idle Arga 188,5 px
		# x 1.273 = 240 px, sama dengan Samurai (247) & Shinobi (237).
		# Skala lama 0.949 warisan art lama -> Arga cuma 179 px, kekecilan.
		# anim_fix dihitung ulang dari skala baru (rumus process_arga_v2.py).
		"frame_h": 256,
		"sprite_scale": 1.273,
		"feet_y": 237,
		"stats": {"hp": 100, "dmg": 1.0, "spd": 1.0},
		"anim_fix": {"walk": [1.273, -157.7], "run": [1.368, -139.3], "jump": [1.423, -166.6], "attack_1": [1.184, -161.6], "attack_2": [1.273, -172.9], "attack_3": [1.273, -172.9], "shield": [0.955, -131.3], "hurt": [1.273, -172.9], "dead": [1.719, -230.0]},
		"anim_speeds": {"walk": 12.0, "attack_3": 13.0, "jump": 7.0},
		"frames": {
			"attack_1": [5, 149], "attack_2": [5, 156], "attack_3": [8, 302],
			"dead": [8, 185], "hurt": [4, 146], "idle": [6, 125],
			"jump": [5, 189], "run": [6, 140], "shield": [4, 165], "walk": [10, 130],
		},
	},
	"marco": {
		"folder": "res://assets/fighters/fighter_marco",
		"frame_h": 256,
		"sprite_scale": 1.152,
		"feet_y": 237,
		"stats": {"hp": 90, "dmg": 0.9, "spd": 1.15},
		"anim_fix": {"walk": [1.152, -136.7], "run": [1.325, -121.3], "jump": [1.555, -146.9], "attack_1": [1.152, -131.5], "attack_2": [1.152, -127.5], "attack_3": [1.152, -137.3], "shield": [1.152, -135.6], "hurt": [1.064, -124.9], "dead": [1.285, -138.5]},
		"frames": {
			"idle": [6, 133],
			"walk": [12, 136],
			"run": [6, 138],
			"jump": [7, 130],
			"attack_1": [11, 140],
			"attack_2": [11, 140],
			"attack_3": [11, 140],
			"shield": [4, 125],
			"hurt": [4, 139],
			"dead": [4, 138],
		},
	},
	"dmitri": {
		"folder": "res://assets/fighters/fighter_dmitri",
		"frame_h": 256,
		"sprite_scale": 1.152,
		"feet_y": 244,
		"stats": {"hp": 140, "dmg": 1.2, "spd": 0.85},
		"anim_fix": {"walk": [1.152, -131.0], "run": [1.325, -129.2], "jump": [1.152, -145.9], "attack_1": [1.314, -144.0], "attack_2": [1.436, -153.6], "attack_3": [1.306, -147.1], "shield": [1.152, -141.3], "hurt": [1.152, -145.9], "dead": [1.152, -136.7]},
		"frames": {
			"idle": [6, 130],
			"walk": [24, 136],
			"run": [6, 135],
			"jump": [13, 212],
			"attack_1": [21, 135],
			"attack_2": [21, 140],
			"attack_3": [21, 152],
			"shield": [4, 200],
			"hurt": [4, 200],
			"dead": [4, 269],
		},
	},
	"lin": {
		"folder": "res://assets/fighters/fighter_lin",
		"frame_h": 256,
		"sprite_scale": 1.185,
		"feet_y": 238,
		"stats": {"hp": 90, "dmg": 0.8, "spd": 1.05},
		"anim_fix": {"walk": [1.185, -139.2], "run": [1.311, -122.7], "jump": [1.185, -120.8], "attack_1": [1.185, -138.0], "attack_2": [1.185, -138.0], "attack_3": [1.394, -131.9], "shield": [1.185, -130.9], "hurt": [1.185, -138.0], "dead": [1.185, -142.7]},
		"frames": {
			"idle": [6, 140],
			"walk": [12, 134],
			"run": [6, 140],
			"jump": [7, 263],
			"attack_1": [11, 140],
			"attack_2": [11, 140],
			"attack_3": [11, 138],
			"shield": [4, 133],
			"hurt": [4, 140],
			"dead": [4, 268],
		},
	},
	"nok": {
		"folder": "res://assets/fighters/fighter_nok",
		"frame_h": 256,
		"sprite_scale": 1.120,
		"feet_y": 246,
		"stats": {"hp": 105, "dmg": 1.1, "spd": 1.0},
		"anim_fix": {"walk": [1.276, -140.2], "run": [1.288, -116.9], "jump": [1.12, -129.3], "attack_1": [1.213, -141.0], "attack_2": [1.2, -142.0], "attack_3": [1.29, -145.5], "shield": [1.12, -134.3], "hurt": [0.933, -128.5], "dead": [1.512, -171.0]},
		"frames": {
			"idle": [6, 127],
			"walk": [12, 136],
			"run": [6, 139],
			"jump": [7, 236],
			"attack_1": [11, 140],
			"attack_2": [11, 138],
			"attack_3": [11, 140],
			"shield": [4, 128],
			"hurt": [4, 215],
			"dead": [4, 137],
		},
	},
	"sora": {
		"folder": "res://assets/fighters/fighter_sora",
		"frame_h": 256,
		"sprite_scale": 1.343,
		"feet_y": 231,
		"stats": {"hp": 95, "dmg": 1.0, "spd": 1.05},
		"anim_fix": {"walk": [1.343, -159.1], "run": [1.544, -132.0], "jump": [1.56, -159.0], "attack_1": [1.555, -160.0], "attack_2": [1.343, -157.1], "attack_3": [1.634, -165.3], "shield": [1.343, -157.7], "hurt": [1.343, -170.5], "dead": [1.343, -165.1]},
		"frames": {
			"idle": [6, 128],
			"walk": [12, 131],
			"run": [6, 137],
			"jump": [7, 138],
			"attack_1": [11, 140],
			"attack_2": [11, 140],
			"attack_3": [11, 139],
			"shield": [4, 129],
			"hurt": [4, 192],
			"dead": [4, 263],
		},
	},
	"tyrone": {
		"folder": "res://assets/fighters/fighter_tyrone",
		"frame_h": 256,
		"sprite_scale": 1.180,
		"feet_y": 244,
		"stats": {"hp": 110, "dmg": 1.15, "spd": 0.95},
		"anim_fix": {"walk": [1.18, -141.0], "run": [1.357, -129.4], "jump": [1.18, -145.7], "attack_1": [1.254, -141.6], "attack_2": [1.413, -141.4], "attack_3": [1.18, -154.0], "shield": [0.926, -123.0], "hurt": [1.18, -151.6], "dead": [1.18, -142.7]},
		"frames": {
			"idle": [6, 131],
			"walk": [12, 140],
			"run": [6, 140],
			"jump": [7, 153],
			"attack_1": [11, 140],
			"attack_2": [11, 140],
			"attack_3": [11, 140],
			"shield": [4, 196],
			"hurt": [4, 124],
			"dead": [4, 197],
		},
	},
	"han": {
		"folder": "res://assets/fighters/fighter_han",
		"frame_h": 256,
		"sprite_scale": 1.286,
		"feet_y": 251,
		"stats": {"hp": 90, "dmg": 1.0, "spd": 1.1},
		"anim_fix": {"walk": [1.286, -138.6], "run": [1.479, -144.6], "jump": [1.065, -140.4], "attack_1": [1.286, -154.0], "attack_2": [1.062, -139.6], "attack_3": [1.286, -110.3], "shield": [1.016, -136.0], "hurt": [1.286, -139.9], "dead": [1.286, -150.2]},
		"frames": {
			"idle": [6, 129],
			"walk": [12, 138],
			"run": [6, 140],
			"jump": [7, 207],
			"attack_1": [11, 140],
			"attack_2": [11, 267],
			"attack_3": [11, 228],
			"shield": [4, 188],
			"hurt": [4, 140],
			"dead": [4, 140],
		},
	},
	"valeria": {
		"folder": "res://assets/fighters/fighter_valeria",
		"frame_h": 256,
		"sprite_scale": 1.080,
		"feet_y": 248,
		"stats": {"hp": 95, "dmg": 1.05, "spd": 1.1},
		"anim_fix": {"walk": [1.08, -136.4], "run": [1.242, -126.7], "jump": [1.08, -136.4], "attack_1": [1.08, -135.8], "attack_2": [1.458, -101.1], "attack_3": [1.458, -56.7], "shield": [1.08, -111.5], "hurt": [1.08, -131.0], "dead": [1.08, -121.2]},
		"frames": {
			"idle": [6, 140],
			"walk": [12, 140],
			"run": [6, 140],
			"jump": [7, 182],
			"attack_1": [11, 140],
			"attack_2": [11, 138],
			"attack_3": [11, 140],
			"shield": [4, 132],
			"hurt": [4, 137],
			"dead": [4, 209],
		},
	},
	"anika": {
		"folder": "res://assets/fighters/fighter_anika",
		"frame_h": 256,
		"sprite_scale": 1.174,
		"feet_y": 240,
		"stats": {"hp": 85, "dmg": 0.9, "spd": 1.2},
		"anim_fix": {"walk": [1.352, -127.6], "run": [1.35, -119.4], "jump": [1.05, -116.0], "attack_1": [1.174, -132.7], "attack_2": [1.174, -137.4], "attack_3": [1.445, -145.8], "shield": [1.174, -153.2], "hurt": [1.028, -139.5], "dead": [1.174, -148.5]},
		"frames": {
			"idle": [6, 139],
			"walk": [12, 139],
			"run": [6, 139],
			"jump": [7, 253],
			"attack_1": [11, 140],
			"attack_2": [11, 140],
			"attack_3": [11, 140],
			"shield": [4, 103],
			"hurt": [4, 198],
			"dead": [4, 268],
		},
	},
}

# Kecepatan animasi per jenis (fps) — idle lambat, serangan cepat & snappy
const ANIM_SPEEDS := {
	"idle": 5.0, "walk": 10.0, "run": 12.0, "jump": 9.0,
	"attack_1": 14.0, "attack_2": 12.0, "attack_3": 10.0,
	"shield": 6.0, "hurt": 10.0, "dead": 6.0,
}

# Data serangan. Nama key SAMA PERSIS dengan nama animasi di SpriteFrames
const ATTACKS := {
	"attack_1": {"damage": 6, "startup": 0.08, "active": 0.08, "recovery": 0.15,
		"reach": 80.0, "height": -120.0, "size": Vector2(70, 40)},
	"attack_2": {"damage": 10, "startup": 0.12, "active": 0.10, "recovery": 0.22,
		"reach": 90.0, "height": -125.0, "size": Vector2(80, 45)},
	"attack_3": {"damage": 15, "startup": 0.18, "active": 0.12, "recovery": 0.30,
		"reach": 110.0, "height": -100.0, "size": Vector2(100, 50)},
}

const STAND_HEIGHT := 180.0
const CROUCH_HEIGHT := 110.0
const BODY_WIDTH := 80.0

@onready var body: ColorRect = $Body
@onready var nose: ColorRect = $Nose
@onready var shape_node: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hitbox_visual: ColorRect = $Hitbox/ColorRect
@onready var sprite: AnimatedSprite2D = $Sprite

var health: int
var facing := 1
var is_crouching := false
var is_attacking := false
var is_dead := false
var is_hurt := false
var can_fight := false
var current_damage := 0
var already_hit: Array = []
var opponent: Node2D = null

# input_state disesuaikan dengan nama aksi baru
var input_state := {
	"left": false, "right": false,
	"jump": false, "block": false,
	"attack_1": false, "attack_2": false, "attack_3": false
}

func _ready() -> void:
	set_character(character_id)
	shape_node.shape = shape_node.shape.duplicate()
	hitbox_shape.shape = hitbox_shape.shape.duplicate()
	health = max_health
	hitbox.monitoring = false
	hitbox_visual.hide()
	add_to_group("fighters")
	_apply_facing()

	if body: body.visible = false
	if nose: nose.visible = false


# Membangun SpriteFrames dari folder karakter (dipakai untuk ganti samurai/shinobi)
func set_character(char_id: String) -> void:
	if not CHARACTERS.has(char_id):
		char_id = "samurai"
	character_id = char_id
	var data: Dictionary = CHARACTERS[char_id]
	char_data = data
	var frame_data: Dictionary = data["frames"]
	var frame_h: int = data.get("frame_h", 128)
	# Override kecepatan animasi per karakter (mis. Arga: walk/attack_3/jump
	# disesuaikan dengan jumlah frame & durasi geraknya); kalau tidak ada,
	# pakai ANIM_SPEEDS global.
	var speed_over: Dictionary = data.get("anim_speeds", {})
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name in frame_data:
		frames.add_animation(anim_name)
		var spec: Array = frame_data[anim_name]
		var count: int = spec[0]
		var frame_w: int = spec[1]
		var tex: Texture2D = load(data["folder"] + "/" + anim_name + ".png")
		for i in count:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * frame_w, 0, frame_w, frame_h)
			frames.add_frame(anim_name, at)
		frames.set_animation_speed(anim_name,
			float(speed_over.get(anim_name, ANIM_SPEEDS.get(anim_name, 8.0))))
		# FIX (2026-11-10): animasi "dead" JANGAN looping — kalau looping,
		# karakter yang sudah pingsan akan bangun lagi (frame awal = berdiri)
		# lalu tidur lagi, berulang-ulang. Dengan loop=false, animasi mati
		# berhenti di frame terakhir (terbaring) dan diam di sana sampai
		# ronde berikutnya (reset_for_next_round mainkan "idle" lagi).
		# Animasi lain tetap looping seperti biasa.
		frames.set_animation_loop(anim_name, anim_name != "dead")
	sprite.sprite_frames = frames
	var sc: float = float(data.get("sprite_scale", 3.0))
	base_scale = sc
	# Samakan tinggi visual & posisi kaki di tanah untuk semua karakter.
	# Kaki (feet_y, dalam px frame) diposisikan di y=-10 seperti samurai.
	var feet_y: float = float(data.get("feet_y", frame_h))
	base_pos_y = -10.0 + (frame_h * sc) / 2.0 - feet_y * sc
	sprite.scale = Vector2.ONE * sc
	sprite.position.y = base_pos_y
	_apply_anim_fix("idle")
	var stats: Dictionary = data.get("stats", {})
	max_health = int(stats.get("hp", 100))
	dmg_mult = float(stats.get("dmg", 1.0))
	spd_mult = float(stats.get("spd", 1.0))
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_dead:
		velocity.x = 0.0
		move_and_slide()
		_update_animation()
		return

	if not can_fight:
		velocity.x = 0.0
		move_and_slide()
		_update_animation()
		return

	_update_facing()
	_set_crouch(input_state["block"] and is_on_floor())

	# Gerak pakai akselerasi biar halus (tidak patah-patah)
	var target_vx := 0.0
	if not (is_attacking or is_crouching):
		var dir := 0.0
		if input_state["left"]: dir -= 1.0
		if input_state["right"]: dir += 1.0
		target_vx = dir * walk_speed * spd_mult
		var accel := 2600.0 if is_on_floor() else 1400.0
		velocity.x = move_toward(velocity.x, target_vx, accel * delta)

		if input_state["jump"] and is_on_floor():
			velocity.y = jump_velocity
			Audio.play_sfx("jump", -8.0)
			input_state["jump"] = false
		elif is_on_floor():
			for attack_name in ATTACKS:
				if input_state[attack_name]:
					_attack(attack_name)
					input_state[attack_name] = false
					break
	else:
		velocity.x = move_toward(velocity.x, 0.0, 2600.0 * delta)

	move_and_slide()
	_check_hits()
	_update_animation()


func _update_animation():
	if not sprite: return

	sprite.flip_h = (facing == -1)

	if is_dead:
		_play_safe("dead")
	elif is_hurt:
		_play_safe("hurt")
	elif is_attacking:
		pass
	elif is_crouching or input_state["block"]:
		_play_safe("shield")
	elif not is_on_floor():
		_play_safe("jump")
	elif abs(velocity.x) > 10.0:
		# FIX (2026-11-10, versi GitHub a12c7e4): game ini tidak punya
		# mekanik lari — semua gerak horizontal adalah jalan kaki
		# (walk_speed), jadi pakai animasi "walk" agar sprite sesuai
		# dengan gerakannya. Sebelumnya "run" selalu menang, jadi
		# animasi "walk" tidak pernah main. ("run" tetap tersedia
		# kalau mekanik lari ditambahkan di kemudian hari.)
		if _has_anim("walk"):
			_play_safe("walk")
		elif _has_anim("run"):
			_play_safe("run")
		else:
			_play_safe("idle")
	else:
		_play_safe("idle")


func _has_anim(anim_name: String) -> bool:
	if sprite and sprite.sprite_frames:
		return sprite.sprite_frames.has_animation(anim_name)
	return false

var base_scale := 3.0
var base_pos_y := -202.0
var char_data: Dictionary = {}

func _play_safe(anim_name: String):
	if _has_anim(anim_name) and sprite.animation != anim_name:
		sprite.play(anim_name)
	_apply_anim_fix(anim_name)


func _apply_anim_fix(anim_name: String):
	# Samakan ukuran badan tiap animasi (koreksi inkonsistensi art).
	var fix: Dictionary = char_data.get("anim_fix", {})
	if fix.has(anim_name):
		var f: Array = fix[anim_name]
		sprite.scale = Vector2.ONE * float(f[0])
		sprite.position.y = float(f[1])
	else:
		sprite.scale = Vector2.ONE * base_scale
		sprite.position.y = base_pos_y


func _update_facing() -> void:
	if is_attacking: return
	if not is_instance_valid(opponent):
		_find_opponent()
		if not is_instance_valid(opponent): return
	var new_facing := 1 if opponent.global_position.x >= global_position.x else -1
	if new_facing != facing:
		facing = new_facing
		_apply_facing()


func _find_opponent() -> void:
	for f in get_tree().get_nodes_in_group("fighters"):
		if f != self:
			opponent = f as Node2D
			return


func _apply_facing() -> void:
	if nose: nose.position = Vector2(facing * 30.0 - 10.0, -100.0)


func _attack(attack_name: String) -> void:
	var atk: Dictionary = ATTACKS[attack_name]
	is_attacking = true
	current_damage = int(atk["damage"] * dmg_mult)
	already_hit.clear()
	_setup_hitbox(atk)
	Audio.play_sfx("swing", -4.0)

	# Mainkan animasi serangan (nama key = nama animasi)
	_play_safe(attack_name)

	await get_tree().create_timer(atk["startup"]).timeout
	if is_dead: return
	hitbox.monitoring = true

	await get_tree().create_timer(atk["active"]).timeout
	hitbox.monitoring = false

	await get_tree().create_timer(atk["recovery"]).timeout
	is_attacking = false


func _setup_hitbox(atk: Dictionary) -> void:
	var box_size: Vector2 = atk["size"]
	(hitbox_shape.shape as RectangleShape2D).size = box_size
	hitbox_visual.size = box_size
	hitbox_visual.position = -box_size / 2.0
	hitbox.position = Vector2(facing * float(atk["reach"]), float(atk["height"]))


func _check_hits() -> void:
	if not hitbox.monitoring: return
	for b in hitbox.get_overlapping_bodies():
		if b == self or b in already_hit: continue
		if b.has_method("take_damage"):
			already_hit.append(b)
			b.take_damage(current_damage)


func take_damage(amount: int) -> void:
	if is_dead: return

	# LOGIKA BLOCK: Jika sedang menangkis, damage diabaikan
	if is_crouching or input_state["block"]:
		Audio.play_sfx("block", -2.0)
		did_block.emit()
		return # Keluar dari fungsi, health TIDAK berkurang dan tidak masuk status 'hurt'

	# Jika tidak block, baru terkena damage normal
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	Audio.play_sfx("hit", -2.0)
	got_hit.emit(amount)

	is_hurt = true
	_play_safe("hurt")
	await get_tree().create_timer(0.2).timeout
	is_hurt = false

	if health == 0:
		is_dead = true
		hitbox.monitoring = false
		died.emit()


func _set_crouch(value: bool) -> void:
	if value == is_crouching: return
	is_crouching = value
	var h := CROUCH_HEIGHT if value else STAND_HEIGHT
	body.size = Vector2(BODY_WIDTH, h)
	body.position = Vector2(-BODY_WIDTH / 2.0, -h)
	var rect := shape_node.shape as RectangleShape2D
	rect.size = Vector2(BODY_WIDTH, h)
	shape_node.position = Vector2(0, -h / 2.0)


func start_fighting():
	can_fight = true


# Fungsi untuk mereset petarung di awal ronde baru
func reset_for_next_round():
	health = max_health
	is_dead = false
	is_attacking = false
	is_hurt = false
	can_fight = false # Akan diaktifkan lagi oleh arena saat countdown selesai
	velocity = Vector2.ZERO
	hitbox.monitoring = false
	
	# Update UI bar nyawa
	health_changed.emit(health, max_health)
	
	# Kembalikan animasi ke idle
	_play_safe("idle")
