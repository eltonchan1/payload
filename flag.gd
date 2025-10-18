extends Area2D

var player_in_range = false
var player_ref = null
var can_toggle_shop = true
var prompt_label: Label = null

func _ready():
	print("Shop flag created and ready")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	monitoring = true
	monitorable = true
	
	create_prompt_label()
	
	# make sure shopui exists
	await get_tree().process_frame
	var shop_ui = get_node_or_null("/root/ShopUI")
	if shop_ui:
		print("✓ ShopUI found successfully!")
	else:
		print("✗ ERROR: ShopUI not found! Check autoload settings!")

func _process(_delta):
	if not player_in_range or not can_toggle_shop:
		return
	
	if Input.is_action_just_pressed("shop_interact"):
		var shop_ui = get_node_or_null("/root/ShopUI")
		
		if not shop_ui:
			print("ERROR: ShopUI not found at /root/ShopUI!")
			print("Make sure ShopUI is added as an Autoload in Project Settings!")
			return
		
		if not shop_ui.has_method("show_shop"):
			print("ERROR: ShopUI doesn't have show_shop method!")
			return
		
		if shop_ui.visible:
			print("Shop already open, flag ignoring input")
			return
		else:
			print("Flag opening shop")
			open_shop()
			
			can_toggle_shop = false
			await get_tree().create_timer(0.3).timeout
			can_toggle_shop = true

func _on_body_entered(body):
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
		var shop_ui = get_node_or_null("/root/ShopUI")
		if shop_ui and shop_ui.has_method("show_shop"):
			print("Calling show_shop on ShopUI...")
			shop_ui.show_shop(player_ref)
		else:
			print("ERROR: Cannot open shop - ShopUI not properly loaded!")

func create_prompt_label():
	prompt_label = Label.new()
	prompt_label.text = "S"
	prompt_label.add_theme_font_size_override("font_size", 100)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 4)
	
	add_child(prompt_label)
	prompt_label.position = Vector2(100, -400)
	prompt_label.visible = false

func show_prompt():
	if prompt_label and player_ref:
		prompt_label.visible = true

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false
