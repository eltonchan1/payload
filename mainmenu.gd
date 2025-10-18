extends Control

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var speedrun_button = $CenterContainer/VBoxContainer/SpeedrunButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton
@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel

# track if should show unlock notif
var show_unlock_on_ready = false

func _ready():
	# check if just unlocked speedrun (b4 updating visibility)
	if has_node("/root/SpeedrunManager"):
		var manager = get_node("/root/SpeedrunManager")
		# check if theres a flag indicating just unlocked
		if manager.get("just_unlocked"):
			show_unlock_on_ready = true
			manager.set("just_unlocked", false)
	
	# connect buttons
	play_button.pressed.connect(_on_play_pressed)
	speedrun_button.pressed.connect(_on_speedrun_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# check if speedrun is unlocked
	update_speedrun_button_visibility()
	
	# connect to speedrun unlock signal
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").speedrun_unlocked_signal.connect(_on_speedrun_unlocked)
	
	# show unlock notif if needed
	if show_unlock_on_ready:
		await get_tree().create_timer(0.5).timeout
		show_unlock_notification()
	
	print("Main Menu ready")

func _input(event):
	if event is InputEventKey and event.pressed:
		if has_node("/root/SpeedrunManager"):
			if get_node("/root/SpeedrunManager").check_konami_input(event.keycode):
				# show unlock feedback
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
	# create a panel for better visibility
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-200, -100)
	panel.custom_minimum_size = Vector2(400, 150)
	add_child(panel)
	
	# style panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	style_box.border_color = Color.GOLD
	style_box.set_border_width_all(3)
	style_box.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style_box)
	
	# vbox for content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	# add padding
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	
	# title
	var title = Label.new()
	title.text = "🏆 SPEEDRUN MODE UNLOCKED! 🏆"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# description
	var desc = Label.new()
	desc.text = "Complete the game as fast as possible!\nNew button added to main menu."
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color.WHITE)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	print("✓ Showing speedrun unlock notification!")
	
	# fade in
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_property(panel, "position:y", panel.position.y + 20, 0.5).set_ease(Tween.EASE_OUT)
	
	# wait & fade out
	await get_tree().create_timer(4.0).timeout
	var fade_out = create_tween()
	fade_out.tween_property(panel, "modulate:a", 0.0, 1.0)
	fade_out.tween_callback(panel.queue_free)

func _on_play_pressed():
	print("Starting new game...")
	
	# make sure speedrun is not active
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").stop_speedrun()
	
	# reset the game in levelmanager
	if has_node("/root/LevelManager"):
		get_node("/root/LevelManager").reset_game()
	
	# start from first lvl
	get_tree().change_scene_to_file("res://levels/early_1.tscn")

func _on_speedrun_pressed():
	print("Starting speedrun...")
	
	# reset the game in levelmanager 1st
	if has_node("/root/LevelManager"):
		get_node("/root/LevelManager").reset_game()
	
	# start speedrun after reset
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").start_speedrun()
	
	# start from first lvl
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
