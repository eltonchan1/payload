extends CharacterBody2D

const SPEED = 750.0
const JUMP_VELOCITY = -1500.0

# Block spawning variables
var block_scene: PackedScene
var blocks_remaining = 10

# Powerup variables
var speed_multiplier = 1.0
var jump_multiplier = 1.0
var gravity_multiplier = 1.0

# UI references (will be set in _ready)
var block_label: Label
var powerup_menu: CanvasLayer

func _ready():
	# Load your block scene
	block_scene = preload("res://Block.tscn")
	
	# Get starting blocks from LevelManager (persistent between levels)
	if has_node("/root/LevelManager"):
		blocks_remaining = get_node("/root/LevelManager").get_starting_blocks()
		print("Starting with ", blocks_remaining, " blocks from LevelManager")
	else:
		blocks_remaining = 10  # Fallback if no LevelManager
		print("No LevelManager found, starting with 10 blocks")
	
	# Setup the label with better visibility
	# Try to find label in different possible locations
	if has_node("../../UI/BlockLabel"):
		block_label = get_node("../../UI/BlockLabel")
	elif has_node("../UI/BlockLabel"):
		block_label = get_node("../UI/BlockLabel")
	
	if block_label:
		block_label.visible = true
		# Position in top-left corner
		block_label.position = Vector2(10, 10)
		# Set anchor to top-left
		block_label.anchor_left = 0
		block_label.anchor_top = 0
		block_label.anchor_right = 0
		block_label.anchor_bottom = 0
		# Make text larger and white
		block_label.add_theme_font_size_override("font_size", 32)
		block_label.add_theme_color_override("font_color", Color.WHITE)
		# Add shadow for better readability
		block_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		block_label.add_theme_constant_override("shadow_offset_x", 2)
		block_label.add_theme_constant_override("shadow_offset_y", 2)
		print("Block label setup complete")
	else:
		print("ERROR: Block label not found")
	
	# Connect to powerup menu - try multiple paths
	var menu_paths = [
		"../../UI/PowerupMenu",
		"../UI/PowerupMenu",
		"../../PowerupMenu",
		"../PowerupMenu"
	]
	
	for path in menu_paths:
		if has_node(path):
			powerup_menu = get_node(path)
			print("Found powerup menu at: ", path)
			break
	
	if powerup_menu:
		if powerup_menu.has_signal("powerup_selected"):
			powerup_menu.powerup_selected.connect(_on_powerup_selected)
			print("Connected to powerup menu successfully")
		else:
			print("PowerupMenu doesn't have powerup_selected signal!")
	else:
		print("Warning: Powerup menu not found at any path")
		print("Player parent: ", get_parent().name)
		print("Player parent's parent: ", get_parent().get_parent().name if get_parent().get_parent() else "none")
	
	# Connect to powerup menu
	if powerup_menu:
		powerup_menu.powerup_selected.connect(_on_powerup_selected)
		print("Connected to powerup menu")
	else:
		print("Warning: Powerup menu not found")
	
	# Connect to flags (with delay to ensure all nodes are ready)
	call_deferred("connect_to_flags")
	
	# Update the label initially
	update_block_label()

func _physics_process(delta: float) -> void:
	# Add gravity with multiplier
	if not is_on_floor():
		velocity += get_gravity() * delta * 2 * gravity_multiplier
	
	# Handle jumping
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# Ground jump (always available)
			velocity.y = JUMP_VELOCITY * jump_multiplier
		elif blocks_remaining > 0:
			# Air jump - costs a block
			spawn_falling_block()
			velocity.y = JUMP_VELOCITY * jump_multiplier
			blocks_remaining -= 1
			update_block_label()
	
	# Handle movement
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * speed_multiplier)
	
	move_and_slide()

func spawn_falling_block():
	if block_scene:
		var block = block_scene.instantiate()
		block.global_position = global_position + Vector2(0, 64)
		get_tree().current_scene.add_child(block)
		
		# Track blocks used in LevelManager
		if has_node("/root/LevelManager"):
			get_node("/root/LevelManager").blocks_used(1)

func update_block_label():
	if block_label:
		block_label.text = "Blocks: " + str(blocks_remaining)

func connect_to_flags():
	print("Searching for flags...")
	var flags = get_tree().get_nodes_in_group("flags")
	print("Found ", flags.size(), " flag(s)")
	
	for flag in flags:
		print("Connecting to flag: ", flag.name)
		flag.flag_touched.connect(_on_flag_touched)

func _on_flag_touched(bonus_blocks):
	print("Flag activated! Getting ", bonus_blocks, " bonus blocks")
	blocks_remaining += bonus_blocks
	update_block_label()
	
	# Show powerup menu
	if powerup_menu:
		powerup_menu.show_menu()

func _on_powerup_selected(powerup_type):
	print("Selected powerup: ", powerup_type)
	
	match powerup_type:
		"speed":
			speed_multiplier += 0.5
			print("Speed boost applied!")
		"jump":
			jump_multiplier += 0.3
			print("Jump boost applied!")
		"gravity":
			gravity_multiplier -= 0.3
			print("Gravity reduction applied!")
		"blocks":
			blocks_remaining += 5
			update_block_label()
			print("Got 5 extra blocks!")
