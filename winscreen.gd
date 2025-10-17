extends Control

var yay_sfx: AudioStreamPlayer

func _ready():
	# Check if this was a speedrun completion
	# The speedrun is already ended by LevelManager, but we can check if time > 0
	var is_speedrun = false
	var speedrun_time = 0.0
	
	if has_node("/root/SpeedrunManager"):
		var manager = get_node("/root/SpeedrunManager")
		print("SpeedrunManager found. speedrun_time = ", manager.speedrun_time)
		print("speedrun_active = ", manager.speedrun_active)
		print("speedrun_paused = ", manager.speedrun_paused)
		# If there's a recorded time, this was a speedrun
		if manager.speedrun_time > 0:
			is_speedrun = true
			speedrun_time = manager.speedrun_time
			print("Speedrun detected! Time: ", manager.format_time(speedrun_time))
			# Don't reset yet - we need the time for display
		else:
			print("No speedrun time recorded (time is 0)")
	else:
		print("SpeedrunManager not found!")
	
	print("is_speedrun = ", is_speedrun)
	
	# Build UI programmatically
	build_win_screen(is_speedrun)
	yay_sfx = AudioStreamPlayer.new()
	yay_sfx.bus = "SFX"
	yay_sfx.stream = preload("res://audio/sfx/yay.mp3")
	add_child(yay_sfx)
	
	# Get stats from LevelManager
	var level_manager = get_node("/root/LevelManager")
	
	if level_manager:
		display_stats(level_manager, is_speedrun)
	
	yay_sfx.play()
	print("YOU WIN!")

func build_win_screen(is_speedrun: bool = false):
	# Set full screen
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.1, 0.15)
	add_child(bg)
	
	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	# Main VBox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "YOU WIN!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(title)
	
	# Rounds completed (or speedrun time)
	var rounds_label = Label.new()
	rounds_label.name = "RoundsLabel"
	if is_speedrun:
		rounds_label.text = "Speedrun Complete!"
	else:
		rounds_label.text = "Completed 10 Rounds!"
	rounds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rounds_label.add_theme_font_size_override("font_size", 32)
	rounds_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(rounds_label)
	
	# Challenge text / Speedrun time
	var challenge_label = Label.new()
	challenge_label.name = "ChallengeLabel"
	challenge_label.text = ""
	challenge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_speedrun:
		challenge_label.add_theme_font_size_override("font_size", 48)
		challenge_label.add_theme_color_override("font_color", Color.CYAN)
	else:
		challenge_label.add_theme_font_size_override("font_size", 28)
		challenge_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	vbox.add_child(challenge_label)
	
	# Only show stats if NOT speedrun
	if not is_speedrun:
		# Spacer
		var spacer1 = Control.new()
		spacer1.custom_minimum_size = Vector2(0, 30)
		vbox.add_child(spacer1)
		
		# Stats title
		var stats_title = Label.new()
		stats_title.text = "FINAL STATS"
		stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_title.add_theme_font_size_override("font_size", 36)
		stats_title.add_theme_color_override("font_color", Color.YELLOW)
		vbox.add_child(stats_title)
		
		# Stats container - centered
		var stats_center = CenterContainer.new()
		vbox.add_child(stats_center)
		
		var stats_container = VBoxContainer.new()
		stats_container.name = "StatsContainer"
		stats_container.add_theme_constant_override("separation", 15)
		stats_center.add_child(stats_container)
		
		# Create stat labels
		var speed_label = create_stat_label("Speed", "1.0x")
		speed_label.name = "SpeedLabel"
		stats_container.add_child(speed_label)
		
		var jump_label = create_stat_label("Jump", "1.0x")
		jump_label.name = "JumpLabel"
		stats_container.add_child(jump_label)
		
		var gravity_label = create_stat_label("Gravity", "1.0x")
		gravity_label.name = "GravityLabel"
		stats_container.add_child(gravity_label)
		
		var blocks_label = create_stat_label("Blocks Remaining", "0")
		blocks_label.name = "BlocksLabel"
		stats_container.add_child(blocks_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer2)
	
	# Menu button
	var menu_button = Button.new()
	menu_button.text = "Return to Main Menu"
	menu_button.custom_minimum_size = Vector2(300, 60)
	menu_button.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_button)

