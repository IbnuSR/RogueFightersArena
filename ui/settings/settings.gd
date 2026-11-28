extends Control
## Layar Pengaturan: volume musik & SFX (langsung diterapkan ke Audio dan
## disimpan ProgressManager) + hapus progres (tekan 2x sebagai konfirmasi).
## Menggunakan tema visual epik selaras dengan menu utama.

const ASSETS_PATH := "res://assets/ui/settings/"
const DEFAULT_NOTE := "Menghapus progres akan membuka kunci chapter & karakter dari awal."

var _music_slider: HSlider
var _sfx_slider: HSlider
var _music_label: Label
var _sfx_label: Label
var _reset_btn: TextureButton
var _note_label: Label
var _reset_armed: bool = false
var _reset_timer: float = 0.0


func _ready() -> void:
	Audio.stop_music()
	_build()


func _process(delta: float) -> void:
	if _reset_armed:
		_reset_timer -= delta
		if _reset_timer <= 0.0:
			_reset_armed = false
			if _reset_btn != null:
				_reset_btn.modulate = Color(1.0, 1.0, 1.0)
			if _note_label != null:
				_note_label.text = DEFAULT_NOTE
				_note_label.add_theme_color_override("font_color", Color(0.75, 0.70, 0.65))


func _build() -> void:
	# 1. Latar Belakang: Fallback tekstur + Video dinamis menu utama + Dim overlay
	var bg_fallback := TextureRect.new()
	bg_fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	var fallback_tex = load("res://assets/backgrounds/main_menu.png")
	if fallback_tex != null:
		bg_fallback.texture = fallback_tex
		bg_fallback.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_fallback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(bg_fallback)

	var video_stream = load("res://assets/backgrounds/tsk_9a2176f11afde72221c87e869151ff53.ogv")
	if video_stream != null:
		var video := VideoStreamPlayer.new()
		video.set_anchors_preset(Control.PRESET_FULL_RECT)
		video.stream = video_stream
		video.speed_scale = 0.5
		video.autoplay = true
		video.expand = true
		video.loop = true
		add_child(video)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.02, 0.05, 0.72)
	add_child(dim)

	# 2. Kontainer Tengah untuk Modal Panel
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel_container := Control.new()
	panel_container.custom_minimum_size = Vector2(740, 580)
	center.add_child(panel_container)

	# Bingkai Berornamen NinePatchRect
	var panel_frame := NinePatchRect.new()
	panel_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	var panel_tex = load(ASSETS_PATH + "settings_panel.png")
	if panel_tex != null:
		panel_frame.texture = panel_tex
		panel_frame.patch_margin_left = 60
		panel_frame.patch_margin_top = 60
		panel_frame.patch_margin_right = 60
		panel_frame.patch_margin_bottom = 60
	panel_container.add_child(panel_frame)

	# Konten di dalam Bingkai Panel
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 65)
	margin.add_theme_constant_override("margin_right", 65)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel_container.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(v)

	# Header 3D Gold/Ruby Flaming
	var header := TextureRect.new()
	var head_tex = load(ASSETS_PATH + "header_pengaturan.png")
	if head_tex != null:
		header.texture = head_tex
		header.custom_minimum_size = Vector2(380, 95)
		header.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		header.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(header)
	else:
		var title := Label.new()
		title.text = "PENGATURAN"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 42)
		title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.2))
		v.add_child(title)

	var pm = get_node_or_null("/root/ProgressManager")
	var music_v: float = pm.music_volume if pm != null else 0.8
	var sfx_v: float = pm.sfx_volume if pm != null else 0.8

	# StyleBox & Icon untuk Slider Epik
	var style_empty := StyleBoxTexture.new()
	var track_empty_tex = load(ASSETS_PATH + "slider_track_empty.png")
	if track_empty_tex != null:
		style_empty.texture = track_empty_tex
		style_empty.texture_margin_left = 90.0
		style_empty.texture_margin_right = 90.0
		style_empty.texture_margin_top = 10.0
		style_empty.texture_margin_bottom = 10.0
		style_empty.content_margin_top = 18.0
		style_empty.content_margin_bottom = 18.0

	# StyleBoxEmpty agar tidak ada efek warna merah pada isian slider
	var style_fill := StyleBoxEmpty.new()

	var knob_tex = load(ASSETS_PATH + "knob_diamond_padded.png")
	var music_icon_tex = load(ASSETS_PATH + "icon_music_scaled.png")
	var sfx_icon_tex = load(ASSETS_PATH + "icon_sfx_scaled.png")

	# --- 3. Pengaturan Musik ---
	var music_row := HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 10)
	if music_icon_tex != null:
		var ico := TextureRect.new()
		ico.texture = music_icon_tex
		ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		music_row.add_child(ico)

	_music_label = Label.new()
	_music_label.text = "Volume Musik: %d%%" % int(music_v * 100)
	_music_label.add_theme_font_size_override("font_size", 18)
	_music_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	music_row.add_child(_music_label)
	v.add_child(music_row)

	_music_slider = HSlider.new()
	_music_slider.min_value = 0
	_music_slider.max_value = 100
	_music_slider.value = music_v * 100
	_music_slider.custom_minimum_size = Vector2(520, 44)
	_apply_slider_theme(_music_slider, style_empty, style_fill, knob_tex)
	_music_slider.value_changed.connect(_on_music_changed)
	v.add_child(_music_slider)

	# --- 4. Pengaturan SFX ---
	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 10)
	if sfx_icon_tex != null:
		var ico_s := TextureRect.new()
		ico_s.texture = sfx_icon_tex
		ico_s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sfx_row.add_child(ico_s)

	_sfx_label = Label.new()
	_sfx_label.text = "Volume Efek Suara: %d%%" % int(sfx_v * 100)
	_sfx_label.add_theme_font_size_override("font_size", 18)
	_sfx_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	sfx_row.add_child(_sfx_label)
	v.add_child(sfx_row)

	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0
	_sfx_slider.max_value = 100
	_sfx_slider.value = sfx_v * 100
	_sfx_slider.custom_minimum_size = Vector2(520, 44)
	_apply_slider_theme(_sfx_slider, style_empty, style_fill, knob_tex)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	v.add_child(_sfx_slider)

	# Spacer kecil
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	v.add_child(spacer)

	# --- 5. Tombol Reset / Hapus Progres (TextureButton menjaga rasio asli tanpa teks tumpang tindih) ---
	_reset_btn = TextureButton.new()
	var reset_tex = load(ASSETS_PATH + "btn_reset.png")
	if reset_tex != null:
		_reset_btn.texture_normal = reset_tex
	_reset_btn.ignore_texture_size = true
	_reset_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_reset_btn.custom_minimum_size = Vector2(320, 74)
	_reset_btn.mouse_entered.connect(func():
		if not _reset_armed:
			_reset_btn.modulate = Color(1.18, 1.12, 1.12)
		Audio.play_sfx("ui_hover", -8.0)
	)
	_reset_btn.mouse_exited.connect(func():
		if not _reset_armed:
			_reset_btn.modulate = Color(1.0, 1.0, 1.0)
	)
	_reset_btn.pressed.connect(_on_reset_pressed)
	v.add_child(_reset_btn)

	_note_label = Label.new()
	_note_label.text = DEFAULT_NOTE
	_note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note_label.add_theme_font_size_override("font_size", 14)
	_note_label.add_theme_color_override("font_color", Color(0.75, 0.70, 0.65))
	v.add_child(_note_label)

	# --- 6. Tombol Kembali ke Menu ---
	var back_tex = load(ASSETS_PATH + "btn_kembali.png")
	if back_tex != null:
		var back_btn := TextureButton.new()
		back_btn.texture_normal = back_tex
		back_btn.ignore_texture_size = true
		back_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		back_btn.custom_minimum_size = Vector2(380, 68)
		back_btn.mouse_entered.connect(func():
			back_btn.modulate = Color(1.18, 1.15, 1.05)
			Audio.play_sfx("ui_hover", -8.0)
		)
		back_btn.mouse_exited.connect(func():
			back_btn.modulate = Color(1.0, 1.0, 1.0)
		)
		back_btn.pressed.connect(_on_back)
		v.add_child(back_btn)
	else:
		var back := Button.new()
		back.text = "KEMBALI KE MENU"
		back.custom_minimum_size = Vector2(380, 48)
		back.add_theme_font_size_override("font_size", 18)
		back.pressed.connect(_on_back)
		v.add_child(back)


