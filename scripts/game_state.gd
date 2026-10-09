extends Node
## GameState (autoload): menyimpan pilihan pemain dari menu utama
## dan dipakai arena untuk mengkonfigurasi pertandingan.

const MODE_ARCADE := "arcade"   # 1 pemain melawan AI
const MODE_VERSUS := "versus"   # 2 pemain di keyboard yang sama

var mode: String = MODE_ARCADE
var difficulty: int = 1  # 0 = MUDAH, 1 = NORMAL, 2 = SUSAH
var p1_character: String = "samurai"
var p2_character: String = "shinobi"

const DIFFICULTY_NAMES := ["MUDAH", "NORMAL", "SUSAH"]

# Parameter AI per tingkat kesulitan (cocok dengan @export di ai_controller.gd)
const DIFFICULTY_PARAMS := [
	{"agresivitas": 0.35, "waktu_reaksi": 0.7, "peluang_tangkis": 0.15},
	{"agresivitas": 0.6, "waktu_reaksi": 0.4, "peluang_tangkis": 0.3},
	{"agresivitas": 0.9, "waktu_reaksi": 0.18, "peluang_tangkis": 0.5},
]


func apply_difficulty(ai: Node) -> void:
	var p: Dictionary = DIFFICULTY_PARAMS[clampi(difficulty, 0, 2)]
	ai.set("agresivitas", p["agresivitas"])
	ai.set("waktu_reaksi", p["waktu_reaksi"])
	ai.set("peluang_tangkis", p["peluang_tangkis"])


func p1_label() -> String:
	if mode == MODE_VERSUS:
		return "PEMAIN 1"
	return "KAMU"


func p2_label() -> String:
	if mode == MODE_VERSUS:
		return "PEMAIN 2"
	return "MUSUH"


func winner_text(p1_won: bool) -> String:
	if mode == MODE_VERSUS:
		return "PEMAIN 1 MENANG!" if p1_won else "PEMAIN 2 MENANG!"
	return "KAMU MENANG!" if p1_won else "MUSUH MENANG!"
