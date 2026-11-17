extends SceneTree
## Render preview (dev tool, bukan tes): peta chapter 4 kartu, pilih
## karakter Free Fight, dan arena boss Ch4 (Voss). Jalankan dengan xvfb:
##   xvfb-run -a godot --path . --script res://tools/render_preview.gd

func _init() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(path)
	print("SHOT: ", path)


func _run() -> void:
	await process_frame
	var gs = root.get_node_or_null("GameSession")
	var pm = root.get_node_or_null("ProgressManager")

	# 1. Peta chapter: ch1-ch3 selesai supaya ch4 terbuka.
	pm.completed_chapters = ["ch1", "ch2", "ch3"]
	pm.unlocked_chars = ["samurai", "arga", "marco", "buruh_bayaran", "penyelundup",
		"geng_jalanan", "akrobat", "murid_dojo", "pengawal_elit",
		"kapten_brak", "ular_neon", "guru_sunyi"]
	pm.highest_chapter = 3
	var map_scene: PackedScene = load("res://ui/chapter_map/chapter_map.tscn")
	var cmap = map_scene.instantiate()
	root.add_child(cmap)
	await _frames(10)
	await _shot("/home/hatch/workspace/rfa-project/preview-chapter-map-v2.png")
	cmap.queue_free()
	await _frames(5)

	# 2. Pilih karakter Free Fight: semua 22 bisa dipilih.
	gs.reset()
	gs.mode = gs.Mode.FREE_FIGHT
	var sel_scene: PackedScene = load("res://ui/character_select/character_select.tscn")
	var sel = sel_scene.instantiate()
	root.add_child(sel)
	await _frames(10)
	await _shot("/home/hatch/workspace/rfa-project/preview-pilih-karakter-v2.png")
	sel.queue_free()
	await _frames(5)

	# 3. Arena Ch4 stage 4 (boss Voss) di Menara Voss.
	gs.reset()
	gs.mode = gs.Mode.STORY
	gs.chapter_id = "ch4"
	gs.arena_id = "ch4"
	gs.stage_index = 3
	gs.player_id = "arga"
	var arena_scene: PackedScene = load("res://arenas/arena_test.tscn")
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	await _frames(10)
	await create_timer(7.0).timeout
	await _frames(10)
	await _shot("/home/hatch/workspace/rfa-project/preview-arena-voss.png")
	quit(0)
