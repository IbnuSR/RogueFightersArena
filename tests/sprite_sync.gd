extends SceneTree
## Tes sinkronisasi gerakan vs sprite.
## Bug yang diperbaiki: tiap karakter yang berjalan memainkan animasi "run"
## padahal gerakannya jalan kaki (walk_speed) — sprite tidak sesuai gerakan.
## Tes ini memastikan:
##  1. Tiap scene fighters/characters/<id>.tscn valid & character_id benar.
##  2. Saat bergerak horizontal, animasi yang main = "walk" (bukan "run").
##  3. flip_h sprite konsisten dengan facing (selalu menghadap lawan).
##  4. Block menampilkan animasi "shield".
## Jalankan: godot --headless --path . --script res://tests/sprite_sync.gd

var failures: Array[String] = []


func _init() -> void:
	_run()


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("[SPRITESYNC] OK: ", msg)
	else:
		failures.append(msg)
		printerr("[SPRITESYNC] FAIL: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _pframes(n: int) -> void:
	for i in n:
		await physics_frame


func _delayed_watchdog() -> void:
	await create_timer(150.0).timeout
	printerr("[SPRITESYNC] WATCHDOG: tes tidak selesai dalam 150 detik, paksa keluar")
	quit(2)


func _make_floor() -> void:
	var sb := StaticBody2D.new()
	sb.name = "TestFloor"
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(4000, 100)
	cs.shape = rect
	cs.position = Vector2(0, 50)
	sb.add_child(cs)
	sb.position = Vector2(0, 600)
	root.add_child(sb)


func _wait_on_floor(f: Node, max_frames: int = 120) -> bool:
	for i in max_frames:
		if f.get("is_on_floor"):
			return true
		await physics_frame
	return false


func _run() -> void:
	print("[SPRITESYNC] mulai")
	_delayed_watchdog()
	await process_frame
	_make_floor()
	await process_frame

	var chars := ["samurai", "shinobi", "arga", "marco", "dmitri", "lin",
		"nok", "sora", "tyrone", "han", "valeria", "anika"]

	for cid in chars:
		# --- 1. Scene per karakter valid ---
		var ps: PackedScene = load("res://fighters/characters/%s.tscn" % cid)
		_check(ps != null, cid + ": scene ke-load")
		if ps == null:
			continue
		_check(ps.can_instantiate(), cid + ": scene bisa di-instance")
		var f: CharacterBody2D = ps.instantiate()
		f.position = Vector2(400, 300)
		root.add_child(f)
		# Lawan dummy di kanan (untuk uji facing)
		var foe: CharacterBody2D = ps.instantiate()
		foe.position = Vector2(900, 300)
		root.add_child(foe)
		await _frames(3)
		_check(f.get("character_id") == cid, cid + ": character_id benar")

		var sprite: AnimatedSprite2D = f.get_node("Sprite")
		_check(sprite.sprite_frames.get_animation_names().size() == 10,
			cid + ": 10 animasi terbangun")

		# Tunggu mendarat di lantai uji
		_check(await _wait_on_floor(f), cid + ": mendarat di lantai")
		f.set("can_fight", true)

		# --- 2. Jalan ke kanan -> animasi harus "walk", bukan "run" ---
		var ist: Dictionary = f.get("input_state")
		ist["right"] = true
		await _pframes(30)
		_check(absf(f.get("velocity").x) > 10.0, cid + ": benar-benar bergerak")
		_check(sprite.animation == &"walk",
			cid + ": jalan pakai anim 'walk' (dapat '%s')" % sprite.animation)

		# --- 3. Facing: lawan di kanan -> facing=1, flip_h=false ---
		await _pframes(5)
		_check(f.get("facing") == 1, cid + ": menghadap kanan (lawan di kanan)")
		_check(sprite.flip_h == false, cid + ": flip_h=false saat facing=1")
		# Pindah lawan ke kiri -> facing=-1, flip_h=true
		foe.position = Vector2(f.position.x - 500, 300)
		await _pframes(5)
		_check(f.get("facing") == -1, cid + ": menghadap kiri (lawan di kiri)")
		_check(sprite.flip_h == true, cid + ": flip_h=true saat facing=-1")

		# --- 4. Block -> animasi "shield" ---
		ist["right"] = false
		ist["block"] = true
		await _pframes(10)
		_check(sprite.animation == &"shield",
			cid + ": block pakai anim 'shield' (dapat '%s')" % sprite.animation)

		f.queue_free()
		foe.queue_free()
		await _frames(2)

	if failures.is_empty():
		print("[SPRITESYNC] SEMUA TES LOLOS")
		quit(0)
	else:
		printerr("[SPRITESYNC] %d TES GAGAL" % failures.size())
		quit(1)
