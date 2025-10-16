extends Control

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var speedrun_button = $CenterContainer/VBoxContainer/SpeedrunButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton
@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel

func _ready():
	# Connect buttons
	play_button.pressed.connect(_on_play_pressed)
	speedrun_button.pressed.connect(_on_speedrun_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Check if speedrun is unlocked
	update_speedrun_button_visibility()
	
	# Connect to speedrun unlock signal
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").speedrun_unlocked_signal.connect(_on_speedrun_unlocked)
	
	print("Main Menu ready")

func _input(event):
	if event is InputEventKey and event.pressed:
		if has_node("/root/SpeedrunManager"):
			if get_node("/root/SpeedrunManager").check_konami_input(event.keycode):
				# Show unlock feedback
				show_unlock_notification()
				update_speedrun_button_visibility()

func update_speedrun_button_visibility():
	if has_node("/root/SpeedrunManager"):
		var manager = get_node("/root/SpeedrunManager")
		speedrun_button.visible = manager.speedrun_unlocked
		print("Speedrun button visible: ", speedrun_button.visible)

func _on_speedrun_unlocked():
	update_speedrun_button_visibility()

func show_unlock_notification():
	# Create a temporary label to show unlock message
	var label = Label.new()
	label.text = "SPEEDRUN MODE UNLOCKED!"
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(get_viewport_rect().size.x / 2 - 150, 50)
	add_child(label)
	
	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(label.queue_free)

func _on_play_pressed():
	print("Starting new game...")
	
	# Make sure speedrun is not active
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").stop_speedrun()
	
	# Reset the game in LevelManager
	if has_node("/root/LevelManager"):
		get_node("/root/LevelManager").reset_game()
	
	# Start from first level
	get_tree().change_scene_to_file("res://levels/early_1.tscn")

func _on_speedrun_pressed():
	print("Starting speedrun...")
	
	# Start speedrun mode
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").start_speedrun()
	
	# Reset the game in LevelManager
	if has_node("/root/LevelManager"):
		get_node("/root/LevelManager").reset_game()
	
	# Start from first level
	get_tree().change_scene_to_file("res://levels/early_1.tscn")

func _on_settings_pressed():
	print("Opening settings from main menu...")
	var settings = get_node_or_null("/root/SettingsMenu")
	if settings:
		settings.show_settings()
	else:
		print("SettingsMenu not found!")

func _on_quit_pressed():
	print("Quitting game...")
	get_tree().quit()
