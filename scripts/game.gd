extends Node

## Main game controller
## Loads levels and manages game state

## Camera zoom configuration
@export_group("Camera Zoom")
@export_range(0.0, 1.0, 0.05) var board_fill_percentage: float = 0.8 ## How much of anchor to fill (0.8 = 80% fill, 20% padding)
@export_range(1.0, 10.0, 0.1) var min_zoom: float = 1.0 ## Minimum camera zoom (zoomed out)
@export_range(1.0, 10.0, 0.1) var max_zoom: float = 5.0 ## Maximum camera zoom (zoomed in)

## Reference to the tile scene to spawn
var tile_scene := preload("res://scenes/Tile.tscn")

## References to scene nodes
@onready var board := $BoardRoot as Node
@onready var board_controller := $BoardRoot/BoardController as Node2D
@onready var tile_container := $BoardRoot/BoardController/TileContainer as Node2D
@onready var overlay := $BoardRoot/Overlay as Node2D
@onready var input_router := $InputRouter as Node
@onready var hud := $UILayer/Hud as Control
@onready var layout_manager := $LayoutManager as Node
@onready var camera := $Camera2D as Camera2D

## Current level being played
var current_level: LevelData

## Number of moves made in current level
var moves_count := 0

## Pre-generated next level (reduces lag when progressing)
var next_level_cached: LevelData = null

## Whether we're currently generating the next level
var is_pregenerating := false

## Persistent level ID for testing (survives scene reload)
static var test_level_id: int = 1

## Load a level by its ID
func _load_level_by_id(level_id: int) -> LevelData:
	# Clear cache before loading to ensure fresh level config
	# (Useful when level definitions change during development)
	if OS.is_debug_build():
		LevelData.clear_cache()
	
	# Use the centralized factory function
	return LevelData.create_level(level_id)

func _ready() -> void:
	# Ensure random seed is set (in case GameManager doesn't exist)
	randomize()

	# Load level from GameManager (if it exists as autoload)
	var level_id: int = 1
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		level_id = game_manager.player_progress["current_level"]
		print("Loading level %d from GameManager" % level_id)
	else:
		# Testing mode: use static variable to persist across reloads
		level_id = test_level_id
		print("Loading level %d (testing mode)" % level_id)

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

	# Isometric tiles: 64x32 (visual scale 0.27x0.12 in editor)
	board.load_level(tile_scene, tile_container, current_level, 64.0, 32.0, 8.0, input_router)

	# Pass level configuration to input router
	input_router.set_current_level(current_level)

	# Position board relative to active layout's BoardAnchor (Golden Rule architecture)
	# Camera is centered at (960, 540) for 1920x1080 viewport
	_position_board_in_layout()

	# Connect to orientation changes for runtime layout switching
	layout_manager.orientation_changed.connect(_on_orientation_changed)

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
	hud.shuffle_requested.connect(_on_shuffle_requested)

	# Reset game state for new level
	moves_count = 0
	input_router.set_input_enabled(true)

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

	# Check for dead board (endless mode only)
	await get_tree().create_timer(0.5).timeout  # Wait for cascades to finish
	_check_for_dead_board()

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

	# Pre-generate next level in background (with artistic delay)
	_pregenerate_next_level()

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
		# Testing fallback: Level 1 -> Level 2 -> Endless
		var next_level_id: int
		if current_level.level_id == 1:
			next_level_id = 2
		elif current_level.level_id == 2:
			next_level_id = 999  # Endless mode
		else:
			next_level_id = 1  # Loop back to level 1
		
		# Store for scene reload
		test_level_id = next_level_id
		
		# Use cached level if available
		if next_level_cached != null and next_level_cached.level_id == next_level_id:
			print("Using pre-generated level %d (instant load!)" % next_level_id)
			next_level_cached = null  # Clear cache
		
		# Reload scene with new level
		get_tree().reload_current_scene()

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

func _on_shuffle_requested() -> void:
	print("[Game] Shuffle requested")
	board.shuffle_board()
	# Re-check after shuffle in case it's still dead
	await get_tree().create_timer(0.3).timeout
	_check_for_dead_board()

## Check if board has no valid moves (for endless mode)
func _check_for_dead_board() -> void:
	# Only check in endless mode (level 999)
	if current_level.level_id != 999:
		return

	# Don't check if there are empty cells (cascades still happening)
	if board.has_empty_cells():
		return

	# Don't check if there are existing matches on the board
	var existing_matches: Array[Vector2i] = board.find_all_2x2_matches()
	if existing_matches.size() > 0:
		return

	# Check for valid moves
	if not board.has_valid_moves():
		print("[Game] Dead board detected - showing shuffle popup")
		hud.show_shuffle_popup()

## Pre-generate the next level in background to prevent lag
## Includes artistic delay to mask generation time
func _pregenerate_next_level() -> void:
	if is_pregenerating:
		return
	
	is_pregenerating = true
	
	# Determine next level ID
	var next_id: int
	if has_node("/root/GameManager"):
		var game_manager = get_node("/root/GameManager")
		next_id = game_manager.player_progress["current_level"] + 1
	else:
		# Testing fallback
		if current_level.level_id == 1:
			next_id = 2
		elif current_level.level_id == 2:
			next_id = 999
		else:
			next_id = 1
	
	print("Pre-generating level %d..." % next_id)
	
	# Add artistic delay (0.5-1.0 seconds) before starting generation
	await get_tree().create_timer(randf_range(0.5, 1.0)).timeout
	
	# Generate the level
	next_level_cached = _load_level_by_id(next_id)
	
	if next_level_cached != null:
		print("Level %d pre-generated successfully" % next_id)
	else:
		push_warning("Failed to pre-generate level %d" % next_id)

	is_pregenerating = false

