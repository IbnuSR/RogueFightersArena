extends Node
## Audio (autoload): memutar SFX dan musik latar.
## Cara pakai: Audio.play_sfx("hit") / Audio.play_music("bgm_battle")

var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _streams: Dictionary = {}
# Level volume 0.0..1.0 (diatur dari Pengaturan, disimpan ProgressManager).
var music_level: float = 0.8
var sfx_level: float = 0.8


func set_music_level(v: float) -> void:
	music_level = clampf(v, 0.0, 1.0)
	if _music_player != null:
		_music_player.volume_db = -10.0 + linear_to_db(maxf(music_level, 0.001))


func set_sfx_level(v: float) -> void:
	sfx_level = clampf(v, 0.0, 1.0)

const SFX_NAMES := [
	"swing", "swing_heavy", "hit", "hit_heavy", "block", "jump", "land", "ko",
	"bell", "ui_click", "ui_hover", "ui_select", "countdown", "round_win",
	"round_1", "round_2", "round_3", "final_round", "ready", "fight",
	"choose_your_character", "winner", "you_win", "you_lose", "game_over",
]
const MUSIC_NAMES := [
	"bgm_menu", "bgm_battle",
	"Chapter 1 BGM", "Chapter 2 BGM", "Chapter 3 BGM", "Chapter 4 BGM",
	"BGM 1", "BGM 2", "BGM 3",
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	for sfx_name in SFX_NAMES:
		_load_stream(sfx_name, false)
	for music_name in MUSIC_NAMES:
		_load_stream(music_name, true)


func _load_stream(stream_name: String, loop: bool) -> void:
	var found_path := ""
	if stream_name.begins_with("res://") and ResourceLoader.exists(stream_name):
		found_path = stream_name
	else:
		var extensions := ["", ".mp3", ".ogg", ".wav"]
		for ext in extensions:
			var p := "res://assets/audio/%s%s" % [stream_name, ext]
			if ResourceLoader.exists(p):
				found_path = p
				break
	if found_path == "":
		return
	var stream = load(found_path)
	if stream is AudioStreamWAV:
		if loop:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.data.size() / 2)
	elif stream is AudioStreamOggVorbis:
		if loop:
			stream.loop = true
	elif stream is AudioStreamMP3:
		if loop:
			stream.loop = true
	_streams[stream_name] = stream


func play_sfx(stream_name: String, volume_db: float = 0.0) -> void:
	if not _streams.has(stream_name):
		_load_stream(stream_name, false)
	if not _streams.has(stream_name):
		return
	var vol: float = volume_db + linear_to_db(maxf(sfx_level, 0.001))
	for p in _players:
		if not p.playing:
			p.stream = _streams[stream_name]
			p.volume_db = vol
			p.play()
			return
	# Semua player sibuk: pakai ulang yang pertama
	_players[0].stream = _streams[stream_name]
	_players[0].volume_db = vol
	_players[0].play()


func play_music(stream_name: String, volume_db: float = -10.0) -> void:
	if not _streams.has(stream_name):
		_load_stream(stream_name, true)
	if not _streams.has(stream_name):
		return
	if _music_player.stream == _streams[stream_name] and _music_player.playing:
		return
	_music_player.stream = _streams[stream_name]
	_music_player.volume_db = volume_db + linear_to_db(maxf(music_level, 0.001))
	_music_player.play()


func play_chapter_music(chapter_id: String, volume_db: float = -10.0) -> void:
	match chapter_id.to_lower():
		"ch1", "1", "dermaga":
			play_music("Chapter 1 BGM", volume_db)
		"ch2", "2", "lorong_neon", "lorong neon":
			play_music("Chapter 2 BGM", volume_db)
		"ch3", "3", "dojo_bayangan", "dojo bayangan":
			play_music("Chapter 3 BGM", volume_db)
		"ch4", "4", "menara_voss", "menara voss":
			play_music("Chapter 4 BGM", volume_db)
		_:
			play_music("bgm_battle", volume_db)


func stop_music() -> void:
	_music_player.stop()
