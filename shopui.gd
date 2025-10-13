extends CanvasLayer

var player_ref = null
var current_tab = 0

var blocks_label
var content_container

var current_gear_shop = []
var current_armor_shop = []
var current_mystery_shop = []
var current_upgrade_shop = []
var shop_level_counter = -1

var purchased_items = []
var purchased_upgrades = []

var gear_items = [
	{"name": "Speed Potion", "cost": 3, "description": "Increase movement speed by 20%", "effect": "speed"},
	{"name": "Jump Elixir", "cost": 4, "description": "Jump 20% higher", "effect": "jump"},
	{"name": "Feather Charm", "cost": 3, "description": "Reduce gravity by 10%", "effect": "gravity"},
	{"name": "Giveaway", "cost": 0, "description": "Gain 5 extra blocks", "effect": "blocks"}
]

var armor_items = [
	{"name": "Speed Helmet", "cost": 5, "slot": "head", "icon": "res://assets/armour/speedhelmet.png", "description": "Increase movement speed by 30%", "bonus_type": "speed", "bonus_value": 0.3},
	{"name": "Jump Boots", "cost": 5, "slot": "feet", "icon": "res://assets/armour/jumpboots.png", "description": "Jump 20% higher", "bonus_type": "jump", "bonus_value": 0.2},
	{"name": "Light Chestplate", "cost": 6, "slot": "chest", "icon": "res://assets/armour/lightchestplate.png", "description": "Reduce gravity by 10%", "bonus_type": "gravity", "bonus_value": -0.2},
	{"name": "Agile Leggings", "cost": 4, "slot": "legs", "icon": "res://assets/armour/agileleggings.png", "description": "Increase movement speed by 30%", "bonus_type": "speed", "bonus_value": 0.3},
	{"name": "Plasma Helmet", "cost": 8, "slot": "head", "icon": "res://assets/armour/plasmahelmet.png", "description": "Part of Plasma Set, speed boost", "bonus_type": "speed", "bonus_value": 0.1, "set": "plasma"},
	{"name": "Plasma Chestplate", "cost": 8, "slot": "chest", "icon": "res://assets/armour/plasmachestplate.png", "description": "Part of Plasma Set, jump boost", "bonus_type": "jump", "bonus_value": 0.1, "set": "plasma"},
	{"name": "Plasma Leggings", "cost": 8, "slot": "legs", "icon": "res://assets/armour/plasmaleggings.png", "description": "Part of Plasma Set, gravity decrease", "bonus_type": "gravity", "bonus_value": -0.1, "set": "plasma"},
	{"name": "Plasma Boots", "cost": 8, "slot": "feet", "icon": "res://assets/armour/plasmaboots.png", "description": "Part of Plasma Set, speed boost", "bonus_type": "speed", "bonus_value": 0.1, "set": "plasma"}
]

var mystery_packs = [
	{"name": "Common Pack", "cost": 6, "description": "Contains 1-3 random items"},
	{"name": "Rare Pack", "cost": 10, "description": "Contains 2-4 random items"}
]

var upgrade_items = [
	{"name": "Bulk Discount", "cost": 10, "description": "All items cost 1 less (permanent)", "effect": "discount"},
	{"name": "Extra Shop Slot", "cost": 15, "description": "Get 1 more item per shop category (permanent)", "effect": "extra_slot"}
]

var discount_active = false
var extra_shop_slots = 0
var items_per_category = 2

# Track active permanent upgrades
var active_upgrades = []

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_shop_ui()
	print("ShopUI ready and loaded as autoload")

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		print("ESC pressed - closing shop")
		hide_shop()
		get_viewport().set_input_as_handled()
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S:
			print("S key pressed in shop - closing")
			hide_shop()
			get_viewport().set_input_as_handled()
			return

