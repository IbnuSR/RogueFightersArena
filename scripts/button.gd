extends Control

const CHARACTER_SELECT := "res://ui/character_select/character_select.tscn"
const CHAPTER_MAP := "res://ui/chapter_map/chapter_map.tscn"
const SETTINGS := "res://ui/settings/settings.tscn"

@onready var story_btn: TextureButton = $Button/storymode
@onready var free_btn: TextureButton = $Button/freebattle
@onready var char_btn: TextureButton = $Button/character
@onready var settings_btn: TextureButton = $Button/settings
@onready var exit_btn: TextureButton = $Button/exit

func _ready() -> void:
	exit_btn.visible = not OS.has_feature("web")
	
	story_btn.pressed.connect(_on_story_pressed)
	free_btn.pressed.connect(_on_freebattle_pressed)
	char_btn.pressed.connect(_on_character_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

func _on_story_pressed() -> void:
	if has_node("/root/GameSession"):
		GameSession.reset()
		GameSession.mode = GameSession.Mode.STORY
	_go(CHAPTER_MAP)

func _on_freebattle_pressed() -> void:
	if has_node("/root/GameSession"):
		GameSession.reset()
		GameSession.mode = GameSession.Mode.FREE_FIGHT
	_go(CHARACTER_SELECT)

func _on_character_pressed() -> void:
	if has_node("/root/GameSession"):
		GameSession.reset()
		GameSession.mode = GameSession.Mode.FREE_FIGHT
	_go(CHARACTER_SELECT)

func _on_settings_pressed() -> void:
	_go(SETTINGS)

func _on_exit_pressed() -> void:
	if has_node("/root/SceneManager"):
		SceneManager.quit_game()
	else:
		get_tree().quit()

func _go(path: String) -> void:
	if ResourceLoader.exists(path):
		if has_node("/root/SceneManager"):
			SceneManager.change_scene(path)
		else:
			get_tree().change_scene_to_file(path)
	else:
		print("Scene belum ada: ", path)