func _apply_slider_theme(slider: HSlider, empty: StyleBox, fill: StyleBox, knob: Texture2D) -> void:
	if empty != null:
		slider.add_theme_stylebox_override("slider", empty)
	if fill != null:
		slider.add_theme_stylebox_override("grabber_area", fill)
		slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	if knob != null:
		slider.add_theme_icon_override("grabber", knob)
		slider.add_theme_icon_override("grabber_highlight", knob)
		slider.add_theme_icon_override("grabber_disabled", knob)


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
		_reset_btn.modulate = Color(1.4, 0.75, 0.65)
		_note_label.text = "TEKAN TOMBOL SEKALI LAGI UNTUK MENGHAPUS PROGRES!"
		_note_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
		Audio.play_sfx("ui_click", -4.0)
		return
	_reset_armed = false
	var pm = get_node_or_null("/root/ProgressManager")
	if pm != null:
		pm.reset_progress()
	_music_slider.value = 80
	_sfx_slider.value = 80
	_reset_btn.modulate = Color(1.0, 1.0, 1.0)
	_note_label.text = "PROGRES BERHASIL DIHAPUS!"
	_note_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.45))
	Audio.play_sfx("ui_click", -4.0)


func _on_back() -> void:
	Audio.play_sfx("ui_click", -6.0)
	SceneManager.change_scene("res://scenes/main_menu/menu.tscn")
