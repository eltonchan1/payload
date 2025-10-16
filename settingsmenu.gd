extends CanvasLayer

# UI elements
var settings_panel
var back_button

# Settings values (placeholders for now)
var master_volume = 100
var sfx_volume = 100
var music_volume = 100
var fullscreen = false
var opened_from_pause = false  # Track where settings was opened from

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Changed from WHEN_PAUSED
	build_settings_menu()
	load_settings()
	print("SettingsMenu ready")

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		hide_settings()
		get_viewport().set_input_as_handled()

func show_settings(from_pause = false):
	opened_from_pause = from_pause
	visible = true
	update_settings_display()
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").pause_timer()
	print("Settings menu opened (from pause: ", from_pause, ")")

func hide_settings():
	visible = false
	save_settings()
	
	# If opened from pause menu, show pause menu again
	if opened_from_pause:
		var pause_menu = get_node_or_null("/root/PauseMenu")
		if pause_menu:
			pause_menu.visible = true
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").resume_timer()
	print("Settings menu closed")

func build_settings_menu():
	# Main container
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	# Dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	control.add_child(overlay)
	
	# Settings panel
	settings_panel = Panel.new()
	settings_panel.custom_minimum_size = Vector2(500, 500)
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.position = Vector2(-250, -250)
	control.add_child(settings_panel)
	
	# Main layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	vbox.add_theme_constant_override("separation", 15)
	settings_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Master Volume
	add_slider_setting(vbox, "Master Volume", "master_volume")
	
	# SFX Volume
	add_slider_setting(vbox, "SFX Volume", "sfx_volume")
	
	# Music Volume
	add_slider_setting(vbox, "Music Volume", "music_volume")
	
	# Fullscreen toggle
	var fullscreen_hbox = HBoxContainer.new()
	var fullscreen_label = Label.new()
	fullscreen_label.text = "Fullscreen:"
	fullscreen_label.custom_minimum_size = Vector2(200, 0)
	fullscreen_label.add_theme_font_size_override("font_size", 20)
	fullscreen_hbox.add_child(fullscreen_label)
	
	var fullscreen_check = CheckButton.new()
	fullscreen_check.name = "FullscreenCheck"
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	fullscreen_hbox.add_child(fullscreen_check)
	vbox.add_child(fullscreen_hbox)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)
	
	# Placeholder info
	var info_label = Label.new()
	info_label.text = "More settings coming soon..."
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(info_label)
	
	# Back button
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.pressed.connect(hide_settings)
	vbox.add_child(back_button)
	
	print("Settings menu built")

func add_slider_setting(parent: VBoxContainer, label_text: String, setting_name: String):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER  # Center align items vertically
	
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(200, 0)
	label.add_theme_font_size_override("font_size", 20)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(label)
	
	var slider = HSlider.new()
	slider.name = setting_name + "_slider"
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = 100
	slider.custom_minimum_size = Vector2(200, 30)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value): _on_slider_changed(setting_name, value))
	hbox.add_child(slider)
	
	var value_label = Label.new()
	value_label.name = setting_name + "_value"
	value_label.text = "100"
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(value_label)
	
	parent.add_child(hbox)

func _on_slider_changed(setting_name: String, value: float):
	# Find the value label by searching in the panel
	var value_label = find_node_by_name(settings_panel, setting_name + "_value")
	if value_label:
		value_label.text = str(int(value))
	
	# Update setting and apply to audio buses
	match setting_name:
		"master_volume":
			master_volume = int(value)
			var db = linear_to_db(value / 100.0)
			AudioServer.set_bus_volume_db(0, db)  # Master bus is index 0
			print("Master volume: ", master_volume, " (", db, " dB)")
		"sfx_volume":
			sfx_volume = int(value)
			var sfx_bus = AudioServer.get_bus_index("SFX")
			if sfx_bus != -1:
				var db = linear_to_db(value / 100.0)
				AudioServer.set_bus_volume_db(sfx_bus, db)
			print("SFX volume: ", sfx_volume)
		"music_volume":
			music_volume = int(value)
			var music_bus = AudioServer.get_bus_index("Music")
			if music_bus != -1:
				var db = linear_to_db(value / 100.0)
				AudioServer.set_bus_volume_db(music_bus, db)
			print("Music volume: ", music_volume)

# Helper function to find node by name recursively
func find_node_by_name(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var result = find_node_by_name(child, node_name)
		if result:
			return result
	return null

func _on_fullscreen_toggled(toggled: bool):
	fullscreen = toggled
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	print("Fullscreen: ", fullscreen)

func update_settings_display():
	# Update sliders using the helper function
	var master_slider = find_node_by_name(settings_panel, "master_volume_slider")
	if master_slider:
		master_slider.value = master_volume
	
	var sfx_slider = find_node_by_name(settings_panel, "sfx_volume_slider")
	if sfx_slider:
		sfx_slider.value = sfx_volume
	
	var music_slider = find_node_by_name(settings_panel, "music_volume_slider")
	if music_slider:
		music_slider.value = music_volume
	
	# Update fullscreen checkbox
	var fullscreen_check = find_node_by_name(settings_panel, "FullscreenCheck")
	if fullscreen_check:
		fullscreen_check.button_pressed = fullscreen

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.save("user://settings.cfg")
	print("Settings saved")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 100)
		sfx_volume = config.get_value("audio", "sfx_volume", 100)
		music_volume = config.get_value("audio", "music_volume", 100)
		fullscreen = config.get_value("video", "fullscreen", false)
		
		# Apply fullscreen setting
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
		print("Settings loaded")
	else:
		print("No saved settings found, using defaults")