func show_shop(player):
	print("show_shop() called with player: ", player)
	player_ref = player
	
	var level_manager = get_node_or_null("/root/LevelManager")
	var current_level_count = 0
	if level_manager:
		current_level_count = level_manager.levels_completed
	
	print("Opening shop - Level count: ", current_level_count, ", Last shop level: ", shop_level_counter)
	
	if shop_level_counter != current_level_count:
		print("NEW LEVEL - Randomizing shop inventory")
		randomize_shop_inventory()
		shop_level_counter = current_level_count
	else:
		print("SAME LEVEL - Using existing shop inventory")
	
	visible = true
	get_tree().paused = true
	update_blocks_display()
	switch_tab(0)
	print("Shop opened successfully")

func hide_shop():
	visible = false
	var inventory_ui = get_node_or_null("/root/InventoryUI")
	if not inventory_ui or not inventory_ui.visible:
		get_tree().paused = false
	print("Shop closed")

func build_shop_ui():
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(700, 500)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-350, -250)
	control.add_child(panel)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	main_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_vbox)
	
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
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	content_container = VBoxContainer.new()
	content_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_theme_constant_override("separation", 10)
	scroll.add_child(content_container)
	main_vbox.add_child(scroll)
	
	print("Shop UI built successfully")

func update_blocks_display():
	if blocks_label and player_ref:
		blocks_label.text = "Blocks: " + str(player_ref.blocks_remaining)

func switch_tab(tab_index):
	current_tab = tab_index
	populate_current_tab()

func populate_current_tab():
	if not content_container:
		return
	
	for child in content_container.get_children():
		child.queue_free()
	
	match current_tab:
		0:
			for item in current_gear_shop:
				content_container.add_child(create_shop_card(item, "gear"))
		1:
			for item in current_armor_shop:
				content_container.add_child(create_shop_card(item, "armor"))
		2:
			for pack in current_mystery_shop:
				content_container.add_child(create_shop_card(pack, "mystery"))
		3:
			for upgrade in current_upgrade_shop:
				content_container.add_child(create_shop_card(upgrade, "upgrade"))

