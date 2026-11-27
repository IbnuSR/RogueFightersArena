
extends Control

@onready var stage1 = $Stage1

func _ready():
	stage1.pressed.connect(_on_stage1_pressed)


func _on_stage1_pressed():
	get_tree().change_scene_to_file("res://ui/character_select/character_select.tscn")
