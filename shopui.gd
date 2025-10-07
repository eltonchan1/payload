extends CanvasLayer

var player_ref = null
var current_tab = 0  # 0=Gear, 1=Armor, 2=Mystery, 3=Upgrades

# References to UI elements
var blocks_label
var content_container

# Armor items (equipment that shows in inventory)
var armor_items = [
	{"name": "Speed Helmet", "cost": 5, "slot": "head", "description": "Sleek helmet for speed", "bonus_type": "speed", "bonus_value": 0.3},
	{"name": "Jump Boots", "cost": 5, "slot": "feet", "description": "Bouncy boots for jumping", "bonus_type": "jump", "bonus_value": 0.2},
	{"name": "Light Chestplate", "cost": 6, "slot": "chest", "description": "Lightweight armor", "bonus_type": "gravity", "bonus_value": -0.2},
	{"name": "Agile Leggings", "cost": 4, "slot": "legs", "description": "Flexible leg protection", "bonus_type": "speed", "bonus_value": 0.2}
]

# Shop items data (easy to customize!)
var gear_items = [
	{"name": "Speed Potion", "cost": 3, "description": "Increase movement speed by 50%", "effect": "speed"},
	{"name": "Jump Elixir", "cost": 4, "description": "Jump 30% higher", "effect": "jump"},
	{"name": "Feather Charm", "cost": 3, "description": "Reduce gravity by 30%", "effect": "gravity"},
	{"name": "Block Pack", "cost": 2, "description": "Gain 5 extra blocks", "effect": "blocks"}
]

var mystery_packs = [
	{"name": "Common Pack", "cost": 5, "description": "Contains 1-3 random items"},
	{"name": "Rare Pack", "cost": 8, "description": "Contains 2-4 random items"}
]

var upgrade_items = [
	{"name": "Bulk Discount", "cost": 10, "description": "All items cost 1 less"},
	{"name": "Extra Jump", "cost": 15, "description": "Gain bonus air jump"}
]

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	build_shop_ui()
	print("ShopUI ready")

func _input(event):
	if visible:
		# Check for ESC or S to close
		if event.is_action_pressed("ui_cancel"):
			hide_shop()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_S and not event.echo:
			hide_shop()
			get_viewport().set_input_as_handled()

func build_shop_ui():
	# Create main container
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	# Create shop panel (centered using anchors)
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(700, 500)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-350, -250)  # Half of size for centering
	control.add_child(panel)
	
	# Create main layout
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	main_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_vbox)
	
	# Top bar with blocks and close button
	var top_bar = HBoxContainer.new()
	blocks_label = Label.new()
	blocks_label.text = "Blocks: 0"
	blocks_label.add_theme_font_size_override("font_size", 24)
	top_bar.add_child(blocks_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)
	
	var close_btn = Button.new()
	close_btn.text = "Close (ESC)"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.pressed.connect(hide_shop)
	top_bar.add_child(close_btn)
	main_vbox.add_child(top_bar)
	
	# Tab buttons
	var tab_bar = HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 5)
	
	var gear_btn = Button.new()
	gear_btn.text = "Powerups"
	gear_btn.custom_minimum_size = Vector2(150, 40)
	gear_btn.pressed.connect(func(): switch_tab(0))
	tab_bar.add_child(gear_btn)
	
	var armor_btn = Button.new()
	armor_btn.text = "Armor"
	armor_btn.custom_minimum_size = Vector2(150, 40)
	armor_btn.pressed.connect(func(): switch_tab(1))
	tab_bar.add_child(armor_btn)
	
	var mystery_btn = Button.new()
	mystery_btn.text = "Mystery"
	mystery_btn.custom_minimum_size = Vector2(150, 40)
	mystery_btn.pressed.connect(func(): switch_tab(2))
	tab_bar.add_child(mystery_btn)
	
	var upgrade_btn = Button.new()
	upgrade_btn.text = "Upgrades"
	upgrade_btn.custom_minimum_size = Vector2(150, 40)
	upgrade_btn.pressed.connect(func(): switch_tab(3))
	tab_bar.add_child(upgrade_btn)
	
	main_vbox.add_child(tab_bar)
	
	# Content area with scroll
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 10)
	scroll.add_child(content_container)
	main_vbox.add_child(scroll)
	
	print("Shop UI built successfully")

