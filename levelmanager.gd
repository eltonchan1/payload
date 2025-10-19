extends Node

# track game progression
var current_stage = "early"
var levels_completed = 0
var total_blocks_used = 0
var player_blocks = 10
var last_level_played = ""

# track powerups btwn lvl
var player_speed_multiplier = 1.0
var player_jump_multiplier = 1.0
var player_gravity_multiplier = 1.0

# win condition
const ROUNDS_TO_WIN = 10

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
		"res://levels/late_3.tscn",
		"res://levels/late_4.tscn"
	]
}

# thresholds for stage progression
const MIDDLE_STAGE_THRESHOLD = 3  # after 3 lvl, enter middle
const LATE_STAGE_THRESHOLD = 6    # after 6 lvl, enter late stage

func _ready():
	print("LevelManager ready")
	print("Current stage: ", current_stage)

# call when lvl is completed
func level_completed(remaining_blocks: int):
	levels_completed += 1
	
	# calculate interest
	var interest = (remaining_blocks / 5)
	
	# add base reward for completing level
	var completion_bonus = 3
	
	# total bonus
	var bonus_blocks = interest + completion_bonus
	
	player_blocks = remaining_blocks + bonus_blocks
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("Level ", levels_completed, " completed!")
	print("Blocks remaining: ", remaining_blocks)
	print("Interest (1 per 5): +", interest, " blocks")
	print("Completion bonus: +", completion_bonus, " blocks")
	print("Total bonus: +", bonus_blocks, " blocks")
	print("Next level blocks: ", player_blocks)
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━")
	
	update_stage()
	
	load_next_level()

# determine which stage rn
func update_stage():
	if levels_completed >= LATE_STAGE_THRESHOLD:
		current_stage = "late"
	elif levels_completed >= MIDDLE_STAGE_THRESHOLD:
		current_stage = "middle"
	else:
		current_stage = "early"
	
	print("Current stage: ", current_stage)

# load random level from current stage pool
func load_next_level():
	if levels_completed >= ROUNDS_TO_WIN:
		show_win_screen()
		return
	
	var available_levels = level_pools[current_stage]
	
	if available_levels.size() == 0:
		print("No levels available for stage: ", current_stage)
		return
	
	if available_levels.size() == 1:
		# only one level, have to use it
		var level_path = available_levels[0]
		last_level_played = level_path
		print("Loading level (only option): ", level_path)
		get_tree().change_scene_to_file(level_path)
		return
	
	# multiple lvl, keep randomizing till get diff one
	var level_path = last_level_played
	var attempts = 0
	while level_path == last_level_played and attempts < 100:
		var random_index = randi() % available_levels.size()
		level_path = available_levels[random_index]
		attempts += 1
	
	last_level_played = level_path
	
	print("Loading level: ", level_path, " (different from last)")
	get_tree().change_scene_to_file(level_path)

func show_win_screen():
	print("YOU WIN! Loading win screen...")
	
	# end speedrun if active
	if has_node("/root/SpeedrunManager"):
		var speedrun_manager = get_node("/root/SpeedrunManager")
		if speedrun_manager.speedrun_active:
			speedrun_manager.end_speedrun()
	
	get_tree().change_scene_to_file("res://winscreen.tscn")

# track blocks used (call from player)
func blocks_used(amount: int):
	total_blocks_used += amount

# get current diff/stage
func get_current_stage() -> String:
	return current_stage

# get blocks for new level (call from player when spawning)
func get_starting_blocks() -> int:
	return player_blocks

# get powerup mult (call from player when spawning)
func get_speed_multiplier() -> float:
	return player_speed_multiplier

func get_jump_multiplier() -> float:
	return player_jump_multiplier

func get_gravity_multiplier() -> float:
	return player_gravity_multiplier

# save powerup mult (call from player when they change)
func save_powerups(speed: float, jump: float, gravity: float):
	player_speed_multiplier = speed
	player_jump_multiplier = jump
	player_gravity_multiplier = gravity
	print("Powerups saved - Speed: ", speed, "x, Jump: ", jump, "x, Gravity: ", gravity, "x")

# reset game (for starting new game)
func reset_game():
	levels_completed = 0
	total_blocks_used = 0
	player_blocks = 10
	current_stage = "early"
	player_speed_multiplier = 1.0
	player_jump_multiplier = 1.0
	player_gravity_multiplier = 1.0
	print("Game reset")
