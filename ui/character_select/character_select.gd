
extends Control

## Pilih Karakter
## Potret, nama, gaya bertarung, bio, dan statistik.
## Data karakter berasal dari data/characters/*.tres.

const GOLD := Color(1.0, 0.84, 0.2)

const INFO_TEMPLATE := "res://assets/image/pilih_karakter/character_info_card.png"

const CHARACTER_CARD_SCENE := preload(
    "res://scenes/character_select/character_card.tscn"
)

# =========================================================
# SEMUA KARAKTER
# =========================================================

const PROTAGONISTS: Array[String] = [
	"samurai", "shinobi", "arga", "marco",
	"dmitri", "lin", "nok", "sora",
	"tyrone", "han", "valeria", "anika",
]

const ENEMIES: Array[String] = [
	"buruh_bayaran", "penyelundup", "geng_jalanan",
	"akrobat", "murid_dojo", "pengawal_elit",
	"kapten_brak", "ular_neon", "guru_sunyi",
	"alaric_voss",
]

const ALL_CHARACTERS: Array[String] = [
	"samurai", "shinobi", "arga", "marco",
	"dmitri", "lin", "nok", "sora",
	"tyrone", "han", "valeria", "anika",

	"buruh_bayaran", "penyelundup", "geng_jalanan",
	"akrobat", "murid_dojo", "pengawal_elit",
	"kapten_brak", "ular_neon", "guru_sunyi",
	"alaric_voss",
]

# =========================================================
# VARIABLES
# =========================================================

var _step: int = 1
var _selected: String = ""

var _grid: GridContainer

var _info_portrait: TextureRect
var _info_name: Label
var _info_style: Label
var _info_bio: Label

var _hp_bar: Panel
var _dmg_bar: Panel
var _spd_bar: Panel

var _hp_value: Label
var _dmg_value: Label
var _spd_value: Label

var _start_btn: Button

var _cells: Dictionary = {}


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	print("========== CEK CHARACTER SELECT ==========")
	print("MODE GAME: ", GameSession.mode)
	print("MODE STORY: ", GameSession.Mode.STORY)

	var pm = get_node_or_null("/root/ProgressManager")

	if pm != null:
		print("PROGRESS MANAGER: DITEMUKAN")
		print("KARAKTER TERBUKA: ", pm.unlocked_chars)
	else:
		print("PROGRESS MANAGER: TIDAK DITEMUKAN!")

	print("==========================================")

	Audio.play_music("bgm_menu")
	Audio.play_sfx("choose_your_character", -2.0)

	_build()


# =========================================================
# MEMBANGUN TAMPILAN UTAMA
# =========================================================

