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

func _ready() -> void:
	# Load and display Level 1
	current_level = LevelData.create_level_1()

	# Debug: Print starting grid
	print("Starting grid:")
	current_level.print_grid(current_level.starting_grid)

	# Use correct isometric tile dimensions: 128x64
	board.load_level(tile_scene, tile_container, current_level, 128.0, 64.0, 8.0, input_router)

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
	var squares_earned: int = points / 10
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

	# Calculate star rating
	var moves_remaining: int = current_level.move_limit - moves_count
	var stars: int = hud.calculate_stars(moves_remaining)

	# Show level complete with stars
	hud.show_level_complete_with_stars(stars, moves_remaining)

## Called when player runs out of moves
func _on_level_failed() -> void:
	print("Level failed - out of moves")
	hud.show_level_failed()
