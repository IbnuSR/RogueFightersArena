extends SceneTree
## Tes Story Mode (11 Nov 2026): ProgressManager save/load + unlock,
## peta chapter, pilih karakter, pengaturan, dan alur arena Story
## (stage 1-4, 1 ronde, boss 2 fase + pola khas).
## Jalankan: godot --headless --path . --script res://tests/story_mode.gd

var failures: Array[String] = []


func _init() -> void:
	_run()


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("[STORY] OK: ", msg)
	else:
		failures.append(msg)
		printerr("[STORY] FAIL: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _find_buttons(node: Node, text: String) -> Array:
	var out: Array = []
	for c in node.get_children():
		if c is Button and c.text == text:
			out.append(c)
		out.append_array(_find_buttons(c, text))
	return out


func _finish() -> void:
	if failures.is_empty():
		print("[STORY] SEMUA TES LOLOS")
	else:
		printerr("[STORY] %d TES GAGAL" % failures.size())
	quit(1 if not failures.is_empty() else 0)


func _run() -> void:
	print("[STORY] mulai")
	_delayed_watchdog()
	await process_frame

	var pm = root.get_node_or_null("ProgressManager")
	var gstate = root.get_node_or_null("GameState")
	_check(pm != null, "autoload ProgressManager ada")
	if pm == null:
		_finish()
		return
	# Simpan progres asli supaya tes tidak merusak simpanan pemain.
	var orig_done: Array = pm.completed_chapters.duplicate()
	var orig_chars: Array = pm.unlocked_chars.duplicate()
	var orig_high: int = pm.highest_chapter
	var orig_music: float = pm.music_volume
	var orig_sfx: float = pm.sfx_volume

	# Reset state awal sementara untuk pengujian
	pm.completed_chapters = []
	pm.unlocked_chars = pm.START_UNLOCKED.duplicate()
	pm.highest_chapter = 0

	# --- 1. ProgressManager: unlock chapter & karakter ---
	_check(pm.is_chapter_unlocked("ch1"), "ch1 selalu terbuka")
	_check(not pm.is_chapter_unlocked("ch2"), "ch2 terkunci sebelum ch1 selesai")
	_check(not pm.is_chapter_unlocked("ch3"), "ch3 terkunci sebelum ch2 selesai")
	_check(not pm.is_chapter_unlocked("ch4"), "ch4 terkunci sebelum ch3 selesai")
	_check(pm.is_char_unlocked("samurai") and pm.is_char_unlocked("arga") and pm.is_char_unlocked("marco"),
		"karakter awal terbuka: samurai, arga, marco")
	_check(not pm.is_char_unlocked("buruh_bayaran"), "buruh_bayaran terkunci di awal")
	_check(pm.unlock_char("buruh_bayaran"), "unlock buruh_bayaran berhasil")
	_check(pm.is_char_unlocked("buruh_bayaran"), "buruh_bayaran terbuka setelah unlock")
	_check(not pm.unlock_char("buruh_bayaran"), "unlock 2x tidak duplikat")
	_check(pm.complete_chapter("ch1"), "complete ch1 berhasil")
	_check(pm.is_chapter_unlocked("ch2"), "ch2 terbuka setelah ch1 selesai")
	_check(pm.highest_chapter >= 1, "highest_chapter >= 1 setelah ch1")
	# Save -> load round-trip
	pm.music_volume = 0.5
	pm.sfx_volume = 0.6
	pm.save_progress()
	pm.completed_chapters = []
	pm.unlocked_chars = ["samurai"]
	pm.load_progress()
	_check(pm.is_chapter_completed("ch1"), "save/load: ch1 tetap selesai")
	_check(pm.is_char_unlocked("buruh_bayaran"), "save/load: buruh_bayaran tetap terbuka")
	_check(is_equal_approx(pm.music_volume, 0.5), "save/load: volume musik 0.5")
	_check(is_equal_approx(pm.sfx_volume, 0.6), "save/load: volume sfx 0.6")

	# --- 2. Menu utama: tombol MODE CERITA + gambar baru ---
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	_check(menu_scene != null, "main_menu.tscn ke-load")
	var menu = menu_scene.instantiate()
	root.add_child(menu)
	await _frames(5)
	var bg = menu.get_node_or_null("BG")
	_check(bg != null and bg.texture != null and bg.texture.resource_path == "res://assets/backgrounds/main_menu.png",
		"menu utama memakai gambar main_menu.png")
	_check(menu.get_node_or_null("Center/VBox/BtnStory") != null, "tombol MODE CERITA ada")
	_check(menu.get_node_or_null("Center/VBox/BtnSettings") != null, "tombol PENGATURAN ada")
	menu.queue_free()
	await _frames(5)

	# --- 3. Peta chapter: 4 kartu, ch3/ch4 terkunci (ch1 selesai, ch2 terbuka) ---
	var map_scene: PackedScene = load("res://ui/chapter_map/chapter_map.tscn")
	_check(map_scene != null, "chapter_map.tscn ke-load")
	var cmap = map_scene.instantiate()
	root.add_child(cmap)
	await _frames(5)
	_check(_find_buttons(cmap, "MAIN").size() == 2, "peta: 2 chapter bisa dimainkan (ch1, ch2)")
	_check(_find_buttons(cmap, "TERKUNCI").size() == 2, "peta: 2 chapter terkunci (ch3, ch4)")
	cmap.queue_free()
	await _frames(5)

	# --- 4. Pilih karakter (STORY): potret + bio + stat, yang terkunci tidak bisa dipilih ---
	var gs0 = root.get_node_or_null("GameSession")
	gs0.mode = gs0.Mode.STORY
	var sel_scene: PackedScene = load("res://ui/character_select/character_select.tscn")
	_check(sel_scene != null, "character_select.tscn ke-load")
	var sel = sel_scene.instantiate()
	root.add_child(sel)
	await _frames(5)
	_check(_find_buttons(sel, "PILIH").size() >= 3, "pilih karakter: >=3 karakter bisa dipilih")
	_check(_find_buttons(sel, "TERKUNCI").size() >= 10, "pilih karakter: musuh/boss masih terkunci")
	sel._on_pick("arga")
	_check(sel.get("_selected") == "arga", "pilih arga tersimpan")
	_check(sel.get("_start_btn").disabled == false, "tombol MULAI aktif setelah pilih")
	_check(String(sel.get("_info_name").text) == "Arga Wiratama", "info panel menampilkan nama Arga")
	_check(String(sel.get("_info_bio").text).length() > 20, "info panel menampilkan bio")
	sel.queue_free()
	await _frames(5)

	# --- 4b. Pilih karakter (FREE FIGHT): SEMUA 22 karakter bisa dipilih ---
	gs0.mode = gs0.Mode.FREE_FIGHT
	var sel2 = sel_scene.instantiate()
	root.add_child(sel2)
	await _frames(5)
	_check(_find_buttons(sel2, "PILIH").size() == 22, "free fight: semua 22 karakter bisa dipilih (dapat %d)" % _find_buttons(sel2, "PILIH").size())
	_check(_find_buttons(sel2, "TERKUNCI").size() == 0, "free fight: tidak ada yang terkunci")
	sel2._on_pick("kapten_brak")
	sel2._on_start()
	await _frames(5)
	_check(sel2.get("_step") == 2, "free fight langkah 2: pilih lawan")
	sel2._on_pick("guru_sunyi")
	sel2._on_start()
	_check(gs0.player_id == "kapten_brak" and gs0.opponent_id == "guru_sunyi",
		"free fight: P1 kapten_brak vs P2 guru_sunyi tersimpan")
	sel2.queue_free()
	await _frames(5)
	gs0.reset()

	# --- 5. Pengaturan: scene ke-load, slider ada ---
	var set_scene: PackedScene = load("res://ui/settings/settings.tscn")
	_check(set_scene != null, "settings.tscn ke-load")
	var settings = set_scene.instantiate()
	root.add_child(settings)
	await _frames(5)
	_check(settings.get("_music_slider") != null and settings.get("_sfx_slider") != null,
		"pengaturan: slider musik & sfx ada")
	settings.queue_free()
	await _frames(5)

	# --- 6. Arena Story ch1 stage 1: latar Dermaga, lawan Buruh Bayaran ---
	var gs = root.get_node_or_null("GameSession")
	gs.reset()
	gs.mode = gs.Mode.STORY
	gs.chapter_id = "ch1"
	gs.arena_id = "ch1"
	gs.stage_index = 0
	gs.player_id = "arga"
	var arena_scene: PackedScene = load("res://arenas/arena_test.tscn")
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	await _frames(10)
	var abg = arena.get_node_or_null("Background")
	_check(abg != null and abg.texture != null and abg.texture.resource_path == "res://assets/backgrounds/dermaga.png",
		"arena story ch1 memakai dermaga.png")
	_check(gstate.p2_character == "buruh_bayaran", "stage 1 ch1 lawannya buruh_bayaran")
	var stage_label = arena.get("_stage_label")
	_check(stage_label != null and "STAGE 1/4" in String(stage_label.text),
		"label stage menampilkan STAGE 1/4 (dapat: %s)" % (stage_label.text if stage_label != null else "null"))
	var ai1 = arena.get_node("Fighter2").get_node_or_null("AIController")
	_check(ai1 != null and String(ai1.get("boss_pattern")) == "", "musuh biasa tidak punya pola boss")
	arena.queue_free()
	await _frames(5)

	# --- 7. Arena Story ch1 stage 4 (boss): pola charge + label BOSS ---
	gs.reset()
	gs.mode = gs.Mode.STORY
	gs.chapter_id = "ch1"
	gs.arena_id = "ch1"
	gs.stage_index = 3
	gs.player_id = "arga"
	var arena2 = arena_scene.instantiate()
	root.add_child(arena2)
	await _frames(10)
	_check(gstate.p2_character == "kapten_brak", "stage 4 ch1 lawannya kapten_brak (boss)")
	var ai2 = arena2.get_node("Fighter2").get_node_or_null("AIController")
	_check(ai2 != null and String(ai2.get("boss_pattern")) == "charge",
		"pola AI Kapten Brak = charge (dapat: %s)" % (String(ai2.get("boss_pattern")) if ai2 != null else "null"))
	var stage_label2 = arena2.get("_stage_label")
	_check(stage_label2 != null and "BOSS" in String(stage_label2.text),
		"label stage boss menampilkan BOSS")
	arena2.queue_free()
	await _frames(5)

	# --- 8. Story end-to-end: kalahkan stage 1 -> maju ke stage 2 ---
	gs.reset()
	gs.mode = gs.Mode.STORY
	gs.chapter_id = "ch1"
	gs.arena_id = "ch1"
	gs.stage_index = 0
	gs.player_id = "arga"
	var arena3 = arena_scene.instantiate()
	root.add_child(arena3)
	await _frames(10)
	# Tunggu countdown selesai (5.6 dtk), lalu KO-kan musuh.
	await create_timer(7.0).timeout
	var f1b = arena3.get_node("Fighter")
	var f2b = arena3.get_node("Fighter2")
	_check(bool(arena3.get("round_active")), "story: ronde aktif sebelum KO")
	f2b.take_damage(9999, f1b, "attack_1", true)
	# KO (1.4 dtk) + resolve (2.5 dtk) + advance (2.0 dtk) = ~6 dtk.
	await create_timer(7.0).timeout
	_check(gs.stage_index == 1, "story: setelah menang stage 1 -> stage_index 1 (dapat %d)" % gs.stage_index)
	_check(gstate.p2_character == "penyelundup", "story: stage 2 lawannya penyelundup")
	var stage_label3 = arena3.get("_stage_label")
	_check(stage_label3 != null and "STAGE 2/4" in String(stage_label3.text),
		"story: label stage maju ke STAGE 2/4")
	arena3.queue_free()
	await _frames(5)

	# --- 9. Story end-to-end: kalahkan boss -> chapter selesai ---
	pm.completed_chapters = []
	pm.unlocked_chars = ["samurai", "arga", "marco"]
	pm.highest_chapter = 0
	pm.save_progress()
	gs.reset()
	gs.mode = gs.Mode.STORY
	gs.chapter_id = "ch1"
	gs.arena_id = "ch1"
	gs.stage_index = 3
	gs.player_id = "arga"
	var arena4 = arena_scene.instantiate()
	root.add_child(arena4)
	await _frames(10)
	await create_timer(7.0).timeout
	var f1c = arena4.get_node("Fighter")
	var f2c = arena4.get_node("Fighter2")
	f2c.take_damage(9999, f1c, "attack_1", true)
	await create_timer(7.0).timeout
	_check(pm.is_chapter_completed("ch1"), "story: kalahkan boss -> ch1 selesai")
	_check(bool(arena4.get("match_over")), "story: match_over setelah boss kalah")
	var go_label = arena4.get_node_or_null("OverlayLayer/GameOverMenu/Center/Panel/VBox/WinnerLabel")
	_check(go_label != null and "CHAPTER 1 SELESAI!" in String(go_label.text),
		"story: label CHAPTER 1 SELESAI! tampil")
	arena4.queue_free()
	await _frames(5)

	# --- 10. Chapter 4 (GDD v2.0 §4) + Voss + scaling stage ---
	var ch4 = load("res://data/chapters/ch4.tres")
	_check(ch4 != null and String(ch4.get("title")) == "Menara Voss", "ch4: judul Menara Voss")
	_check(ch4 != null and String(ch4.get("boss_id")) == "alaric_voss", "ch4: boss Alaric Voss")
	_check(ch4 != null and String(ch4.get("arena_bg")) == "res://assets/backgrounds/menara_voss.png",
		"ch4: latar menara_voss.png")
	_check(ResourceLoader.exists("res://assets/backgrounds/menara_voss.png"), "ch4: file menara_voss.png ada")
	var voss = load("res://data/characters/alaric_voss.tres")
	_check(voss != null and String(voss.get("trait_id")) == "boss_voss", "voss: trait boss_voss")
	# Unlock berantai sampai ch4 (ch1 sudah selesai di bagian 9).
	pm.complete_chapter("ch2")
	pm.complete_chapter("ch3")
	_check(pm.is_chapter_completed("ch2") and pm.is_chapter_completed("ch3"),
		"ch4: ch2 & ch3 selesai berurutan")
	_check(pm.is_chapter_unlocked("ch4"), "ch4 terbuka setelah ch3 selesai")
	# Arena ch4 stage 4 (boss): pola charge di awal + label BOSS.
	gs.reset()
	gs.mode = gs.Mode.STORY
	gs.chapter_id = "ch4"
	gs.arena_id = "ch4"
	gs.stage_index = 3
	gs.player_id = "arga"
	var arena5 = arena_scene.instantiate()
	root.add_child(arena5)
	await _frames(10)
	_check(gstate.p2_character == "alaric_voss", "stage 4 ch4 lawannya alaric_voss")
	var ai5 = arena5.get_node("Fighter2").get_node_or_null("AIController")
	_check(ai5 != null and String(ai5.get("boss_pattern")) == "charge",
		"Voss fase 1 pola charge (dapat: %s)" % (String(ai5.get("boss_pattern")) if ai5 != null else "null"))
	var f2v = arena5.get_node("Fighter2")
	_check(f2v.max_health == 200, "Voss HP 200 (dapat %d)" % f2v.max_health)
	var stage_label5 = arena5.get("_stage_label")
	_check(stage_label5 != null and "CHAPTER 4" in String(stage_label5.text) and "BOSS" in String(stage_label5.text),
		"label ch4 boss tampil (dapat: %s)" % (stage_label5.text if stage_label5 != null else "null"))
	arena5.queue_free()
	await _frames(5)
	# Scaling: ch3 stage 2 (murid_dojo HP 100) -> 110.
	gs.reset()
	gs.mode = gs.Mode.STORY
	gs.chapter_id = "ch3"
	gs.arena_id = "ch3"
	gs.stage_index = 1
	gs.player_id = "arga"
	var arena6 = arena_scene.instantiate()
	root.add_child(arena6)
	await _frames(10)
	var f2s = arena6.get_node("Fighter2")
	_check(gstate.p2_character == "murid_dojo", "ch3 stage 2 lawannya murid_dojo (bukan pengawal_elit)")
	_check(f2s.max_health == 110, "scaling stage 2: murid HP 100 -> 110 (dapat %d)" % f2s.max_health)
	arena6.queue_free()
	await _frames(5)

	# Kembalikan progres asli pemain.
	pm.completed_chapters = orig_done
	pm.unlocked_chars = orig_chars
	pm.highest_chapter = orig_high
	pm.music_volume = orig_music
	pm.sfx_volume = orig_sfx
	pm.save_progress()
	gs.reset()
	_finish()


func _delayed_watchdog() -> void:
	var t := create_timer(150.0)
	await t.timeout
	printerr("[STORY] TIMEOUT 150 detik")
	quit(1)
