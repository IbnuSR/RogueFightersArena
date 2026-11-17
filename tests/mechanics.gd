extends SceneTree
## Tes mekanik GDD v2.0 + wiring musuh/boss palette-swap.
## Jalankan: godot --headless --path . --script res://tests/mechanics.gd

var failures: Array[String] = []


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("[MECH] OK: ", msg)
	else:
		failures.append(msg)
		printerr("[MECH] FAIL: ", msg)


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


func _wait_on_floor(f) -> bool:
	for i in 240:
		if f.is_on_floor():
			return true
		await physics_frame
	return false


func _mk(cid: String, x: float) -> Node:
	var ps: PackedScene = load("res://fighters/characters/%s.tscn" % cid)
	var f = ps.instantiate()
	f.position = Vector2(x, 300)
	root.add_child(f)
	await process_frame
	return f


func _free(f) -> void:
	f.queue_free()
	await process_frame
	await process_frame


func _run() -> void:
	await process_frame
	_make_floor()
	var f1 = await _mk("samurai", 400)
	var f2 = await _mk("samurai", 490)
	_check(await _wait_on_floor(f1) and await _wait_on_floor(f2), "kedua petarung mendarat")
	f1.set("can_fight", true)
	f2.set("can_fight", true)
	await _pframes(5)
	f1.set("opponent", f2)
	f2.set("opponent", f1)

	# --- 1. Hitstun + knockback + meter korban ---
	var hp0: int = f2.get("health")
	var x0: float = f2.global_position.x
	f2.take_damage(10, f1, "attack_1")
	_check(f2.get("health") == hp0 - 10, "take_damage 10 mengurangi HP 100->90 (dapat %d)" % f2.get("health"))
	_check(f2.get("hitstun_timer") > 0.2, "hitstun aktif (%.2f dtk)" % f2.get("hitstun_timer"))
	_check(f2.get("velocity").x > 100.0, "knockback mendorong menjauh (vx=%.0f)" % f2.get("velocity").x)
	_check(f2.get("meter") >= 8.0, "meter korban +8 saat terkena (%.0f)" % f2.get("meter"))
	_check(bool(f2.get("is_hurt")), "is_hurt=true saat hitstun")
	await _pframes(30)
	_check(f2.global_position.x > x0 + 5.0, "badan benar-benar berpindah karena knockback (%.1f -> %.1f)" % [x0, f2.global_position.x])
	_check(not bool(f2.get("is_hurt")), "hitstun habis setelah ~0.5 dtk")

	# --- 2. Blockstun + chip damage ---
	f2.set("health", 100)
	var ist2: Dictionary = f2.get("input_state")
	ist2["block"] = true
	await _pframes(3)
	f2.take_damage(15, f1, "attack_3")
	_check(f2.get("health") == 98, "attack_3 ditangkis: chip 2 saja, HP 100->98 (dapat %d)" % f2.get("health"))
	_check(f2.get("blockstun_timer") > 0.0, "blockstun aktif (%.2f)" % f2.get("blockstun_timer"))
	_check(f2.get("meter") >= 12.0, "meter +4 saat menangkis (%.0f)" % f2.get("meter"))
	f2.take_damage(6, f1, "attack_1")
	_check(f2.get("health") == 98, "attack_1 ditangkis: tanpa chip, HP tetap 98")
	# Chip tidak bisa membunuh
	f2.set("health", 1)
	f2.take_damage(15, f1, "attack_3")
	_check(f2.get("health") == 1, "chip tidak bisa membunuh (HP tetap 1)")
	ist2["block"] = false
	# Blockstun mengunci gerak
	f2.set("health", 100)
	ist2["block"] = true
	await _pframes(3)
	f2.take_damage(6, f1, "attack_1")
	ist2["block"] = false
	ist2["right"] = true
	await _pframes(5)
	_check(absf(f2.get("velocity").x) < 20.0, "blockstun mengunci gerak (vx=%.1f)" % f2.get("velocity").x)
	ist2["right"] = false
	await _pframes(20)

	# --- 3. Kombo + damage scaling ---
	# current_damage diset manual = damage dasar attack_1 penyerang.
	f1.set("combo_count", 0)
	f1.set("current_damage", 6)
	f1.set("current_attack_name", "attack_1")
	f2.set("hitstun_timer", 0.0)
	var d1: int = f1._compute_hit_damage(f2)  # f2 tidak hitstun -> hit ke-1
	_check(d1 == 6, "kombo hit ke-1: 100%% = 6 dmg (dapat %d)" % d1)
	_check(f1.get("combo_count") == 1 and f1.get("last_combo") == 1, "combo_count=1, last_combo=1")
	f2.set("hitstun_timer", 0.3)  # masih hitstun -> kombo berlanjut
	var d2: int = f1._compute_hit_damage(f2)
	_check(d2 == 5, "kombo hit ke-2: 85%% = 5 dmg (dapat %d)" % d2)
	var d3: int = f1._compute_hit_damage(f2)
	_check(d3 == 4, "kombo hit ke-3: 70%% = 4 dmg (dapat %d)" % d3)
	_check(f1.get("last_combo") == 3, "last_combo=3")
	f2.set("hitstun_timer", 0.0)
	# Reset kombo setelah 0.5 dtk tanpa hit
	f1.set("combo_reset_timer", 0.05)
	await _pframes(10)
	_check(f1.get("combo_count") == 0, "kombo reset setelah >0.5 dtk tanpa hit")
	# Lin: scaling lebih ringan (attack_1 dasar int(6*0.8)=4)
	var fl = await _mk("lin", 700)
	fl.set("combo_count", 0)
	fl.set("current_damage", 4)
	fl.set("current_attack_name", "attack_1")
	f2.set("hitstun_timer", 0.0)
	var ld1: int = fl._compute_hit_damage(f2)
	f2.set("hitstun_timer", 0.3)
	var ld2: int = fl._compute_hit_damage(f2)
	_check(ld1 == 4 and ld2 == 4, "Lin: hit ke-1 4 dmg, hit ke-2 95%% tetap 4 (dapat %d/%d)" % [ld1, ld2])
	await _free(fl)
	f2.set("hitstun_timer", 0.0)

	# --- 4. Meter + special ---
	f1.set("meter", 100.0)
	var ist1: Dictionary = f1.get("input_state")
	ist1["special"] = true
	await _pframes(3)
	_check(f1.get("meter") == 0.0, "special mengosongkan meter 100->0")
	_check(bool(f1.get("is_attacking")), "special memicu serangan")
	_check(bool(f1.get("current_is_special")), "flag current_is_special=true")
	var ds: int = f1._compute_hit_damage(f2)
	_check(ds == 25, "special damage flat 25, tidak kena scaling (dapat %d)" % ds)
	await _pframes(60)
	# Special tanpa meter: tidak jalan
	f1.set("meter", 50.0)
	f1.set("is_attacking", false)
	ist1["special"] = true
	await _pframes(3)
	_check(not bool(f1.get("is_attacking")) and f1.get("meter") == 50.0, "special ditolak saat meter <100")

	# --- 5. Throw menembus block (jarak 90px, dalam THROW_RANGE 100) ---
	f1.set("throw_cd", 0.0)
	f2.set("health", 100)
	f2.global_position = Vector2(f1.global_position.x + 90.0, f2.global_position.y)
	ist2["block"] = true
	await _pframes(3)
	f1._try_throw()
	_check(f2.get("health") == 92, "throw menembus block: 8 dmg (dapat HP %d)" % f2.get("health"))
	_check(f1.get("throw_cd") > 0.5, "throw cooldown 1 dtk (%.2f)" % f1.get("throw_cd"))
	_check(f2.get("hitstun_timer") >= 0.55, "throw knockdown 0.6 dtk (%.2f)" % f2.get("hitstun_timer"))
	ist2["block"] = false
	await _pframes(40)
	# Throw gagal kalau lawan tidak block
	f1.set("throw_cd", 0.0)
	f2.set("health", 100)
	f2.global_position = Vector2(f1.global_position.x + 90.0, f2.global_position.y)
	await _pframes(3)
	f1._try_throw()
	_check(f2.get("health") == 100, "throw gagal saat lawan tidak block")
	# Dmitri: throw 14
	var fd = await _mk("dmitri", 800)
	var f3 = await _mk("samurai", 890)
	_check(await _wait_on_floor(fd) and await _wait_on_floor(f3), "dmitri & korban mendarat")
	fd.set("can_fight", true)
	f3.set("can_fight", true)
	fd.set("opponent", f3)
	var ist3: Dictionary = f3.get("input_state")
	ist3["block"] = true
	await _pframes(5)
	fd._try_throw()
	_check(f3.get("health") == 86, "Dmitri throw 14 dmg (dapat HP %d)" % f3.get("health"))
	await _free(fd)
	await _free(f3)

	# --- 6. Jongkok: state terpisah, attack_3 miss ---
	ist2["crouch"] = true
	ist2["block"] = false
	await _pframes(5)
	_check(bool(f2.get("is_crouching")), "jongkok aktif lewat input crouch")
	var shape = f2.get_node("CollisionShape2D").shape as RectangleShape2D
	_check(shape.size.y == 110.0, "collision jongkok 110px (dapat %.0f)" % shape.size.y)
	var hp_before: int = f2.get("health")
	f2.take_damage(15, f1, "attack_3")
	_check(f2.get("health") == hp_before, "attack_3 MISS lawan jongkok (HP tetap %d)" % hp_before)
	f2.take_damage(6, f1, "attack_1")
	_check(f2.get("health") == hp_before - 6, "attack_1 tetap kena lawan jongkok")
	await _pframes(20)  # tunggu hitstun + knockback dari pukulan tadi habis
	# Jongkok mengunci gerak (samurai)
	ist2["right"] = true
	await _pframes(5)
	_check(absf(f2.get("velocity").x) < 20.0, "jongkok mengunci gerak (vx=%.1f)" % f2.get("velocity").x)
	ist2["right"] = false
	ist2["crouch"] = false
	await _pframes(5)
	_check(not bool(f2.get("is_crouching")) and shape.size.y == 180.0, "berdiri lagi: collision 180px")

	# --- 7. Trait: Arga stance, Sora counter, Nok dekat ---
	var fa = await _mk("arga", 200)
	var fb = await _mk("samurai", 290)
	_check(await _wait_on_floor(fa) and await _wait_on_floor(fb), "arga & lawan mendarat")
	fa.set("can_fight", true)
	fb.set("can_fight", true)
	fa.set("opponent", fb)
	fb.set("opponent", fa)
	_check(String(fa.get("stance_name")) == "menyerang", "Arga stance awal menyerang")
	var ista: Dictionary = fa.get("input_state")
	ista["block"] = true
	await _pframes(3)
	fa.take_damage(6, fb, "attack_1")
	_check(String(fa.get("stance_name")) == "bertahan", "Arga ganti stance -> bertahan setelah 1x block")
	fa.take_damage(6, fb, "attack_1")
	_check(String(fa.get("stance_name")) == "menyerang", "Arga ganti stance -> menyerang setelah 2x block")
	ista["block"] = false
	await _free(fa)
	await _free(fb)
	# Sora counter: perfect block -> buff -> serangan +50%
	var fs = await _mk("sora", 1000)
	var ft = await _mk("samurai", 1090)
	_check(await _wait_on_floor(fs) and await _wait_on_floor(ft), "sora & lawan mendarat")
	fs.set("can_fight", true)
	ft.set("can_fight", true)
	fs.set("opponent", ft)
	ft.set("opponent", fs)
	var ists: Dictionary = fs.get("input_state")
	ists["block"] = true
	await _pframes(2)
	fs.take_damage(6, ft, "attack_1")  # perfect block (baru mulai <0.15 dtk)
	_check(bool(fs.get("counter_buff")), "Sora perfect block -> counter_buff=true")
	ists["block"] = false
	fs.set("current_damage", 6)
	fs.set("current_attack_name", "attack_1")
	fs.set("combo_count", 0)
	var sdmg: int = fs._compute_hit_damage(ft)
	_check(sdmg == 9, "Sora serangan balasan +50%% = 9 dmg (dapat %d)" % sdmg)
	_check(not bool(fs.get("counter_buff")), "counter_buff habis setelah 1x pakai")
	await _free(fs)
	await _free(ft)
	# Nok jarak dekat +25% (jarak 90px < 100)
	var fn = await _mk("nok", 400)
	var fo = await _mk("samurai", 490)
	_check(await _wait_on_floor(fn) and await _wait_on_floor(fo), "nok & lawan mendarat")
	fn.set("opponent", fo)
	fn.set("current_damage", 10)
	fn.set("current_attack_name", "attack_2")
	var ndmg: int = fn._compute_hit_damage(fo)
	_check(ndmg == 12 or ndmg == 13, "Nok jarak <100px damage +25%% (10 -> %d)" % ndmg)
	await _free(fn)
	await _free(fo)

	# --- 8. Integrasi nyata: attack_1 lewat input kena lawan ---
	f1.set("combo_count", 0)
	f2.set("health", 100)
	f2.set("hitstun_timer", 0.0)
	f2.set("blockstun_timer", 0.0)
	f2.global_position = Vector2(f1.global_position.x + 90.0, f2.global_position.y)
	await _pframes(3)
	ist1["attack_1"] = true
	await _pframes(30)
	_check(f2.get("health") < 100, "attack_1 via input nyata mengenai lawan (HP %d)" % f2.get("health"))
	_check(f1.get("last_combo") >= 1, "last_combo tercatat (>=1, dapat %d)" % f1.get("last_combo"))
	_check(f1.get("meter") > 0.0, "meter penyerang terisi saat kena (%.0f)" % f1.get("meter"))

	# --- 9. reset_for_next_round membersihkan state ---
	f1.reset_for_next_round()
	_check(f1.get("meter") == 0.0 and f1.get("combo_count") == 0 and f1.get("hitstun_timer") == 0.0, "reset ronde: meter/kombo/hitstun nol")
	_check(f1.get("health") == f1.get("max_health") and not bool(f1.get("is_dead")), "reset ronde: HP penuh, hidup lagi")

	# --- 10. Wiring musuh & boss (musuh = palette-swap per GDD §7,
	# boss = badan asli prosedural, lihat docs/ASSET_NOTES.md) ---
	# Tiap id baru harus ke-load via set_character: 10 animasi, dead tidak
	# looping, skala idle sesuai manifest, HP sesuai .tres.
	var _wiring := {
		"buruh_bayaran": {"hp": 120, "scale": 1.132, "idle": 6, "walk": 24, "a1": 21, "dead": 4},
		"penyelundup": {"hp": 85, "scale": 1.263, "idle": 6, "walk": 12, "a1": 11, "dead": 4},
		"geng_jalanan": {"hp": 95, "scale": 1.206, "idle": 6, "walk": 12, "a1": 11, "dead": 4},
		"akrobat": {"hp": 85, "scale": 1.218, "idle": 6, "walk": 12, "a1": 11, "dead": 4},
		"murid_dojo": {"hp": 100, "scale": 1.124, "idle": 6, "walk": 12, "a1": 11, "dead": 4},
		"pengawal_elit": {"hp": 115, "scale": 2.909, "idle": 6, "walk": 8, "a1": 7, "dead": 3},
		"kapten_brak": {"hp": 160, "scale": 1.983, "idle": 10, "walk": 8, "a1": 7, "dead": 3},
		"ular_neon": {"hp": 130, "scale": 1.091, "idle": 6, "walk": 8, "a1": 7, "dead": 3},
		"guru_sunyi": {"hp": 150, "scale": 1.091, "idle": 6, "walk": 8, "a1": 7, "dead": 3},
		"alaric_voss": {"hp": 200, "scale": 1.091, "idle": 6, "walk": 8, "a1": 7, "dead": 3},
	}
	for _cid in _wiring:
		var _exp: Dictionary = _wiring[_cid]
		var _bps: PackedScene = load("res://fighters/fighter.tscn")
		var _bf: CharacterBody2D = _bps.instantiate()
		_bf.position = Vector2(400, 300)
		root.add_child(_bf)
		await process_frame
		await process_frame
		_bf.set_character(_cid)
		var _bs: AnimatedSprite2D = _bf.get_node("Sprite")
		# Skala dicek SEGERA setelah set_character (sinkron): begitu ada
		# physics frame, _update_animation bisa mengganti animasi ke "jump"
		# (petarung tes ini masih jatuh) dan skalanya jadi anim_fix jump.
		_check(absf(_bs.scale.x - float(_exp["scale"])) < 0.01, _cid + ": skala idle %.3f" % float(_exp["scale"]))
		await process_frame
		var _bsf: SpriteFrames = _bs.sprite_frames
		_check(_bf.get("character_id") == _cid, _cid + ": character_id benar")
		_check(_bsf.get_animation_names().size() == 10, _cid + ": 10 animasi terbangun")
		_check(_bsf.get_frame_count("idle") == int(_exp["idle"]), _cid + ": idle %d frame" % int(_exp["idle"]))
		_check(_bsf.get_frame_count("walk") == int(_exp["walk"]), _cid + ": walk %d frame" % int(_exp["walk"]))
		_check(_bsf.get_frame_count("attack_1") == int(_exp["a1"]), _cid + ": attack_1 %d frame" % int(_exp["a1"]))
		_check(_bsf.get_frame_count("dead") == int(_exp["dead"]), _cid + ": dead %d frame" % int(_exp["dead"]))
		_check(_bsf.get_animation_loop("dead") == false, _cid + ": dead tidak looping")
		_check(_bf.get("max_health") == int(_exp["hp"]), _cid + ": HP %d sesuai .tres" % int(_exp["hp"]))
		_bf.queue_free()
		await process_frame
		await process_frame
	if failures.is_empty():
		print("[MECH] SEMUA TES LOLOS")
		quit(0)
	else:
		printerr("[MECH] %d TES GAGAL" % failures.size())
		quit(1)


func _init() -> void:
	_run()
