extends CanvasLayer

var player_ref = null

# Equipment slots
var head_item = null
var chest_item = null
var legs_item = null
var feet_item = null

# UI references (will be created dynamically)
var inventory_panel
var head_slot
var chest_slot
var legs_slot
var feet_slot
var stats_labels = {}

# Icon references for each slot
var head_icon
var chest_icon
var legs_icon
var feet_icon

# Set bonus tracking
var has_plasma_set_bonus = false
var plasma_set_speed_bonus = 1.0  # Additional multiplier
var plasma_set_jump_bonus = 1.0   # Additional multiplier
var plasma_set_gravity_bonus = -0.4  # Subtract from gravity

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_inventory_ui()
	print("InventoryUI ready - Press Q to open")

func _input(event):
	if not event is InputEventKey:
		return
	
	var shop_ui = get_node_or_null("/root/ShopUI")
	if shop_ui and shop_ui.visible:
		return
	
	if event.pressed and not event.echo:
		if event.keycode == KEY_Q or event.keycode == KEY_SHIFT:
			print("Toggle key pressed - toggling inventory")
			toggle_inventory()
			get_viewport().set_input_as_handled()
			return
	
	if InputMap.has_action("inventory_toggle") and event.is_action_pressed("inventory_toggle"):
		print("inventory_toggle action pressed")
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
	
	if visible and event.is_action_pressed("ui_cancel"):
		print("ESC pressed - closing inventory")
		hide_inventory()
		get_viewport().set_input_as_handled()

func toggle_inventory():
	print("Toggle inventory called - current visible state: ", visible)
	if visible:
		hide_inventory()
	else:
		show_inventory()

func show_inventory():
	var shop_ui = get_node_or_null("/root/ShopUI")
	if shop_ui and shop_ui.visible:
		print("Can't open inventory - shop is open")
		return
	
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
	
	visible = true
	if not get_tree().paused:
		get_tree().paused = true
	update_stats_display()
	print("Inventory opened")

func hide_inventory():
	visible = false
	var shop_ui = get_node_or_null("/root/ShopUI")
	if not shop_ui or not shop_ui.visible:
		get_tree().paused = false
	print("Inventory closed")

func build_inventory_ui():
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	inventory_panel = Panel.new()
	inventory_panel.custom_minimum_size = Vector2(600, 500)
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	inventory_panel.position = Vector2(-300, -250)
	control.add_child(inventory_panel)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 15)
	main_hbox.add_theme_constant_override("separation", 20)
	inventory_panel.add_child(main_hbox)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(250, 0)
	left_vbox.add_theme_constant_override("separation", 10)
	
	var equip_title = Label.new()
	equip_title.text = "EQUIPMENT"
	equip_title.add_theme_font_size_override("font_size", 24)
	equip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(equip_title)
	
	var head_result = create_equipment_slot("Head", "helmet")
	head_slot = head_result["slot"]
	head_icon = head_result["icon"]
	
	var chest_result = create_equipment_slot("Chest", "chestplate")
	chest_slot = chest_result["slot"]
	chest_icon = chest_result["icon"]
	
	var legs_result = create_equipment_slot("Legs", "leggings")
	legs_slot = legs_result["slot"]
	legs_icon = legs_result["icon"]
	
	var feet_result = create_equipment_slot("Feet", "boots")
	feet_slot = feet_result["slot"]
	feet_icon = feet_result["icon"]
	
	left_vbox.add_child(head_slot)
	left_vbox.add_child(chest_slot)
	left_vbox.add_child(legs_slot)
	left_vbox.add_child(feet_slot)
	
	main_hbox.add_child(left_vbox)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 10)
	
	var stats_title = Label.new()
	stats_title.text = "STATS"
	stats_title.add_theme_font_size_override("font_size", 24)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(stats_title)
	
	stats_labels["speed"] = create_stat_label("Speed")
	stats_labels["jump"] = create_stat_label("Jump Power")
	stats_labels["gravity"] = create_stat_label("Gravity")
	stats_labels["blocks"] = create_stat_label("Blocks")
	
	for stat in stats_labels.values():
		right_vbox.add_child(stat)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	right_vbox.add_child(spacer)
	
	var powerups_title = Label.new()
	powerups_title.text = "ACTIVE UPGRADES"
	powerups_title.add_theme_font_size_override("font_size", 20)
	right_vbox.add_child(powerups_title)
	
	var powerups_list = VBoxContainer.new()
	powerups_list.name = "PowerupsList"
	right_vbox.add_child(powerups_list)
	
	main_hbox.add_child(right_vbox)
	
	var close_btn = Button.new()
	close_btn.text = "Close (Q or ESC)"
	close_btn.custom_minimum_size = Vector2(200, 40)
	close_btn.pressed.connect(hide_inventory)
	
	close_btn.anchor_left = 0.5
	close_btn.anchor_right = 0.5
	close_btn.anchor_top = 1.0
	close_btn.anchor_bottom = 1.0
	close_btn.offset_left = -100
	close_btn.offset_right = 100
	close_btn.offset_top = -60
	close_btn.offset_bottom = -20
	close_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inventory_panel.add_child(close_btn)
	
	print("Inventory UI built")

