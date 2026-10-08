extends Node2D

@onready var fighter_1 = $Fighter
@onready var fighter_2 = $Fighter2
@onready var p1_bar: ProgressBar = $HUD/P1Bar
@onready var p2_bar: ProgressBar = $HUD/P2Bar
@onready var countdown_label: Label = $CanvasLayer/CountdownLabel
@onready var background: Sprite2D = $Background

# Referensi ke Kotak Kemenangan (Win Boxes)
@onready var p1_win_1: ColorRect = $HUD/P1Win1
@onready var p1_win_2: ColorRect = $HUD/P1Win2
@onready var p2_win_1: ColorRect = $HUD/P2Win1
@onready var p2_win_2: ColorRect = $HUD/P2Win2

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
const WINS_REQUIRED: int = 2

func _ready() -> void:
	_setup_bar(fighter_1, p1_bar)
	_setup_bar(fighter_2, p2_bar)
	fighter_1.died.connect(_on_fighter_died.bind(fighter_1))
	fighter_2.died.connect(_on_fighter_died.bind(fighter_2))
	
	_set_background() # Set background awal
	_start_countdown()

func _set_background():
	if list_background.size() > 0 and background:
		background.texture = list_background[bg_index]

func _start_countdown():
	fighter_1.can_fight = false
	fighter_2.can_fight = false
	
	if countdown_label:
		countdown_label.visible = true
		countdown_label.add_theme_font_size_override("font_size", 100)
		countdown_label.add_theme_color_override("font_color", Color.YELLOW)

	countdown_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "READY"
	await get_tree().create_timer(0.8).timeout
	
	countdown_label.text = "SET"
	await get_tree().create_timer(0.8).timeout
	
	countdown_label.text = "FIGHT!"
	await get_tree().create_timer(1.0).timeout
	
	if countdown_label:
		countdown_label.visible = false
		
	fighter_1.start_fighting()
	fighter_2.start_fighting()

func _on_fighter_died(fighter) -> void:
	countdown_label.visible = true
	countdown_label.add_theme_font_size_override("font_size", 80)
	
	if fighter == fighter_2:
		p1_wins += 1
		_light_up_box(p1_wins, [p1_win_1, p1_win_2])
		countdown_label.text = "YOU WIN ROUND!"
		countdown_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		p2_wins += 1
		_light_up_box(p2_wins, [p2_win_1, p2_win_2])
		countdown_label.text = "ENEMY WINS ROUND!"
		countdown_label.add_theme_color_override("font_color", Color.RED)

	# Ganti background untuk ronde berikutnya
	bg_index += 1
	if bg_index >= list_background.size():
		bg_index = 0 # Loop kembali ke awal
	_set_background()

	await get_tree().create_timer(2.5).timeout

	if p1_wins >= WINS_REQUIRED:
		countdown_label.text = "YOU WIN!"
		countdown_label.add_theme_font_size_override("font_size", 120)
		await get_tree().create_timer(3.0).timeout
		get_tree().reload_current_scene()
	elif p2_wins >= WINS_REQUIRED:
		countdown_label.text = "ENEMY WIN!"
		countdown_label.add_theme_font_size_override("font_size", 120)
		await get_tree().create_timer(3.0).timeout
		get_tree().reload_current_scene()
	else:
		_start_next_round()

func _start_next_round():
	fighter_1.reset_for_next_round()
	fighter_2.reset_for_next_round()
	_start_countdown()

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
