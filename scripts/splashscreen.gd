
extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready():

	# Menyesuaikan video dengan ukuran layar
	video_player.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# Mengaktifkan penyesuaian ukuran video
	video_player.expand = true

	# Memutar video
	video_player.play()

	# Menunggu sampai video selesai
	await video_player.finished

	# Berpindah ke Main Menu
	get_tree().change_scene_to_file(
		"res://scenes/menu.tscn"
	)