func show_shop(player):
	player_ref = player
	visible = true
	get_tree().paused = true
	update_blocks_display()
	switch_tab(0)  # Show gear tab by default
	print("Shop opened - Player has ", player.blocks_remaining, " blocks")

func hide_shop():
	visible = false
	# Only unpause if inventory is not open
	var inventory_ui = get_node_or_null("/root/InventoryUI")
	if not inventory_ui or not inventory_ui.visible:
		get_tree().paused = false
	print("Shop closed")

func update_blocks_display():
	if blocks_label and player_ref:
		blocks_label.text = "Blocks: " + str(player_ref.blocks_remaining)
		print("Updated shop display to: ", player_ref.blocks_remaining, " blocks")

func switch_tab(tab_index):
	current_tab = tab_index
	populate_current_tab()
	print("Switched to tab: ", tab_index)

func populate_current_tab():
	if not content_container:
		print("ERROR: Content container not found!")
		return
	
	# Clear existing items
	for child in content_container.get_children():
		child.queue_free()
	
	# Add items based on current tab
	var items_added = 0
	match current_tab:
		0:  # Gear/Powerups
			for item in gear_items:
				content_container.add_child(create_shop_card(item, "gear"))
				items_added += 1
		1:  # Armor
			for item in armor_items:
				content_container.add_child(create_shop_card(item, "armor"))
				items_added += 1
		2:  # Mystery
			for pack in mystery_packs:
				content_container.add_child(create_shop_card(pack, "mystery"))
				items_added += 1
		3:  # Upgrades
			for upgrade in upgrade_items:
				content_container.add_child(create_shop_card(upgrade, "upgrade"))
				items_added += 1
	
	print("Added ", items_added, " items to tab ", current_tab)