func create_stat_label(stat_name: String, default_value: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	
	var name_label = Label.new()
	name_label.text = stat_name + ":"
	name_label.custom_minimum_size = Vector2(250, 0)
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(name_label)
	
	var value_label = Label.new()
	value_label.name = "Value"
	value_label.text = default_value
	value_label.add_theme_font_size_override("font_size", 28)
	value_label.add_theme_color_override("font_color", Color.CYAN)
	hbox.add_child(value_label)
	
	return hbox

func display_stats(level_manager, is_speedrun: bool = false):
	# Check if any upgrades were purchased
	var used_upgrades = (level_manager.player_speed_multiplier != 1.0 or 
						 level_manager.player_jump_multiplier != 1.0 or 
						 level_manager.player_gravity_multiplier != 1.0)
	
	# Update rounds label for speedrun category
	if is_speedrun:
		var rounds_label = find_node_recursive(self, "RoundsLabel")
		if rounds_label:
			if used_upgrades:
				rounds_label.text = "chat is this an any% wr"
			else:
				rounds_label.text = "chat is this a min% wr"
	
	# Update challenge text
	var challenge_label = find_node_recursive(self, "ChallengeLabel")
	if challenge_label:
		if is_speedrun:
			# Show speedrun time
			if has_node("/root/SpeedrunManager"):
				var manager = get_node("/root/SpeedrunManager")
				challenge_label.text = manager.format_time(manager.speedrun_time)
		else:
			if used_upgrades:
				challenge_label.text = "now try to win without buying anything..."
			else:
				challenge_label.text = "wow pro gaming"
	
	# Only update stats if NOT speedrun
	if not is_speedrun:
		# Update rounds
		var rounds_label = get_node_or_null("CenterContainer/VBoxContainer/RoundsLabel")
		if rounds_label:
			rounds_label.text = "Completed " + str(level_manager.levels_completed) + " Rounds!"
		
		# Update stats - search for nodes recursively
		var speed_value = find_node_recursive(self, "SpeedLabel")
		if speed_value:
			var value_node = speed_value.get_node_or_null("Value")
			if value_node:
				value_node.text = str(snapped(level_manager.player_speed_multiplier, 0.1)) + "x"
		
		var jump_value = find_node_recursive(self, "JumpLabel")
		if jump_value:
			var value_node = jump_value.get_node_or_null("Value")
			if value_node:
				value_node.text = str(snapped(level_manager.player_jump_multiplier, 0.1)) + "x"
		
		var gravity_value = find_node_recursive(self, "GravityLabel")
		if gravity_value:
			var value_node = gravity_value.get_node_or_null("Value")
			if value_node:
				value_node.text = str(snapped(level_manager.player_gravity_multiplier, 0.1)) + "x"
		
		var blocks_value = find_node_recursive(self, "BlocksLabel")
		if blocks_value:
			var value_node = blocks_value.get_node_or_null("Value")
			if value_node:
				value_node.text = str(level_manager.player_blocks)
	else:
		# Unlock speedrun mode when beating in speedrun
		if has_node("/root/SpeedrunManager"):
			get_node("/root/SpeedrunManager").unlock_speedrun()

func find_node_recursive(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var result = find_node_recursive(child, node_name)
		if result:
			return result
	return null

func _on_menu_pressed():
	# Unequip all items
	var inventory_ui = get_node_or_null("/root/InventoryUI")
	if inventory_ui:
		inventory_ui.unequip_all_items()
		print("✓ Unequipped all items before returning to menu")
	
	# Reset speedrun for next time
	if has_node("/root/SpeedrunManager"):
		get_node("/root/SpeedrunManager").stop_speedrun()
	
	# Reset game and go to main menu
	var level_manager = get_node("/root/LevelManager")
	if level_manager:
		level_manager.reset_game()
	get_tree().change_scene_to_file("res://mainmenu.tscn")
