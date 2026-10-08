extends Node

# Pastikan nama aksi di Project Settings -> Input Map sesuai dengan prefix ini
@export var input_prefix: String = "p1" 

func _process(delta: float) -> void:
	var fighter = get_parent()
	if not fighter: return

	# Gerakan & Block (Ditekan terus-menerus / Pressed)
	fighter.input_state["left"] = Input.is_action_pressed(input_prefix + "_left")
	fighter.input_state["right"] = Input.is_action_pressed(input_prefix + "_right")
	fighter.input_state["block"] = Input.is_action_pressed(input_prefix + "_block")
	
	# Lompat & Serangan (Hanya sekali tekan / Just Pressed)
	fighter.input_state["jump"] = Input.is_action_just_pressed(input_prefix + "_jump")
	fighter.input_state["attack_1"] = Input.is_action_just_pressed(input_prefix + "_attack_1")
	fighter.input_state["attack_2"] = Input.is_action_just_pressed(input_prefix + "_attack_2")
	fighter.input_state["attack_3"] = Input.is_action_just_pressed(input_prefix + "_attack_3")
