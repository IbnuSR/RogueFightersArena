extends Node

enum Mode { NONE, STORY, FREE_FIGHT }

var mode: Mode = Mode.NONE
var player_id: String = ""
var opponent_id: String = ""
var arena_id: String = ""
# Story Mode: chapter & stage yang sedang dimainkan (stage 0-2 = musuh
# biasa dari ChapterData.stages, stage 3 = boss dari ChapterData.boss_id).
var chapter_id: String = ""
var stage_index: int = 0


func reset() -> void:
	mode = Mode.NONE
	player_id = ""
	opponent_id = ""
	arena_id = ""
	chapter_id = ""
	stage_index = 0
