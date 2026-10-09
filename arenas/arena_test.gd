extends Node2D
## Arena: mengatur ronde, timer, pause, game over, efek, dan mode permainan.

const HumanControllerScript := preload("res://HumanController.gd")
const ROUND_TIME := 60.0
const WINS_REQUIRED := 2

@onready var fighter_1 = $Fighter
@onready var fighter_2 = $Fighter2
@onready var p1_bar: ProgressBar = $HUD/P1Bar
@onready var p2_bar: ProgressBar = $HUD/P2Bar
@onready var p1_name: Label = $HUD/P1Name
@onready var p2_name: Label = $HUD/P2Name
@onready var timer_label: Label = $HUD/TimerLabel
@onready var countdown_label: Label = $CanvasLayer/CountdownLabel
@onready var background: Sprite2D = $Background
@onready var camera: Camera2D = $Camera2D

@onready var p1_win_1: ColorRect = $HUD/P1Win1
@onready var p1_win_2: ColorRect = $HUD/P1Win2
@onready var p2_win_1: ColorRect = $HUD/P2Win1
@onready var p2_win_2: ColorRect = $HUD/P2Win2

@onready var ko_label: Label = $OverlayLayer/KOLabel
@onready var pause_menu: Control = $OverlayLayer/PauseMenu
@onready var gameover_menu: Control = $OverlayLayer/GameOverMenu
@onready var winner_label: Label = $OverlayLayer/GameOverMenu/Center/Panel/VBox/WinnerLabel

# DAFTAR BACKGROUND: Path sudah pakai underscore
var list_background: Array[Texture2D] = [
	preload("res://assets/backgrounds/castle.png"),
	preload("res://assets/backgrounds/dead_forest.png"),
	preload("res://assets/backgrounds/terrace.png"),
	preload("res://assets/backgrounds/throne_room.png")
]
var bg_index: int = 0

var p1_wins: int = 0
var p2_wins: int = 0
var time_left: float = ROUND_TIME
var round_active: bool = false
var match_over: bool = false
var is_paused: bool = false
var shake: float = 0.0
var ko_active: bool = false


# Dipanggil SEBELUM _ready milik fighter: agar karakter sudah benar
# saat SpriteFrames dibangun.
func _enter_tree() -> void:
	$Fighter.set("character_id", GameState.p1_character)
	$Fighter2.set("character_id", GameState.p2_character)


func _ready() -> void:
	_setup_controllers()
	_setup_bar(fighter_1, p1_bar)
	_setup_bar(fighter_2, p2_bar)
	fighter_1.died.connect(_on_fighter_died.bind(fighter_1))
	fighter_2.died.connect(_on_fighter_died.bind(fighter_2))
	fighter_1.got_hit.connect(_on_fighter_got_hit.bind(fighter_1))
	fighter_2.got_hit.connect(_on_fighter_got_hit.bind(fighter_2))
	fighter_1.did_block.connect(_on_fighter_blocked.bind(fighter_1))
	fighter_2.did_block.connect(_on_fighter_blocked.bind(fighter_2))

	p1_name.text = "%s · %s" % [GameState.p1_label(), GameState.p1_character.to_upper()]
	p2_name.text = "%s · %s" % [GameState.p2_label(), GameState.p2_character.to_upper()]
	_reset_win_boxes()
	_update_timer_label()

	# Tombol-tombol pause & game over
	$OverlayLayer/PauseMenu/Center/Panel/VBox/BtnResume.pressed.connect(_toggle_pause)
	$OverlayLayer/PauseMenu/Center/Panel/VBox/BtnRestart.pressed.connect(_on_restart)
	$OverlayLayer/PauseMenu/Center/Panel/VBox/BtnMenu.pressed.connect(_on_quit_to_menu)
	$OverlayLayer/GameOverMenu/Center/Panel/VBox/BtnRematch.pressed.connect(_on_restart)
	$OverlayLayer/GameOverMenu/Center/Panel/VBox/BtnGoMenu.pressed.connect(_on_quit_to_menu)

	Audio.play_music("bgm_battle")
	_set_background()
	_start_countdown()


func _setup_controllers() -> void:
	if GameState.mode == GameState.MODE_VERSUS:
		var ai := fighter_2.get_node_or_null("AIController")
		if ai:
			ai.queue_free()
		var hc: Node = HumanControllerScript.new()
		hc.set("input_prefix", "p2")
		hc.name = "HumanController"
		fighter_2.add_child(hc)
	else:
		var ai2 := fighter_2.get_node_or_null("AIController")
		if ai2:
			GameState.apply_difficulty(ai2)


func _process(delta: float) -> void:
	# Timer ronde
	if round_active and not is_paused and not match_over:
		time_left -= delta
		_update_timer_label()
		if time_left <= 0.0:
			_on_timeout()
	# Screen shake
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 2.5)
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * 22.0
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not match_over and round_active:
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if match_over and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_on_restart()
		elif event.keycode == KEY_M:
			_on_quit_to_menu()


func _update_timer_label() -> void:
	timer_label.text = str(int(ceil(maxf(time_left, 0.0))))


func _set_background() -> void:
	if list_background.size() > 0 and background:
		background.texture = list_background[bg_index]


