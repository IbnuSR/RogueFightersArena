extends Control
## Pilih Karakter: potret (crop frame idle), nama, gaya, bio 1 paragraf,
## dan statistik (HP / DMG / SPD) dari data/characters/*.tres.
## Alur 2 langkah:
##  1) PILIH KARAKTERMU  ->  Story: langsung ke arena (lawan = stage chapter)
##                          Free Fight: lanjut langkah 2
##  2) PILIH LAWAN (Free Fight saja, dari SEMUA 21 karakter)
## Di Story Mode hanya karakter yang sudah terbuka yang bisa dipilih
## (musuh/boss yang belum dikalahkan tampil gelap + TERKUNCI).
## Di Free Fight SEMUA karakter bisa dipilih, termasuk musuh & boss.

const GOLD := Color(1.0, 0.84, 0.2)
const DIM := Color(0.55, 0.55, 0.55)
const PROTAGONISTS: Array[String] = [
	"samurai", "shinobi", "arga", "marco", "dmitri", "lin",
	"nok", "sora", "tyrone", "han", "valeria", "anika",
]
const ENEMIES: Array[String] = [
	"buruh_bayaran", "penyelundup", "geng_jalanan", "akrobat",
	"murid_dojo", "pengawal_elit", "kapten_brak", "ular_neon", "guru_sunyi",
	"alaric_voss",
]

var _step: int = 1
var _selected: String = ""
var _title: Label
var _grid: GridContainer
var _info_portrait: TextureRect
var _info_name: Label
var _info_style: Label
var _info_bio: Label
var _info_trait: Label
var _hp_bar: ProgressBar
var _dmg_bar: ProgressBar
var _spd_bar: ProgressBar
var _start_btn: Button
var _cells: Dictionary = {}


func _ready() -> void:
	Audio.play_music("bgm_menu")
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.06, 0.13)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 24)
	margin.add_child(main)

	# ---- Kiri: daftar karakter ----
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	main.add_child(left)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", GOLD)
	left.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	# ---- Kanan: info karakter terpilih ----
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(380, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	main.add_child(right)

	# Info dibungkus ScrollContainer agar teks panjang tidak pernah mendorong tombol keluar layar
	var info_scroll := ScrollContainer.new()
	info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(info_scroll)

	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 6)
	info_scroll.add_child(info_box)

	_info_portrait = TextureRect.new()
	_info_portrait.custom_minimum_size = Vector2(130, 130)
	_info_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_info_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_box.add_child(_info_portrait)

	_info_name = Label.new()
	_info_name.add_theme_font_size_override("font_size", 26)
	_info_name.add_theme_color_override("font_color", GOLD)
	info_box.add_child(_info_name)

	_info_style = Label.new()
	_info_style.add_theme_font_size_override("font_size", 15)
	info_box.add_child(_info_style)

	_info_bio = Label.new()
	_info_bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_bio.add_theme_font_size_override("font_size", 14)
	info_box.add_child(_info_bio)

	_info_trait = Label.new()
	_info_trait.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_trait.add_theme_font_size_override("font_size", 13)
	_info_trait.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	info_box.add_child(_info_trait)

	_hp_bar = _stat_bar(info_box, "HP")
	_dmg_bar = _stat_bar(info_box, "DMG")
	_spd_bar = _stat_bar(info_box, "SPD")

	# Tombol aksi berdampingan di bawah, selalu terlihat dan dapat diklik
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_child(btn_row)

	var back := Button.new()
	back.text = "KEMBALI"
	back.custom_minimum_size = Vector2(150, 48)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(_on_back)
	btn_row.add_child(back)

	_start_btn = Button.new()
	_start_btn.text = "MULAI"
	_start_btn.custom_minimum_size = Vector2(190, 48)
	_start_btn.add_theme_font_size_override("font_size", 22)
	_start_btn.disabled = true
	_start_btn.pressed.connect(_on_start)
	btn_row.add_child(_start_btn)

	_rebuild_grid()


func _stat_bar(parent: Control, label: String) -> ProgressBar:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(40, 0)
	l.add_theme_font_size_override("font_size", 14)
	row.add_child(l)
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.value = 50
	bar.custom_minimum_size = Vector2(240, 16)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	row.add_child(bar)
	parent.add_child(row)
	return bar


func _char_data(char_id: String):
	var path := "res://data/characters/%s.tres" % char_id
	if not ResourceLoader.exists(path):
		return null
	return load(path)


