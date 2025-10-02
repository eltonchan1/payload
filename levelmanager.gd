extends Node

# Track game progression
var current_stage = "early"  # early, middle, late
var levels_completed = 0
var total_blocks_used = 0
var player_blocks = 10  # Track blocks between levels

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
	player_blocks = remaining_blocks  # Save blocks for next level
	print("Level completed! Total: ", levels_completed)
	print("Player has ", remaining_blocks, " blocks remaining")
	
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

# Reset game (for starting new game)
func reset_game():
	levels_completed = 0
	total_blocks_used = 0
	player_blocks = 10
	current_stage = "early"
	print("Game reset")
