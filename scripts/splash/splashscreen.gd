
extends Control

const NEXT_SCENE := "res://scenes/main_menu/menu.tscn"

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
var _is_skipped: bool = false

func _ready() -> void:
	# Menyesuaikan video dengan ukuran layar
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.loop = false
	video_player.play()
	video_player.finished.connect(_go_to_menu)

	# Label petunjuk lewati di pojok kanan bawah
	var hint := Label.new()
	hint.text = "Tekan Enter untuk Lewati"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left = -280
	hint.offset_top = -45
	hint.offset_right = -20
	hint.offset_bottom = -15
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	hint.add_theme_constant_override("outline_size", 4)
	add_child(hint)

func _input(event: InputEvent) -> void:
	if _is_skipped:
		return

	# Tombol Enter, Numpad Enter, Space, Escape, atau aksi ui_accept
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE:
			_skip()
			return

	if event.is_action_pressed("ui_accept"):
		_skip()
		return

	# Klik mouse kiri
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_skip()
		return

func _skip() -> void:
	_go_to_menu()

func _go_to_menu() -> void:
	if _is_skipped:
		return
	_is_skipped = true
	if video_player != null and video_player.is_playing():
		video_player.stop()
	if has_node("/root/SceneManager"):
		get_node("/root/SceneManager").change_scene(NEXT_SCENE)
	else:
		get_tree().change_scene_to_file(NEXT_SCENE)
