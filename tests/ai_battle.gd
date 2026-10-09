extends SceneTree
## Tes AI vs AI: pastikan AI baru bertarung tanpa error selama 30 detik.

func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	await process_frame
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		printerr("[AIBATTLE] GameState tidak ada")
		quit()
		return
	gs.mode = "arcade"
	gs.difficulty = 1
	gs.p1_character = "dmitri"
	gs.p2_character = "lin"
	var arena_scene: PackedScene = load("res://arenas/arena_test.tscn")
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	await create_timer(1.0).timeout
	# Paksa kedua fighter pakai AI
	for fname in ["Fighter", "Fighter2"]:
		var f = arena.get_node(fname)
		if f.get_node_or_null("HumanController"):
			f.get_node("HumanController").queue_free()
		var ai = load("res://ai_controller.gd").new()
		ai.agresivitas = 0.8
		f.add_child(ai)
	print("[AIBATTLE] mulai simulasi 30 detik")
	for i in range(30):
		await create_timer(1.0).timeout
		var f1 = arena.get_node("Fighter")
		var f2 = arena.get_node("Fighter2")
		if i % 10 == 9:
			print("[AIBATTLE] t=%ds HP: %d vs %d" % [i + 1, f1.get("health"), f2.get("health")])
	var f1e = arena.get_node("Fighter")
	var f2e = arena.get_node("Fighter2")
	print("[AIBATTLE] SELESAI. HP akhir: %d vs %d" % [f1e.get("health"), f2e.get("health")])
	quit()
