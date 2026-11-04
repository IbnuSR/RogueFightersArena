extends CanvasLayer

signal transition_started
signal transition_finished

const FADE_TIME := 0.25

var _fade_rect: ColorRect
var _busy := false
var _history: Array[String] = []


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	add_child(_fade_rect)


func change_scene(path: String, remember_current: bool = true) -> void:
	if _busy:
		return
	if not ResourceLoader.exists(path):
		push_warning("Scene belum ada: " + path)
		return
	_busy = true
	transition_started.emit()
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0)

	if remember_current and get_tree().current_scene != null:
		var current := get_tree().current_scene.scene_file_path
		if current != "":
			_history.append(current)

	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Gagal pindah ke %s (kode %d)" % [path, err])

	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false
	transition_finished.emit()


func go_back(fallback: String = "") -> void:
	if _history.is_empty():
		if fallback != "":
			change_scene(fallback, false)
		return
	var previous: String = _history.pop_back()
	change_scene(previous, false)


func quit_game() -> void:
	await _fade_to(1.0)
	get_tree().quit()


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, FADE_TIME)
	await tween.finished
