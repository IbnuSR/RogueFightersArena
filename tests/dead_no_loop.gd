extends SceneTree
## Tes animasi mati tidak looping (regressi 10 Nov 2026).
## Bug: "dead" di-set loop=true seperti animasi lain, jadi karakter yang
## sudah pingsan bangun lagi (frame awal = berdiri) lalu tidur lagi,
## berulang-ulang. Tes ini memastikan untuk semua 12 karakter:
##  1. SpriteFrames "dead" tidak looping, animasi lain tetap looping.
##  2. Setelah KO, animasi "dead" main sampai frame terakhir lalu BERHENTI
##     di sana (tidak kembali ke frame 0 / berdiri lagi) meski ditunggu
##     3 detik setelah animasinya selesai.
##  3. reset_for_next_round() menghidupkan lagi (animasi kembali "idle").
## Jalankan: godot --headless --path . --script res://tests/dead_no_loop.gd

var failures: Array[String] = []


func _init() -> void:
	_run()


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("[DEADLOOP] OK: ", msg)
	else:
		failures.append(msg)
		printerr("[DEADLOOP] FAIL: ", msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _pframes(n: int) -> void:
	for i in n:
		await physics_frame


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


func _delayed_watchdog() -> void:
	await create_timer(150.0).timeout
	printerr("[DEADLOOP] WATCHDOG: tes tidak selesai dalam 150 detik, paksa keluar")
	quit(2)


func _run() -> void:
	print("[DEADLOOP] mulai")
	_delayed_watchdog()
	await process_frame
	_make_floor()
	await process_frame

	var chars := ["samurai", "shinobi", "arga", "marco", "dmitri", "lin",
		"nok", "sora", "tyrone", "han", "valeria", "anika"]

	for cid in chars:
		var ps: PackedScene = load("res://fighters/characters/%s.tscn" % cid)
		_check(ps != null, cid + ": scene ke-load")
		if ps == null:
			continue
		var f: CharacterBody2D = ps.instantiate()
		f.position = Vector2(400, 300)
		root.add_child(f)
		await _frames(3)
		var sprite: AnimatedSprite2D = f.get_node("Sprite")
		var sf: SpriteFrames = sprite.sprite_frames
		_check(sf.get_animation_loop("dead") == false,
			cid + ": anim 'dead' tidak looping")
		_check(sf.get_animation_loop("idle") == true,
			cid + ": anim 'idle' tetap looping")
		_check(sf.get_animation_loop("walk") == true,
			cid + ": anim 'walk' tetap looping")

		# KO-kan petarung (take_damage jalan sendiri sebagai coroutine)
		f.take_damage(99999)
		# hurt 0,2 dtk + dead paling lama 8 frame @6fps = 1,33 dtk,
		# tunggu 2 dtk: animasi mati pasti sudah selesai.
		await create_timer(2.0).timeout
		_check(f.get("is_dead") == true, cid + ": is_dead=true setelah KO")
		_check(sprite.animation == &"dead",
			cid + ": animasi 'dead' sedang main (dapat '%s')" % sprite.animation)
		var last: int = sf.get_frame_count("dead") - 1
		_check(sprite.frame == last,
			cid + ": berhenti di frame terakhir dead (%d)" % last)
		# Tunggu 3 detik lagi: kalau masih looping, frame sudah kembali ke 0.
		await create_timer(3.0).timeout
		_check(sprite.animation == &"dead",
			cid + ": 3 detik kemudian masih anim 'dead'")
		_check(sprite.frame == last,
			cid + ": 3 detik kemudian tetap di frame terakhir (%d), tidak bangun lagi" % last)

		# Ronde baru: harus hidup lagi dan kembali idle.
		# reset_for_next_round() langsung memainkan "idle"; setelah
		# mendarat di lantai, _update_animation juga harus memberi "idle"
		# (bukan "jump" — itu cuma karena petarung tes ini masih jatuh).
		f.reset_for_next_round()
		_check(sprite.animation == &"idle",
			cid + ": reset -> langsung main 'idle' (dapat '%s')" % sprite.animation)
		_check(await _wait_on_floor(f), cid + ": mendarat di lantai setelah reset")
		await _frames(3)
		_check(f.get("is_dead") == false, cid + ": reset -> is_dead=false")
		_check(sprite.animation == &"idle",
			cid + ": reset -> kembali anim 'idle' (dapat '%s')" % sprite.animation)

		f.queue_free()
		await _frames(2)

	if failures.is_empty():
		print("[DEADLOOP] SEMUA TES LOLOS")
		quit(0)
	else:
		printerr("[DEADLOOP] %d TES GAGAL" % failures.size())
		quit(1)
