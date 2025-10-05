extends Control

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton
@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel

func _ready():
	# Connect buttons
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	print("Main Menu ready")

func _on_play_pressed():
	print("Starting new game...")
	
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
