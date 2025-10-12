extends CanvasLayer

var is_paused = false

# UI elements
var pause_panel
var resume_button
var settings_button
var main_menu_button

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_pause_menu()
	print("PauseMenu ready - Press ESC to pause")

func _input(event):
	# Only process keyboard events
	if not event is InputEventKey:
		return
	
	# Don't allow pausing in main menu
	if get_tree().current_scene.name == "MainMenu":
		return
	
	# Don't open pause menu if shop or inventory are open
	var shop_ui = get_node_or_null("/root/ShopUI")
	var inventory_ui = get_node_or_null("/root/InventoryUI")
	var settings_ui = get_node_or_null("/root/SettingsMenu")
	
	if shop_ui and shop_ui.visible:
		return
	if inventory_ui and inventory_ui.visible:
		return
	if settings_ui and settings_ui.visible:
		return
	
	# Toggle pause with ESC
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause():
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	is_paused = true
	visible = true
	print("Game paused")

func resume_game():
	is_paused = false
	visible = false
	print("Game resumed")

func build_pause_menu():
	# Main container
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	# Dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	control.add_child(overlay)
	
	# Pause panel
	pause_panel = Panel.new()
	pause_panel.custom_minimum_size = Vector2(400, 400)
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-200, -200)
	control.add_child(pause_panel)
	
	# Main layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	vbox.add_theme_constant_override("separation", 20)
	pause_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer1)
	
	# Resume button
	resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.custom_minimum_size = Vector2(300, 60)
	resume_button.pressed.connect(resume_game)
	vbox.add_child(resume_button)
	
	# Settings button
	settings_button = Button.new()
	settings_button.text = "Settings"
	settings_button.custom_minimum_size = Vector2(300, 60)
	settings_button.pressed.connect(_on_settings_pressed)
	vbox.add_child(settings_button)
	
	# Main menu button
	main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	main_menu_button.custom_minimum_size = Vector2(300, 60)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(main_menu_button)
	
	print("Pause menu built")

func _on_settings_pressed():
	print("Opening settings...")
	
	# Try to find SettingsMenu in multiple locations
	var settings = get_node_or_null("/root/SettingsMenu")
	
	if not settings:
		print("SettingsMenu not in autoload, checking if it needs to be added...")
		print("Make sure SettingsMenu.tscn is added to Project Settings → Autoload")
	else:
		settings.show_settings()

func _on_main_menu_pressed():
	print("Returning to main menu...")
	resume_game()  # Unpause first
	get_tree().change_scene_to_file("res://MainMenu.tscn")