## ========================================================================
##  GOLDEN RULE LAYOUT SYSTEM
## ========================================================================

## Position the board container relative to the active layout's BoardAnchor
## This implements layout-relative positioning (Golden Rule principle #5)
## MONUMENT VALLEY SOLUTION: Board scales to feel right, UI scales to fit
func _position_board_in_layout() -> void:
	# Wait one frame to ensure layout nodes are ready
	await get_tree().process_frame

	var board_anchor: Control = layout_manager.get_active_board_anchor()
	var is_portrait: bool = layout_manager.is_portrait()

	# Get BoardAnchor's global position and size
	var anchor_global_pos: Vector2 = board_anchor.global_position
	var anchor_size: Vector2 = board_anchor.size

	# Calculate center of BoardAnchor
	var anchor_center: Vector2 = anchor_global_pos + (anchor_size / 2.0)

	# Wait a frame for tiles to be positioned by board.gd (at default 1.0 zoom)
	await get_tree().process_frame

	# Compute actual visual bounds of all tiles in TileContainer
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF

	for child in tile_container.get_children():
		if child is Node2D:
			var p: Vector2 = child.global_position
			min_x = min(min_x, p.x)
			min_y = min(min_y, p.y)
			max_x = max(max_x, p.x)
			max_y = max(max_y, p.y)

	# Calculate actual board dimensions in world space
	var board_width := max_x - min_x
	var board_height := max_y - min_y

	# GODOT 4 BEST PRACTICE: Dynamic camera zoom based on board size
	# Calculate zoom to fit board in anchor with configurable padding
	var zoom_x := (anchor_size.x * board_fill_percentage) / board_width if board_width > 0 else 1.0
	var zoom_y := (anchor_size.y * board_fill_percentage) / board_height if board_height > 0 else 1.0

	# Use the smaller zoom to ensure board fits in both dimensions
	var camera_zoom: float = min(zoom_x, zoom_y)

	# Clamp zoom to configurable range
	camera_zoom = clamp(camera_zoom, min_zoom, max_zoom)

	# Apply zoom
	camera.zoom = Vector2(camera_zoom, camera_zoom)

	# Calculate the actual visual center of the board
	var board_visual_center := Vector2((min_x + max_x) * 0.5, (min_y + max_y) * 0.5)

	# TALL PHONE ADJUSTMENT: On portrait devices, nudge board upward by 6%
	# This compensates for optical center shift on tall phones (Samsung Fold 4, iPhone 14 Pro Max)
	# where bottom UI elements make the board feel too low if mathematically centered
	var target_position := anchor_center
	if is_portrait:
		var viewport_height := get_viewport().get_visible_rect().size.y
		var nudge_amount := viewport_height * 0.06
		target_position.y -= nudge_amount  # 6% upward nudge
		print("[Game] Portrait mode: Applying 6%% upward nudge (%.1fpx)" % nudge_amount)

	# Move BoardController so the visual center lands on target position
	var offset := target_position - board_visual_center
	board_controller.global_position += offset

	print("[Game] Board positioning debug:")
	print("  Orientation: %s" % ("Portrait" if is_portrait else "Landscape"))
	print("  Board size: %dx%d" % [current_level.width, current_level.height])
	print("  Board dimensions: %.1f x %.1f" % [board_width, board_height])
	print("  Anchor size: %v (already accounts for safe area)" % anchor_size)
	print("  Calculated zoom X: %.2f, Y: %.2f" % [zoom_x, zoom_y])
	print("  Final camera zoom: %.2fx (clamped %.1f-%.1f)" % [camera_zoom, min_zoom, max_zoom])
	print("  Board visual center: %v" % board_visual_center)
	print("  Target position: %v" % target_position)
	print("  Viewport size: %v" % get_viewport().get_visible_rect().size)
	print("  Window size: %v" % DisplayServer.window_get_size())
	print("  BoardAnchor global_pos: %v" % anchor_global_pos)
	print("  BoardAnchor size: %v" % anchor_size)
	print("  Anchor center: %v" % anchor_center)
	print("  BoardController scale: %v" % board_controller.scale)
	print("  BoardController positioned at: %v" % board_controller.global_position)
	print("  TileContainer global position: %v" % tile_container.global_position)

## Handle orientation changes (portrait <-> landscape)
## Re-positions board when layout switches at runtime
func _on_orientation_changed(is_portrait: bool, tall_ratio: float, is_very_tall: bool) -> void:
	print("[Game] Orientation changed:")
	print("  Mode: %s" % ("Portrait" if is_portrait else "Landscape"))
	print("  Tall ratio: %.2f" % tall_ratio)
	print("  Very tall screen: %s" % is_very_tall)
	_position_board_in_layout()