func _build() -> void:

	var video_bg := VideoStreamPlayer.new()

	video_bg.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	video_bg.stream = load(
        "res://assets/backgrounds/video/bacground_pilih_karakter.ogv"
	)

	video_bg.expand = true
	video_bg.autoplay = false
	video_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_bg.z_index = -10

	add_child(video_bg)

	video_bg.finished.connect(video_bg.play)

	if video_bg.stream != null:
		video_bg.play()
	else:
		push_warning("Video background tidak ditemukan!")

	# OVERLAY GELAP

	var overlay := ColorRect.new()

	overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	overlay.color = Color(0.02, 0.01, 0.04, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = -5

	add_child(overlay)

	# MARGIN UTAMA

	var margin := MarginContainer.new()

	margin.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)

	add_child(margin)

	# LAYOUT KIRI DAN KANAN

	var main := HBoxContainer.new()

	main.add_theme_constant_override("separation", 24)

	margin.add_child(main)

	# BAGIAN KIRI

	var left := VBoxContainer.new()

	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL

	main.add_child(left)

	var top_space := Control.new()

	top_space.custom_minimum_size = Vector2(0, 85)

	left.add_child(top_space)

	# SCROLL DAFTAR KARAKTER

	var scroll := ScrollContainer.new()

	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	left.add_child(scroll)

	# GRID KARAKTER

	_grid = GridContainer.new()

	_grid.columns = 4

	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)

	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	scroll.add_child(_grid)

	# BAGIAN KANAN

	var right := VBoxContainer.new()

	right.custom_minimum_size = Vector2(380, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL

	right.add_theme_constant_override("separation", 8)

	main.add_child(right)

	# SCROLL INFORMASI

	var info_scroll := ScrollContainer.new()

	info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	right.add_child(info_scroll)

	# KARTU INFORMASI

	var card_root := Control.new()

	card_root.custom_minimum_size = Vector2(380, 570)
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	info_scroll.add_child(card_root)

	# BACKGROUND TEMPLATE

	var card_bg := TextureRect.new()

	if ResourceLoader.exists(INFO_TEMPLATE):
		card_bg.texture = load(INFO_TEMPLATE)

	card_bg.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	card_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_bg.stretch_mode = TextureRect.STRETCH_SCALE
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

	card_root.add_child(card_bg)

	# NAMA KARAKTER

	_info_name = Label.new()

	_info_name.position = Vector2(48, 26)
	_info_name.size = Vector2(310, 55)

	_info_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_info_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	_info_name.clip_text = true

	_info_name.add_theme_font_size_override("font_size", 23)
	_info_name.add_theme_color_override("font_color", GOLD)
	_info_name.add_theme_color_override("font_shadow_color", Color.BLACK)

	_info_name.add_theme_constant_override("shadow_offset_x", 2)
	_info_name.add_theme_constant_override("shadow_offset_y", 2)

	card_root.add_child(_info_name)

	# GAYA BERTARUNG DAN NEGARA

	_info_style = Label.new()

	_info_style.position = Vector2(75, 80)
	_info_style.size = Vector2(230, 28)

	_info_style.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_style.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_info_style.add_theme_font_size_override("font_size", 12)
	_info_style.add_theme_color_override("font_color", Color.WHITE)

	card_root.add_child(_info_style)

	# POTRET KARAKTER

	_info_portrait = TextureRect.new()

	_info_portrait.position = Vector2(75, 125)
	_info_portrait.size = Vector2(230, 165)

	_info_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_info_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_info_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_info_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE

	card_root.add_child(_info_portrait)

	# BIO KARAKTER

	_info_bio = Label.new()

	_info_bio.position = Vector2(45, 291)
	_info_bio.size = Vector2(290, 115)

	_info_bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_info_bio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_bio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_info_bio.clip_text = true

	_info_bio.add_theme_font_size_override("font_size", 12)
	_info_bio.add_theme_color_override("font_color", Color.WHITE)

	card_root.add_child(_info_bio)

	# STATISTIK

	_hp_bar = _stat_bar(card_root, "HP", 424)
	_dmg_bar = _stat_bar(card_root, "DMG", 452)
	_spd_bar = _stat_bar(card_root, "SPD", 480)

	_hp_value = _stat_value(card_root, 427)
	_dmg_value = _stat_value(card_root, 455)
	_spd_value = _stat_value(card_root, 483)

	# TOMBOL AKSI

	var btn_row := HBoxContainer.new()

	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER

	right.add_child(btn_row)

	# TOMBOL KEMBALI

	var back := Button.new()

	back.text = "KEMBALI"
	back.custom_minimum_size = Vector2(150, 48)

	back.add_theme_font_size_override("font_size", 18)

	back.pressed.connect(_on_back)

	btn_row.add_child(back)

	# TOMBOL MULAI

	_start_btn = Button.new()

	_start_btn.text = "MULAI"
	_start_btn.custom_minimum_size = Vector2(190, 48)

	_start_btn.add_theme_font_size_override("font_size", 22)

	_start_btn.disabled = true

	_start_btn.pressed.connect(_on_start)

	btn_row.add_child(_start_btn)

	_rebuild_grid()


# =========================================================
# MEMBUAT INDIKATOR STATISTIK
# =========================================================

func _stat_bar(
	parent: Control,
	label: String,
	y_position: float
) -> Panel:

	var stat_label := Label.new()

	stat_label.text = label

	stat_label.position = Vector2(65, y_position - 3)
	stat_label.size = Vector2(50, 20)

	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	stat_label.add_theme_font_size_override("font_size", 15)
	stat_label.add_theme_color_override("font_color", GOLD)
	stat_label.add_theme_color_override("font_shadow_color", Color.BLACK)

	stat_label.add_theme_constant_override("shadow_offset_x", 1)
	stat_label.add_theme_constant_override("shadow_offset_y", 1)

	stat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	parent.add_child(stat_label)

	var fill := Panel.new()

	fill.position = Vector2(135, y_position + 3)
	fill.size = Vector2(0, 16)

	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()

	style.bg_color = Color(1.0, 0.68, 0.05, 1.0)
	style.set_corner_radius_all(5)

	fill.add_theme_stylebox_override("panel", style)

	parent.add_child(fill)

	return fill


# =========================================================
# MEMBUAT ANGKA STATISTIK
# =========================================================

func _stat_value(
	parent: Control,
	y_position: float
) -> Label:

	var value_label := Label.new()

	value_label.text = "0"
	value_label.visible = false

	value_label.position = Vector2(300, y_position - 3)
	value_label.size = Vector2(32, 18)

	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	value_label.add_theme_font_size_override("font_size", 10)
	value_label.add_theme_color_override("font_color", Color.WHITE)
	value_label.add_theme_color_override("font_shadow_color", Color.BLACK)

	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)

	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	parent.add_child(value_label)

	return value_label


