extends Node

# global music player
var music_player: AudioStreamPlayer

func _ready():
	# create music player
	music_player = AudioStreamPlayer.new()
	music_player.stream = load("res://audio/music/background.ogg")
	if music_player.stream and music_player.stream.has_method("set_loop"): # safe check
		music_player.stream.loop = true
	music_player.bus = "Music"
	music_player.autoplay = true
	
	# keep music playing even if game is paused
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	add_child(music_player)
	
	print("MusicManager ready - music playing globally")

# call to play music if stopped
func play_music():
	if music_player and not music_player.playing:
		music_player.play()

# call to stop music
func stop_music():
	if music_player:
		music_player.stop()

# set music volume (%)
func set_volume(volume_percent: float):
	var db = linear_to_db(clamp(volume_percent, 0, 100) / 100.0)
	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index != -1:
		AudioServer.set_bus_volume_db(music_bus_index, db)