func _rebuild_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_cells.clear()
	_selected = ""
	_start_btn.disabled = true
	_info_portrait.texture = null
	_info_name.text = "Pilih karakter"
	_info_style.text = ""
	_info_bio.text = "Klik salah satu potret untuk melihat latar belakang dan statistiknya."
	_info_trait.text = ""
	_hp_bar.value = 0
	_dmg_bar.value = 0
	_spd_bar.value = 0

	if _step == 1:
		_title.text = "PILIH KARAKTERMU"
		_start_btn.text = "MULAI" if GameSession.mode == GameSession.Mode.STORY else "LANJUT: PILIH LAWAN"
	else:
		_title.text = "PILIH LAWAN"
		_start_btn.text = "MULAI BERTARUNG"

	var pm = get_node_or_null("/root/ProgressManager")
	for section in [["PROTAGONIS", PROTAGONISTS], ["MUSUH & BOSS", ENEMIES]]:
		var header := Label.new()
		header.text = section[0]
		header.add_theme_font_size_override("font_size", 20)
		header.add_theme_color_override("font_color", GOLD)
		_grid.add_child(header)
		for i in range(3):
			_grid.add_child(Control.new())
		for char_id in section[1]:
			_grid.add_child(_make_cell(char_id, pm))


func _make_cell(char_id: String, pm) -> PanelContainer:
	var cd = _char_data(char_id)
	# Free Fight: semua karakter bisa dipilih. Story: hanya yang terbuka.
	var unlocked: bool = true
	if GameSession.mode == GameSession.Mode.STORY and pm != null:
		unlocked = pm.is_char_unlocked(char_id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 190)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.12, 0.22, 0.95)
	style.border_color = GOLD if unlocked else Color(0.35, 0.35, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)

	var pic := TextureRect.new()
	pic.texture = load("res://assets/ui/portraits/%s.png" % char_id)
	pic.custom_minimum_size = Vector2(120, 120)
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if not unlocked:
		pic.modulate = Color(0.35, 0.35, 0.35)
	v.add_child(pic)

	var name_label := Label.new()
	name_label.text = String(cd.get("display_name")) if cd != null else char_id.to_upper()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	if not unlocked:
		name_label.add_theme_color_override("font_color", DIM)
	v.add_child(name_label)

	var btn := Button.new()
	btn.text = "TERKUNCI" if not unlocked else "PILIH"
	btn.disabled = not unlocked
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(_on_pick.bind(char_id))
	v.add_child(btn)
	_cells[char_id] = panel
	return panel


func _on_pick(char_id: String) -> void:
	Audio.play_sfx("ui_click", -6.0)
	_selected = char_id
	_start_btn.disabled = false
	for cid in _cells:
		var panel: PanelContainer = _cells[cid]
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel")
		style.border_color = GOLD if cid == char_id else Color(0.35, 0.35, 0.35)
	var cd = _char_data(char_id)
	_info_portrait.texture = load("res://assets/ui/portraits/%s.png" % char_id)
	if cd != null:
		_info_name.text = String(cd.get("display_name"))
		_info_style.text = "%s · %s" % [String(cd.get("style")), String(cd.get("country"))]
		_info_bio.text = String(cd.get("bio"))
		_info_trait.text = "Ciri khas: " + String(cd.get("trait_desc"))
		_hp_bar.value = clampf(float(cd.get("hp")) / 200.0 * 100.0, 0, 100)
		_dmg_bar.value = clampf(float(cd.get("dmg")) / 2.0 * 100.0, 0, 100)
		_spd_bar.value = clampf(float(cd.get("spd")) / 2.0 * 100.0, 0, 100)


func _on_start() -> void:
	if _selected == "":
		return
	Audio.play_sfx("ui_click", -6.0)
	if _step == 1:
		GameSession.player_id = _selected
		GameState.p1_character = _selected
		if GameSession.mode == GameSession.Mode.STORY:
			_go_arena()
		else:
			_step = 2
			_rebuild_grid()
	else:
		GameSession.opponent_id = _selected
		GameState.p2_character = _selected
		GameSession.arena_id = ""
		_go_arena()


func _go_arena() -> void:
	SceneManager.change_scene("res://arenas/arena_test.tscn")


func _on_back() -> void:
	Audio.play_sfx("ui_click", -6.0)
	if _step == 2:
		_step = 1
		_rebuild_grid()
		return
	if GameSession.mode == GameSession.Mode.STORY:
		SceneManager.change_scene("res://ui/chapter_map/chapter_map.tscn")
	else:
		SceneManager.change_scene("res://scenes/menu.tscn")
