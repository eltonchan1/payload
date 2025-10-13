extends Area2D

@onready var sprite = $Sprite2D 

func _ready():
	body_entered.connect(_on_body_entered)
	print("Goal area ready")

func _on_body_entered(body):
	if "blocks_remaining" in body:
		print("Player reached the goal!")
		
		# Get player's remaining blocks
		var remaining_blocks = body.blocks_remaining
		var bonus_blocks = max(2, (remaining_blocks / 5) * 2)
		
		print("Player finished with ", remaining_blocks, " blocks")
		print("Bonus reward: +", bonus_blocks, " blocks!")
		
		# Wait a moment before loading next level
		await get_tree().create_timer(1.0).timeout
		
		# Tell level manager to load next level with blocks count
		if has_node("/root/LevelManager"):
			get_node("/root/LevelManager").level_completed(remaining_blocks)
		else:
			print("LevelManager not found!")
