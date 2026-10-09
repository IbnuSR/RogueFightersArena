extends Node
## AI petarung: footwork (goyang maju-mundur), menyerang dengan kombo,
## mundur setelah menyerang, sesekali lompat-serang, dan menangkis reaktif.

@export var agresivitas: float = 0.6   # 0.0 - 1.0 (seberapa sering menyerang)
@export var waktu_reaksi: float = 0.4  # jeda dasar antar keputusan (detik)
@export var jarak_serang: float = 110.0 # jarak ideal untuk memukul
@export var peluang_tangkis: float = 0.3 # 0.0 - 1.0

var player: Node2D
var state: String = "footwork"
var state_timer: float = 0.0
var attack_cd: float = 0.0
var block_cd: float = 0.0
var foot_dir: float = 0.0   # -1 = mundur, +1 = maju (relatif ke pemain)
var combo_step: int = 0      # 0 = tidak kombo, 1+ = lanjutkan kombo


func _ready() -> void:
	for f in get_tree().get_nodes_in_group("fighters"):
		if f != get_parent():
			player = f
			break


func _set_move(fighter: Node, dir_to_player: float, move: float) -> void:
	# move: -1 = menjauh, +1 = mendekat, 0 = diam
	if move > 0.0:
		if dir_to_player > 0.0:
			fighter.input_state["right"] = true
		else:
			fighter.input_state["left"] = true
	elif move < 0.0:
		if dir_to_player > 0.0:
			fighter.input_state["left"] = true
		else:
			fighter.input_state["right"] = true


func _pick_attack() -> String:
	# Serangan ringan lebih sering; kombo: attack_1 -> attack_2
	if combo_step == 1:
		combo_step = 0
		return "attack_2"
	var r := randf()
	if r < 0.5:
		return "attack_1"
	elif r < 0.8:
		return "attack_2"
	return "attack_3"


func _process(delta: float) -> void:
	var fighter = get_parent()
	if not fighter or not player:
		return
	for key in fighter.input_state:
		fighter.input_state[key] = false

	var to_p: float = player.global_position.x - fighter.global_position.x
	var dist := absf(to_p)
	var dir_p := signf(to_p)
	if dir_p == 0.0:
		dir_p = 1.0

	state_timer -= delta
	attack_cd -= delta
	block_cd -= delta

	# --- Tangkis reaktif (override, dengan cooldown agar tidak kedip) ---
	if block_cd <= 0.0 and player.get("is_attacking") and dist < jarak_serang + 50.0:
		if randf() < peluang_tangkis:
			fighter.input_state["block"] = true
			block_cd = 0.35 + randf() * 0.3
			return

	match state:
		"footwork":
			# Goyang kaki: langkah pendek maju/mundur seperti petarung beneran
			if state_timer <= 0.0:
				state_timer = 0.25 + randf() * 0.45
				if dist > jarak_serang * 1.6:
					foot_dir = 1.0  # kejauhan: mendekat
				elif dist < jarak_serang * 0.7:
					foot_dir = -1.0 if randf() < 0.6 else 1.0  # kedekatan: jaga jarak
				else:
					# zona nyaman: goyang acak (tinju footwork)
					foot_dir = 1.0 if randf() < 0.5 else -1.0
			_set_move(fighter, dir_p, foot_dir)
			# Putuskan menyerang
			if dist <= jarak_serang and attack_cd <= 0.0 and state_timer <= 0.15:
				if randf() < agresivitas:
					state = "attack"
					state_timer = 0.1
			# Sesekali lompat-serang (makin agresif makin sering)
			elif dist > jarak_serang and dist < 320.0 and attack_cd <= 0.0:
				if randf() < agresivitas * 0.12:
					state = "jumpin"

		"attack":
			if state_timer <= 0.0:
				var atk := _pick_attack()
				fighter.input_state[atk] = true
				# Peluang kombo: lanjutkan dengan serangan kedua
				if atk == "attack_1" and randf() < agresivitas * 0.5:
					combo_step = 1
					state_timer = 0.32
					state = "combo_wait"
				else:
					attack_cd = waktu_reaksi + randf() * 0.6
					state = "retreat"
					state_timer = 0.25 + randf() * 0.35

		"combo_wait":
			# Tunggu serangan pertama selesai, lalu lanjutkan kombo
			if state_timer <= 0.0:
				state = "attack"
				state_timer = 0.05

		"retreat":
			# Mundur sejenak setelah menyerang (jaga jarak, seperti petarung)
			_set_move(fighter, dir_p, -1.0)
			if state_timer <= 0.0:
				state = "footwork"
				state_timer = 0.2 + randf() * 0.3

		"jumpin":
			# Lompat ke arah pemain + serang saat mendarat
			_set_move(fighter, dir_p, 1.0)
			if fighter.is_on_floor():
				fighter.input_state["jump"] = true
				state = "jumpin_air"

		"jumpin_air":
			_set_move(fighter, dir_p, 1.0)
			if fighter.is_on_floor():
				# Mendarat: langsung serang
				fighter.input_state[_pick_attack()] = true
				attack_cd = waktu_reaksi + randf() * 0.6
				state = "retreat"
				state_timer = 0.3
