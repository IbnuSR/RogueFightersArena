extends Control

@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("SplashIntro")

	await animation_player.animation_finished

	get_tree().change_scene_to_file(
        "res://scenes/menu.tscn"
	)
