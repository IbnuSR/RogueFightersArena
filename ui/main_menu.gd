extends Control

const CHARACTER_SELECT := "res://ui/character_select/character_select.tscn"
const CHAPTER_MAP := "res://ui/chapter_map/chapter_map.tscn"
const SETTINGS := "res://ui/settings/settings.tscn"

@onready var continue_button: BaseButton = %ContinueButton
@onready var story_button: BaseButton = %StoryButton
@onready var free_fight_button: BaseButton = %FreeFightButton
@onready var settings_button: BaseButton = %SettingsButton
@onready var quit_button: BaseButton = %QuitButton
@onready var toast_label: Label = %ToastLabel

var _toast_tween: Tween


func _ready() -> void:
	toast_label.modulate.a = 0.0

	# Tombol Lanjutkan hanya muncul kalau sudah ada progres tersimpan
	var progress := get_node_or_null("/root/ProgressManager")
	continue_button.visible = progress != null and progress.highest_chapter > 0
	quit_button.visible = not OS.has_feature("web")

	continue_button.pressed.connect(_on_continue_pressed)
	story_button.pressed.connect(_on_story_pressed)
	free_fight_button.pressed.connect(_on_free_fight_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_continue_pressed() -> void:
	GameSession.mode = GameSession.Mode.STORY
	_go(CHAPTER_MAP)


func _on_story_pressed() -> void:
	GameSession.reset()
	GameSession.mode = GameSession.Mode.STORY
	_go(CHARACTER_SELECT)


func _on_free_fight_pressed() -> void:
	GameSession.reset()
	GameSession.mode = GameSession.Mode.FREE_FIGHT
	_go(CHARACTER_SELECT)


func _on_settings_pressed() -> void:
	_go(SETTINGS)


func _on_quit_pressed() -> void:
	SceneManager.quit_game()


func _go(path: String) -> void:
	if ResourceLoader.exists(path):
		SceneManager.change_scene(path)
	else:
		_show_toast("Layar ini belum dibuat")


func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.2)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.4)
