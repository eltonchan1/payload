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

# UI references
@onready var block_label = get_node("Camera2D/BlockLabel")
@onready var powerup_menu = get_node("../PowerupMenu")  # Adjust path as needed

func _ready():
	# Load your block scene
	block_scene = preload("res://Block.tscn")
	
	# Setup the label with better visibility
	if block_label:
		block_label.visible = true
		block_label.position = Vector2(20, 20)
		block_label.add_theme_font_size_override("font_size", 32)
		block_label.add_theme_color_override("font_color", Color.YELLOW)
		print("Block label setup complete")
	else:
		print("ERROR: Block label not found at Camera2D/BlockLabel")
	
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
