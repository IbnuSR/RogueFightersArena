extends Control
## Layar Pengaturan: volume musik & SFX (langsung diterapkan ke Audio dan
## disimpan ProgressManager) + hapus progres (tekan 2x sebagai konfirmasi).

var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_label: Label
var _sfx_label: Label
var _reset_btn: Button
var _reset_armed: bool = false
var _reset_timer: float = 0.0


func _ready() -> void:
	Audio.play_music("bgm_menu")
	_build()


func _process(delta: float) -> void:
	if _reset_armed:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			_reset_armed = false
			_reset_btn.text = "HAPUS PROGRES (RESET)"


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.06, 0.13)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	center.add_child(v)

	var title := Label.new()
	title.text = "PENGATURAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
	v.add_child(title)

	var pm = get_node_or_null("/root/ProgressManager")
	var music_v: float = pm.music_volume if pm != null else 0.8
	var sfx_v: float = pm.sfx_volume if pm != null else 0.8

	_music_label = Label.new()
	_music_label.text = "Volume Musik: %d%%" % int(music_v * 100)
	_music_label.add_theme_font_size_override("font_size", 20)
	v.add_child(_music_label)
	_music_slider = HSlider.new()
	_music_slider.min_value = 0
	_music_slider.max_value = 100
	_music_slider.value = music_v * 100
	_music_slider.custom_minimum_size = Vector2(420, 30)
	_music_slider.value_changed.connect(_on_music_changed)
	v.add_child(_music_slider)

	_sfx_label = Label.new()
	_sfx_label.text = "Volume Efek Suara: %d%%" % int(sfx_v * 100)
	_sfx_label.add_theme_font_size_override("font_size", 20)
	v.add_child(_sfx_label)
	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0
	_sfx_slider.max_value = 100
	_sfx_slider.value = sfx_v * 100
	_sfx_slider.custom_minimum_size = Vector2(420, 30)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	v.add_child(_sfx_slider)

	_reset_btn = Button.new()
	_reset_btn.text = "HAPUS PROGRES (RESET)"
	_reset_btn.custom_minimum_size = Vector2(420, 48)
	_reset_btn.add_theme_font_size_override("font_size", 18)
	_reset_btn.pressed.connect(_on_reset_pressed)
	v.add_child(_reset_btn)

	var note := Label.new()
	note.text = "Menghapus progres akan membuka kunci chapter & karakter dari awal."
	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	v.add_child(note)

	var back := Button.new()
	back.text = "KEMBALI KE MENU"
	back.custom_minimum_size = Vector2(420, 48)
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(_on_back)
	v.add_child(back)


func _on_music_changed(value: float) -> void:
	_music_label.text = "Volume Musik: %d%%" % int(value)
	var pm = get_node_or_null("/root/ProgressManager")
	if pm != null:
		pm.music_volume = value / 100.0
		pm.save_progress()
	Audio.set_music_level(value / 100.0)


func _on_sfx_changed(value: float) -> void:
	_sfx_label.text = "Volume Efek Suara: %d%%" % int(value)
	var pm = get_node_or_null("/root/ProgressManager")
	if pm != null:
		pm.sfx_volume = value / 100.0
		pm.save_progress()
	Audio.set_sfx_level(value / 100.0)
	Audio.play_sfx("ui_click", -6.0)


func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_timer = 3.0
		_reset_btn.text = "TEKAN LAGI UNTUK MENGHAPUS!"
		return
	_reset_armed = false
	var pm = get_node_or_null("/root/ProgressManager")
	if pm != null:
		pm.reset_progress()
	_music_slider.value = 80
	_sfx_slider.value = 80
	_reset_btn.text = "PROGRES DIHAPUS"


func _on_back() -> void:
	Audio.play_sfx("ui_click", -6.0)
	SceneManager.change_scene("res://scenes/menu.tscn")
