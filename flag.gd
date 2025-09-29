extends Area2D

signal flag_touched(blocks_to_add)

func _ready():
	print("Flag created and ready")
	body_entered.connect(_on_body_entered)
	
	# Make sure we're monitoring
	monitoring = true
	monitorable = true

func _on_body_entered(body):
	print("Something touched the flag: ", body.name)
	
	# Check if it's the player by looking for blocks_remaining property
	if "blocks_remaining" in body:
		print("Player confirmed! Current blocks: ", body.blocks_remaining)
		
		# Calculate bonus: 2 blocks for every 5 current blocks (minimum 2)
		var current_blocks = body.blocks_remaining
		var bonus_blocks = max(2, (current_blocks / 5) * 2)
		
		print("Giving player ", bonus_blocks, " bonus blocks")
		
		# Send signal
		flag_touched.emit(bonus_blocks)
		
		# Disable this flag
		visible = false
		set_deferred("monitoring", false)
		print("Flag disabled")
