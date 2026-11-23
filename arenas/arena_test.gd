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
@onready var btn_rematch: Button = $OverlayLayer/GameOverMenu/Center/Panel/VBox/BtnRematch
@onready var btn_go_menu: Button = $OverlayLayer/GameOverMenu/Center/Panel/VBox/BtnGoMenu

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
# Story Mode: stage yang sedang dimainkan & apakah banner FASE 2 sudah tampil.
var _phase2_shown: bool = false
var _stage_label: Label
var _story_chapter_done: bool = false


# ---------- Story Mode ----------

func _is_story() -> bool:
	return GameSession.mode == GameSession.Mode.STORY


func _story_chapter():
	if GameSession.chapter_id == "":
		return null
	return load("res://data/chapters/%s.tres" % GameSession.chapter_id)


func _story_opponent_id() -> String:
	var chapter = _story_chapter()
	if chapter == null:
		return GameState.p2_character
	var stages: Array = chapter.get("stages")
	if GameSession.stage_index < stages.size():
		return String(stages[GameSession.stage_index])
	return String(chapter.get("boss_id"))


func _story_is_boss_stage() -> bool:
	var chapter = _story_chapter()
	if chapter == null:
		return false
	var stages: Array = chapter.get("stages")
	return GameSession.stage_index >= stages.size()


func _story_wins_required() -> int:
	# Story Mode: musuh biasa 1 ronde, boss 1 pertarungan (2 fase).
	return 1 if _is_story() else WINS_REQUIRED


func _apply_boss_ai() -> void:
	# Pola khas boss (charge/hitrun/counter) dari trait_id di .tres-nya.
	# Sebelumnya tidak ada yang menyetel boss_pattern, jadi pola boss
	# tidak pernah aktif — sekarang disetel di sini tiap lawan berubah.
	var ai = fighter_2.get_node_or_null("AIController")
	if ai == null:
		return
	var pattern := ""
	var cd = null
	var path := "res://data/characters/%s.tres" % GameState.p2_character
	if ResourceLoader.exists(path):
		cd = load(path)
	if cd != null:
		match String(cd.get("trait_id")):
			"boss_charge":
				pattern = "charge"
			"boss_hitrun":
				pattern = "hitrun"
			"boss_counter":
				pattern = "counter"
			"boss_voss":
				# Voss menggabungkan jurus 3 boss: fase 1 charge (Brak);
				# fase 2 (di _process) ganti hit & run (Ular) + sering
				# menangkis (Guru).
				pattern = "charge"
	ai.set("boss_pattern", pattern)
	ai.set("phase2", false)
	_phase2_shown = false


# Dipanggil SEBELUM _ready milik fighter: agar karakter sudah benar
# saat SpriteFrames dibangun.
func _enter_tree() -> void:
	if _is_story():
		if GameSession.player_id != "":
			GameState.p1_character = GameSession.player_id
		GameState.p2_character = _story_opponent_id()
		# Latar chapter mengikuti chapter_id; tapi jangan menimpa arena_id
		# yang sudah diisi langsung (mis. oleh tes chapter_bg).
		if GameSession.chapter_id != "":
			GameSession.arena_id = GameSession.chapter_id
	else:
		if GameSession.player_id != "":
			GameState.p1_character = GameSession.player_id
		if GameSession.opponent_id != "":
			GameState.p2_character = GameSession.opponent_id
	$Fighter.character_id = GameState.p1_character
	$Fighter2.character_id = GameState.p2_character


func _ready() -> void:
	fighter_1.set_character(GameState.p1_character)
	fighter_2.set_character(GameState.p2_character)
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

	# Kontrol sentuh (TouchScreenButton) hanya diaktifkan jika di platform mobile / web sentuh
	# Di laptop/PC dinonaktifkan agar tidak menutupi layar dan menggunakan keyboard
	if OS.has_feature("mobile") and ResourceLoader.exists("res://ui/touch_controls/touch_controls.tscn"):
		var tc_scene = load("res://ui/touch_controls/touch_controls.tscn")
		if tc_scene:
			var tc = tc_scene.instantiate()
			add_child(tc)

	if _is_story():
		# Story Mode 1 ronde: kotak kemenangan Best-of-3 disembunyikan,
		# diganti label chapter & stage.
		for box in [p1_win_1, p1_win_2, p2_win_1, p2_win_2]:
			if box:
				box.visible = false
		_stage_label = Label.new()
		_stage_label.position = Vector2(490, 108)
		_stage_label.size = Vector2(300, 30)
		_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_stage_label.add_theme_font_size_override("font_size", 22)
		_stage_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
		$HUD.add_child(_stage_label)
		_update_stage_label()
	_apply_boss_ai()
	# Stage awal (termasuk Rematch di stage yang sama) juga kena
	# scaling +10% HP/stage — bukan cuma saat maju stage.
	_apply_stage_scaling()

	# Tombol-tombol pause & game over
	$OverlayLayer/PauseMenu/Center/Panel/VBox/BtnResume.pressed.connect(_toggle_pause)
	$OverlayLayer/PauseMenu/Center/Panel/VBox/BtnRestart.pressed.connect(_on_restart)
	$OverlayLayer/PauseMenu/Center/Panel/VBox/BtnMenu.pressed.connect(_on_quit_to_menu)
	$OverlayLayer/GameOverMenu/Center/Panel/VBox/BtnRematch.pressed.connect(_on_restart)
	$OverlayLayer/GameOverMenu/Center/Panel/VBox/BtnGoMenu.pressed.connect(_on_quit_to_menu)

	_play_battle_music()
	_set_background()
	_start_countdown()


