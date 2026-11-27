
extends Control

@onready var card_dermaga: TextureButton = $Chapter1
@onready var card_neon: TextureButton = $Chapter2
@onready var card_dojo: TextureButton = $Chapter3
@onready var card_menara: TextureButton = $Chapter4
@onready var button_kembali: TextureButton = $Kembali


# ==================================
# ASET CARD CHAPTER
# ==================================

const CHAPTER_NORMAL = [
	preload("res://assets/chapter/buka/chapter1.png"),
	preload("res://assets/chapter/buka/chapter2.png"),
	preload("res://assets/chapter/buka/chapter3.png"),
	preload("res://assets/chapter/buka/chapter4.png")
]

const CHAPTER_LOCKED = [
	null,
	preload("res://assets/chapter/kunci/chapter2.png"),
	preload("res://assets/chapter/kunci/chapter3.png"),
	preload("res://assets/chapter/kunci/chapter4.png")
]


# ==================================
# LOKASI SCENE
# ==================================

@export_file("*.tscn") var main_menu_scene: String = "res://scenes/main_menu/menu.tscn"

const STAGE_SELECT_SCENE := "res://scenes/main_menu/pilih_chapter/chapter1/chapter1.tscn"


# ==================================
# VARIABEL
# ==================================

var sedang_diklik = false


# ==================================
# READY
# ==================================

func _ready():
	
	GameSession.mode = GameSession.Mode.STORY
	print("MODE SAAT PILIH CHAPTER: ", GameSession.mode)
	
	# Atur titik tengah animasi card
	card_dermaga.pivot_offset = card_dermaga.size / 2
	card_neon.pivot_offset = card_neon.size / 2
	card_dojo.pivot_offset = card_dojo.size / 2
	card_menara.pivot_offset = card_menara.size / 2

	button_kembali.pivot_offset = button_kembali.size / 2

	# Hubungkan card
	card_dermaga.pressed.connect(func():
		animasi_card(card_dermaga, "Dermaga")
	)

	card_neon.pressed.connect(func():
		animasi_card(card_neon, "Lorong Neon")
	)

	card_dojo.pressed.connect(func():
		animasi_card(card_dojo, "Dojo Bayangan")
	)

	card_menara.pressed.connect(func():
		animasi_card(card_menara, "Menara Vogs")
	)

	# Efek interaksi semua tombol chapter
	for card in [card_dermaga, card_neon, card_dojo, card_menara, button_kembali]:
		UIButtonEffects.apply(card)

	# Hubungkan tombol kembali
	button_kembali.pressed.connect(animasi_kembali)

	# Animasi floating
	animasi_floating(card_dermaga, 0.0)
	animasi_floating(card_neon, 0.3)
	animasi_floating(card_dojo, 0.6)
	animasi_floating(card_menara, 0.9)

	# Perbarui gambar dan status chapter setelah autoload selesai dimuat.
	update_chapter_cards()
	await get_tree().process_frame
	update_chapter_cards()


# ==================================
# UPDATE STATUS CHAPTER
# ==================================

func update_chapter_cards():

	var cards = [
		card_dermaga,
		card_neon,
		card_dojo,
		card_menara
	]

	for i in range(cards.size()):

		var chapter_number = i + 1

		# Cek status chapter
		var terbuka = ProgressManager.is_chapter_unlocked(
			chapter_number
		)

		_set_chapter_card_state(cards[i], i, terbuka)


func _set_chapter_card_state(card: TextureButton, index: int, terbuka: bool) -> void:
	var texture: Texture2D = CHAPTER_NORMAL[index] if terbuka else CHAPTER_LOCKED[index]
	if texture == null:
		return
	# Set semua state ke gambar yang sesuai sebelum mengubah disabled.
	# TextureButton dapat mempertahankan cache state sebelumnya.
	card.texture_normal = texture
	card.texture_hover = texture
	card.texture_pressed = texture
	card.texture_disabled = texture
	card.self_modulate = Color.WHITE
	card.disabled = not terbuka


# ==================================
# ANIMASI FLOATING CARD
# ==================================

func animasi_floating(card: TextureButton, delay: float):

	var posisi_awal = card.position

	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_interval(delay)

	tween.tween_property(
		card,
		"position",
		posisi_awal + Vector2(0, -8),
		1.2
	)

	tween.tween_property(
		card,
		"position",
		posisi_awal,
		1.2
	)


