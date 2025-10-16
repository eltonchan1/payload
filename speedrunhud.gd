extends CanvasLayer

@onready var timer_label = $TimerLabel

func _ready():
	# Check if speedrun is active
	if has_node("/root/SpeedrunManager"):
		var manager = get_node("/root/SpeedrunManager")
		visible = manager.speedrun_active
	else:
		visible = false

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