func create_equipment_slot(slot_name: String, _slot_type: String) -> Dictionary:
	var slot_panel = PanelContainer.new()
	slot_panel.custom_minimum_size = Vector2(230, 70)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	slot_panel.add_child(hbox)
	
	# Create TextureRect for icon instead of ColorRect
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(50, 50)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.name = "Icon"
	hbox.add_child(icon)
	
	var vbox = VBoxContainer.new()
	var name_label = Label.new()
	name_label.text = slot_name
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	var item_label = Label.new()
	item_label.name = "ItemLabel"
	item_label.text = "Empty"
	item_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(item_label)
	
	hbox.add_child(vbox)
	
	return {"slot": slot_panel, "icon": icon}

func create_stat_label(stat_name: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = stat_name + ":"
	name_label.custom_minimum_size = Vector2(150, 0)
	name_label.add_theme_font_size_override("font_size", 18)
	hbox.add_child(name_label)
	
	var value_label = Label.new()
	value_label.name = "Value"
	value_label.text = "1.0x"
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color.YELLOW)
	hbox.add_child(value_label)
	
	return hbox

func check_plasma_set_bonus():
	# Debug: Print all equipped items
	print("=== CHECKING PLASMA SET ===")
	print("Head: ", head_item.get("name", "Empty") if head_item else "Empty")
	print("Chest: ", chest_item.get("name", "Empty") if chest_item else "Empty")
	print("Legs: ", legs_item.get("name", "Empty") if legs_item else "Empty")
	print("Feet: ", feet_item.get("name", "Empty") if feet_item else "Empty")
	
	# Check if all armor pieces are plasma armor
	var head_is_plasma = head_item != null and head_item.get("name", "").contains("Plasma")
	var chest_is_plasma = chest_item != null and chest_item.get("name", "").contains("Plasma")
	var legs_is_plasma = legs_item != null and legs_item.get("name", "").contains("Plasma")
	var feet_is_plasma = feet_item != null and feet_item.get("name", "").contains("Plasma")
	
	print("Head is plasma: ", head_is_plasma)
	print("Chest is plasma: ", chest_is_plasma)
	print("Legs is plasma: ", legs_is_plasma)
	print("Feet is plasma: ", feet_is_plasma)
	
	var is_plasma_set = head_is_plasma and chest_is_plasma and legs_is_plasma and feet_is_plasma
	
	print("Full set: ", is_plasma_set)
	print("Current set bonus active: ", has_plasma_set_bonus)
	print("========================")
	
	# Apply or remove set bonus
	if is_plasma_set and not has_plasma_set_bonus:
		print("✓ PLASMA SET BONUS ACTIVATED!")
		has_plasma_set_bonus = true
		apply_plasma_set_bonus(true)
	elif not is_plasma_set and has_plasma_set_bonus:
		print("✗ Plasma set bonus removed")
		has_plasma_set_bonus = false
		apply_plasma_set_bonus(false)
	else:
		print("No change in set bonus status")

