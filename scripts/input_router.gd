extends Node

## Handles player input and tile selection/swapping
## Routes tile tap signals to board swap logic

## Emitted when a successful swap is completed
signal swap_completed

## Reference to the board node for swap operations
@onready var board := get_node("/root/Game/BoardRoot") as Node
@onready var tile_container := get_node("/root/Game/BoardRoot/TileContainer") as Node2D
@onready var hud := get_node("/root/Game/UILayer/Hud") as Control

## Currently selected tile (first tap)
var selected_tile: Area2D = null

## Current level being played (set by game controller)
var current_level: LevelData = null

## Last swap data for undo functionality
var last_swap_tile_a: Area2D = null
var last_swap_tile_b: Area2D = null
var last_swap_valid := false  # True if there's a swap that can be undone

## Whether input is enabled (disabled when level complete/failed)
var input_enabled := true

## Emitted when undo is performed
signal undo_completed

func _ready() -> void:
	# Connect to all tile tapped signals when tiles are spawned
	# We'll use a different approach - tiles will be connected after spawning
	pass

## Set the current level configuration (called by game controller)
func set_current_level(level: LevelData) -> void:
	current_level = level

## Connect a tile's tapped signal to this input router
func connect_tile(tile: Area2D) -> void:
	if not tile.tapped.is_connected(_on_tile_tapped):
		tile.tapped.connect(_on_tile_tapped)

## Handle tile tap/click events
func _on_tile_tapped(tile: Area2D) -> void:
	# Ignore input if board is frozen
	if not input_enabled:
		return

	print("Tile tapped at grid_pos: %v, color_id: %d" % [tile.grid_pos, tile.color_id])

	# If no tile is selected, select this one
	if selected_tile == null:
		_select_tile(tile)
		return

	# If same tile is tapped again, deselect it
	if selected_tile == tile:
		_deselect_tile()
		return

	# Store references to both tiles before swapping
	var tile_a: Area2D = selected_tile
	var tile_b: Area2D = tile

	# Try to swap the two tiles in board data
	var success: bool = board.try_swap(tile_a.grid_pos, tile_b.grid_pos)

	if success:
		print("Swap successful!")

		# Animate the swap visually
		await _animate_swap(tile_a, tile_b)

		# Store last swap for undo (before updating grid_pos)
		last_swap_tile_a = tile_a
		last_swap_tile_b = tile_b
		last_swap_valid = true

		# Swap the grid_pos properties to match new positions
		var temp_grid_pos: Vector2i = tile_a.grid_pos
		tile_a.grid_pos = tile_b.grid_pos
		tile_b.grid_pos = temp_grid_pos

		# Sync tile colors from board data (board already swapped them)
		var cell_a: Dictionary = board.get_cell(tile_a.grid_pos.x, tile_a.grid_pos.y)
		var cell_b: Dictionary = board.get_cell(tile_b.grid_pos.x, tile_b.grid_pos.y)
		tile_a.color_id = cell_a["color"]
		tile_b.color_id = cell_b["color"]

		# Update z-index for proper isometric depth sorting
		# Tiles closer to camera (higher y+x) need higher z-index to render on top
		tile_a.z_index = tile_a.grid_pos.y + tile_a.grid_pos.x
		tile_b.z_index = tile_b.grid_pos.y + tile_b.grid_pos.x

		# Check for matches
		var matches: Array[Vector2i] = board.find_all_2x2_matches()
		if matches.size() > 0:
			print("Found %d matches!" % matches.size())

			# Visual feedback: flash matched tiles
			await _flash_matched_squares(matches)

			# Always award points for matches
			board.award_points_for_matches(matches, 10)

			# Only lock if level configuration allows it
			if current_level != null and current_level.lock_on_match:
				# Lock the matched squares
				board.lock_squares(matches)

				# Update locked state on affected tiles
				_update_locked_tiles(matches)

				# Clear locked squares if enabled
				if current_level.clear_locked_squares:
					await _clear_locked_squares(matches)

					# Apply gravity if enabled
					if current_level.enable_gravity:
						await _apply_gravity()

						# Refill empty spaces if enabled
						if current_level.refill_from_top:
							await _refill_board()

							# Check for cascade matches
							await _check_cascade_matches()

			# Board settle animation
			_board_settle_animation()

		# Emit signal to notify game that a move was completed
		emit_signal("swap_completed")

		_deselect_tile()
	else:
		print("Swap failed - invalid move")
		# Animate invalid swap: swap then swap back
		await _animate_invalid_swap(tile_a, tile_b)
		# Deselect current and select the new tile instead
		_deselect_tile()
		_select_tile(tile)

## Select a tile and highlight it
func _select_tile(tile: Area2D) -> void:
	selected_tile = tile
	tile.set_highlighted(true)
	print("Selected tile at %v" % tile.grid_pos)

