extends Control
## Menu utama: pilih mode, kesulitan AI, dan karakter.

const GOLD := Color(1.0, 0.84, 0.2)
const DIM := Color(0.7, 0.7, 0.7)

@onready var btn_1p: Button = $Center/VBox/ModeRow/Btn1P
@onready var btn_2p: Button = $Center/VBox/ModeRow/Btn2P
@onready var diff_row: HBoxContainer = $Center/VBox/DiffRow
@onready var btn_easy: Button = $Center/VBox/DiffRow/BtnEasy
@onready var btn_normal: Button = $Center/VBox/DiffRow/BtnNormal
@onready var btn_hard: Button = $Center/VBox/DiffRow/BtnHard
@onready var p2_row: HBoxContainer = $Center/VBox/P2Row
@onready var btn_p1_sam: Button = $Center/VBox/P1Row/BtnP1Sam
@onready var btn_p1_shi: Button = $Center/VBox/P1Row/BtnP1Shi
@onready var btn_p2_sam: Button = $Center/VBox/P2Row/BtnP2Sam
@onready var btn_p2_shi: Button = $Center/VBox/P2Row/BtnP2Shi
@onready var btn_start: Button = $Center/VBox/BtnStart
@onready var btn_how: Button = $Center/VBox/BtnHow
@onready var btn_quit: Button = $Center/VBox/BtnQuit


func _ready() -> void:
	Audio.play_music("bgm_menu")
	btn_1p.pressed.connect(_on_mode.bind(GameState.MODE_ARCADE))
	btn_2p.pressed.connect(_on_mode.bind(GameState.MODE_VERSUS))
	btn_easy.pressed.connect(_on_difficulty.bind(0))
	btn_normal.pressed.connect(_on_difficulty.bind(1))
	btn_hard.pressed.connect(_on_difficulty.bind(2))
	btn_p1_sam.pressed.connect(_on_p1_char.bind("samurai"))
	btn_p1_shi.pressed.connect(_on_p1_char.bind("shinobi"))
	btn_p2_sam.pressed.connect(_on_p2_char.bind("samurai"))
	btn_p2_shi.pressed.connect(_on_p2_char.bind("shinobi"))
	btn_start.pressed.connect(_on_start)
	btn_how.pressed.connect(_on_how)
	btn_quit.pressed.connect(_on_quit)
	_refresh()


func _click() -> void:
	Audio.play_sfx("ui_click", -6.0)


func _on_mode(mode: String) -> void:
	GameState.mode = mode
	_click()
	_refresh()


func _on_difficulty(level: int) -> void:
	GameState.difficulty = level
	_click()
	_refresh()


func _on_p1_char(char_id: String) -> void:
	GameState.p1_character = char_id
	_click()
	_refresh()


func _on_p2_char(char_id: String) -> void:
	GameState.p2_character = char_id
	_click()
	_refresh()


func _mark(btn: Button, selected: bool) -> void:
	btn.modulate = GOLD if selected else DIM


func _refresh() -> void:
	var versus: bool = GameState.mode == GameState.MODE_VERSUS
	_mark(btn_1p, not versus)
	_mark(btn_2p, versus)
	_mark(btn_easy, GameState.difficulty == 0)
	_mark(btn_normal, GameState.difficulty == 1)
	_mark(btn_hard, GameState.difficulty == 2)
	_mark(btn_p1_sam, GameState.p1_character == "samurai")
	_mark(btn_p1_shi, GameState.p1_character == "shinobi")
	_mark(btn_p2_sam, GameState.p2_character == "samurai")
	_mark(btn_p2_shi, GameState.p2_character == "shinobi")
	# Kesulitan AI hanya relevan di mode 1 player
	diff_row.visible = not versus
	p2_row.visible = versus


func _on_start() -> void:
	_click()
	get_tree().change_scene_to_file("res://arenas/arena_test.tscn")


func _on_how() -> void:
	_click()
	get_tree().change_scene_to_file("res://scenes/how_to_play.tscn")


func _on_quit() -> void:
	_click()
	get_tree().quit()