func _play_battle_music() -> void:
	if _is_story():
		var chapter = _story_chapter()
		if chapter != null and "arena_bgm" in chapter and chapter.arena_bgm != "":
			Audio.play_music(chapter.arena_bgm)
			return
		if GameSession.chapter_id != "":
			Audio.play_chapter_music(GameSession.chapter_id)
			return
	elif GameSession.arena_id != "":
		Audio.play_chapter_music(GameSession.arena_id)
		return
	Audio.play_music("bgm_battle")


func _apply_stage_scaling() -> void:
	# Musuh biasa yang sama muncul 3x per chapter (GDD §4): stage makin
	# jauh makin kuat, +10% HP per stage. Boss tidak di-scale (stat boss
	# sudah tinggi). health_changed meng-update bar nyawa (max ikut naik).
	if not _is_story() or _story_is_boss_stage():
		return
	var scaled_hp := int(round(fighter_2.max_health * (1.0 + 0.1 * GameSession.stage_index)))
	fighter_2.max_health = scaled_hp
	fighter_2.health = scaled_hp
	fighter_2.health_changed.emit(scaled_hp, scaled_hp)


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


func _update_stage_label() -> void:
	if _stage_label == null:
		return
	var n: int = int(GameSession.chapter_id.trim_prefix("ch"))
	var stage_no: int = GameSession.stage_index + 1
	var boss: String = " · BOSS" if _story_is_boss_stage() else ""
	_stage_label.text = "CHAPTER %d · STAGE %d/4%s" % [n, stage_no, boss]


