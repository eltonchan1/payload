extends Node

# Track game progression
var current_stage = "early"  # early, middle, late
var levels_completed = 0
var total_blocks_used = 0
var player_blocks = 10  # Track blocks between levels

# Track powerups between levels
var player_speed_multiplier = 1.0
var player_jump_multiplier = 1.0
var player_gravity_multiplier = 1.0

# Define level paths for each stage
var level_pools = {
	"early": [
		"res://levels/early_1.tscn",
		"res://levels/early_2.tscn",
		"res://levels/early_3.tscn"
	],
	"middle": [
		"res://levels/middle_1.tscn",
		"res://levels/middle_2.tscn",
		"res://levels/middle_3.tscn"
	],
	"late": [
		"res://levels/late_1.tscn",
		"res://levels/late_2.tscn",
		"res://levels/late_3.tscn"
	]
}

# Thresholds for stage progression
const MIDDLE_STAGE_THRESHOLD = 3  # After 3 levels, enter middle stage
const LATE_STAGE_THRESHOLD = 7    # After 7 levels, enter late stage

func _ready():
	print("LevelManager ready")
	print("Current stage: ", current_stage)

# Call this when a level is completed
func level_completed(remaining_blocks: int):
	levels_completed += 1
	
	# Calculate interest: 2 blocks for every 5 blocks remaining
	var interest = int(remaining_blocks / 5.0) * 2
	
	# Minimum guaranteed blocks: 5
	var bonus_blocks = max(5, interest)
	
	player_blocks = remaining_blocks + bonus_blocks
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("Level ", levels_completed, " completed!")
	print("Blocks remaining: ", remaining_blocks)
	print("Interest earned: +", interest, " blocks")
	if interest < 5:
		print("Minimum bonus applied: +", 5 - interest, " blocks")
	print("Total bonus: +", bonus_blocks, " blocks")
	print("Next level blocks: ", player_blocks)
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━")
	
	# Update stage based on progression
	update_stage()
	
	# Load next level
	load_next_level()

# Determine which stage we're in
func update_stage():
	if levels_completed >= LATE_STAGE_THRESHOLD:
		current_stage = "late"
	elif levels_completed >= MIDDLE_STAGE_THRESHOLD:
		current_stage = "middle"
	else:
		current_stage = "early"
	
	print("Current stage: ", current_stage)

# Load a random level from current stage pool
func load_next_level():
	var available_levels = level_pools[current_stage]
	
	if available_levels.size() == 0:
		print("No levels available for stage: ", current_stage)
		return
	
	# Pick random level from pool
	var random_index = randi() % available_levels.size()
	var level_path = available_levels[random_index]
	
	print("Loading level: ", level_path)
	get_tree().change_scene_to_file(level_path)

# Track blocks used (call from player)
func blocks_used(amount: int):
	total_blocks_used += amount

# Get current difficulty/stage
func get_current_stage() -> String:
	return current_stage

# Get blocks for new level (call from player when spawning)
func get_starting_blocks() -> int:
	return player_blocks

# Get powerup multipliers (call from player when spawning)
func get_speed_multiplier() -> float:
	return player_speed_multiplier

func get_jump_multiplier() -> float:
	return player_jump_multiplier

func get_gravity_multiplier() -> float:
	return player_gravity_multiplier

# Save powerup multipliers (call from player when they change)
func save_powerups(speed: float, jump: float, gravity: float):
	player_speed_multiplier = speed
	player_jump_multiplier = jump
	player_gravity_multiplier = gravity
	print("Powerups saved - Speed: ", speed, "x, Jump: ", jump, "x, Gravity: ", gravity, "x")

# Reset game (for starting new game)
func reset_game():
	levels_completed = 0
	total_blocks_used = 0
	player_blocks = 10
	current_stage = "early"
	player_speed_multiplier = 1.0
	player_jump_multiplier = 1.0
	player_gravity_multiplier = 1.0
	print("Game reset")
