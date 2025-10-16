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
	if visible and has_node("/root/SpeedrunManager"):
		var manager = get_node("/root/SpeedrunManager")
		if manager.speedrun_active:
			timer_label.text = manager.format_time(manager.get_current_time())