# =========================================================
# MENGATUR NILAI STATISTIK
# =========================================================

func _set_stat_value(
	bar: Panel,
	value_label: Label,
	value: float,
	max_value: float
) -> void:

	var percentage := clampf(
		value / max_value,
		0.0,
		1.0
	)

	bar.size.x = 300.0 * percentage

	value_label.text = str(int(value))


# =========================================================
# MENGAMBIL DATA KARAKTER
# =========================================================

func _char_data(char_id: String):

	var path := "res://data/characters/%s.tres" % char_id

	if not ResourceLoader.exists(path):

		push_error("DATA KARAKTER TIDAK DITEMUKAN: " + path)

		return null

	var data = load(path)

	if data == null:
		push_error("GAGAL LOAD DATA: " + char_id)

	return data


# =========================================================
# MENYESUAIKAN UKURAN NAMA KARAKTER
# =========================================================

func _set_character_name(char_name: String) -> void:

	_info_name.text = char_name

	var font_size := 23

	if char_name.length() > 17:
		font_size = 17
	elif char_name.length() > 14:
		font_size = 19
	elif char_name.length() > 11:
		font_size = 21

	_info_name.add_theme_font_size_override(
		"font_size",
		font_size
	)


# =========================================================
# MEMBANGUN GRID KARAKTER
# =========================================================

func _rebuild_grid() -> void:

	for c in _grid.get_children():
		c.queue_free()

	_cells.clear()

	_selected = ""
	_start_btn.disabled = true

	# RESET INFORMASI

	_info_portrait.texture = null

	_info_name.text = "Pilih karakter"
	_info_style.text = ""
	_info_bio.text = "Pilih karakter untuk melihat informasinya."

	# RESET STATISTIK

	_set_stat_value(_hp_bar, _hp_value, 0, 200)
	_set_stat_value(_dmg_bar, _dmg_value, 0, 2)
	_set_stat_value(_spd_bar, _spd_value, 0, 2)

	# TOMBOL SESUAI MODE

	if _step == 1:

		_start_btn.text = (
            "MULAI"
			if GameSession.mode == GameSession.Mode.STORY
			else "LANJUT: PILIH LAWAN"
		)

	else:

		_start_btn.text = "MULAI BERTARUNG"

	var pm = get_node_or_null("/root/ProgressManager")

	# KEDUA TAHAP SELALU MENAMPILKAN SEMUA KARAKTER

	var character_list: Array[String] = ALL_CHARACTERS

	print("========== STATUS UNLOCK ==========")
	print("MODE: ", GameSession.mode)
	print("STEP: ", _step)
	print("JUMLAH DATA: ", character_list.size())

	for char_id in character_list:

		_add_character_card(char_id, pm)

	print("JUMLAH CARD BERHASIL DIBUAT: ", _grid.get_child_count())
	print("===================================")


# =========================================================
# MEMBUAT CARD KARAKTER
# =========================================================

