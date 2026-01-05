extends Node

## Handles player input and tile selection/swapping
## Routes tile tap signals to board swap logic

## Emitted when a successful swap is completed
signal swap_completed

## Reference to the board node for swap operations
@onready var board := get_node("/root/Game/BoardRoot") as Node
@onready var tile_container := get_node("/root/Game/BoardRoot/TileContainer") as Node2D

## Currently selected tile (first tap)
var selected_tile: Area2D = null

func _ready() -> void:
	# Connect to all tile tapped signals when tiles are spawned
	# We'll use a different approach - tiles will be connected after spawning
	pass

## Connect a tile's tapped signal to this input router
func connect_tile(tile: Area2D) -> void:
	if not tile.tapped.is_connected(_on_tile_tapped):
		tile.tapped.connect(_on_tile_tapped)

## Handle tile tap/click events
func _on_tile_tapped(tile: Area2D) -> void:
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

		# Swap the color_ids of the tile objects directly
		var temp_color: int = tile_a.color_id
		tile_a.color_id = tile_b.color_id
		tile_b.color_id = temp_color

		# Swap the grid_pos properties to match new positions
		var temp_grid_pos: Vector2i = tile_a.grid_pos
		tile_a.grid_pos = tile_b.grid_pos
		tile_b.grid_pos = temp_grid_pos

		# Check for matches and lock them
		var matches: Array[Vector2i] = board.find_all_2x2_matches()
		if matches.size() > 0:
			print("Found %d matches!" % matches.size())

			# Visual feedback: flash matched tiles
			await _flash_matched_squares(matches)

			# Lock squares and award points
			board.lock_squares(matches, 10)

			# Update locked state on affected tiles
			_update_locked_tiles(matches)

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
