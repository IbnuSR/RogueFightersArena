extends Control
## Menu utama: pilih mode, kesulitan AI, dan karakter.

const GOLD := Color(1.0, 0.84, 0.2)
const DIM := Color(0.7, 0.7, 0.7)

@onready var btn_1p: Button = $Center/VBox/ModeRow/Btn1P
@onready var btn_2p: Button = $Center/VBox/ModeRow/Btn2P
@onready var mode_row: HBoxContainer = $Center/VBox/ModeRow
@onready var diff_row: HBoxContainer = $Center/VBox/DiffRow
@onready var btn_easy: Button = $Center/VBox/DiffRow/BtnEasy
@onready var btn_normal: Button = $Center/VBox/DiffRow/BtnNormal
@onready var btn_hard: Button = $Center/VBox/DiffRow/BtnHard
# Daftar karakter: [id, label]. Urutan = urutan tombol di grid.
const CHAR_LIST := [
	["samurai", "SAMURAI"], ["shinobi", "SHINOBI"], ["arga", "ARGA"],
	["marco", "MARCO"], ["dmitri", "DMITRI"], ["lin", "LIN"],
	["nok", "NOK"], ["sora", "SORA"], ["tyrone", "TYRONE"],
	["han", "HAN"], ["valeria", "VALERIA"], ["anika", "ANIKA"],
]

@onready var p2_row: HBoxContainer = $Center/VBox/P2Row
@onready var p1_grid: GridContainer = $Center/VBox/P1Row/P1Grid
@onready var p2_grid: GridContainer = $Center/VBox/P2Row/P2Grid
@onready var btn_start: Button = $Center/VBox/BtnStart
@onready var btn_how: Button = $Center/VBox/BtnHow
@onready var btn_quit: Button = $Center/VBox/BtnQuit
var p1_buttons: Dictionary = {}
var p2_buttons: Dictionary = {}


func _ready() -> void:
	Audio.play_music("bgm_menu")
	# Mode 1 player saja untuk sekarang (versus disembunyikan).
	GameState.mode = GameState.MODE_ARCADE
	btn_1p.visible = false
	btn_2p.visible = false
	if mode_row:
		mode_row.visible = false
	btn_easy.pressed.connect(_on_difficulty.bind(0))
	btn_normal.pressed.connect(_on_difficulty.bind(1))
	btn_hard.pressed.connect(_on_difficulty.bind(2))
	_build_char_buttons()
	btn_start.pressed.connect(_on_start)
	btn_how.pressed.connect(_on_how)
	btn_quit.pressed.connect(_on_quit)
	_refresh()


func _build_char_buttons() -> void:
	for entry in CHAR_LIST:
		var char_id: String = entry[0]
		var b1 := Button.new()
		b1.custom_minimum_size = Vector2(104, 40)
		b1.add_theme_font_size_override("font_size", 16)
		b1.text = entry[1]
		b1.pressed.connect(_on_p1_char.bind(char_id))
		p1_grid.add_child(b1)
		p1_buttons[char_id] = b1
		var b2 := Button.new()
		b2.custom_minimum_size = Vector2(104, 40)
		b2.add_theme_font_size_override("font_size", 16)
		b2.text = entry[1]
		b2.pressed.connect(_on_p2_char.bind(char_id))
		p2_grid.add_child(b2)
		p2_buttons[char_id] = b2


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
	for char_id in p1_buttons:
		_mark(p1_buttons[char_id], GameState.p1_character == char_id)
	for char_id in p2_buttons:
		_mark(p2_buttons[char_id], GameState.p2_character == char_id)
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
