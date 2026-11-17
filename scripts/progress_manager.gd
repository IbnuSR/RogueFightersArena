extends Node
## ProgressManager (autoload): menyimpan progres Story Mode & pengaturan
## ke user://progress.save (JSON). Dibaca menu & arena.
## - completed_chapters: ["ch1", ...] — chapter 1 selalu terbuka,
##   chapter N terbuka kalau chapter N-1 sudah selesai.
## - unlocked_chars: karakter yang bisa dipakai. Awal: samurai, arga, marco.
##   Mengalahkan musuh/boss di Story Mode membuka karakter itu.
## - music_volume / sfx_volume: 0.0..1.0, diterapkan ke Audio saat load.
## - highest_chapter: jumlah chapter tertinggi yang sudah selesai (untuk
##   tombol "Lanjutkan" di menu lama).

const SAVE_PATH := "user://progress.save"
const START_UNLOCKED: Array[String] = ["samurai", "arga", "marco"]
const CHAPTER_IDS: Array[String] = ["ch1", "ch2", "ch3", "ch4"]

var completed_chapters: Array = []
var unlocked_chars: Array = []
var highest_chapter: int = 0
var music_volume: float = 0.8
var sfx_volume: float = 0.8


func _ready() -> void:
	load_progress()
	_apply_volumes()


func is_chapter_unlocked(chapter_id: String) -> bool:
	var n: int = int(chapter_id.trim_prefix("ch"))
	if n <= 1:
		return true
	return ("ch%d" % (n - 1)) in completed_chapters


func is_chapter_completed(chapter_id: String) -> bool:
	return chapter_id in completed_chapters


func is_char_unlocked(char_id: String) -> bool:
	return char_id in unlocked_chars


func unlock_char(char_id: String) -> bool:
	if char_id == "" or char_id in unlocked_chars:
		return false
	unlocked_chars.append(char_id)
	save_progress()
	return true


func complete_chapter(chapter_id: String) -> bool:
	if chapter_id == "" or chapter_id in completed_chapters:
		return false
	completed_chapters.append(chapter_id)
	highest_chapter = maxi(highest_chapter, int(chapter_id.trim_prefix("ch")))
	save_progress()
	return true


func save_progress() -> void:
	var data := {
		"completed_chapters": completed_chapters,
		"unlocked_chars": unlocked_chars,
		"highest_chapter": highest_chapter,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("ProgressManager: tidak bisa menulis " + SAVE_PATH)
		return
	f.store_string(JSON.stringify(data))
	f.close()


func load_progress() -> void:
	completed_chapters = []
	unlocked_chars = []
	for c in START_UNLOCKED:
		unlocked_chars.append(c)
	highest_chapter = 0
	music_volume = 0.8
	sfx_volume = 0.8
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		return
	if parsed.get("completed_chapters") is Array:
		completed_chapters = parsed["completed_chapters"]
	if parsed.get("unlocked_chars") is Array and not parsed["unlocked_chars"].is_empty():
		unlocked_chars = parsed["unlocked_chars"]
	highest_chapter = int(parsed.get("highest_chapter", 0))
	music_volume = clampf(float(parsed.get("music_volume", 0.8)), 0.0, 1.0)
	sfx_volume = clampf(float(parsed.get("sfx_volume", 0.8)), 0.0, 1.0)


func reset_progress() -> void:
	completed_chapters = []
	unlocked_chars = []
	for c in START_UNLOCKED:
		unlocked_chars.append(c)
	highest_chapter = 0
	music_volume = 0.8
	sfx_volume = 0.8
	save_progress()
	_apply_volumes()


func _apply_volumes() -> void:
	var audio = get_node_or_null("/root/Audio")
	if audio != null and audio.has_method("set_music_level"):
		audio.set_music_level(music_volume)
		audio.set_sfx_level(sfx_volume)
