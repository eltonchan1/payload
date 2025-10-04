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

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Changed from WHEN_PAUSED
	build_inventory_ui()
	print("InventoryUI ready - Press Q to open")

func _input(event):
	# Only process keyboard events to avoid spam from mouse movement
	if not event is InputEventKey:
		return
	
	# Don't process input if shop is open
	var shop_ui = get_node_or_null("/root/ShopUI")
	if shop_ui and shop_ui.visible:
		return
	
	# Toggle inventory with Q key or Shift keys
	if event.pressed and not event.echo:
		if event.keycode == KEY_Q or event.keycode == KEY_SHIFT or event.keycode == KEY_SHIFT:
			print("Toggle key pressed - toggling inventory")
			toggle_inventory()
			get_viewport().set_input_as_handled()
			return
	
	# Also check for the proper input action if it exists
	if InputMap.has_action("inventory_toggle") and event.is_action_pressed("inventory_toggle"):
		print("inventory_toggle action pressed")
		toggle_inventory()
		get_viewport().set_input_as_handled()
		return
	
	# Also allow ESC to close (but don't open with ESC)
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
	# Don't open if shop is open
	var shop_ui = get_node_or_null("/root/ShopUI")
	if shop_ui and shop_ui.visible:
		print("Can't open inventory - shop is open")
		return
	
	# Find player
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
	
	visible = true
	# Only pause if not already paused
	if not get_tree().paused:
		get_tree().paused = true
	update_stats_display()
	print("Inventory opened")

func hide_inventory():
	visible = false
	# Only unpause if shop is not open
	var shop_ui = get_node_or_null("/root/ShopUI")
	if not shop_ui or not shop_ui.visible:
		get_tree().paused = false
	print("Inventory closed")

func build_inventory_ui():
	# Main container
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	# Main panel
	inventory_panel = Panel.new()
	inventory_panel.custom_minimum_size = Vector2(600, 500)
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	inventory_panel.position = Vector2(-300, -250)
	control.add_child(inventory_panel)
	
	# Main layout
	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 15)
	main_hbox.add_theme_constant_override("separation", 20)
	inventory_panel.add_child(main_hbox)
	
	# Left side - Equipment
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(250, 0)
	left_vbox.add_theme_constant_override("separation", 10)
	
	var equip_title = Label.new()
	equip_title.text = "EQUIPMENT"
	equip_title.add_theme_font_size_override("font_size", 24)
	equip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_vbox.add_child(equip_title)
	
	# Create equipment slots
	head_slot = create_equipment_slot("Head", "helmet")
	chest_slot = create_equipment_slot("Chest", "chestplate")
	legs_slot = create_equipment_slot("Legs", "leggings")
	feet_slot = create_equipment_slot("Feet", "boots")
	
	left_vbox.add_child(head_slot)
	left_vbox.add_child(chest_slot)
	left_vbox.add_child(legs_slot)
	left_vbox.add_child(feet_slot)
	
	main_hbox.add_child(left_vbox)
	
	# Right side - Stats
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 10)
	
	var stats_title = Label.new()
	stats_title.text = "STATS"
	stats_title.add_theme_font_size_override("font_size", 24)
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_vbox.add_child(stats_title)
	
	# Create stats display
	stats_labels["speed"] = create_stat_label("Speed")
	stats_labels["jump"] = create_stat_label("Jump Power")
	stats_labels["gravity"] = create_stat_label("Gravity")
	stats_labels["blocks"] = create_stat_label("Blocks")
	
	for stat in stats_labels.values():
		right_vbox.add_child(stat)
	
	# Add powerup list
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
	
	# Close button at bottom
	var close_btn = Button.new()
	close_btn.text = "Close (Q or ESC)"
	close_btn.custom_minimum_size = Vector2(200, 40)
	close_btn.pressed.connect(hide_inventory)
	
	# Position close button at bottom center manually
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

