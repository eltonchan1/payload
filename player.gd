extends CharacterBody2D

const SPEED = 750.0
const JUMP_VELOCITY = -1500.0

# Platformer feel improvements
const JUMP_BUFFER_TIME = 0.15  # How long to remember jump input
const COYOTE_TIME = 0.15  # How long you can jump after leaving ground
const LEDGE_PUSH_DISTANCE = 10.0  # How far to push off ledges

var jump_buffer_timer = 0.0
var coyote_timer = 0.0
var was_on_floor = false

# Block spawning variables
var block_scene: PackedScene
var blocks_remaining = 10
var block_place_sfx: AudioStreamPlayer  # SFX for placing blocks

# Powerup variables
var speed_multiplier = 1.0
var jump_multiplier = 1.0
var gravity_multiplier = 1.0

# UI references (will be set in _ready)
var block_label: Label
# powerup_menu removed - now using shop system

func _ready():
	# Add player to group so inventory can find it
	add_to_group("player")
	
	# Load your block scene
	block_scene = preload("res://Block.tscn")
	
	block_place_sfx = AudioStreamPlayer.new()
	block_place_sfx.bus = "SFX"
	block_place_sfx.stream = preload("res://audio/sfx/blockplace.mp3")
	add_child(block_place_sfx)
	
	# Get starting blocks from LevelManager (persistent between levels)
	if has_node("/root/LevelManager"):
		var level_manager = get_node("/root/LevelManager")
		blocks_remaining = level_manager.get_starting_blocks()
		
		# Load powerups from previous levels
		speed_multiplier = level_manager.get_speed_multiplier()
		jump_multiplier = level_manager.get_jump_multiplier()
		gravity_multiplier = level_manager.get_gravity_multiplier()
		
		print("Starting with ", blocks_remaining, " blocks from LevelManager")
		print("Powerups loaded - Speed: ", speed_multiplier, "x, Jump: ", jump_multiplier, "x, Gravity: ", gravity_multiplier, "x")
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
		# Convert Label to HBoxContainer with icon + text
		setup_block_counter_with_icon()
		print("Block label setup complete with icon")
	else:
		print("ERROR: Block label not found")
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
			block_place_sfx.play()
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
		block_label.text = str(blocks_remaining)  # Just the number now
	
	# Also update shop UI if it's open (check autoload first)
	var shop_ui = get_node_or_null("/root/ShopUI")
	if not shop_ui:
		shop_ui = get_tree().current_scene.get_node_or_null("UI/ShopUI")
	
	if shop_ui and shop_ui.visible:
		shop_ui.update_blocks_display()

func setup_block_counter_with_icon():
	# Create an HBoxContainer to hold icon + number
	var parent = block_label.get_parent()
	
	var container = HBoxContainer.new()
	container.position = Vector2(10, 10)
	container.add_theme_constant_override("separation", 10)
	
	# Create icon (TextureRect)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Load your block sprite (CHANGE THIS PATH to your actual block image)
	var block_texture = load("res://sprites/block.png")  # ← Change this!
	
	if block_texture:
		icon.texture = block_texture
	else:
		# Fallback: Create a simple colored square
		var fallback = ColorRect.new()
		fallback.custom_minimum_size = Vector2(32, 32)
		fallback.color = Color.ORANGE_RED
		container.add_child(fallback)
		print("Warning: Block icon not found at res://sprites/block_icon.png, using fallback")
	
	if icon.texture:
		container.add_child(icon)
	
	# Remove old label and add container
	parent.remove_child(block_label)
	parent.add_child(container)
	
	# Re-setup the label with better styling
	block_label.text = str(blocks_remaining)
	block_label.add_theme_font_size_override("font_size", 32)
	block_label.add_theme_color_override("font_color", Color.WHITE)
	block_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	block_label.add_theme_constant_override("shadow_offset_x", 2)
	block_label.add_theme_constant_override("shadow_offset_y", 2)
	block_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	container.add_child(block_label)

# Removed connect_to_flags and _on_flag_touched - flags are now shops

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
