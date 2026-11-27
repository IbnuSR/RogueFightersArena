
extends Node

## ==================================
## PROGRESS MANAGER
## ==================================
## Mengatur:
## 1. Penyelesaian 4 stage dalam setiap chapter.
## 2. Membuka chapter berikutnya secara otomatis.
## 3. Penyimpanan karakter yang terbuka.
## 4. Penyimpanan volume musik dan SFX.
## 5. Penyimpanan progres ke user://progress.save.


# ==================================
# KONFIGURASI
# ==================================

const SAVE_PATH := "user://progress.save"

const JUMLAH_CHAPTER := 4
const JUMLAH_STAGE := 4

# HANYA SAMURAI YANG TERBUKA DI AWAL
const START_UNLOCKED: Array[String] = [
	"samurai"
]

const CHAPTER_IDS: Array[String] = [
	"ch1",
	"ch2",
	"ch3",
	"ch4"
]


# ==================================
# VARIABEL PROGRES
# ==================================

# false = belum selesai
# true = sudah selesai

var stage_progress: Array = [
	[false, false, false, false],
	[false, false, false, false],
	[false, false, false, false],
	[false, false, false, false]
]

# Daftar chapter yang sudah selesai
var completed_chapters: Array = []

# Daftar karakter yang sudah terbuka
var unlocked_chars: Array = []

# Chapter tertinggi yang selesai
var highest_chapter: int = 0

# Volume audio
var music_volume: float = 0.8
var sfx_volume: float = 0.8


# ==================================
# SAAT GAME DIMULAI
# ==================================

func _ready() -> void:
	load_progress()
	_apply_volumes()


# ==================================
# KONVERSI NOMOR CHAPTER
# ==================================

func get_chapter_number(chapter: Variant) -> int:

	if chapter is int:
		return chapter

	var chapter_text := str(chapter)

	if chapter_text.begins_with("ch"):
		return int(chapter_text.trim_prefix("ch"))

	return int(chapter_text)


# ==================================
# CEK CHAPTER TERBUKA
# ==================================

func is_chapter_unlocked(chapter: Variant) -> bool:

	var nomor := get_chapter_number(chapter)

	if nomor < 1 or nomor > JUMLAH_CHAPTER:
		return false

	# Chapter 1 selalu terbuka
	if nomor == 1:
		return true

	# Chapter berikutnya terbuka jika
	# stage boss (stage 4) chapter sebelumnya sudah selesai
	return is_stage_completed(nomor - 1, 4)


# ==================================
# CEK CHAPTER SELESAI
# ==================================

func is_chapter_completed(chapter: Variant) -> bool:

	var nomor := get_chapter_number(chapter)

	if nomor < 1 or nomor > JUMLAH_CHAPTER:
		return false

	for selesai in stage_progress[nomor - 1]:

		if not selesai:
			return false

	return true


# ==================================
# MENYELESAIKAN STAGE
# ==================================

func complete_stage(chapter: int, stage: int) -> bool:

	# Validasi chapter
	if chapter < 1 or chapter > JUMLAH_CHAPTER:
		push_warning("Nomor chapter tidak valid!")
		return false

	# Validasi stage
	if stage < 1 or stage > JUMLAH_STAGE:
		push_warning("Nomor stage tidak valid!")
		return false

	# Pastikan chapter terbuka
	if not is_chapter_unlocked(chapter):
		push_warning("Chapter masih terkunci!")
		return false

	# Cek apakah stage sudah selesai
	if stage_progress[chapter - 1][stage - 1]:
		return false

	# Tandai stage selesai
	stage_progress[chapter - 1][stage - 1] = true

	print(
		"Chapter ", chapter,
		" Stage ", stage,
		" selesai!"
	)

	# Periksa apakah seluruh stage chapter selesai
	if is_chapter_completed(chapter):

		var chapter_id := CHAPTER_IDS[chapter - 1]

		if chapter_id not in completed_chapters:
			completed_chapters.append(chapter_id)

		highest_chapter = maxi(
			highest_chapter,
			chapter
		)

		print("Chapter ", chapter, " berhasil diselesaikan!")

		if chapter < JUMLAH_CHAPTER:
			print(
				"Chapter ",
				chapter + 1,
				" berhasil terbuka!"
			)

	# Simpan progres
	save_progress()

	return true


# ==================================
# CEK STATUS STAGE
# ==================================

func is_stage_completed(chapter: int, stage: int) -> bool:

	if chapter < 1 or chapter > JUMLAH_CHAPTER:
		return false

	if stage < 1 or stage > JUMLAH_STAGE:
		return false

	return stage_progress[chapter - 1][stage - 1]


# ==================================
# MENYELESAIKAN CHAPTER
# ==================================

func complete_chapter(chapter: Variant) -> bool:

	var nomor := get_chapter_number(chapter)

	if nomor < 1 or nomor > JUMLAH_CHAPTER:
		push_warning("Nomor chapter tidak valid!")
		return false

	if not is_chapter_unlocked(nomor):
		push_warning("Chapter masih terkunci!")
		return false

	if is_chapter_completed(nomor):
		return false

	# Tandai seluruh stage selesai
	for i in range(JUMLAH_STAGE):
		stage_progress[nomor - 1][i] = true

	var chapter_id := CHAPTER_IDS[nomor - 1]

	if chapter_id not in completed_chapters:
		completed_chapters.append(chapter_id)

	highest_chapter = maxi(
		highest_chapter,
		nomor
	)

	save_progress()

	print("Chapter ", nomor, " selesai!")

	return true


