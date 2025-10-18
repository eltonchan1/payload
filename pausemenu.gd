extends CanvasLayer

var is_paused = false

# ui ele
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
	# only process keyboard events
	if not event is InputEventKey:
		return
	
	# dont allow pausing in main menu
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "MainMenu":
		return
	
	# dont open pause if shop or inv are open
	var shop_ui = get_node_or_null("/root/ShopUI")
	var inventory_ui = get_node_or_null("/root/InventoryUI")
	var settings_ui = get_node_or_null("/root/SettingsMenu")
	
	if shop_ui and shop_ui.visible:
		return
	if inventory_ui and inventory_ui.visible:
		return
	if settings_ui and settings_ui.visible:
		return
	
	# pause w/ esc
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
	get_tree().paused = true
	
	# pause speedrun timer
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").pause_timer()
	
	print("Game paused")

func resume_game():
	is_paused = false
	visible = false
	get_tree().paused = false
	
	# resume speedrun timer
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").resume_timer()
	
	print("Game resumed")

func build_pause_menu():
	# main container
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	# dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	control.add_child(overlay)
	
	# pause panel
	pause_panel = Panel.new()
	pause_panel.custom_minimum_size = Vector2(400, 400)
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.position = Vector2(-200, -200)
	control.add_child(pause_panel)
	
	# main layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	vbox.add_theme_constant_override("separation", 20)
	pause_panel.add_child(vbox)
	
	# title
	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title)
	
	# spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer1)
	
	# resume button
	resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.custom_minimum_size = Vector2(300, 60)
	resume_button.pressed.connect(resume_game)
	vbox.add_child(resume_button)
	
	# settings button
	settings_button = Button.new()
	settings_button.text = "Settings"
	settings_button.custom_minimum_size = Vector2(300, 60)
	settings_button.pressed.connect(_on_settings_pressed)
	vbox.add_child(settings_button)
	
	# main menu button
	main_menu_button = Button.new()
	main_menu_button.text = "Main Menu"
	main_menu_button.custom_minimum_size = Vector2(300, 60)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(main_menu_button)
	
	print("Pause menu built")

func _on_settings_pressed():
	print("Opening settings...")
	
	# try to find settingsmenu in multiple locations
	var settings = get_node_or_null("/root/SettingsMenu")
	
	if not settings:
		print("SettingsMenu not in autoload, checking if it needs to be added...")
		print("Make sure SettingsMenu.tscn is added to Project Settings → Autoload")
	else:
		settings.show_settings()

func _on_main_menu_pressed():
	print("Returning to main menu...")
	
	# stop speedrun if active
	if has_node("/root/SpeedrunManager"):
		var speedrun_manager = get_node("/root/SpeedrunManager")
		if speedrun_manager.speedrun_active:
			speedrun_manager.stop_speedrun()
	
	# unequip all items
	var inventory_ui = get_node_or_null("/root/InventoryUI")
	if inventory_ui:
		inventory_ui.unequip_all_items()
		print("✓ Unequipped all items before returning to menu")
		
	# reset shop, clear upgrades & purchases
	var shop_ui = get_node_or_null("/root/ShopUI")
	if shop_ui:
		shop_ui.reset_shop()
		print("✓ Reset shop upgrades before returning to menu")
	
	resume_game()  # unpause first
	get_tree().change_scene_to_file("res://mainmenu.tscn")