func apply_plasma_set_bonus(enable: bool):
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
		else:
			print("ERROR: No player found for plasma set bonus!")
			return
	
	if enable:
		# ADD set bonuses to existing stats
		player_ref.speed_multiplier += plasma_set_speed_bonus
		player_ref.jump_multiplier += plasma_set_jump_bonus
		player_ref.gravity_multiplier += plasma_set_gravity_bonus
		
		# Clamp gravity to reasonable values
		if player_ref.gravity_multiplier < 0.1:
			player_ref.gravity_multiplier = 0.1
		
		print("Applied plasma set bonus!")
		print("  → Speed: +", plasma_set_speed_bonus, "x (now ", player_ref.speed_multiplier, "x)")
		print("  → Jump: +", plasma_set_jump_bonus, "x (now ", player_ref.jump_multiplier, "x)")
		print("  → Gravity: ", plasma_set_gravity_bonus, " (now ", player_ref.gravity_multiplier, "x)")
		
		# Save to level manager
		var level_manager = player_ref.get_node_or_null("/root/LevelManager")
		if level_manager:
			level_manager.save_powerups(
				player_ref.speed_multiplier,
				player_ref.jump_multiplier,
				player_ref.gravity_multiplier
			)
	else:
		# REMOVE set bonuses from current stats
		player_ref.speed_multiplier -= plasma_set_speed_bonus
		player_ref.jump_multiplier -= plasma_set_jump_bonus
		player_ref.gravity_multiplier -= plasma_set_gravity_bonus
		
		# Ensure values don't go below minimums
		if player_ref.speed_multiplier < 1.0:
			player_ref.speed_multiplier = 1.0
		if player_ref.jump_multiplier < 1.0:
			player_ref.jump_multiplier = 1.0
		if player_ref.gravity_multiplier < 0.1:
			player_ref.gravity_multiplier = 0.1
		
		print("Removed plasma set bonus")
		print("  → Speed now: ", player_ref.speed_multiplier, "x")
		print("  → Jump now: ", player_ref.jump_multiplier, "x")
		print("  → Gravity now: ", player_ref.gravity_multiplier, "x")
		
		# Save to level manager
		var level_manager = player_ref.get_node_or_null("/root/LevelManager")
		if level_manager:
			level_manager.save_powerups(
				player_ref.speed_multiplier,
				player_ref.jump_multiplier,
				player_ref.gravity_multiplier
			)
	
	# Update UI if visible
	if visible:
		update_stats_display()

func update_stats_display():
	if not player_ref:
		return
	
	stats_labels["speed"].get_node("Value").text = str(player_ref.speed_multiplier) + "x"
	stats_labels["jump"].get_node("Value").text = str(player_ref.jump_multiplier) + "x"
	stats_labels["gravity"].get_node("Value").text = str(player_ref.gravity_multiplier) + "x"
	stats_labels["blocks"].get_node("Value").text = str(player_ref.blocks_remaining)
	
	if player_ref.speed_multiplier > 1.0:
		stats_labels["speed"].get_node("Value").add_theme_color_override("font_color", Color.GREEN)
	else:
		stats_labels["speed"].get_node("Value").add_theme_color_override("font_color", Color.YELLOW)
	
	if player_ref.jump_multiplier > 1.0:
		stats_labels["jump"].get_node("Value").add_theme_color_override("font_color", Color.GREEN)
	else:
		stats_labels["jump"].get_node("Value").add_theme_color_override("font_color", Color.YELLOW)
	
	if player_ref.gravity_multiplier < 1.0:
		stats_labels["gravity"].get_node("Value").add_theme_color_override("font_color", Color.GREEN)
	else:
		stats_labels["gravity"].get_node("Value").add_theme_color_override("font_color", Color.YELLOW)
	
	update_powerups_list()