# ==================================
# KARAKTER TERBUKA
# ==================================

func is_char_unlocked(char_id: String) -> bool:

	return char_id in unlocked_chars


func unlock_char(char_id: String) -> bool:

	if char_id == "":
		return false

	# Jangan membuka karakter dua kali
	if char_id in unlocked_chars:
		return false

	# Tambahkan karakter ke daftar terbuka
	unlocked_chars.append(char_id)

	# Simpan progres
	save_progress()

	print("Karakter terbuka: ", char_id)

	return true


# ==================================
# MENYIMPAN PROGRES
# ==================================

func save_progress() -> void:

	var data := {
		"stage_progress": stage_progress,
		"completed_chapters": completed_chapters,
		"unlocked_chars": unlocked_chars,
		"highest_chapter": highest_chapter,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_warning(
			"ProgressManager: tidak bisa menulis " + SAVE_PATH
		)
		return

	file.store_string(JSON.stringify(data))
	file.close()

	print("Progres berhasil disimpan!")


# ==================================
# MEMUAT PROGRES
# ==================================

func load_progress() -> void:

	# Atur progres awal
	reset_data_default()

	# Periksa apakah file tersedia
	if not FileAccess.file_exists(SAVE_PATH):

		print("Belum ada data progres. Memulai permainan baru.")
		return

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if not (parsed is Dictionary):
		push_warning("Data progres tidak valid!")
		return


	# ----------------------------------
	# MEMUAT PROGRES STAGE
	# ----------------------------------

	var saved_stages = parsed.get(
		"stage_progress",
		null
	)

	if saved_stages is Array:

		if saved_stages.size() == JUMLAH_CHAPTER:

			var valid := true

			for chapter_data in saved_stages:

				if not chapter_data is Array:
					valid = false
					break

				if chapter_data.size() != JUMLAH_STAGE:
					valid = false
					break

			if valid:
				stage_progress = saved_stages.duplicate(true)
			else:
				push_warning("Struktur stage_progress tidak valid!")


	# ----------------------------------
	# MEMUAT CHAPTER SELESAI
	# ----------------------------------

	var saved_chapters = parsed.get(
		"completed_chapters",
		[]
	)

	if saved_chapters is Array:

		for chapter_id in saved_chapters:

			if chapter_id in CHAPTER_IDS:

				if chapter_id not in completed_chapters:
					completed_chapters.append(chapter_id)

				# Kompatibilitas progres lama
				var nomor := get_chapter_number(chapter_id)

				for i in range(JUMLAH_STAGE):
					stage_progress[nomor - 1][i] = true


	# ----------------------------------
	# MEMUAT KARAKTER
	# ----------------------------------

	var saved_chars = parsed.get(
		"unlocked_chars",
		null
	)

	if saved_chars is Array:

		# Pertahankan semua karakter yang sudah dibuka, termasuk karakter
		# yang dikalahkan pada stage awal sebelum chapter selesai.
		unlocked_chars = START_UNLOCKED.duplicate()
		for char_id in saved_chars:
			if char_id is String:
				if char_id != "" and char_id not in unlocked_chars:
					unlocked_chars.append(char_id)


	# ----------------------------------
	# MEMUAT HIGHEST CHAPTER
	# ----------------------------------

	highest_chapter = int(
		parsed.get("highest_chapter", 0)
	)

	# Perbarui berdasarkan stage yang selesai
	for i in range(JUMLAH_CHAPTER):

		if is_chapter_completed(i + 1):

			highest_chapter = maxi(
				highest_chapter,
				i + 1
			)


	# ----------------------------------
	# MEMUAT VOLUME AUDIO
	# ----------------------------------

	music_volume = clampf(
		float(parsed.get("music_volume", 0.8)),
		0.0,
		1.0
	)

	sfx_volume = clampf(
		float(parsed.get("sfx_volume", 0.8)),
		0.0,
		1.0
	)

	print("Progres berhasil dimuat!")
	print("Karakter terbuka: ", unlocked_chars)


# ==================================
# DATA AWAL / DEFAULT
# ==================================

func reset_data_default() -> void:

	stage_progress = [
		[false, false, false, false],
		[false, false, false, false],
		[false, false, false, false],
		[false, false, false, false]
	]

	completed_chapters = []

	# HANYA SAMURAI YANG TERBUKA
	unlocked_chars = START_UNLOCKED.duplicate()

	highest_chapter = 0

	music_volume = 0.8
	sfx_volume = 0.8


# ==================================
# RESET SELURUH PROGRES
# ==================================

func reset_progress() -> void:

	reset_data_default()

	save_progress()

	_apply_volumes()

	print("Seluruh progres permainan berhasil direset!")


# ==================================
# PENGATURAN AUDIO
# ==================================

func _apply_volumes() -> void:

	var audio = get_node_or_null("/root/Audio")

	if audio != null and audio.has_method("set_music_level"):

		audio.set_music_level(music_volume)
		audio.set_sfx_level(sfx_volume)
