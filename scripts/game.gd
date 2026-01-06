extends Node

## Main game controller
## Loads levels and manages game state

## Reference to the tile scene to spawn
var tile_scene := preload("res://scenes/Tile.tscn")

## References to scene nodes
@onready var board := $BoardRoot as Node
@onready var tile_container := $BoardRoot/TileContainer as Node2D
@onready var input_router := $InputRouter as Node
@onready var hud := $UILayer/Hud as Control

## Current level being played
var current_level: LevelData

## Number of moves made in current level
var moves_count := 0

## Load a level by its ID
func _load_level_by_id(level_id: int) -> LevelData:
	# Use the centralized factory function
	return LevelData.create_level(level_id)

func _ready() -> void:
	# Load level from GameManager (if it exists as autoload)
	var level_id: int = 1
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		level_id = game_manager.player_progress["current_level"]
		print("Loading level %d from GameManager" % level_id)

	# Load the appropriate level based on level_id
	current_level = _load_level_by_id(level_id)
	
	# Validate level was loaded successfully
	if current_level == null:
		push_error("Failed to load level %d" % level_id)
		return
	if current_level.starting_grid.size() == 0:
		push_error("Level %d has empty starting_grid" % level_id)
		return

	# Debug: Print starting grid
	print("Starting grid:")
	current_level.print_grid(current_level.starting_grid)

	# Use correct isometric tile dimensions: 128x64
	board.load_level(tile_scene, tile_container, current_level, 128.0, 64.0, 8.0, input_router)

	# Pass level configuration to input router
	input_router.set_current_level(current_level)

	# Center the board on screen (camera is at 640, 359)
	# For a 4x4 grid, the center should be offset
	tile_container.position = Vector2(640, 200)

	print("Level loaded: %s" % current_level.level_name)
	print("Board size: %dx%d" % [current_level.width, current_level.height])
	print("Tiles in container: %d" % tile_container.get_child_count())

	# Check for any matches at start
	var starting_matches: Array[Vector2i] = board.find_all_2x2_matches()
	if starting_matches.size() > 0:
		print("WARNING: Found %d matches at start!" % starting_matches.size())
		for match_pos in starting_matches:
			print("  Match at: %v" % match_pos)
	else:
		print("Good: No matches at start")

	# Connect board signals to HUD
	board.score_awarded.connect(_on_score_awarded)

	# Connect input router to track moves
	input_router.swap_completed.connect(_on_swap_completed)
	input_router.undo_completed.connect(_on_undo_completed)

	# Connect HUD signals
	hud.restart_requested.connect(_on_restart_requested)
	hud.next_level_requested.connect(_on_next_level_requested)
	hud.undo_requested.connect(_on_undo_requested)

	# Initialize HUD with level data
	hud.set_move_limit(current_level.move_limit)
	hud.set_squares_goal(current_level.squares_goal)
	hud.update_score(0)
	hud.update_moves(0)

## Handle score updates from board
func _on_score_awarded(points: int) -> void:
	var new_score: int = hud.current_score + points
	hud.update_score(new_score)

	# Show "SQUARE UP!" popup for each square completed (10 points per square)
	var squares_earned: int = int(points / 10.0)
	if squares_earned > 0:
		hud.show_square_popup(points)
		var goal_reached: bool = hud.add_squares(squares_earned)

		# Check win condition based on squares goal
		if goal_reached:
			_on_level_complete()

## Handle move tracking when swap succeeds
func _on_swap_completed() -> void:
	moves_count += 1
	hud.update_moves(moves_count)

	# Check fail condition (ran out of moves)
	if current_level.move_limit > 0 and moves_count >= current_level.move_limit:
		var current_score: int = hud.current_score
		if current_score < current_level.target_score:
			_on_level_failed()

## Called when player completes level
func _on_level_complete() -> void:
	print("Level complete!")

	# Freeze the board
	input_router.set_input_enabled(false)

	# Calculate star rating
	var moves_remaining: int = current_level.move_limit - moves_count
	var stars: int = hud.calculate_stars(moves_remaining)

	# Show level complete with stars
	hud.show_level_complete_with_stars(stars, moves_remaining)

	# Report completion to GameManager
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		game_manager.complete_level(current_level.level_id, hud.current_score, moves_remaining)

## Called when player runs out of moves
func _on_level_failed() -> void:
	print("Level failed - out of moves")

	# Freeze the board
	input_router.set_input_enabled(false)

	hud.show_level_failed()

## Restart the current level
func restart_level() -> void:
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		game_manager.restart_current_level()
	else:
		# Fallback: reload current scene
		get_tree().reload_current_scene()

## Load the next level
func load_next_level() -> void:
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		game_manager.load_next_level()
	else:
		print("GameManager not found - cannot load next level")

## HUD signal handlers
func _on_restart_requested() -> void:
	restart_level()

func _on_next_level_requested() -> void:
	load_next_level()

func _on_undo_requested() -> void:
	# Try to undo the last swap
	var success: bool = await input_router.undo_last_swap()
	if success:
		hud.mark_undo_used()

func _on_undo_completed() -> void:
	# Decrement move counter when undo is performed
	if moves_count > 0:
		moves_count -= 1
		hud.update_moves(moves_count)
