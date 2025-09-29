extends RigidBody2D

func _ready():
	# Set physics properties
	gravity_scale = 1.0
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	
	# Set collision layers to avoid conflicts
	collision_layer = 2   # Layer 2 for blocks
	collision_mask = 1    # Can hit layer 1 (ground/walls)
	
	# Auto-delete after 10 seconds
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
