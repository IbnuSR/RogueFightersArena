extends Node

# Parameter AI sesuai PDF
@export var agresivitas: float = 0.6 # 0.0 - 1.0 (Seberapa sering menyerang)
@export var waktu_reaksi: float = 0.4 # Delay dalam detik
@export var jarak_serang: float = 110.0 # Jarak ideal untuk mulai memukul
@export var peluang_tangkis: float = 0.3 # 0.0 - 1.0

var reaction_timer: float = 0.0
var player: Node2D

func _ready() -> void:
	# Cari fighter lain di scene sebagai target (Player)
	for f in get_tree().get_nodes_in_group("fighters"):
		if f != get_parent():
			player = f
			break

func _process(delta: float) -> void:
	var fighter = get_parent()
	if not fighter or not player: return

	# 1. Reset semua input state setiap frame
	for key in fighter.input_state:
		fighter.input_state[key] = false

	var distance = fighter.global_position.distance_to(player.global_position)
	var direction_to_player = sign(player.global_position.x - fighter.global_position.x)

	# 2. Logika Gerakan (Mendekat)
	if distance > jarak_serang:
		if direction_to_player > 0:
			fighter.input_state["right"] = true
		else:
			fighter.input_state["left"] = true
	else:
		# 3. Logika Serangan (Jika sudah dekat)
		reaction_timer -= delta
		if reaction_timer <= 0:
			# Reset timer dengan sedikit variasi acak
			reaction_timer = waktu_reaksi + randf() * 0.3
			
			# Putuskan apakah akan menyerang berdasarkan agresivitas
			if randf() < agresivitas:
				# Pilih serangan acak (Sesuai nama baru)
				var attacks = ["attack_1", "attack_2", "attack_3"]
				var random_attack = attacks[randi() % attacks.size()]
				fighter.input_state[random_attack] = true
		
		# 4. Logika Menangkis (Jika player sedang menyerang)
		if player.is_attacking and distance < jarak_serang + 30:
			if randf() < peluang_tangkis:
				fighter.input_state["block"] = true
