extends Node
## Audio (autoload): memutar SFX dan musik latar.
## Cara pakai: Audio.play_sfx("hit") / Audio.play_music("bgm_battle")

var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _streams: Dictionary = {}

const SFX_NAMES := [
	"swing", "hit", "block", "jump", "ko",
	"bell", "ui_click", "countdown", "round_win",
]
const MUSIC_NAMES := ["bgm_menu", "bgm_battle"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
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
	var path := "res://assets/audio/%s.wav" % stream_name
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStreamWAV = load(path)
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		# 16-bit mono: jumlah sample = byte data / 2
		stream.loop_end = int(stream.data.size() / 2)
	_streams[stream_name] = stream


func play_sfx(stream_name: String, volume_db: float = 0.0) -> void:
	if not _streams.has(stream_name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[stream_name]
			p.volume_db = volume_db
			p.play()
			return
	# Semua player sibuk: pakai ulang yang pertama
	_players[0].stream = _streams[stream_name]
	_players[0].volume_db = volume_db
	_players[0].play()


func play_music(stream_name: String, volume_db: float = -10.0) -> void:
	if not _streams.has(stream_name):
		return
	if _music_player.stream == _streams[stream_name] and _music_player.playing:
		return
	_music_player.stream = _streams[stream_name]
	_music_player.volume_db = volume_db
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()
