extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

@export var body_color: Color = Color(0.2, 0.4, 1.0)
@export var walk_speed: float = 300.0
@export var jump_velocity: float = -900.0
@export var gravity: float = 2400.0
@export var max_health: int = 100

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
	shape_node.shape = shape_node.shape.duplicate()
	hitbox_shape.shape = hitbox_shape.shape.duplicate()
	health = max_health
	hitbox.monitoring = false
	hitbox_visual.hide()
	add_to_group("fighters")
	_apply_facing()

	if body: body.visible = false
	if nose: nose.visible = false

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

	if is_attacking or is_crouching:
		velocity.x = 0.0
	else:
		var dir := 0.0
		if input_state["left"]: dir -= 1.0
		if input_state["right"]: dir += 1.0
		velocity.x = dir * walk_speed

		if input_state["jump"] and is_on_floor():
			velocity.y = jump_velocity
			input_state["jump"] = false
		elif is_on_floor():
			for attack_name in ATTACKS:
				if input_state[attack_name]:
					_attack(attack_name)
					input_state[attack_name] = false
					break

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
		if _has_anim("run"):
			_play_safe("run")
		elif _has_anim("walk"):
			_play_safe("walk")
		else:
			_play_safe("idle")
	else:
		_play_safe("idle")


func _has_anim(anim_name: String) -> bool:
	if sprite and sprite.sprite_frames:
		return sprite.sprite_frames.has_animation(anim_name)
	return false

func _play_safe(anim_name: String):
	if _has_anim(anim_name) and sprite.animation != anim_name:
		sprite.play(anim_name)


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
	current_damage = atk["damage"]
	already_hit.clear()
	_setup_hitbox(atk)

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
		print("Serangan ditangkis!")
		# Opsional: Kamu bisa tambahkan efek suara 'ting!' atau partikel percikan di sini nanti
		return # Keluar dari fungsi, health TIDAK berkurang dan tidak masuk status 'hurt'

	# Jika tidak block, baru terkena damage normal
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	
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
