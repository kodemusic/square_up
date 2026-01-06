extends Node

## Main game controller - handles level progression, saves, and scene management
## Manages unlocking levels and tracking player progress

## Path to save file for persistent progress
const SAVE_FILE_PATH := "user://square_up_save.json"

## Mobile stretch scale multiplier
const MOBILE_STRETCH_SCALE := 1.25
const DESKTOP_STRETCH_SCALE := 1.0

## Current progress data
var player_progress := {
	"current_level": 1,           # Current level player is on
	"highest_unlocked": 1,        # Highest level unlocked
	"level_stars": {},            # Stars earned per level: {level_id: stars}
	"level_high_scores": {},      # High scores per level: {level_id: score}
	"total_score": 0,             # Cumulative score across all levels
}

func _ready() -> void:
	# Detect platform and adjust stretch scale
	_configure_stretch_scale()
	
	# Load saved progress on startup
	load_progress()

	print("Player Progress Loaded:")
	print("  Current Level: %d" % player_progress["current_level"])
	print("  Highest Unlocked: %d" % player_progress["highest_unlocked"])
	print("  Total Score: %d" % player_progress["total_score"])

## Detect if running on mobile and adjust content scale
func _configure_stretch_scale() -> void:
	var platform := OS.get_name()
	var is_mobile := platform in ["Android", "iOS"]
	
	# Also check screen size for small screens (phones vs tablets)
	# Phones typically have shorter dimension < 600-800 logical pixels
	var screen_size := DisplayServer.screen_get_size()
	var min_dimension := mini(screen_size.x, screen_size.y)
	var is_small_screen := min_dimension < 800
	
	if is_mobile and is_small_screen:
		# Phone - use larger scale
		get_tree().root.content_scale_factor = MOBILE_STRETCH_SCALE
		print("Mobile phone detected - stretch scale: %.2f" % MOBILE_STRETCH_SCALE)
	else:
		# Desktop or tablet - use normal scale
		get_tree().root.content_scale_factor = DESKTOP_STRETCH_SCALE
		print("Desktop/tablet detected - stretch scale: %.2f" % DESKTOP_STRETCH_SCALE)

## Load the specified level
## level_id: ID of the level to load (1, 2, 3, etc., 999 for endless)
func load_level(level_id: int) -> void:
	# Check if level is unlocked
	if level_id > player_progress["highest_unlocked"] and level_id != 999:
		print("Level %d is locked!" % level_id)
		return

	# Update current level
	player_progress["current_level"] = level_id
	save_progress()

	# Load the game scene with the specified level
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

	# The Game scene will need to know which level to load
	# We'll use a global autoload or pass it through game.gd

## Complete a level with results
## level_id: Level that was completed
## score: Score achieved
## moves_remaining: Moves left (for star calculation)
func complete_level(level_id: int, score: int, moves_remaining: int) -> void:
	print("Level %d completed! Score: %d, Moves Left: %d" % [level_id, score, moves_remaining])

	# Calculate stars (1-3 based on moves remaining)
	var stars := _calculate_stars(moves_remaining)

	# Update high score if this is better
	var current_high_score: int = player_progress["level_high_scores"].get(str(level_id), 0)
	if score > current_high_score:
		player_progress["level_high_scores"][str(level_id)] = score
		player_progress["total_score"] += (score - current_high_score)

	# Update stars if this is better
	var current_stars: int = player_progress["level_stars"].get(str(level_id), 0)
	if stars > current_stars:
		player_progress["level_stars"][str(level_id)] = stars

	# Unlock next level
	var next_level := level_id + 1
	if next_level > player_progress["highest_unlocked"]:
		player_progress["highest_unlocked"] = next_level
		print("Unlocked Level %d!" % next_level)

	# Save progress
	save_progress()

## Restart the current level
func restart_current_level() -> void:
	load_level(player_progress["current_level"])

## Load the next level
func load_next_level() -> void:
	var next_level: int = player_progress["current_level"] + 1
	load_level(next_level)

## Load endless mode
func load_endless_mode() -> void:
	load_level(999)

## Calculate star rating based on moves remaining
func _calculate_stars(moves_remaining: int) -> int:
	if moves_remaining >= 4:
		return 3
	elif moves_remaining >= 2:
		return 2
	else:
		return 1

## Check if a level is unlocked
func is_level_unlocked(level_id: int) -> bool:
	return level_id <= player_progress["highest_unlocked"] or level_id == 999

## Get stars earned for a specific level
func get_level_stars(level_id: int) -> int:
	return player_progress["level_stars"].get(str(level_id), 0)

## Get high score for a specific level
func get_level_high_score(level_id: int) -> int:
	return player_progress["level_high_scores"].get(str(level_id), 0)

## Save player progress to disk
func save_progress() -> void:
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		print("Error: Could not open save file for writing: %s" % SAVE_FILE_PATH)
		return

	var json_string := JSON.stringify(player_progress, "\t")
	file.store_string(json_string)
	file.close()

	print("Progress saved to: %s" % SAVE_FILE_PATH)

## Load player progress from disk
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found. Starting fresh.")
		return

	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		print("Error: Could not open save file for reading: %s" % SAVE_FILE_PATH)
		return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)

	if parse_result != OK:
		print("Error: Could not parse save file JSON")
		return

	var loaded_data = json.data
	if loaded_data is Dictionary:
		player_progress = loaded_data
		print("Progress loaded from: %s" % SAVE_FILE_PATH)
	else:
		print("Error: Invalid save file format")

## Reset all progress (for debugging or "new game")
func reset_progress() -> void:
	player_progress = {
		"current_level": 1,
		"highest_unlocked": 1,
		"level_stars": {},
		"level_high_scores": {},
		"total_score": 0,
	}
	save_progress()
	print("Progress reset!")
