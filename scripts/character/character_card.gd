
extends Control

signal selected(char_id: String)

@onready var portrait: TextureRect = $Portrait
@onready var name_label: Label = $NameLabel

@onready var button_pilih: TextureButton = $ButtonPilih
@onready var button_terkunci: TextureButton = $ButtonTerkunci

var char_id: String = ""


# =====================================================
# READY
# =====================================================

func _ready() -> void:

	if not button_pilih.pressed.is_connected(_on_select):
		button_pilih.pressed.connect(_on_select)

	# Pengaturan gambar
	portrait.set_anchors_preset(Control.PRESET_TOP_LEFT)

	portrait.position = Vector2(15, 12)
	portrait.size = Vector2(140, 165)

	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Pengaturan nama
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true


# =====================================================
# MENGATUR UKURAN NAMA
# =====================================================


func _update_name_size() -> void:

	# Pastikan teks tidak berpindah baris
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Ambil font yang digunakan
	var font := name_label.get_theme_font("font")

	# Lebar maksimal teks di dalam kotak
	var available_width := name_label.size.x - 12.0

	# Ukuran font awal
	var font_size := 16

	# Perkecil font sampai seluruh nama muat
	while font_size > 10:

		var text_width := font.get_string_size(
			name_label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size
		).x

		if text_width <= available_width:
			break

		font_size -= 1

	# Terapkan ukuran font
	name_label.add_theme_font_size_override(
		"font_size",
		font_size
	)


# =====================================================
# MENGATUR DATA KARAKTER
# =====================================================

func setup(id: String, data, unlocked: bool) -> void:

	char_id = id

	# Nama karakter
	if data != null:
		name_label.text = str(data.get("display_name"))
	else:
		name_label.text = id.to_upper()

	call_deferred("_update_name_size")

	# Gambar karakter
	var portrait_path := "res://assets/ui/portraits/%s.png" % id

	if ResourceLoader.exists(portrait_path):

		portrait.texture = load(portrait_path)

	else:

		portrait.texture = null

		push_warning("Portrait tidak ditemukan: " + portrait_path)

	# Status tombol
	button_pilih.visible = unlocked
	button_terkunci.visible = not unlocked

	# Karakter terbuka
	if unlocked:

		portrait.modulate = Color.WHITE

		name_label.add_theme_color_override(
			"font_color",
			Color(1.0, 0.85, 0.25)
		)

	# Karakter terkunci
	else:

		portrait.modulate = Color(0.3, 0.3, 0.3, 1.0)

		name_label.add_theme_color_override(
			"font_color",
			Color(0.55, 0.55, 0.55)
		)


# =====================================================
# MEMILIH KARAKTER
# =====================================================

func _on_select() -> void:

	if char_id == "":
		return

	Audio.play_sfx("ui_click", -6.0)

	selected.emit(char_id)
