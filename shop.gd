extends Area2D

var player_in_range = false
var shop_ui = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	print("Shop ready")

func _process(_delta):
	# Check if player presses 'S' while in range
	if player_in_range and Input.is_action_just_pressed("ui_text_completion_accept"):  # Default 'S' key
		open_shop()

func _on_body_entered(body):
	if "blocks_remaining" in body:
		player_in_range = true
		print("Press S to open shop")

func _on_body_exited(body):
	if "blocks_remaining" in body:
		player_in_range = false
		print("Left shop area")

func open_shop():
	print("Opening shop...")
	# Find the shop UI in the level
	if not shop_ui:
		shop_ui = get_node("../../UI/ShopUI")  
	
	if shop_ui:
		shop_ui.open_shop()
	else:
		print("Shop UI not found!")