## Deselect the currently selected tile
func _deselect_tile() -> void:
	if selected_tile != null:
		selected_tile.set_highlighted(false)
		print("Deselected tile at %v" % selected_tile.grid_pos)
		selected_tile = null

## Undo the last swap (can only be called once per level)
## Returns true if undo was performed
func undo_last_swap() -> bool:
	if not last_swap_valid:
		print("No swap to undo")
		return false
	
	if last_swap_tile_a == null or last_swap_tile_b == null:
		print("Undo tiles are invalid")
		return false
	
	print("Undoing last swap...")
	
	# Deselect any selected tile first
	_deselect_tile()
	
	var tile_a: Area2D = last_swap_tile_a
	var tile_b: Area2D = last_swap_tile_b
	
	# Swap back in board data (this just swaps colors since swap is its own inverse)
	board._swap_colors(tile_a.grid_pos, tile_b.grid_pos)
	
	# Animate the swap back visually
	await _animate_swap(tile_a, tile_b)
	
	# Swap the grid_pos properties back
	var temp_grid_pos: Vector2i = tile_a.grid_pos
	tile_a.grid_pos = tile_b.grid_pos
	tile_b.grid_pos = temp_grid_pos
	
	# Sync tile colors from board data
	var cell_a: Dictionary = board.get_cell(tile_a.grid_pos.x, tile_a.grid_pos.y)
	var cell_b: Dictionary = board.get_cell(tile_b.grid_pos.x, tile_b.grid_pos.y)
	tile_a.color_id = cell_a["color"]
	tile_b.color_id = cell_b["color"]
	
	# Update z-index for proper isometric depth sorting
	tile_a.z_index = tile_a.grid_pos.y + tile_a.grid_pos.x
	tile_b.z_index = tile_b.grid_pos.y + tile_b.grid_pos.x
	
	# Clear undo state
	last_swap_valid = false
	last_swap_tile_a = null
	last_swap_tile_b = null
	
	emit_signal("undo_completed")
	print("Undo completed")
	return true

## Clear undo state (called when starting new level)
func clear_undo_state() -> void:
	last_swap_valid = false
	last_swap_tile_a = null
	last_swap_tile_b = null

## Enable or disable input (call with false to freeze board)
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	# Deselect any selected tile when disabling
	if not enabled:
		_deselect_tile()

## Update locked state for tiles in matched squares
func _update_locked_tiles(match_positions: Array[Vector2i]) -> void:
	for top_left in match_positions:
		# Get all 4 tiles in this 2x2 square
		var tiles_to_lock: Array[Vector2i] = [
			Vector2i(top_left.x, top_left.y),
			Vector2i(top_left.x + 1, top_left.y),
			Vector2i(top_left.x, top_left.y + 1),
			Vector2i(top_left.x + 1, top_left.y + 1),
		]

		# Find and lock each tile
		for tile_pos in tiles_to_lock:
			var tile := _find_tile_at_grid_pos(tile_pos)
			if tile != null:
				tile.set_locked(true)

## Find a tile at a specific grid position
func _find_tile_at_grid_pos(grid_pos: Vector2i) -> Area2D:
	for child in tile_container.get_children():
		if child is Area2D:
			var tile := child as Area2D
			if tile.grid_pos == grid_pos:
				return tile
	return null

## Flash matched squares with visual feedback
func _flash_matched_squares(match_positions: Array[Vector2i]) -> void:
	for top_left in match_positions:
		# Get all 4 tiles in this 2x2 square
		var tiles_to_flash: Array[Vector2i] = [
			Vector2i(top_left.x, top_left.y),
			Vector2i(top_left.x + 1, top_left.y),
			Vector2i(top_left.x, top_left.y + 1),
			Vector2i(top_left.x + 1, top_left.y + 1),
		]

		# Flash each tile
		for tile_pos in tiles_to_flash:
			var tile := _find_tile_at_grid_pos(tile_pos)
			if tile != null:
				var tween := create_tween()
				tween.set_parallel(true)
				# Brief bright flash
				tween.tween_property(tile, "modulate", Color.WHITE * 1.4, 0.15)
				tween.tween_property(tile, "scale", Vector2(1.08, 1.08), 0.15)
				# Return to locked state
				tween.chain().tween_property(tile, "modulate", tile.locked_modulate, 0.2)
				tween.parallel().tween_property(tile, "scale", Vector2(1.0, 1.0), 0.2)

	# Wait for flash animation to complete
	await get_tree().create_timer(0.35).timeout

