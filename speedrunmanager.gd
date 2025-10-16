extends Node

# Speedrun state
var speedrun_unlocked = false
var speedrun_active = false
var speedrun_time = 0.0
var speedrun_paused = false

# Konami code: Up, Up, Down, Down, Left, Right, Left, Right, B, A
var konami_code = [
	KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN,
	KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT,
	KEY_B, KEY_A
]
var konami_progress = 0

signal speedrun_unlocked_signal
signal speedrun_started
signal speedrun_ended

func _ready():
	load_speedrun_data()
	print("SpeedrunManager ready. Unlocked: ", speedrun_unlocked)

func _process(delta):
	if speedrun_active and not speedrun_paused:
		speedrun_time += delta

func start_speedrun():
	speedrun_active = true
	speedrun_time = 0.0
	speedrun_paused = false
	emit_signal("speedrun_started")
	print("Speedrun started!")

func end_speedrun():
	speedrun_paused = true
	speedrun_active = false
	emit_signal("speedrun_ended")
	print("Speedrun ended! Final time: ", format_time(speedrun_time))

func stop_speedrun():
	speedrun_active = false
	speedrun_time = 0.0
	speedrun_paused = false

func pause_timer():
	speedrun_paused = true
	print("Speedrun timer paused")

func resume_timer():
	speedrun_paused = false
	print("Speedrun timer resumed")

func is_timer_paused() -> bool:
	return speedrun_paused

func get_current_time():
	return speedrun_time

func format_time(time: float) -> String:
	var minutes = int(time) / 60
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 1000)
	return "%d:%02d.%03d" % [minutes, seconds, milliseconds]

func unlock_speedrun():
	if not speedrun_unlocked:
		speedrun_unlocked = true
		save_speedrun_data()
		emit_signal("speedrun_unlocked_signal")
		print("Speedrun mode unlocked!")

func check_konami_input(key: int) -> bool:
	if key == konami_code[konami_progress]:
		konami_progress += 1
		print("Konami progress: ", konami_progress, "/", konami_code.size())
		if konami_progress >= konami_code.size():
			konami_progress = 0
			unlock_speedrun()
			return true
	else:
		if konami_progress > 0:
			print("Konami code reset")
		konami_progress = 0
	return false

func save_speedrun_data():
	var save_data = {
		"speedrun_unlocked": speedrun_unlocked
	}
	var file = FileAccess.open("user://speedrun_save.dat", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Speedrun data saved")

func load_speedrun_data():
	if FileAccess.file_exists("user://speedrun_save.dat"):
		var file = FileAccess.open("user://speedrun_save.dat", FileAccess.READ)
		if file:
			var save_data = file.get_var()
			file.close()
			if save_data.has("speedrun_unlocked"):
				speedrun_unlocked = save_data["speedrun_unlocked"]
				print("Speedrun data loaded. Unlocked: ", speedrun_unlocked)
	else:
		print("No speedrun save data found")
