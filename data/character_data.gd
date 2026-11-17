class_name CharacterData
extends Resource

## Data statis satu petarung (GDD v2.0 §6): dipisah dari logika fighter.gd.
## fighter.gd membaca .tres ini di set_character() dan jatuh kembali ke
## dict CHARACTERS bila file tidak ada — frame/anim_fix/sprite_scale
## tetap di CHARACTERS, .tres hanya menimpa stat (hp/dmg/spd) & trait.
## File: data/characters/<id>.tres (12 protagonis + 6 musuh + 3 boss).

@export var id: String = ""
@export var display_name: String = ""
@export var country: String = ""
@export var style: String = ""
@export var bio: String = ""
@export var hp: int = 100
@export var dmg: float = 1.0
@export var spd: float = 1.0
@export var trait_id: String = "none"
@export var trait_desc: String = ""
@export var portrait_anim: String = "idle"
@export var folder: String = ""
