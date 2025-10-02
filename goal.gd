extends Area2D

# Visual feedback
@onready var sprite = $Sprite2D  # Or ColorRect

func _ready():
	body_entered.connect(_on_body_entered)
	print("Goal area ready")

func _on_body_entered(body):
	if "blocks_remaining" in body:
		print("Player reached the goal!")
		
		# Get player's remaining blocks
		var remaining_blocks = body.blocks_remaining
		print("Player finished with ", remaining_blocks, " blocks")
		
		# Visual feedback
		animate_completion()
		
		# Wait a moment before loading next level
		await get_tree().create_timer(1.0).timeout
		
		# Tell level manager to load next level with blocks count
		if has_node("/root/LevelManager"):
			get_node("/root/LevelManager").level_completed(remaining_blocks)
		else:
			print("LevelManager not found!")

func animate_completion():
	# Simple pulse animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.3)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.3)
