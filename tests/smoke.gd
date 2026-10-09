extends SceneTree
## Smoke test headless: memastikan semua scene bisa dibuka tanpa error.
## Jalankan: godot --headless --path . --script res://tests/smoke.gd

var failures: Array[String] = []


func _init() -> void:
	_run()


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("[SMOKE] OK: ", msg)
	else:
		failures.append(msg)
		printerr("[SMOKE] FAIL: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


# Menunggu sampai kondisi terpenuhi (maks ~20 detik), untuk menunggu
# timer real-time seperti KO slow-mo dan jeda antar ronde.
func _wait_until(cond: Callable, max_frames: int = 1200) -> void:
	for i in max_frames:
		if cond.call():
			return
		await process_frame
	printerr("[SMOKE] TIMEOUT menunggu kondisi")


func _run() -> void:
	print("[SMOKE] mulai")
	# Pengaman: paksa keluar setelah 150 detik agar tidak menggantung selamanya
	_delayed_watchdog()
	await process_frame
	_check(root.has_node("GameState"), "autoload GameState ada")
	_check(root.has_node("Audio"), "autoload Audio ada")
	var audio = root.get_node_or_null("Audio")
	if audio:
		_check(audio._streams.size() >= 11, "audio ke-load: %d stream" % audio._streams.size())
	var gs = root.get_node_or_null("GameState")

	# 1. Menu utama
	var menu_scene: PackedScene = load("res://scenes/main_menu.tscn")
	_check(menu_scene != null, "main_menu.tscn ke-load")
	var menu = menu_scene.instantiate()
	root.add_child(menu)
	await _frames(5)
	_check(menu.has_node("Center/VBox/ModeRow/Btn1P"), "tombol 1P ada")
	_check(menu.has_node("Center/VBox/BtnStart"), "tombol start ada")

	# 2. Masuk arena (mode arcade default)
	menu._on_start()
	await _frames(30)
	var arena = current_scene
	_check(arena != null and arena.name == "ArenaTest", "arena terbuka")
	if arena == null:
		_finish()
		return
	var f1 = arena.get_node("Fighter")
	var f2 = arena.get_node("Fighter2")
	_check(f1.get_node("Sprite").sprite_frames.get_animation_names().size() == 10, "P1 punya 10 animasi")
	_check(f2.get_node("Sprite").sprite_frames.get_animation_names().size() == 10, "P2 punya 10 animasi")
	_check(f2.has_node("AIController"), "mode arcade: AIController ada")
	_check(arena.has_node("Camera2D"), "kamera ada")
	_check(arena.has_node("HUD/TimerLabel"), "timer HUD ada")
	_check(arena.has_node("OverlayLayer/PauseMenu"), "menu pause ada")
	_check(arena.has_node("OverlayLayer/GameOverMenu"), "menu game over ada")

	# 3. Simulasi K.O. -> ronde selesai -> menang 2x -> game over
	arena.round_active = true
	arena._on_fighter_died(f2)
	await _wait_until(func(): return arena.p1_wins >= 1)
	_check(arena.p1_wins == 1, "P1 menang ronde 1 (KO)")
	arena.round_active = true
	arena._on_fighter_died(f2)
	await _wait_until(func(): return arena.match_over)
	_check(arena.p1_wins == 2, "P1 menang ronde 2 (KO)")
	_check(arena.match_over, "match_over = true")
	_check(arena.get_node("OverlayLayer/GameOverMenu").visible, "panel game over muncul")

	# 4. Timeout: P2 dilukai dulu, waktu habis -> P1 menang ronde
	arena._on_restart()
	await _frames(30)
	arena = current_scene
	f2 = arena.get_node("Fighter2")
	f2.take_damage(60)
	arena.round_active = true
	arena.time_left = 0.05
	await _wait_until(func(): return arena.p1_wins >= 1)
	_check(arena.p1_wins == 1, "timeout: P1 menang ronde (nyawa lebih banyak)")

	# 5. Mode versus: AI diganti HumanController P2
	gs.mode = "versus"
	arena._on_restart()
	await _frames(30)
	arena = current_scene
	var f2v = arena.get_node("Fighter2")
	_check(not f2v.has_node("AIController"), "mode versus: AIController dibuang")
	var hc = f2v.get_node_or_null("HumanController")
	_check(hc != null and hc.get("input_prefix") == "p2", "P2 pakai HumanController (p2)")

	# 6. Ganti karakter
	gs.p1_character = "shinobi"
	gs.p2_character = "samurai"
	arena._on_restart()
	await _frames(30)
	arena = current_scene
	_check(arena.get_node("Fighter").get("character_id") == "shinobi", "P1 jadi shinobi")
	_check(arena.get_node("Fighter2").get("character_id") == "samurai", "P2 jadi samurai")

	_finish()


func _delayed_watchdog() -> void:
	await create_timer(150.0).timeout
	printerr("[SMOKE] WATCHDOG: tes tidak selesai dalam 150 detik, paksa keluar")
	quit(2)


func _finish() -> void:
	if failures.is_empty():
		print("[SMOKE] SEMUA TES LOLOS")
		quit(0)
	else:
		printerr("[SMOKE] %d TES GAGAL" % failures.size())
		quit(1)