func _process(delta: float) -> void:
	# Boss Story Mode: HP <= 50% -> fase 2 (lebih agresif, banner FASE 2).
	if _is_story() and _story_is_boss_stage() and round_active and not _phase2_shown:
		var ai = fighter_2.get_node_or_null("AIController")
		if ai != null and fighter_2.health <= fighter_2.max_health / 2:
			ai.set("phase2", true)
			_phase2_shown = true
			# Voss fase 2: ganti pola charge -> hit & run (Ular) dan
			# jadi sering menangkis (Guru) — gabungan 3 jurus boss.
			if GameState.p2_character == "alaric_voss":
				ai.set("boss_pattern", "hitrun")
				ai.set("peluang_tangkis", 0.5)
			Audio.play_sfx("bell", -2.0)
			countdown_label.visible = true
			countdown_label.add_theme_font_size_override("font_size", 80)
			countdown_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
			countdown_label.text = "FASE 2!"
			await get_tree().create_timer(1.5).timeout
			if not match_over:
				countdown_label.visible = false
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
	# Story Mode: pakai background chapter (GameSession.arena_id = ch1/ch2/ch3,
	# path diambil dari data/chapters/<id>.tres -> arena_bg). Kalau tidak ada,
	# jatuh ke daftar lama yang berputar tiap ronde.
	if GameSession.arena_id != "":
		var chapter: ChapterData = load("res://data/chapters/%s.tres" % GameSession.arena_id)
		if chapter and chapter.arena_bg != "" and background:
			background.texture = load(chapter.arena_bg)
			return
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
		countdown_label.add_theme_font_size_override("font_size", 120)
		countdown_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2)) # Emas cerah
		countdown_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		countdown_label.add_theme_constant_override("outline_size", 22)

	var cur_round := p1_wins + p2_wins + 1
	if p1_wins == WINS_REQUIRED - 1 and p2_wins == WINS_REQUIRED - 1:
		countdown_label.text = "FINAL ROUND"
		Audio.play_sfx("final_round", -2.0)
	elif cur_round == 1:
		countdown_label.text = "ROUND 1"
		Audio.play_sfx("round_1", -2.0)
	elif cur_round == 2:
		countdown_label.text = "ROUND 2"
		Audio.play_sfx("round_2", -2.0)
	else:
		countdown_label.text = "ROUND %d" % cur_round
		Audio.play_sfx("round_3", -2.0)
	await get_tree().create_timer(1.1).timeout

	countdown_label.text = "READY"
	Audio.play_sfx("ready", -2.0)
	await get_tree().create_timer(0.8).timeout

	countdown_label.add_theme_font_size_override("font_size", 140)
	countdown_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.15)) # Oranye kemerahan menyala
	countdown_label.text = "FIGHT!"
	Audio.play_sfx("fight", -1.0)
	Audio.play_sfx("bell", -2.0)
	await get_tree().create_timer(0.8).timeout

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
	countdown_label.add_theme_font_size_override("font_size", 72)
	countdown_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	countdown_label.add_theme_constant_override("outline_size", 16)

	if p1_won:
		p1_wins += 1
		_light_up_box(p1_wins, [p1_win_1, p1_win_2])
		countdown_label.text = reason + "\n" + GameState.p1_label() + " MENANG RONDE!"
		countdown_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		p2_wins += 1
		_light_up_box(p2_wins, [p2_win_1, p2_win_2])
		countdown_label.text = reason + "\n" + GameState.p2_label() + " MENANG RONDE!"
		countdown_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	Audio.play_sfx("round_win", -4.0)

	# Ganti background untuk ronde berikutnya (Free Battle saja;
	# Story Mode memakai background chapter yang tetap, jangan diputar).
	if GameSession.mode != GameSession.Mode.STORY:
		bg_index += 1
		if bg_index >= list_background.size():
			bg_index = 0
	_set_background()

	await get_tree().create_timer(2.5).timeout
	countdown_label.visible = false

	if _is_story():
		if p1_won:
			_story_advance()
		else:
			_show_game_over(false)
		return

	if p1_wins >= WINS_REQUIRED:
		_show_game_over(true)
	elif p2_wins >= WINS_REQUIRED:
		_show_game_over(false)
	else:
		_start_next_round()


func _story_advance() -> void:
	# Buka kunci karakter yang baru dikalahkan (bisa dipakai di Free Fight).
	var pm = get_node_or_null("/root/ProgressManager")
	if pm != null:
		pm.unlock_char(GameState.p2_character)
	if _story_is_boss_stage():
		# Boss kalah = chapter selesai, chapter berikutnya terbuka.
		if pm != null:
			pm.complete_chapter(GameSession.chapter_id)
		_show_game_over(true, true)
		return
	GameSession.stage_index += 1
	_update_stage_label()
	countdown_label.visible = true
	countdown_label.add_theme_font_size_override("font_size", 80)
	countdown_label.add_theme_color_override("font_color", Color.GREEN)
	countdown_label.text = "STAGE SELESAI!"
	Audio.play_sfx("round_win", -4.0)
	await get_tree().create_timer(2.0).timeout
	countdown_label.visible = false
	_start_next_stage()


func _start_next_stage() -> void:
	p1_wins = 0
	p2_wins = 0
	GameState.p2_character = _story_opponent_id()
	fighter_2.set_character(GameState.p2_character)
	fighter_2.reset_for_next_round()
	# Musuh biasa yang sama muncul 3x per chapter (GDD §4: tiap chapter
	# cuma 1-2 tipe musuh biasa): stage makin jauh makin kuat, +10% HP
	# per stage, supaya stage 2-3 tidak terasa pengulangan yang sama.
	_apply_stage_scaling()
	fighter_1.reset_for_next_round()
	p2_name.text = "%s · %s" % [GameState.p2_label(), GameState.p2_character.to_upper()]
	_apply_boss_ai()
	_update_stage_label()
	_start_countdown()


func _show_game_over(p1_won: bool, chapter_complete: bool = false) -> void:
	match_over = true
	Engine.time_scale = 1.0
	if p1_won or chapter_complete:
		Audio.play_sfx("you_win", -1.0)
	else:
		Audio.play_sfx("you_lose", -1.0)
	if chapter_complete:
		_story_chapter_done = true
		var n: int = int(GameSession.chapter_id.trim_prefix("ch"))
		winner_label.text = "CHAPTER %d SELESAI!" % n
		winner_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
		btn_go_menu.text = "PETA CHAPTER (M)"
	else:
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
	if _story_chapter_done:
		get_tree().change_scene_to_file("res://ui/chapter_map/chapter_map.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
