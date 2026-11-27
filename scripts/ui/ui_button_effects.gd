class_name UIButtonEffects
extends RefCounted

static func apply(button: BaseButton, hover_scale := 1.06, click_scale := 0.92) -> void:
	if button == null or button.disabled:
		return
	button.pivot_offset = button.size / 2.0
	button.mouse_entered.connect(_on_mouse_entered.bind(button, hover_scale))
	button.mouse_exited.connect(_on_mouse_exited.bind(button))
	button.button_down.connect(_on_button_down.bind(button, click_scale))
	button.button_up.connect(_on_button_up.bind(button))

static func _on_mouse_entered(button: BaseButton, hover_scale: float) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	_tween(button, Vector2.ONE * hover_scale, Color(1.08, 1.08, 1.08, 1.0), 0.14)
	if Audio != null:
		Audio.play_sfx("ui_hover", -10.0)

static func _on_mouse_exited(button: BaseButton) -> void:
	if is_instance_valid(button):
		_tween(button, Vector2.ONE, Color.WHITE, 0.14)

static func _on_button_down(button: BaseButton, click_scale: float) -> void:
	if is_instance_valid(button):
		_tween(button, Vector2.ONE * click_scale, Color(1.0, 0.88, 0.55, 1.0), 0.08)

static func _on_button_up(button: BaseButton) -> void:
	if is_instance_valid(button) and not button.disabled:
		_tween(button, Vector2.ONE * 1.04, Color.WHITE, 0.10)

static func _tween(button: BaseButton, target_scale: Vector2, target_modulate: Color, duration: float) -> void:
	var tween := button.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(button, "scale", target_scale, duration)
	tween.parallel().tween_property(button, "self_modulate", target_modulate, duration)
