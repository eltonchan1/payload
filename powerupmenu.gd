extends CanvasLayer

signal powerup_selected(powerup_type)

@onready var speed_button = $Control/Panel/VBoxContainer/SpeedButton
@onready var jump_button = $Control/Panel/VBoxContainer/JumpButton  
@onready var gravity_button = $Control/Panel/VBoxContainer/GravityButton
@onready var blocks_button = $Control/Panel/VBoxContainer/BlocksButton

func _ready():
	# hide menu initially
	visible = false
	
	# set process mode so menu works when game paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# connect buttons
	speed_button.pressed.connect(func(): _select_powerup("speed"))
	jump_button.pressed.connect(func(): _select_powerup("jump"))
	gravity_button.pressed.connect(func(): _select_powerup("gravity"))
	blocks_button.pressed.connect(func(): _select_powerup("blocks"))

func show_menu():
	visible = true
	get_tree().paused = true
	print("Powerup menu shown")

func hide_menu():
	visible = false
	get_tree().paused = false
	print("Powerup menu hidden")

func _select_powerup(type):
	print("Powerup selected: ", type)
	powerup_selected.emit(type)
	hide_menu()