## Play a subtle "settle" animation on the board after match
func _board_settle_animation() -> void:
	# Quick down-and-up bounce on the tile container
	var tween := create_tween()
	tween.tween_property(tile_container, "position:y", tile_container.position.y + 8, 0.1)\
		 .set_trans(Tween.TRANS_QUAD)\
		 .set_ease(Tween.EASE_OUT)
	tween.tween_property(tile_container, "position:y", tile_container.position.y, 0.15)\
		 .set_trans(Tween.TRANS_BOUNCE)\
		 .set_ease(Tween.EASE_OUT)

## Animate a successful swap between two tiles
## Tiles move to each other's positions with a settling pop
func _animate_swap(tile_a: Area2D, tile_b: Area2D) -> void:
	# Store original positions
	var pos_a := tile_a.position
	var pos_b := tile_b.position

	# Create parallel tweens for both tiles
	var tween_a := create_tween()
	var tween_b := create_tween()

	# Move tiles to each other's positions
	tween_a.tween_property(tile_a, "position", pos_b, 0.15)\
		   .set_trans(Tween.TRANS_QUAD)\
		   .set_ease(Tween.EASE_OUT)
	tween_b.tween_property(tile_b, "position", pos_a, 0.15)\
		   .set_trans(Tween.TRANS_QUAD)\
		   .set_ease(Tween.EASE_OUT)

	# Wait for movement to complete
	await tween_a.finished

	# Ensure final positions are exact (fix any floating point errors)
	tile_a.position = pos_b
	tile_b.position = pos_a

	# Quick "pop" on arrival: scale up then back
	var pop_a := create_tween()
	var pop_b := create_tween()

	pop_a.tween_property(tile_a, "scale", Vector2(1.03, 1.03), 0.05)
	pop_a.tween_property(tile_a, "scale", Vector2(1.0, 1.0), 0.05)
	pop_b.tween_property(tile_b, "scale", Vector2(1.03, 1.03), 0.05)
	pop_b.tween_property(tile_b, "scale", Vector2(1.0, 1.0), 0.05)

	await pop_a.finished

## Animate an invalid swap: swap then immediately swap back
## Includes red flash to indicate rejection
func _animate_invalid_swap(tile_a: Area2D, tile_b: Area2D) -> void:
	# Store original positions
	var pos_a := tile_a.position
	var pos_b := tile_b.position

	# Swap forward (faster than valid swap)
	var tween_a := create_tween()
	var tween_b := create_tween()

	tween_a.tween_property(tile_a, "position", pos_b, 0.12)\
		   .set_trans(Tween.TRANS_QUAD)\
		   .set_ease(Tween.EASE_OUT)
	tween_b.tween_property(tile_b, "position", pos_a, 0.12)\
		   .set_trans(Tween.TRANS_QUAD)\
		   .set_ease(Tween.EASE_OUT)

	await tween_a.finished

	# Red flash to indicate "nope"
	var flash_a := create_tween()
	var flash_b := create_tween()
	flash_a.tween_property(tile_a, "modulate", Color(1.5, 0.5, 0.5), 0.08)
	flash_a.tween_property(tile_a, "modulate", Color.WHITE, 0.08)
	flash_b.tween_property(tile_b, "modulate", Color(1.5, 0.5, 0.5), 0.08)
	flash_b.tween_property(tile_b, "modulate", Color.WHITE, 0.08)

	# Swap back immediately
	var back_a := create_tween()
	var back_b := create_tween()

	back_a.tween_property(tile_a, "position", pos_a, 0.12)\
		  .set_trans(Tween.TRANS_QUAD)\
		  .set_ease(Tween.EASE_OUT)
	back_b.tween_property(tile_b, "position", pos_b, 0.12)\
		  .set_trans(Tween.TRANS_QUAD)\
		  .set_ease(Tween.EASE_OUT)

	await back_a.finished

## Clear locked squares with fade out animation
## Also removes tile visuals from scene
func _clear_locked_squares(positions: Array[Vector2i]) -> void:
	# Fade out and shrink tiles
	for top_left in positions:
		var tiles_to_clear := [
			Vector2i(top_left.x, top_left.y),
			Vector2i(top_left.x + 1, top_left.y),
			Vector2i(top_left.x, top_left.y + 1),
			Vector2i(top_left.x + 1, top_left.y + 1),
		]

		for tile_pos in tiles_to_clear:
			var tile := _find_tile_at_grid_pos(tile_pos)
			if tile != null:
				var tween := create_tween()
				tween.set_parallel(true)
				tween.tween_property(tile, "modulate:a", 0.0, 0.25)
				tween.tween_property(tile, "scale", Vector2(0.5, 0.5), 0.25)

	# Wait for animation to complete
	await get_tree().create_timer(0.3).timeout

	# Remove from board data
	board.clear_locked_squares(positions)

	# Delete tile visuals
	for top_left in positions:
		var tiles_to_delete := [
			Vector2i(top_left.x, top_left.y),
			Vector2i(top_left.x + 1, top_left.y),
			Vector2i(top_left.x, top_left.y + 1),
			Vector2i(top_left.x + 1, top_left.y + 1),
		]

		for tile_pos in tiles_to_delete:
			var tile := _find_tile_at_grid_pos(tile_pos)
			if tile != null:
				tile.queue_free()

