extends Area2D

# This is now a SHOP, not a flag that gives blocks
var player_in_range = false
var player_ref = null
var can_toggle_shop = true  # Cooldown to prevent instant reopen

func _ready():
	print("Shop flag created and ready")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Make sure we're monitoring
	monitoring = true
	monitorable = true

func _process(_delta):
	if not player_in_range or not can_toggle_shop:
		return
	
	# Check for S key press
	if Input.is_action_just_pressed("shop_interact"):
		var shop_ui = get_node_or_null("/root/ShopUI")
		
		if shop_ui:
			if shop_ui.visible:
				# Shop is open - let the shop's _input handle closing
				print("Shop is open, flag ignoring input")
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

func _on_body_exited(body):
	if "blocks_remaining" in body:
		player_in_range = false
		player_ref = null

func open_shop():
	if player_ref:
		# Try to find shop UI - check autoload first, then in scene
		print("Looking for ShopUI...")
		var shop_ui = get_node_or_null("/root/ShopUI")
		if shop_ui:
			print("Found ShopUI in autoload")
		else:
			print("ShopUI not in autoload, checking scene...")
			shop_ui = get_tree().current_scene.get_node_or_null("UI/ShopUI")
			if shop_ui:
				print("Found ShopUI in scene")
		
		if shop_ui:
			shop_ui.show_shop(player_ref)
		else:
			print("ERROR: ShopUI not found anywhere!")
			print("Available autoloads: ", get_tree().root.get_children())