func update_powerups_list():
	var powerups_list = inventory_panel.get_node_or_null("HBoxContainer/VBoxContainer2/PowerupsList")
	if not powerups_list:
		return
	
	for child in powerups_list.get_children():
		child.queue_free()
	
	var powerups = []
	
	# Check for plasma set bonus first
	if has_plasma_set_bonus:
		powerups.append("• PLASMA SET BONUS (Active!)")
		powerups.append("  +100% Speed, +100% Jump, -40% Gravity")
	
	if player_ref.speed_multiplier > 1.0:
		var boost = (player_ref.speed_multiplier - 1.0) * 100
		powerups.append("• Total Speed: +" + str(int(boost)) + "%")
	
	if player_ref.jump_multiplier > 1.0:
		var boost = (player_ref.jump_multiplier - 1.0) * 100
		powerups.append("• Total Jump: +" + str(int(boost)) + "%")
	
	if player_ref.gravity_multiplier < 1.0:
		var reduction = (1.0 - player_ref.gravity_multiplier) * 100
		powerups.append("• Total Gravity Reduction: -" + str(int(reduction)) + "%")
	
	if powerups.size() == 0:
		var none_label = Label.new()
		none_label.text = "No upgrades active"
		none_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		powerups_list.add_child(none_label)
	else:
		for i in range(powerups.size()):
			var label = Label.new()
			label.text = powerups[i]
			# Make plasma set bonus stand out with magenta color
			if powerups[i].contains("PLASMA SET"):
				label.add_theme_color_override("font_color", Color.MAGENTA)
				label.add_theme_font_size_override("font_size", 16)
			elif powerups[i].begins_with("  "):
				label.add_theme_color_override("font_color", Color.LIGHT_CORAL)
			else:
				label.add_theme_color_override("font_color", Color.CYAN)
			powerups_list.add_child(label)

func equip_item(slot: String, item_data: Dictionary):
	print("equip_item called - slot: ", slot, ", item: ", item_data.get("name", "???"))
	
	# Ensure we have player reference
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
			print("✓ Found player reference")
	
	var slot_node = null
	var icon_node = null
	
	match slot:
		"head":
			head_item = item_data
			slot_node = head_slot
			icon_node = head_icon
		"chest":
			chest_item = item_data
			slot_node = chest_slot
			icon_node = chest_icon
		"legs":
			legs_item = item_data
			slot_node = legs_slot
			icon_node = legs_icon
		"feet":
			feet_item = item_data
			slot_node = feet_slot
			icon_node = feet_icon
	
	if slot_node:
		var item_label = find_item_label(slot_node)
		if item_label:
			item_label.text = item_data.get("name", "???")
			item_label.add_theme_color_override("font_color", Color.GREEN)
			print("✓ Updated ", slot, " slot to: ", item_data.get("name"))
		else:
			print("✗ Could not find ItemLabel in slot")
	else:
		print("✗ Slot node not found")
	
	# Update the icon if icon path is provided
	if icon_node and item_data.has("icon"):
		var icon_path = item_data.get("icon")
		if icon_path and icon_path != "":
			var texture = load(icon_path)
			if texture:
				icon_node.texture = texture
				print("✓ Loaded icon: ", icon_path)
			else:
				print("✗ Failed to load icon: ", icon_path)
		else:
			# Clear icon if no path provided
			icon_node.texture = null
	
	# Check for plasma set bonus after equipping
	check_plasma_set_bonus()

func find_item_label(node: Node) -> Label:
	if node.name == "ItemLabel" and node is Label:
		return node
	for child in node.get_children():
		var result = find_item_label(child)
		if result:
			return result
	return null
