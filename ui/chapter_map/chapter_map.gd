extends Control
## Peta Chapter Story Mode: 4 kartu chapter dengan thumbnail latar,
## nama musuh & boss, status terkunci/terbuka (ProgressManager), dan
## tombol MAIN yang lanjut ke pilih karakter.
## Dibuka dari menu utama (Mode Cerita) atau tombol Lanjutkan.

const GOLD := Color(1.0, 0.84, 0.2)
const DIM := Color(0.55, 0.55, 0.55)

var _cards: Dictionary = {}


func _ready() -> void:
	Audio.play_music("bgm_menu")
	_build()


func _build() -> void:
	# Latar: gambar main menu yang digelapkan.
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.texture = load("res://assets/backgrounds/main_menu.png")
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.modulate = Color(1, 1, 1, 0.35)
	add_child(bg)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	add_child(dim)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	var title := Label.new()
	title.text = "PETA CHAPTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", GOLD)
	vbox.add_child(title)

	var pm = get_node_or_null("/root/ProgressManager")
	var done: int = pm.completed_chapters.size() if pm != null else 0
	var unlocked: int = pm.unlocked_chars.size() if pm != null else 3
	var sub := Label.new()
	sub.text = "Chapter selesai: %d/4   ·   Karakter terbuka: %d/22" % [done, unlocked]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	vbox.add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	vbox.add_child(row)

	var ids: Array[String] = pm.CHAPTER_IDS if pm != null else ["ch1", "ch2", "ch3", "ch4"]
	for ch_id in ids:
		row.add_child(_make_card(ch_id))

	var back := Button.new()
	back.text = "KEMBALI KE MENU"
	back.custom_minimum_size = Vector2(260, 48)
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(_on_back)
	var back_row := HBoxContainer.new()
	back_row.alignment = BoxContainer.ALIGNMENT_CENTER
	back_row.add_child(back)
	vbox.add_child(back_row)


func _make_card(ch_id: String) -> PanelContainer:
	var chapter = load("res://data/chapters/%s.tres" % ch_id)
	var pm = get_node_or_null("/root/ProgressManager")
	var open: bool = pm.is_chapter_unlocked(ch_id) if pm != null else ch_id == "ch1"
	var done: bool = pm.is_chapter_completed(ch_id) if pm != null else false
	var n: int = int(ch_id.trim_prefix("ch"))

	var panel := PanelContainer.new()
	# 4 kartu muat di lebar 1280: kartu 300x470, thumb 276x155.
	panel.custom_minimum_size = Vector2(300, 470)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.2, 0.95)
	style.border_color = GOLD if open else Color(0.4, 0.4, 0.4)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var thumb := TextureRect.new()
	thumb.texture = load("res://assets/ui/thumbs/%s.png" % ch_id)
	thumb.custom_minimum_size = Vector2(276, 155)
	thumb.stretch_mode = TextureRect.STRETCH_SCALE
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if not open:
		thumb.modulate = Color(0.4, 0.4, 0.4)
	v.add_child(thumb)

	var t1 := Label.new()
	t1.text = "CHAPTER %d" % n
	t1.add_theme_font_size_override("font_size", 22)
	t1.add_theme_color_override("font_color", GOLD if open else DIM)
	v.add_child(t1)

	var t2 := Label.new()
	t2.text = String(chapter.get("title")).to_upper() if chapter != null else ch_id
	t2.add_theme_font_size_override("font_size", 32)
	v.add_child(t2)

	var enemies: Array = chapter.get("stages") if chapter != null else []
	var enemy_names: Array[String] = []
	for e in enemies:
		enemy_names.append(_char_name(String(e)))
	var l_enemy := Label.new()
	l_enemy.text = "Musuh: " + ", ".join(enemy_names)
	l_enemy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_enemy.add_theme_font_size_override("font_size", 17)
	v.add_child(l_enemy)

	var boss_id: String = String(chapter.get("boss_id")) if chapter != null else ""
	var l_boss := Label.new()
	l_boss.text = "Boss: " + _char_name(boss_id).to_upper()
	l_boss.add_theme_font_size_override("font_size", 19)
	l_boss.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	v.add_child(l_boss)

	var status := Label.new()
	if done:
		status.text = "SELESAI — bisa diulang"
		status.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	elif open:
		status.text = "TERBUKA — 4 stage (3 musuh + boss)"
		status.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		status.text = "TERKUNCI — selesaikan Chapter %d dulu" % (n - 1)
		status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 17)
	v.add_child(status)

	var play := Button.new()
	play.text = "MAIN" if open else "TERKUNCI"
	play.custom_minimum_size = Vector2(200, 48)
	play.add_theme_font_size_override("font_size", 22)
	play.disabled = not open
	play.pressed.connect(_on_play.bind(ch_id))
	v.add_child(play)
	return panel


func _char_name(char_id: String) -> String:
	var path := "res://data/characters/%s.tres" % char_id
	if not ResourceLoader.exists(path):
		return char_id.to_upper()
	var cd = load(path)
	if cd == null:
		return char_id.to_upper()
	return String(cd.get("display_name"))


func _on_play(chapter_id: String) -> void:
	Audio.play_sfx("ui_click", -6.0)
	GameSession.reset()
	GameSession.mode = GameSession.Mode.STORY
	GameSession.chapter_id = chapter_id
	GameSession.arena_id = chapter_id
	GameSession.stage_index = 0
	SceneManager.change_scene("res://ui/character_select/character_select.tscn")


func _on_back() -> void:
	Audio.play_sfx("ui_click", -6.0)
	SceneManager.change_scene("res://scenes/menu.tscn")