func create_shop_card(item_data, item_type):
	var item_name = item_data.get("name", "Unknown")
	var is_sold_out = false
	
	if item_type == "upgrade":
		is_sold_out = purchased_upgrades.has(item_name)
	else:
		is_sold_out = purchased_items.has(item_name)
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(650, 80)
	
	if is_sold_out:
		card.modulate = Color(0.5, 0.5, 0.5)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = item_name + (" [SOLD OUT]" if is_sold_out else "")
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.RED if is_sold_out else Color.YELLOW)
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item_data.get("description", "")
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	var bottom_hbox = HBoxContainer.new()
	var cost_label = Label.new()
	
	var final_cost = item_data.get("cost", 0)
	if discount_active and final_cost > 0:
		final_cost = max(0, final_cost - 1)
		cost_label.text = "Cost: " + str(final_cost) + " blocks (discounted!)"
		cost_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	else:
		cost_label.text = "Cost: " + str(final_cost) + " blocks"
	
	cost_label.add_theme_font_size_override("font_size", 16)
	bottom_hbox.add_child(cost_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(spacer)
	
	var buy_btn = Button.new()
	buy_btn.text = "SOLD OUT" if is_sold_out else "Purchase"
	buy_btn.custom_minimum_size = Vector2(100, 30)
	buy_btn.disabled = is_sold_out
	buy_btn.pressed.connect(func(): purchase_item(item_data, item_type))
	bottom_hbox.add_child(buy_btn)
	
	vbox.add_child(bottom_hbox)
	
	return card

func purchase_item(item_data, item_type):
	if not player_ref:
		return
	
	var base_cost = item_data["cost"]
	var final_cost = base_cost
	if discount_active and base_cost > 0:
		final_cost = max(0, base_cost - 1)
	
	var item_name = item_data.get("name", "Unknown")
	
	if player_ref.blocks_remaining >= final_cost:
		player_ref.blocks_remaining -= final_cost
		player_ref.update_block_label()
		update_blocks_display()
		
		if item_type == "upgrade":
			purchased_upgrades.append(item_name)
		else:
			purchased_items.append(item_name)
		
		apply_item_effect(item_data, item_type)
		populate_current_tab()
		
		print("✓ Purchased: ", item_data["name"], " for ", final_cost, " blocks")
	else:
		print("✗ Not enough blocks!")

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
			player_ref.speed_multiplier += 0.2
			if stat_notif:
				stat_notif.show_stat_change("Speed", old_speed, player_ref.speed_multiplier, Color.CYAN)
			save_powerups_to_manager()
		"jump":
			var old_jump = player_ref.jump_multiplier
			player_ref.jump_multiplier += 0.2
			if stat_notif:
				stat_notif.show_stat_change("Jump", old_jump, player_ref.jump_multiplier, Color.LIGHT_GREEN)
			save_powerups_to_manager()
		"gravity":
			var old_gravity = player_ref.gravity_multiplier
			player_ref.gravity_multiplier -= 0.1
			if player_ref.gravity_multiplier < 0.5:
				player_ref.gravity_multiplier = 0.5
			if stat_notif:
				stat_notif.show_stat_change("Gravity", old_gravity, player_ref.gravity_multiplier, Color.LIGHT_BLUE)
			save_powerups_to_manager()
		"blocks":
			var old_blocks = player_ref.blocks_remaining
			player_ref.blocks_remaining += 5
			player_ref.update_block_label()
			update_blocks_display()
			if stat_notif:
				stat_notif.show_blocks_change(old_blocks, player_ref.blocks_remaining)

func check_plasma_set_status_before() -> bool:
	var inventory = get_node_or_null("/root/InventoryUI")
	if not inventory:
		return false
	
	var has_helmet = inventory.head_item and inventory.head_item.get("name", "").contains("Plasma")
	var has_chest = inventory.chest_item and inventory.chest_item.get("name", "").contains("Plasma")
	var has_legs = inventory.legs_item and inventory.legs_item.get("name", "").contains("Plasma")
	var has_boots = inventory.feet_item and inventory.feet_item.get("name", "").contains("Plasma")
	
	return has_helmet and has_chest and has_legs and has_boots

func apply_armor_effect(item_data):
	var stat_notif = get_node_or_null("/root/StatNotifications")
	var inventory = get_node_or_null("/root/InventoryUI")
	
	# Check if we had the full set BEFORE this change
	var had_full_set = check_plasma_set_status_before()
	
	var old_armor = null
	if inventory:
		match item_data["slot"]:
			"head":
				old_armor = inventory.head_item
			"chest":
				old_armor = inventory.chest_item
			"legs":
				old_armor = inventory.legs_item
			"feet":
				old_armor = inventory.feet_item
	
	if old_armor:
		var refund = old_armor.get("cost", 0) / 2
		var old_blocks = player_ref.blocks_remaining
		player_ref.blocks_remaining += refund
		player_ref.update_block_label()
		update_blocks_display()
		
		if stat_notif:
			stat_notif.show_blocks_change(old_blocks, player_ref.blocks_remaining)
		
		if old_armor.has("bonus_type") and old_armor.has("bonus_value"):
			match old_armor["bonus_type"]:
				"speed":
					player_ref.speed_multiplier -= old_armor["bonus_value"]
				"jump":
					player_ref.jump_multiplier -= old_armor["bonus_value"]
				"gravity":
					player_ref.gravity_multiplier -= old_armor["bonus_value"]
	
	if item_data.has("bonus_type") and item_data.has("bonus_value"):
		var bonus_type = item_data["bonus_type"]
		var bonus_value = item_data["bonus_value"]
		
		match bonus_type:
			"speed":
				var old_speed = player_ref.speed_multiplier
				player_ref.speed_multiplier += bonus_value
				if stat_notif:
					stat_notif.show_stat_change("Speed", old_speed, player_ref.speed_multiplier, Color.STEEL_BLUE)
			"jump":
				var old_jump = player_ref.jump_multiplier
				player_ref.jump_multiplier += bonus_value
				if stat_notif:
					stat_notif.show_stat_change("Jump", old_jump, player_ref.jump_multiplier, Color.STEEL_BLUE)
			"gravity":
				var old_gravity = player_ref.gravity_multiplier
				player_ref.gravity_multiplier += bonus_value
				if player_ref.gravity_multiplier < 0.1:
					player_ref.gravity_multiplier = 0.1
				if stat_notif:
					stat_notif.show_stat_change("Gravity", old_gravity, player_ref.gravity_multiplier, Color.STEEL_BLUE)
		
		save_powerups_to_manager()
	
	# Equip the armor in inventory (this will trigger the inventory's plasma set check)
	if inventory:
		inventory.equip_item(item_data["slot"], item_data)
		
		# Wait a moment, then check if plasma set status changed
		await get_tree().create_timer(0.1).timeout
		
		var has_full_set_now = inventory.has_plasma_set_bonus
		
		# Show notifications based on set status change
		if not had_full_set and has_full_set_now:
			# Just completed the plasma set!
			await get_tree().create_timer(0.4).timeout
			show_plasma_set_complete_notification()
		elif had_full_set and not has_full_set_now:
			# Just lost the plasma set
			await get_tree().create_timer(0.4).timeout
			show_plasma_set_broken_notification()

func show_plasma_set_complete_notification():
	var stat_notif = get_node_or_null("/root/StatNotifications")
	if not stat_notif:
		return
	
	# Get the actual bonus values from inventory
	var inventory = get_node_or_null("/root/InventoryUI")
	if not inventory:
		return
	
	var old_speed = player_ref.speed_multiplier - inventory.plasma_set_speed_bonus
	var old_jump = player_ref.jump_multiplier - inventory.plasma_set_jump_bonus
	var old_gravity = player_ref.gravity_multiplier - inventory.plasma_set_gravity_bonus
	
	# Show main notification
	if stat_notif.has_method("show_notification"):
		stat_notif.show_notification("PLASMA SET COMPLETE!", "Set bonuses activated!", Color.MAGENTA)
	
	# Show individual stat changes with delays
	await get_tree().create_timer(0.3).timeout
	stat_notif.show_stat_change("Speed", old_speed, player_ref.speed_multiplier, Color.MAGENTA)
	
	await get_tree().create_timer(0.3).timeout
	stat_notif.show_stat_change("Jump", old_jump, player_ref.jump_multiplier, Color.MAGENTA)
	
	await get_tree().create_timer(0.3).timeout
	stat_notif.show_stat_change("Gravity", old_gravity, player_ref.gravity_multiplier, Color.MAGENTA)
	
	print("✓ PLASMA SET COMPLETE - Notification shown!")

func show_plasma_set_broken_notification():
	var stat_notif = get_node_or_null("/root/StatNotifications")
	if not stat_notif:
		return
	
	# Get the actual bonus values from inventory
	var inventory = get_node_or_null("/root/InventoryUI")
	if not inventory:
		return
	
	var old_speed = player_ref.speed_multiplier + inventory.plasma_set_speed_bonus
	var old_jump = player_ref.jump_multiplier + inventory.plasma_set_jump_bonus
	var old_gravity = player_ref.gravity_multiplier + inventory.plasma_set_gravity_bonus
	
	# Show main notification
	if stat_notif.has_method("show_notification"):
		stat_notif.show_notification("Plasma Set Broken", "Set bonuses removed", Color.ORANGE_RED)
	
	# Show individual stat changes with delays
	await get_tree().create_timer(0.3).timeout
	stat_notif.show_stat_change("Speed", old_speed, player_ref.speed_multiplier, Color.ORANGE_RED)
	
	await get_tree().create_timer(0.3).timeout
	stat_notif.show_stat_change("Jump", old_jump, player_ref.jump_multiplier, Color.ORANGE_RED)
	
	await get_tree().create_timer(0.3).timeout
	stat_notif.show_stat_change("Gravity", old_gravity, player_ref.gravity_multiplier, Color.ORANGE_RED)
	
	print("✗ PLASMA SET BROKEN - Notification shown")

func open_mystery_pack(pack_data):
	var num_items = randi_range(1, 3) if pack_data["name"] == "Common Pack" else randi_range(2, 4)
	
	for i in range(num_items):
		var random_item = gear_items[randi() % gear_items.size()]
		apply_gear_effect(random_item)

func apply_upgrade(upgrade_data):
	var stat_notif = get_node_or_null("/root/StatNotifications")
	var upgrade_name = upgrade_data.get("name", "Unknown Upgrade")
	
	match upgrade_data["effect"]:
		"discount":
			discount_active = true
			active_upgrades.append("Bulk Discount - All items cost 1 less")
			print("✓ BULK DISCOUNT ACTIVATED - All items now cost -1 block!")
			if stat_notif and stat_notif.has_method("show_notification"):
				stat_notif.show_notification("Bulk Discount Active!", "All items -1 block", Color.GOLD)
			populate_current_tab()
		"extra_slot":
			extra_shop_slots += 1
			items_per_category = 2 + extra_shop_slots
			active_upgrades.append("Extra Shop Slot - " + str(items_per_category) + " items per category")
			print("✓ EXTRA SHOP SLOT UNLOCKED - Now showing ", items_per_category, " items per category!")
			if stat_notif and stat_notif.has_method("show_notification"):
				stat_notif.show_notification("Extra Shop Slot!", "Now showing " + str(items_per_category) + " items per category", Color.GOLD)
			randomize_shop_inventory()
			populate_current_tab()
	
	print("Active upgrades: ", active_upgrades)

func save_powerups_to_manager():
	var level_manager = player_ref.get_node_or_null("/root/LevelManager")
	if level_manager:
		level_manager.save_powerups(
			player_ref.speed_multiplier,
			player_ref.jump_multiplier,
			player_ref.gravity_multiplier
		)

func randomize_shop_inventory():
	purchased_items.clear()
	
	var gravity_maxed = player_ref and player_ref.gravity_multiplier <= 0.1
	
	var inventory = get_node_or_null("/root/InventoryUI")
	var equipped_slots = []
	if inventory:
		if inventory.head_item:
			equipped_slots.append(inventory.head_item.get("name", ""))
		if inventory.chest_item:
			equipped_slots.append(inventory.chest_item.get("name", ""))
		if inventory.legs_item:
			equipped_slots.append(inventory.legs_item.get("name", ""))
		if inventory.feet_item:
			equipped_slots.append(inventory.feet_item.get("name", ""))
	
	var num_items = items_per_category
	
	var available_gear = []
	for item in gear_items:
		if gravity_maxed and item.get("effect") == "gravity":
			continue
		available_gear.append(item)
	current_gear_shop = get_random_items(available_gear, num_items)
	
	var available_armor = []
	for armor in armor_items:
		if equipped_slots.has(armor.get("name", "")):
			continue
		if gravity_maxed and armor.get("bonus_type") == "gravity":
			continue
		available_armor.append(armor)
	current_armor_shop = get_random_items(available_armor, num_items)
	
	current_mystery_shop = get_random_items(mystery_packs, num_items)
	
	var available_upgrades = []
	for upgrade in upgrade_items:
		if not purchased_upgrades.has(upgrade.get("name", "")):
			available_upgrades.append(upgrade)
	current_upgrade_shop = get_random_items(available_upgrades, num_items)

func get_random_items(source_array: Array, count: int) -> Array:
	var result = []
	var available = source_array.duplicate()
	
	for i in range(min(count, available.size())):
		if available.size() == 0:
			break
		var random_index = randi() % available.size()
		result.append(available[random_index])
		available.remove_at(random_index)
	
	return result