func create_equipment_slot(slot_name: String, _slot_type: String) -> PanelContainer:
	var slot_panel = PanelContainer.new()
	slot_panel.custom_minimum_size = Vector2(230, 70)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	slot_panel.add_child(hbox)
	
	# Slot icon/placeholder
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(50, 50)
	icon.color = Color(0.3, 0.3, 0.3)
	hbox.add_child(icon)
	
	# Slot info
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
	
	return slot_panel

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

func update_stats_display():
	if not player_ref:
		return
	
	# Update stats
	stats_labels["speed"].get_node("Value").text = str(player_ref.speed_multiplier) + "x"
	stats_labels["jump"].get_node("Value").text = str(player_ref.jump_multiplier) + "x"
	stats_labels["gravity"].get_node("Value").text = str(player_ref.gravity_multiplier) + "x"
	stats_labels["blocks"].get_node("Value").text = str(player_ref.blocks_remaining)
	
	# Color code stats (green if boosted, white if normal)
	if player_ref.speed_multiplier > 1.0:
		stats_labels["speed"].get_node("Value").add_theme_color_override("font_color", Color.GREEN)
	
	if player_ref.jump_multiplier > 1.0:
		stats_labels["jump"].get_node("Value").add_theme_color_override("font_color", Color.GREEN)
	
	if player_ref.gravity_multiplier < 1.0:
		stats_labels["gravity"].get_node("Value").add_theme_color_override("font_color", Color.GREEN)
	
	# Update powerups list
	update_powerups_list()

func update_powerups_list():
	var powerups_list = inventory_panel.get_node_or_null("HBoxContainer/VBoxContainer2/PowerupsList")
	if not powerups_list:
		return
	
	# Clear existing
	for child in powerups_list.get_children():
		child.queue_free()
	
	# Add active powerups
	var powerups = []
	
	if player_ref.speed_multiplier > 1.0:
		var boost = (player_ref.speed_multiplier - 1.0) * 100
		powerups.append("• Speed Boost (+" + str(int(boost)) + "%)")
	
	if player_ref.jump_multiplier > 1.0:
		var boost = (player_ref.jump_multiplier - 1.0) * 100
		powerups.append("• Jump Boost (+" + str(int(boost)) + "%)")
	
	if player_ref.gravity_multiplier < 1.0:
		var reduction = (1.0 - player_ref.gravity_multiplier) * 100
		powerups.append("• Reduced Gravity (-" + str(int(reduction)) + "%)")
	
	if powerups.size() == 0:
		var none_label = Label.new()
		none_label.text = "No upgrades active"
		none_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		powerups_list.add_child(none_label)
	else:
		for powerup in powerups:
			var label = Label.new()
			label.text = powerup
			label.add_theme_color_override("font_color", Color.CYAN)
			powerups_list.add_child(label)

# Equipment management functions (for future use)
func equip_item(slot: String, item_data: Dictionary):
	print("equip_item called - slot: ", slot, ", item: ", item_data.get("name", "???"))
	
	var slot_node = null
	match slot:
		"head":
			head_item = item_data
			slot_node = head_slot
		"chest":
			chest_item = item_data
			slot_node = chest_slot
		"legs":
			legs_item = item_data
			slot_node = legs_slot
		"feet":
			feet_item = item_data
			slot_node = feet_slot
	
	if slot_node:
		# Find the ItemLabel by searching through children
		var item_label = find_item_label(slot_node)
		if item_label:
			item_label.text = item_data.get("name", "???")
			item_label.add_theme_color_override("font_color", Color.GREEN)
			print("✓ Updated ", slot, " slot to: ", item_data.get("name"))
		else:
			print("✗ Could not find ItemLabel in slot")
	else:
		print("✗ Slot node not found")

# Helper function to find the ItemLabel recursively
func find_item_label(node: Node) -> Label:
	if node.name == "ItemLabel" and node is Label:
		return node
	for child in node.get_children():
		var result = find_item_label(child)
		if result:
			return result
	return null
