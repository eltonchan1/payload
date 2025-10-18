extends CharacterBody2D

const SPEED = 750.0
const JUMP_VELOCITY = -1500.0

# platformer feel improvements
const JUMP_BUFFER_TIME = 0.15  # time to remember jump input
const COYOTE_TIME = 0.15  # how long can jump after leaving ground
const LEDGE_PUSH_DISTANCE = 10.0  # how far to push off ledges

var jump_buffer_timer = 0.0
var coyote_timer = 0.0
var was_on_floor = false

# block spawning vars
var block_scene: PackedScene
var blocks_remaining = 10
var block_place_sfx: AudioStreamPlayer  # sfx

# powerup vars
var speed_multiplier = 1.0
var jump_multiplier = 1.0
var gravity_multiplier = 1.0

# ui references (_ready)
var block_label: Label

func _ready():
	# add player to group so inv can find it
	add_to_group("player")
	
	# load block scene
	block_scene = preload("res://block.tscn")
	
	block_place_sfx = AudioStreamPlayer.new()
	block_place_sfx.bus = "SFX"
	block_place_sfx.stream = preload("res://audio/sfx/blockplace.mp3")
	add_child(block_place_sfx)
	
	# get starting blocks from levelmanager (sync btwn lvl)
	if has_node("/root/LevelManager"):
		var level_manager = get_node("/root/LevelManager")
		blocks_remaining = level_manager.get_starting_blocks()
		
		# load powerups from previous lvl
		speed_multiplier = level_manager.get_speed_multiplier()
		jump_multiplier = level_manager.get_jump_multiplier()
		gravity_multiplier = level_manager.get_gravity_multiplier()
		
		print("Starting with ", blocks_remaining, " blocks from LevelManager")
		print("Powerups loaded - Speed: ", speed_multiplier, "x, Jump: ", jump_multiplier, "x, Gravity: ", gravity_multiplier, "x")
	else:
		blocks_remaining = 10  # fallback
		print("No LevelManager found, starting with 10 blocks")
	
	# try find label in diff possible locations
	if has_node("../../UI/BlockLabel"):
		block_label = get_node("../../UI/BlockLabel")
	elif has_node("../UI/BlockLabel"):
		block_label = get_node("../UI/BlockLabel")
	
	if block_label:
		# convert label to hboxcontainer w/ icon + text + background panel
		setup_block_counter_with_panel()
		print("Block label setup complete with panel and icon")
	else:
		print("ERROR: Block label not found")
	# update the label initially
	update_block_label()
	
	# add speedrun hud if in speedrun mode
	if has_node("/root/SpeedrunManager"):
		var manager = get_node("/root/SpeedrunManager")
		if manager.speedrun_active:
			var hud = preload("res://speedrunhud.tscn").instantiate()
			get_tree().root.add_child(hud)

func _physics_process(delta: float) -> void:
	# add gravity with mult
	if not is_on_floor():
		velocity += get_gravity() * delta * 2 * gravity_multiplier
	
	# handle jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# ground jump (always available)
			velocity.y = JUMP_VELOCITY * jump_multiplier
		elif blocks_remaining > 0:
			# air jump - costs a block
			spawn_falling_block()
			block_place_sfx.play()
			velocity.y = JUMP_VELOCITY * jump_multiplier
			blocks_remaining -= 1
			update_block_label()
	
	# handle movement
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
		
		# track blocks used in levelmanager
		if has_node("/root/LevelManager"):
			get_node("/root/LevelManager").blocks_used(1)

func update_block_label():
	if block_label:
		block_label.text = str(blocks_remaining)  
	
	# update shop ui if open (check autoload first)
	var shop_ui = get_node_or_null("/root/ShopUI")
	if not shop_ui:
		shop_ui = get_tree().current_scene.get_node_or_null("UI/ShopUI")
	
	if shop_ui and shop_ui.visible:
		shop_ui.update_blocks_display()

func setup_block_counter_with_panel():
	# get the parent (ui canvaslayer)
	var parent = block_label.get_parent()
	
	# remove the old label
	parent.remove_child(block_label)
	
	# create control container in top left
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.offset_left = 10
	control.offset_top = 10
	control.offset_right = 200
	control.offset_bottom = 70
	parent.add_child(control)
	
	# create panel container for background
	var panel_container = PanelContainer.new()
	panel_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.add_child(panel_container)
	
	# style the panel w/ semi transparent dark background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.7)
	style_box.border_color = Color(1, 1, 1, 0.3)
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(8)
	style_box.content_margin_left = 15
	style_box.content_margin_right = 15
	style_box.content_margin_top = 10
	style_box.content_margin_bottom = 10
	panel_container.add_theme_stylebox_override("panel", style_box)
	
	# create hboxcontainer to hold icon + number
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	panel_container.add_child(container)
	
	# create icon (texturerect)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# load block sprite 
	var block_texture = load("res://sprites/block.png") 
	
	if block_texture:
		icon.texture = block_texture
		container.add_child(icon)
	else:
		# fallback
		var fallback_label = Label.new()
		fallback_label.text = "■"
		fallback_label.add_theme_font_size_override("font_size", 32)
		fallback_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		fallback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		container.add_child(fallback_label)
		print("Warning: Block icon not found at res://sprites/block.png, using fallback")
	
	# re setup the label
	block_label.text = str(blocks_remaining)
	block_label.add_theme_font_size_override("font_size", 32)
	block_label.add_theme_color_override("font_color", Color.WHITE)
	block_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	container.add_child(block_label)

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