func _add_character_card(char_id: String, pm) -> void:

	var cd = _char_data(char_id)

	if cd == null:
		return

	# FREE BATTLE: SEMUA KARAKTER TERBUKA
	# STORY: SEMUA TAMPIL, TETAPI MENGIKUTI SISTEM UNLOCK

	var unlocked: bool = true

	if GameSession.mode == GameSession.Mode.STORY:

		unlocked = false

		if pm != null:
			unlocked = pm.is_char_unlocked(char_id)
		else:
			push_error("ProgressManager tidak ditemukan!")

	print(
		"Karakter: ", char_id,
		" | Mode: ", GameSession.mode,
		" | Terbuka: ", unlocked
	)

	var card = CHARACTER_CARD_SCENE.instantiate()

	_grid.add_child(card)

	card.custom_minimum_size = Vector2(170, 255)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	card.setup(
		char_id,
		cd,
		unlocked
	)

	card.selected.connect(_on_pick)

	_cells[char_id] = card


# =========================================================
# MEMILIH KARAKTER
# =========================================================

func _on_pick(char_id: String) -> void:

	if not _cells.has(char_id):
		return

	var pm = get_node_or_null("/root/ProgressManager")

	# VALIDASI UNLOCK STORY MODE

	if GameSession.mode == GameSession.Mode.STORY:

		if pm == null:
			return

		if not pm.is_char_unlocked(char_id):
			print("Karakter masih terkunci: ", char_id)
			return

	Audio.play_sfx("ui_click", -6.0)

	_selected = char_id

	_start_btn.disabled = false

	# HIGHLIGHT CARD

	for cid in _cells:

		var card = _cells[cid]

		if card.has_method("set_selected"):
			card.set_selected(cid == char_id)

	var cd = _char_data(char_id)

	if cd == null:
		return

	# POTRET

	var portrait_path := "res://assets/ui/portraits/%s.png" % char_id

	if ResourceLoader.exists(portrait_path):
		_info_portrait.texture = load(portrait_path)
	else:
		_info_portrait.texture = null

	# NAMA

	var char_name := String(cd.get("display_name"))

	_set_character_name(char_name)

	# GAYA BERTARUNG DAN NEGARA

	_info_style.text = "%s · %s" % [
		String(cd.get("style")),
		String(cd.get("country"))
	]

	# BIO

	_info_bio.text = String(cd.get("bio"))

	# HP

	var hp := float(cd.get("hp"))

	_set_stat_value(
		_hp_bar,
		_hp_value,
		hp,
		200.0
	)

	# DMG

	var dmg := float(cd.get("dmg"))

	_set_stat_value(
		_dmg_bar,
		_dmg_value,
		dmg,
		2.0
	)

	# SPD

	var spd := float(cd.get("spd"))

	_set_stat_value(
		_spd_bar,
		_spd_value,
		spd,
		2.0
	)


# =========================================================
# TOMBOL MULAI
# =========================================================

func _on_start() -> void:

	if _selected == "":
		return

	Audio.play_sfx("ui_select", -2.0)

	# VALIDASI ULANG STORY MODE

	if GameSession.mode == GameSession.Mode.STORY:

		var pm = get_node_or_null("/root/ProgressManager")

		if pm == null:
			push_error("ProgressManager tidak ditemukan!")
			return

		if not pm.is_char_unlocked(_selected):
			push_warning("Karakter belum terbuka!")
			return

	if _step == 1:

		GameSession.player_id = _selected
		GameState.p1_character = _selected

		# STORY MODE LANGSUNG KE ARENA

		if GameSession.mode == GameSession.Mode.STORY:

			_go_arena()

		# FREE BATTLE MEMILIH LAWAN

		else:

			_step = 2
			_rebuild_grid()

	else:

		GameSession.opponent_id = _selected
		GameState.p2_character = _selected

		GameSession.arena_id = ""

		_go_arena()


# =========================================================
# PINDAH KE ARENA
# =========================================================

func _go_arena() -> void:

	SceneManager.change_scene(
        "res://arenas/arena_test.tscn"
	)


# =========================================================
# TOMBOL KEMBALI
# =========================================================

func _on_back() -> void:

	Audio.play_sfx("ui_click", -6.0)

	# KEMBALI KE PEMILIHAN KARAKTER PEMAIN

	if _step == 2:

		_step = 1

		_rebuild_grid()

		return

	# KEMBALI KE HALAMAN SEBELUMNYA

	if GameSession.mode == GameSession.Mode.STORY:

		SceneManager.change_scene(
            "res://ui/chapter_map/chapter_map.tscn"
		)

	else:

		SceneManager.change_scene(
            "res://scenes/menu.tscn"
		)
