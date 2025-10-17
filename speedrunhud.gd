extends CanvasLayer

var timer_container: PanelContainer
var timer_label: Label

func _ready():
	# Check if speedrun is active
	if has_node("/root/SpeedrunManager"):
		var manager = get_node("/root/SpeedrunManager")
		visible = manager.speedrun_active
	else:
		visible = false
	
	# Build the timer UI with background panel
	build_timer_ui()

func _process(_delta):
	if has_node("/root/SpeedrunManager"):
		var manager = get_node("/root/SpeedrunManager")
		# Hide HUD if speedrun is not active
		if not manager.speedrun_active:
			visible = false
			return
		# Show and update if speedrun is active
		if manager.speedrun_active:
			visible = true
			timer_label.text = manager.format_time(manager.get_current_time())

func build_timer_ui():
	# Remove the old TimerLabel if it exists
	if has_node("TimerLabel"):
		var old_label = get_node("TimerLabel")
		old_label.queue_free()
	
	# Create a control container positioned in top-right area (but left of actual corner)
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	control.offset_left = -300  # Move left from right edge
	control.offset_top = 10
	control.offset_right = -10
	control.offset_bottom = 70
	add_child(control)
	
	# Create panel container for background
	timer_container = PanelContainer.new()
	timer_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(timer_container)
	
	# Style the panel with semi-transparent dark background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)
	style_box.border_color = Color(1, 1, 1, 0.3)
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(8)
	style_box.content_margin_left = 15
	style_box.content_margin_right = 15
	style_box.content_margin_top = 10
	style_box.content_margin_bottom = 10
	timer_container.add_theme_stylebox_override("panel", style_box)
	
	# Create HBox for icon + timer
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	timer_container.add_child(hbox)
	
	# Add clock icon (using a Label with emoji as fallback)
	var icon_label = Label.new()
	icon_label.text = "⏱"
	icon_label.add_theme_font_size_override("font_size", 32)
	icon_label.add_theme_color_override("font_color", Color.WHITE)
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon_label)
	
	# Create the timer label
	timer_label = Label.new()
	timer_label.text = "0:00.000"
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(timer_label)
