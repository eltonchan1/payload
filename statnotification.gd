extends CanvasLayer

var notification_panel
var stat_labels = {}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_notification_ui()
	hide_notification()
	print("StatNotification ready")

func build_notification_ui():
	# Main container
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(control)
	
	# Notification panel (positioned under blocks counter)
	notification_panel = PanelContainer.new()
	notification_panel.custom_minimum_size = Vector2(300, 120)
	# Position it top-left, under where blocks counter would be
	notification_panel.position = Vector2(10, 60)
	control.add_child(notification_panel)
	
	# Layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	notification_panel.add_child(vbox)
	
	# Create stat display rows
	var stats_data = [
		{"key": "speed", "name": "Speed", "icon": "⚡"},
		{"key": "jump", "name": "Jump", "icon": "🦘"},
		{"key": "gravity", "name": "Gravity", "icon": "🪶"},
		{"key": "blocks", "name": "Blocks", "icon": "🧱"}
	]
	
	for stat in stats_data:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		
		# Icon
		var icon_label = Label.new()
		icon_label.text = stat["icon"]
		icon_label.add_theme_font_size_override("font_size", 20)
		hbox.add_child(icon_label)
		
		# Stat name
		var name_label = Label.new()
		name_label.text = stat["name"] + ":"
		name_label.custom_minimum_size = Vector2(80, 0)
		name_label.add_theme_font_size_override("font_size", 18)
		hbox.add_child(name_label)
		
		# Value label (will animate)
		var value_label = Label.new()
		value_label.name = stat["key"] + "_value"
		value_label.text = "1.0x"
		value_label.add_theme_font_size_override("font_size", 24)
		value_label.add_theme_color_override("font_color", Color.WHITE)
		stat_labels[stat["key"]] = value_label
		hbox.add_child(value_label)
		
		# Arrow (hidden by default)
		var arrow_label = Label.new()
		arrow_label.name = stat["key"] + "_arrow"
		arrow_label.text = "→"
		arrow_label.add_theme_font_size_override("font_size", 24)
		arrow_label.add_theme_color_override("font_color", Color.YELLOW)
		arrow_label.visible = false
		hbox.add_child(arrow_label)
		
		# New value label (hidden by default)
		var new_value_label = Label.new()
		new_value_label.name = stat["key"] + "_new"
		new_value_label.text = "1.5x"
		new_value_label.add_theme_font_size_override("font_size", 24)
		new_value_label.add_theme_color_override("font_color", Color.GREEN)
		new_value_label.visible = false
		hbox.add_child(new_value_label)
		
		vbox.add_child(hbox)
	
	print("Stat notification UI built")

func show_notification():
	notification_panel.visible = true

func hide_notification():
	notification_panel.visible = false

func animate_stat_change(stat_name: String, old_value: float, new_value: float):
	var value_label = stat_labels.get(stat_name)
	if not value_label:
		return
	
	# Get the arrow and new value labels
	var arrow_label = notification_panel.get_node_or_null("VBoxContainer").get_node_or_null("HBoxContainer").get_node_or_null(stat_name + "_arrow")
	var new_value_label = notification_panel.get_node_or_null("VBoxContainer").get_node_or_null("HBoxContainer").get_node_or_null(stat_name + "_new")
	
	# Find the correct HBoxContainer for this stat
	for hbox in notification_panel.get_node("VBoxContainer").get_children():
		var arrow = hbox.get_node_or_null(stat_name + "_arrow")
		var new_val = hbox.get_node_or_null(stat_name + "_new")
		if arrow and new_val:
			arrow_label = arrow
			new_value_label = new_val
			break
	
	# Update current value
	if stat_name == "blocks":
		value_label.text = str(int(old_value))
	else:
		value_label.text = str(snappedf(old_value, 0.01)) + "x"
	
	# Show the notification panel
	show_notification()
	
	# Create animation
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# Fade in
	notification_panel.modulate = Color(1, 1, 1, 0)
	tween.tween_property(notification_panel, "modulate", Color.WHITE, 0.3)
	
	# Wait a moment
	tween.tween_interval(0.3)
	
	# Show arrow and new value
	tween.tween_callback(func():
		if arrow_label:
			arrow_label.visible = true
		if new_value_label:
			new_value_label.visible = true
			if stat_name == "blocks":
				new_value_label.text = str(int(new_value))
			else:
				new_value_label.text = str(snappedf(new_value, 0.01)) + "x"
	)
	
	# Animate the counting
	var duration = 0.8
	var steps = 20
	var step_time = duration / steps
	
	for i in range(steps + 1):
		var progress = float(i) / steps
		var current_value = lerp(old_value, new_value, progress)
		
		tween.tween_callback(func():
			if stat_name == "blocks":
				value_label.text = str(int(current_value))
			else:
				value_label.text = str(snappedf(current_value, 0.01)) + "x"
		)
		
		if i < steps:
			tween.tween_interval(step_time)
	
	# Pop effect on value
	tween.parallel().tween_property(value_label, "scale", Vector2(1.3, 1.3), 0.4)
	tween.parallel().tween_property(value_label, "modulate", Color.YELLOW, 0.4)
	
	# Scale back
	tween.tween_property(value_label, "scale", Vector2(1.0, 1.0), 0.3)
	tween.parallel().tween_property(value_label, "modulate", Color.WHITE, 0.3)
	
	# Wait before fading out
	tween.tween_interval(1.0)
	
	# Fade out entire panel
	tween.tween_property(notification_panel, "modulate", Color(1, 1, 1, 0), 0.5)
	
	# Hide everything at the end
	tween.tween_callback(func():
		hide_notification()
		if arrow_label:
			arrow_label.visible = false
		if new_value_label:
			new_value_label.visible = false
		notification_panel.modulate = Color.WHITE
	)
