extends Control


func _ready() -> void:
	$Center/VBox/BtnBack.pressed.connect(_on_back)


func _on_back() -> void:
	Audio.play_sfx("ui_click", -6.0)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
