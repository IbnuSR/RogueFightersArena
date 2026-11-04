extends Node

enum Mode { NONE, STORY, FREE_FIGHT }

var mode: Mode = Mode.NONE
var player_id: String = ""
var opponent_id: String = ""
var arena_id: String = ""


func reset() -> void:
	mode = Mode.NONE
	player_id = ""
	opponent_id = ""
	arena_id = ""
