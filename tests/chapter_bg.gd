extends SceneTree
## Tes background chapter Story Mode (11 Nov 2026).
## Jalankan: godot --headless --path . --script res://tests/chapter_bg.gd
## Memastikan tiap chapter punya arena_bg yang ter-load (3840x2160),
## dan arena memakai background chapter itu saat GameSession.arena_id diisi
## (bukan latar lama yang berputar tiap ronde).

var failures: Array[String] = []


func _init() -> void:
	_run()


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("[CHBG] OK: ", msg)
	else:
		failures.append(msg)
		printerr("[CHBG] FAIL: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _finish() -> void:
	if failures.is_empty():
		print("[CHBG] SEMUA TES LOLOS")
	else:
		printerr("[CHBG] %d TES GAGAL" % failures.size())
	quit(1 if not failures.is_empty() else 0)


func _run() -> void:
	print("[CHBG] mulai")
	_delayed_watchdog()
	await process_frame

	var expected := {
		"ch1": "res://assets/backgrounds/dermaga.png",
		"ch2": "res://assets/backgrounds/lorong_neon.png",
		"ch3": "res://assets/backgrounds/dojo_bayangan.png",
		"ch4": "res://assets/backgrounds/menara_voss.png",
	}
	for ch_id in expected.keys():
		var chapter: ChapterData = load("res://data/chapters/%s.tres" % ch_id)
		_check(chapter != null, "%s.tres ke-load" % ch_id)
		if chapter == null:
			continue
		_check(chapter.arena_bg == expected[ch_id], "%s arena_bg = %s" % [ch_id, expected[ch_id]])
		var tex: Texture2D = load(chapter.arena_bg) if chapter.arena_bg != "" else null
		_check(tex != null, "%s background ke-load" % ch_id)
		if tex:
			_check(tex.get_width() == 3840 and tex.get_height() == 2160,
				"%s ukuran 3840x2160 (dapat %dx%d)" % [ch_id, tex.get_width(), tex.get_height()])

	# Arena memakai background chapter saat GameSession.arena_id diisi.
	var gs = root.get_node_or_null("GameSession")
	_check(gs != null, "autoload GameSession ada")
	if gs != null:
		gs.arena_id = "ch1"
		gs.mode = gs.Mode.STORY
		var arena_scene: PackedScene = load("res://arenas/arena_test.tscn")
		_check(arena_scene != null, "arena_test.tscn ke-load")
		if arena_scene != null:
			var arena = arena_scene.instantiate()
			root.add_child(arena)
			await _frames(10)
			var bg = arena.get_node_or_null("Background")
			_check(bg != null, "node Background ada")
			if bg != null:
				_check(bg.texture != null and bg.texture.resource_path == "res://assets/backgrounds/dermaga.png",
					"arena ch1 memakai dermaga.png (dapat %s)" % (bg.texture.resource_path if bg.texture else "null"))
			arena.queue_free()
			await _frames(5)
		# Mode bebas tanpa arena_id tetap memakai latar lama (tidak crash).
		gs.arena_id = ""
		gs.mode = gs.Mode.FREE_FIGHT
		var arena2 = arena_scene.instantiate()
		root.add_child(arena2)
		await _frames(10)
		var bg2 = arena2.get_node_or_null("Background")
		_check(bg2 != null and bg2.texture != null, "arena free fight tetap punya background")
		arena2.queue_free()
		gs.reset()
	_finish()


func _delayed_watchdog() -> void:
	# Pengaman: paksa keluar setelah 60 detik agar tidak menggantung.
	var t := create_timer(60.0)
	await t.timeout
	printerr("[CHBG] TIMEOUT 60 detik")
	quit(1)