# ==================================
# ANIMASI CARD SAAT DITEKAN
# ==================================

func animasi_card(card: TextureButton, nama_chapter: String):

	if sedang_diklik:
		return

	sedang_diklik = true

	# Nonaktifkan semua card sementara
	update_card_input(false)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	# Card membesar
	tween.tween_property(
		card,
		"scale",
		Vector2(1.12, 1.12),
		0.15
	)

	# Kembali ke ukuran semula
	tween.tween_property(
		card,
		"scale",
		Vector2(1.0, 1.0),
		0.20
	)

	await tween.finished

	print("Chapter dipilih: ", nama_chapter)

	var chapter_id := ""
	if card == card_dermaga:
		chapter_id = "ch1"
	elif card == card_neon:
		chapter_id = "ch2"
	elif card == card_dojo:
		chapter_id = "ch3"
	elif card == card_menara:
		chapter_id = "ch4"
	if chapter_id != "":
		GameSession.reset()
		GameSession.mode = GameSession.Mode.STORY
		GameSession.chapter_id = chapter_id
		GameSession.arena_id = chapter_id
		GameSession.stage_index = 0
		await transisi_ke_chapter(STAGE_SELECT_SCENE)
		return

	sedang_diklik = false
	update_chapter_cards()


# ==================================
# AKTIF / NONAKTIF CARD
# ==================================

func update_card_input(aktif: bool):

	var cards = [
		card_dermaga,
		card_neon,
		card_dojo,
		card_menara
	]

	for i in range(cards.size()):

		var terbuka = ProgressManager.is_chapter_unlocked(i + 1)

		cards[i].disabled = not aktif or not terbuka


# ==================================
# ANIMASI TOMBOL KEMBALI
# ==================================

func animasi_kembali():

	if sedang_diklik:
		return

	sedang_diklik = true
	button_kembali.disabled = true

	update_card_input(false)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	# Tombol membesar
	tween.tween_property(
		button_kembali,
		"scale",
		Vector2(1.10, 1.10),
		0.15
	)

	# Kembali ke ukuran normal
	tween.tween_property(
		button_kembali,
		"scale",
		Vector2(1.0, 1.0),
		0.15
	)

	await tween.finished

	await transisi_ke_menu()


# ==================================
# TRANSISI KE MAIN MENU
# ==================================

func transisi_ke_menu():

	var tree = get_tree()

	var layer = CanvasLayer.new()
	layer.layer = 100
	tree.root.add_child(layer)

	var layar = ColorRect.new()
	layar.color = Color(0, 0, 0, 0)
	layar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	layar.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	layer.add_child(layar)

	# Fade Out
	var fade_out = tree.create_tween()

	fade_out.tween_property(
		layar,
		"color",
		Color(0, 0, 0, 1),
		0.5
	)

	await fade_out.finished

	# Pindah Main Menu
	var error = tree.change_scene_to_file(main_menu_scene)

	if error != OK:
		push_error("Gagal membuka Main Menu: " + str(error))
		layer.queue_free()
		return

	await tree.process_frame

	# Fade In
	var fade_in = tree.create_tween()

	fade_in.tween_property(
		layar,
		"color",
		Color(0, 0, 0, 0),
		0.7
	)

	await fade_in.finished

	layer.queue_free()


# ==================================
# TRANSISI KE CHAPTER
# ==================================

func transisi_ke_chapter(target_scene: String):

	var tree = get_tree()

	var layer = CanvasLayer.new()
	layer.layer = 100
	tree.root.add_child(layer)

	var layar = ColorRect.new()
	layar.color = Color(0, 0, 0, 0)
	layar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	layar.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	layer.add_child(layar)

	# Fade Out
	var fade = tree.create_tween()

	fade.tween_property(
		layar,
		"color",
		Color(0, 0, 0, 1),
		0.5
	)

	await fade.finished

	# Pindah Chapter
	var error = tree.change_scene_to_file(target_scene)

	if error != OK:
		push_error("Gagal membuka Chapter: " + str(error))
		layer.queue_free()
		return

	await tree.process_frame

	# Fade In
	var fade_in = tree.create_tween()

	fade_in.tween_property(
		layar,
		"color",
		Color(0, 0, 0, 0),
		0.7
	)

	await fade_in.finished

	layer.queue_free()
