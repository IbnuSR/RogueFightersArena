
extends Control

@onready var stages: Array[TextureButton] = [$Stage1, $Stage2, $Stage3, $Stage4]
@onready var back_button: TextureButton = $Kembali

var _stage_transitioning := false

func _ready() -> void:
	# Hentikan musik Main Menu saat berada di layar pilih stage.
	Audio.stop_music()
	GameSession.mode = GameSession.Mode.STORY
	UIButtonEffects.apply(back_button)
	back_button.pressed.connect(_on_back_pressed)
	for i in range(stages.size()):
		var stage := stages[i]
		stage.pressed.connect(_on_stage_pressed.bind(i))
		var unlocked := _stage_unlocked(i)
		_apply_stage_texture(i, unlocked)
		stage.disabled = not unlocked
		stage.self_modulate = Color.WHITE if unlocked else Color(0.45, 0.45, 0.45, 1.0)
		if unlocked:
			UIButtonEffects.apply(stage)
			_start_stage_float(stage, i)

func _start_stage_float(stage: TextureButton, index: int) -> void:
	var base_position := stage.position
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(stage, "position", base_position + Vector2(0, -5), 1.2 + index * 0.08)
	tween.tween_property(stage, "position", base_position, 1.2 + index * 0.08)


func _apply_stage_texture(index: int, unlocked: bool) -> void:
	if index == 0:
		return
	var stage := stages[index]
	var texture: Texture2D
	if index == 1:
		texture = load("res://assets/image/chapter1/stage 2 pelabuhan tua buka.png") if unlocked else load("res://assets/image/chapter1/stage 2 pelabuhan tua.png")
	elif index == 2:
		texture = load("res://assets/image/chapter1/stage 3 kapal perang buka.png") if unlocked else load("res://assets/image/chapter1/stage 3 kapal perang.png")
	else:
		texture = load("res://assets/image/chapter1/stage 4 gudang laut buka.png") if unlocked else load("res://assets/image/chapter1/stage 4 gudang laut.png")
	stage.texture_normal = texture
	stage.texture_hover = texture
	stage.texture_pressed = texture
	stage.texture_disabled = texture

func _stage_unlocked(index: int) -> bool:
	var pm = get_node_or_null("/root/ProgressManager")
	if pm == null:
		return index == 0
	var chapter_number := ProgressManager.get_chapter_number(GameSession.chapter_id)
	if chapter_number < 1:
		chapter_number = 1
	# Stage 1 terbuka dari awal. Stage berikutnya terbuka setelah
	# stage tepat sebelumnya selesai: index 1 mengecek stage nomor 1.
	if index == 0:
		return true
	return pm.is_stage_completed(chapter_number, index)

func _on_stage_pressed(index: int) -> void:
	if _stage_transitioning or not _stage_unlocked(index):
		return
	_stage_transitioning = true
	for stage in stages:
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var selected := stages[index]
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(selected, "scale", Vector2(0.9, 0.9), 0.10)
	tween.parallel().tween_property(selected, "self_modulate", Color(1.0, 0.85, 0.45, 1.0), 0.10)
	tween.tween_property(selected, "scale", Vector2(1.12, 1.12), 0.18)
	await tween.finished
	GameSession.stage_index = index
	GameSession.arena_id = GameSession.chapter_id
	SceneManager.change_scene("res://ui/character_select/character_select.tscn")

func _on_back_pressed() -> void:
	SceneManager.change_scene("res://scenes/main_menu/pilih_chapter/pilih_chapter.tscn")