func create_shop_card(item_data, item_type):
	# Create card container
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(650, 80)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)
	
	# Item name
	var name_label = Label.new()
	name_label.text = item_data["name"]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = item_data["description"]
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	# Cost and buy button
	var bottom_hbox = HBoxContainer.new()
	var cost_label = Label.new()
	cost_label.text = "Cost: " + str(item_data["cost"]) + " blocks"
	cost_label.add_theme_font_size_override("font_size", 16)
	bottom_hbox.add_child(cost_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(spacer)
	
	var buy_btn = Button.new()
	buy_btn.text = "Purchase"
	buy_btn.custom_minimum_size = Vector2(100, 30)
	buy_btn.pressed.connect(func(): purchase_item(item_data, item_type))
	bottom_hbox.add_child(buy_btn)
	
	vbox.add_child(bottom_hbox)
	
	return card

func purchase_item(item_data, item_type):
	if not player_ref:
		print("ERROR: No player reference!")
		return
	
	var cost = item_data["cost"]
	
	if player_ref.blocks_remaining >= cost:
		var old_blocks = player_ref.blocks_remaining
		player_ref.blocks_remaining -= cost
		player_ref.update_block_label()  # Update player's label too
		update_blocks_display()
		
		# Don't show purchase notification - only stat changes
		# apply_item_effect will show the stat changes
		
		# Apply the effect (this will show stat changes)
		apply_item_effect(item_data, item_type)
		
		print("✓ Purchased: ", item_data["name"])
	else:
		print("✗ Not enough blocks! Need ", cost, " but have ", player_ref.blocks_remaining)

func apply_item_effect(item_data, item_type):
	match item_type:
		"gear":
			apply_gear_effect(item_data)
		"armor":
			apply_armor_effect(item_data)
		"mystery":
			open_mystery_pack(item_data)
		"upgrade":
			apply_upgrade(item_data)

func apply_gear_effect(item_data):
	if not player_ref:
		return
	
	var stat_notif = get_node_or_null("/root/StatNotifications")
		
	match item_data["effect"]:
		"speed":
			var old_speed = player_ref.speed_multiplier
			player_ref.speed_multiplier += 0.5
			if stat_notif:
				stat_notif.show_stat_change("Speed", old_speed, player_ref.speed_multiplier, Color.CYAN)
			print("→ Speed increased to ", player_ref.speed_multiplier, "x")
			save_powerups_to_manager()
		"jump":
			var old_jump = player_ref.jump_multiplier
			player_ref.jump_multiplier += 0.3
			if stat_notif:
				stat_notif.show_stat_change("Jump", old_jump, player_ref.jump_multiplier, Color.LIGHT_GREEN)
			print("→ Jump power increased to ", player_ref.jump_multiplier, "x")
			save_powerups_to_manager()
		"gravity":
			var old_gravity = player_ref.gravity_multiplier
			player_ref.gravity_multiplier -= 0.3
			if stat_notif:
				stat_notif.show_stat_change("Gravity", old_gravity, player_ref.gravity_multiplier, Color.LIGHT_BLUE)
			print("→ Gravity reduced to ", player_ref.gravity_multiplier, "x")
			save_powerups_to_manager()
		"blocks":
			var old_blocks = player_ref.blocks_remaining
			player_ref.blocks_remaining += 5
			player_ref.update_block_label()
			update_blocks_display()
			if stat_notif:
				stat_notif.show_blocks_change(old_blocks, player_ref.blocks_remaining)
			print("→ Got 5 bonus blocks!")

func save_powerups_to_manager():
	# Save powerups to LevelManager so they persist
	var level_manager = player_ref.get_node_or_null("/root/LevelManager")
	if level_manager:
		level_manager.save_powerups(
			player_ref.speed_multiplier,
			player_ref.jump_multiplier,
			player_ref.gravity_multiplier
		)

func open_mystery_pack(pack_data):
	var num_items = randi_range(1, 3) if pack_data["name"] == "Common Pack" else randi_range(2, 4)
	
	print("Opening ", pack_data["name"], "...")
	for i in range(num_items):
		var random_item = gear_items[randi() % gear_items.size()]
		print("  → Got: ", random_item["name"])
		apply_gear_effect(random_item)

func apply_upgrade(upgrade_data):
	print("→ Applied upgrade: ", upgrade_data["name"])
	# TODO: Implement specific upgrade effects

func apply_armor_effect(item_data):
	print("→ Equipped: ", item_data["name"], " to slot: ", item_data["slot"])
	
	var stat_notif = get_node_or_null("/root/StatNotifications")
	
	# Apply stat bonus from armor
	if item_data.has("bonus_type") and item_data.has("bonus_value"):
		var bonus_type = item_data["bonus_type"]
		var bonus_value = item_data["bonus_value"]
		
		match bonus_type:
			"speed":
				var old_speed = player_ref.speed_multiplier
				player_ref.speed_multiplier += bonus_value
				if stat_notif:
					stat_notif.show_stat_change("Speed", old_speed, player_ref.speed_multiplier, Color.STEEL_BLUE)
				print("  + Speed bonus: ", bonus_value, " (new total: ", player_ref.speed_multiplier, "x)")
			"jump":
				var old_jump = player_ref.jump_multiplier
				player_ref.jump_multiplier += bonus_value
				if stat_notif:
					stat_notif.show_stat_change("Jump", old_jump, player_ref.jump_multiplier, Color.STEEL_BLUE)
				print("  + Jump bonus: ", bonus_value, " (new total: ", player_ref.jump_multiplier, "x)")
			"gravity":
				var old_gravity = player_ref.gravity_multiplier
				player_ref.gravity_multiplier += bonus_value  # negative value = less gravity
				if stat_notif:
					stat_notif.show_stat_change("Gravity", old_gravity, player_ref.gravity_multiplier, Color.STEEL_BLUE)
				print("  + Gravity bonus: ", bonus_value, " (new total: ", player_ref.gravity_multiplier, "x)")
		
		# Save powerups to persist between levels
		save_powerups_to_manager()
	
	# Add armor to inventory
	var inventory = get_node_or_null("/root/InventoryUI")
	print("Looking for inventory... found: ", inventory != null)
	
	if inventory:
		print("Calling equip_item on inventory")
		inventory.equip_item(item_data["slot"], item_data)
	else:
		print("Warning: Inventory not found at /root/InventoryUI")
