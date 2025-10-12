extends Area2D

var player_in_range = false
var player_ref = null
var can_toggle_shop = true  # Cooldown to prevent instant reopen
var prompt_label: Label = null  # The "S" prompt above player

func _ready():
	print("Shop flag created and ready")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Make sure we're monitoring
	monitoring = true
	monitorable = true
	
	# Create the prompt label (hidden initially)
	create_prompt_label()

func _process(_delta):
	if not player_in_range or not can_toggle_shop:
		return
	
	# Check for S key press using the action
	if Input.is_action_just_pressed("shop_interact"):
		var shop_ui = get_node_or_null("/root/ShopUI")
		
		if not shop_ui:
			print("ERROR: ShopUI not found!")
			return
		
		if shop_ui.visible:
			# Shop is open - don't do anything, let shop handle closing
			print("Shop already open, flag ignoring input")
			return
		else:
			# Shop is closed - open it
			print("Flag opening shop")
			open_shop()
			
			# Cooldown to prevent rapid toggling
			can_toggle_shop = false
			await get_tree().create_timer(0.3).timeout
			can_toggle_shop = true

func _on_body_entered(body):
	print("Something near shop: ", body.name)
	
	if "blocks_remaining" in body:
		print("Player can now open shop - Press S")
		player_in_range = true
		player_ref = body
		show_prompt()

func _on_body_exited(body):
	if "blocks_remaining" in body:
		player_in_range = false
		player_ref = null
		hide_prompt()

func open_shop():
	if player_ref:
		# Find and open shop UI
		var shop_ui = get_node_or_null("/root/ShopUI")
		if shop_ui:
			shop_ui.show_shop(player_ref)
		else:
			print("ShopUI not found anywhere!")

func create_prompt_label():
	prompt_label = Label.new()
	prompt_label.text = "S"
	prompt_label.add_theme_font_size_override("font_size", 100)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Add background/outline for visibility
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 4)
	
	# Add to scene
	add_child(prompt_label)
	
	# Position above the flag (adjust as needed)
	prompt_label.position = Vector2(100, -400)  # Centered and above
	prompt_label.visible = false

func show_prompt():
	if prompt_label and player_ref:
		prompt_label.visible = true

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false