## Apply gravity with tile drop animation
func _apply_gravity() -> void:
	const TILE_WIDTH := 64.0
	const TILE_HEIGHT := 32.0
	const HEIGHT_STEP := 8.0

	var moves: Array[Dictionary] = board.apply_gravity()

	# Animate tiles dropping
	for move in moves:
		var tile := _find_tile_at_grid_pos(move["from"])
		if tile != null:
			var target_pos: Vector2 = board.grid_to_iso(
				move["to"].y, move["to"].x, 0,
				TILE_WIDTH, TILE_HEIGHT, HEIGHT_STEP
			)

			var tween := create_tween()
			tween.tween_property(tile, "position", target_pos, 0.3)\
				 .set_trans(Tween.TRANS_BOUNCE)\
				 .set_ease(Tween.EASE_OUT)

			# Update tile's grid position
			tile.grid_pos = move["to"]

			# Update z-index for new position
			tile.z_index = move["to"].y + move["to"].x

	# Wait for all drops to complete
	await get_tree().create_timer(0.35).timeout

## Refill board with new tiles spawning from above
func _refill_board() -> void:
	const TILE_WIDTH := 64.0
	const TILE_HEIGHT := 32.0
	const HEIGHT_STEP := 8.0

	# Get available colors from level (default to 3 colors)
	var colors := [0, 1, 2]  # Red, Blue, Green

	# Spawn new tiles in board data
	var spawned: Array[Vector2i] = board.refill_empty_spaces(colors)

	# Get reference to tile scene
	var tile_scene := preload("res://scenes/Tile.tscn")

	# Spawn tile visuals above board and drop them in
	for spawn_pos in spawned:
		var tile := tile_scene.instantiate() as Area2D
		tile.grid_pos = spawn_pos
		tile.color_id = board.get_cell(spawn_pos.x, spawn_pos.y)["color"]
		tile.height = 0

		# Calculate final position
		var final_pos: Vector2 = board.grid_to_iso(
			spawn_pos.y, spawn_pos.x, 0,
			TILE_WIDTH, TILE_HEIGHT, HEIGHT_STEP
		)

		# Start above board
		var start_pos: Vector2 = final_pos + Vector2(0, -200)
		tile.position = start_pos
		tile.modulate.a = 0

		# Set z-index
		tile.z_index = spawn_pos.y + spawn_pos.x

		# Add to scene
		tile_container.add_child(tile)

		# Connect to input router
		connect_tile(tile)

		# Animate: drop and fade in
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(tile, "position", final_pos, 0.4)\
			 .set_trans(Tween.TRANS_BOUNCE)\
			 .set_ease(Tween.EASE_OUT)
		tween.tween_property(tile, "modulate:a", 1.0, 0.2)

	# Wait for all spawns to complete
	await get_tree().create_timer(0.45).timeout

## Check for cascade matches (recursive with combo tracking)
## Called after refilling to check if new tiles created matches
## combo_depth: Current chain reaction depth (1 = first match, 2 = first cascade, etc.)
func _check_cascade_matches(combo_depth: int = 1) -> void:
	var matches: Array[Vector2i] = board.find_all_2x2_matches()
	if matches.size() > 0:
		print("Cascade: Found %d matches! (Combo x%d)" % [matches.size(), combo_depth])

		# Flash matched squares
		await _flash_matched_squares(matches)

		# Award points with combo multiplier
		board.award_points_for_matches(matches, 10, combo_depth)

		# Show combo UI if this is a cascade (depth > 1)
		if combo_depth > 1:
			_show_combo_indicator(combo_depth)

		# Check if we should lock (shouldn't happen in cascade but check anyway)
		if current_level != null and current_level.lock_on_match:
			board.lock_squares(matches)
			_update_locked_tiles(matches)

			# Continue cascade if enabled
			if current_level.clear_locked_squares:
				await _clear_locked_squares(matches)

				if current_level.enable_gravity:
					await _apply_gravity()

					if current_level.refill_from_top:
						await _refill_board()

						# Recursive cascade check with increased combo depth
						await _check_cascade_matches(combo_depth + 1)

## Show a brief combo indicator when cascades occur
func _show_combo_indicator(combo: int) -> void:
	if hud != null and hud.has_method("show_combo"):
		hud.show_combo(combo)
