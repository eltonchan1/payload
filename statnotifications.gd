extends CanvasLayer

# UI container for notifications
var notification_container: VBoxContainer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_notification_ui()
	print("StatNotifications ready")

func build_notification_ui():
	# Main container
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)
	
	# Notification container (positioned under block counter)
	notification_container = VBoxContainer.new()
	notification_container.position = Vector2(20, 70)  # Under block counter at (20, 50)
	notification_container.add_theme_constant_override("separation", 5)
	notification_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(notification_container)

func show_stat_change(stat_name: String, old_value: float, new_value: float, color: Color = Color.YELLOW):
	# Create notification label
	var notification = create_stat_notification(stat_name, old_value, new_value, color)
	notification_container.add_child(notification)
	
	# Animate it
	animate_notification(notification)
	
	print("Showing stat change: ", stat_name, " ", old_value, " → ", new_value)

func create_stat_notification(stat_name: String, old_value: float, new_value: float, color: Color) -> Label:
	var label = Label.new()
	
	# Format the text
	var formatted_old = format_stat_value(stat_name, old_value)
	var formatted_new = format_stat_value(stat_name, new_value)
	
	label.text = stat_name + ": " + formatted_old + " → " + formatted_new
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	
	# Add shadow for visibility
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Start transparent
	label.modulate = Color(1, 1, 1, 0)
	
	return label

func format_stat_value(stat_name: String, value: float) -> String:
	match stat_name:
		"Speed", "Jump", "Gravity":
			return str(snapped(value, 0.1)) + "x"
		"Blocks":
			return str(int(value))
		_:
			return str(value)

func animate_notification(notification: Label):
	var tween = create_tween()
	
	# Phase 1: Fade in (0.3s) - don't slide, just fade
	tween.tween_property(notification, "modulate:a", 1.0, 0.3)
	
	# Phase 2: Stay visible (1.5s)
	tween.tween_interval(1.5)
	
	# Phase 3: Fade out (0.5s)
	tween.tween_property(notification, "modulate:a", 0.0, 0.5)
	
	# Phase 4: Remove from scene
	tween.tween_callback(notification.queue_free)

func show_item_purchased(item_name: String, item_type: String):
	# Show what was purchased
	var notification = Label.new()
	notification.text = "Purchased: " + item_name
	notification.add_theme_font_size_override("font_size", 28)
	
	# Color based on type
	var color = Color.CYAN
	match item_type:
		"gear":
			color = Color.YELLOW
		"armor":
			color = Color.STEEL_BLUE
		"mystery":
			color = Color.PURPLE
		"upgrade":
			color = Color.ORANGE
	
	notification.add_theme_color_override("font_color", color)
	notification.add_theme_color_override("font_shadow_color", Color.BLACK)
	notification.add_theme_constant_override("shadow_offset_x", 2)
	notification.add_theme_constant_override("shadow_offset_y", 2)
	notification.modulate = Color(1, 1, 1, 0)
	
	notification_container.add_child(notification)
	animate_notification(notification)
	
	print("Showing purchase: ", item_name)

func show_blocks_change(old_blocks: int, new_blocks: int):
	show_stat_change("Blocks", float(old_blocks), float(new_blocks), Color.LIME_GREEN)