func _start_countdown() -> void:
	round_active = false
	time_left = ROUND_TIME
	_update_timer_label()
	fighter_1.can_fight = false
	fighter_2.can_fight = false

	if countdown_label:
		countdown_label.visible = true
		countdown_label.add_theme_font_size_override("font_size", 100)
		countdown_label.add_theme_color_override("font_color", Color.YELLOW)

	countdown_label.text = "3"
	Audio.play_sfx("countdown", -4.0)
	await get_tree().create_timer(1.0).timeout

	countdown_label.text = "2"
	Audio.play_sfx("countdown", -4.0)
	await get_tree().create_timer(1.0).timeout

	countdown_label.text = "1"
	Audio.play_sfx("countdown", -4.0)
	await get_tree().create_timer(1.0).timeout

	countdown_label.text = "READY"
	await get_tree().create_timer(0.8).timeout

	countdown_label.text = "SET"
	await get_tree().create_timer(0.8).timeout

	countdown_label.text = "FIGHT!"
	Audio.play_sfx("bell", -2.0)
	await get_tree().create_timer(1.0).timeout

	if countdown_label:
		countdown_label.visible = false

	fighter_1.start_fighting()
	fighter_2.start_fighting()
	round_active = true


func _on_fighter_died(fighter) -> void:
	if match_over or not round_active:
		return
	round_active = false
	# Efek K.O.: slow motion + tulisan besar
	ko_active = true
	ko_label.visible = true
	Audio.play_sfx("ko")
	Engine.time_scale = 0.25
	await get_tree().create_timer(1.4, true, false, true).timeout
	Engine.time_scale = 1.0
	ko_label.visible = false
	ko_active = false
	_resolve_round(fighter == fighter_2, "K.O.!")


func _on_timeout() -> void:
	if match_over or not round_active:
		return
	round_active = false
	var h1: int = fighter_1.health
	var h2: int = fighter_2.health
	if h1 == h2:
		countdown_label.visible = true
		countdown_label.add_theme_font_size_override("font_size", 80)
		countdown_label.add_theme_color_override("font_color", Color.YELLOW)
		countdown_label.text = "SERI! RONDE DIULANG"
		Audio.play_sfx("bell", -4.0)
		await get_tree().create_timer(2.0).timeout
		countdown_label.visible = false
		_start_next_round()
	else:
		_resolve_round(h1 > h2, "WAKTU HABIS!")


func _resolve_round(p1_won: bool, reason: String) -> void:
	countdown_label.visible = true
	countdown_label.add_theme_font_size_override("font_size", 80)

	if p1_won:
		p1_wins += 1
		_light_up_box(p1_wins, [p1_win_1, p1_win_2])
		countdown_label.text = reason + "\n" + GameState.p1_label() + " MENANG RONDE!"
		countdown_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		p2_wins += 1
		_light_up_box(p2_wins, [p2_win_1, p2_win_2])
		countdown_label.text = reason + "\n" + GameState.p2_label() + " MENANG RONDE!"
		countdown_label.add_theme_color_override("font_color", Color.RED)

	Audio.play_sfx("round_win", -4.0)

	# Ganti background untuk ronde berikutnya
	bg_index += 1
	if bg_index >= list_background.size():
		bg_index = 0
	_set_background()

	await get_tree().create_timer(2.5).timeout
	countdown_label.visible = false

	if p1_wins >= WINS_REQUIRED:
		_show_game_over(true)
	elif p2_wins >= WINS_REQUIRED:
		_show_game_over(false)
	else:
		_start_next_round()


func _show_game_over(p1_won: bool) -> void:
	match_over = true
	Engine.time_scale = 1.0
	winner_label.text = GameState.winner_text(p1_won)
	winner_label.add_theme_color_override(
		"font_color", Color.GREEN if p1_won else Color.RED)
	gameover_menu.visible = true


func _start_next_round() -> void:
	fighter_1.reset_for_next_round()
	fighter_2.reset_for_next_round()
	_start_countdown()


func _reset_win_boxes() -> void:
	for box in [p1_win_1, p1_win_2, p2_win_1, p2_win_2]:
		if box:
			box.color = Color(0.25, 0.25, 0.25, 1)


func _light_up_box(wins: int, boxes: Array) -> void:
	for i in range(wins):
		if i < boxes.size() and boxes[i] != null:
			boxes[i].color = Color(1.0, 0.8, 0.0) # Kuning Emas


func _setup_bar(fighter, bar: ProgressBar) -> void:
	bar.max_value = fighter.max_health
	bar.value = fighter.health
	fighter.health_changed.connect(func(current: int, maximum: int) -> void:
		bar.max_value = maximum
		bar.value = current)


# ---------- Efek (juice) ----------

func _on_fighter_got_hit(_amount: int, fighter) -> void:
	_spawn_hit_particles(fighter.global_position + Vector2(0, -110), false)
	_add_shake(0.45)
	_hit_stop()


func _on_fighter_blocked(fighter) -> void:
	_spawn_hit_particles(fighter.global_position + Vector2(0, -110), true)
	_add_shake(0.2)


func _add_shake(amount: float) -> void:
	shake = minf(1.0, shake + amount)


func _hit_stop() -> void:
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.05, true, false, true).timeout
	if not is_paused and not match_over and not ko_active:
		Engine.time_scale = 1.0


func _spawn_hit_particles(pos: Vector2, blocked: bool) -> void:
	var p := CPUParticles2D.new()
	p.amount = 14
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 12.0
	p.direction = Vector2(0, -1)
	p.spread = 65.0
	p.initial_velocity_min = 250.0
	p.initial_velocity_max = 550.0
	p.gravity = Vector2(0, 900)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = Color(1.0, 0.85, 0.3) if not blocked else Color(0.55, 0.8, 1.0)
	p.position = pos
	p.z_index = 50
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


# ---------- Pause & navigasi ----------

func _toggle_pause() -> void:
	if match_over:
		return
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused
	Audio.play_sfx("ui_click", -6.0)


func _on_restart() -> void:
	Audio.play_sfx("ui_click", -6.0)
	is_paused = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _on_quit_to_menu() -> void:
	Audio.play_sfx("ui_click", -6.0)
	is_paused = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
