class_name ChapterData
extends Resource

## Data satu chapter Story Mode: satu pertandingan per chapter.
## Chapter 4 memakai boss_id, chapter lain memakai satu item di stages.
## File: data/chapters/<id>.tres (ch1 Dermaga, ch2 Lorong Neon,
## ch3 Dojo Bayangan). arena_bg kosong = background chapter belum ada
## di assets (subagent arena yang mengisi saat asetnya tersedia).

@export var id: String = ""
@export var title: String = ""
@export var arena_bg: String = ""
@export var arena_bgm: String = ""
@export var stages: Array[String] = []
@export var boss_id: String = ""
