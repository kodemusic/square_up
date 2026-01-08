extends Node

## Tile states
const STATE_NORMAL := 0    # Can be swapped and matched
const STATE_LOCKED := 1    # Matched and locked, can't be swapped
const STATE_CLEARING := 2  # Being cleared/animated

## Special color value for empty cells
const COLOR_NONE := -1

## SquareGlow effect scene
var square_glow_scene := preload("res://scenes/SquareGlow.tscn")

## Reference to tile container (set by load_level)
var tile_container: Node2D = null

## Isometric tile dimensions (set by load_level)
var tile_width: float = 64.0
var tile_height: float = 32.0

## Emitted when tiles are matched and points are awarded
signal score_awarded(points: int)

## Board dimensions in grid units
@export var width := 8
@export var height := 8

## 2D array storing cell data: board[y][x] -> {color, height, state}
var board: Array = []

func _ready() -> void:
	_init_board(width, height)

## Initialize the board grid with empty cells
func _init_board(w: int, h: int) -> void:
	board.clear()
	for y in range(h):
		var row: Array = []
		for x in range(w):
			row.append(_make_cell())
		board.append(row)

## Create a cell dictionary with default or specified values
func _make_cell(color: int = COLOR_NONE, z: int = 0, state: int = STATE_NORMAL) -> Dictionary:
	return {
		"color": color,
		"height": z,
		"state": state,
	}

## Public debug function: Print current board state and check for matches
## Can be called from console or other scripts: board.debug_board_state()
func debug_board_state(label: String = "Current Board State") -> void:
	print("\n=== %s ===" % label)
	print("Board dimensions: %dx%d" % [width, height])
	
	# Print board grid
	print("\nBoard layout (color IDs):")
	for y in range(height):
		var row_str := "  "
		for x in range(width):
			var cell: Dictionary = board[y][x]
			var color: int = cell["color"]
			var state: int = cell["state"]
			
			# Format cell display
			if color == COLOR_NONE:
				row_str += "[.] "
			elif state == STATE_LOCKED:
				row_str += "[%dL] " % color  # L = locked
			elif state == STATE_CLEARING:
				row_str += "[%dC] " % color  # C = clearing
			else:
				row_str += "[%d] " % color
		print(row_str)
	
	# Check for matches
	var matches: Array[Vector2i] = []
	for y in range(height - 1):
		for x in range(width - 1):
			var c0: int = board[y][x]["color"]
			if c0 == COLOR_NONE:
				continue
			if (board[y][x + 1]["color"] == c0 and
				board[y + 1][x]["color"] == c0 and
				board[y + 1][x + 1]["color"] == c0):
				matches.append(Vector2i(x, y))
	
	# Print match status
	if matches.size() == 0:
		print("\n✅ No 2x2 matches detected")
	else:
		print("\n⚠️  %d match(es) detected:" % matches.size())
		for match_pos in matches:
			var color: int = board[match_pos.y][match_pos.x]["color"]
			print("  - Match at (%d, %d) with color %d" % [match_pos.x, match_pos.y, color])
	
	print("=== END %s ===\n" % label)

## Get the cell data at grid position (x, y)
func get_cell(x: int, y: int) -> Dictionary:
	if y < 0 or y >= board.size() or x < 0 or (board.size() > 0 and x >= board[0].size()):
		push_error("get_cell out of bounds: (%d, %d)" % [x, y])
		return _make_cell()
	return board[y][x]

## Set all properties of a cell at grid position (x, y)
func set_cell(x: int, y: int, color: int, z: int, state: int) -> void:
	if y < 0 or y >= board.size() or x < 0 or (board.size() > 0 and x >= board[0].size()):
		push_error("set_cell out of bounds: (%d, %d)" % [x, y])
		return
	board[y][x]["color"] = color
	board[y][x]["height"] = z
	board[y][x]["state"] = state

## Convert grid coordinates to screen position
## Mobile-first: Square grid (64x64 tiles, not isometric)
func grid_to_iso(row: float, col: float, z: float, tw: float, _th: float, height_step: float) -> Vector2:
	# Square grid: simple x,y mapping
	# tw parameter is now tile_size (64x64)
	# _th parameter kept for API compatibility but unused in square grid
	var x := col * tw
	var y := row * tw - (z * height_step)
	return Vector2(x, y)

## Attempt to swap two tiles, returns true if swap creates a match
## Automatically reverts the swap if no match is created
func try_swap(a: Vector2i, b: Vector2i) -> bool:
	# Check basic swap validity (adjacency, states, height)
	if not _can_swap(a, b):
		return false
	# Perform the swap
	_swap_colors(a, b)
	# Check if swap creates a 2x2 match
	if not _is_swap_valid(a, b):
		# Revert swap if no match created
		_swap_colors(a, b)
		return false
	return true

## Check if two tiles can be swapped (basic validity, not match logic)
func _can_swap(a: Vector2i, b: Vector2i) -> bool:
	# Both positions must be on the board
	if not _in_bounds(a) or not _in_bounds(b):
		return false
	# Tiles must be adjacent (Manhattan distance = 1)
	if abs(a.x - b.x) + abs(a.y - b.y) != 1:
		return false
	var cell_a: Dictionary = board[a.y][a.x]
	var cell_b: Dictionary = board[b.y][b.x]
	# Both tiles must be in normal state (not locked)
	if cell_a["state"] != STATE_NORMAL or cell_b["state"] != STATE_NORMAL:
		return false
	# Tiles must be at the same height to swap
	return cell_a["height"] == cell_b["height"]

## Swap the colors of two cells (doesn't check validity)
func _swap_colors(a: Vector2i, b: Vector2i) -> void:
	var cell_a: Dictionary = board[a.y][a.x]
	var cell_b: Dictionary = board[b.y][b.x]
	var temp: int = cell_a["color"]
	cell_a["color"] = cell_b["color"]
	cell_b["color"] = temp

## Update tile visuals in the tile container after data changes
## Finds tiles by grid position and updates their color_id
func update_tile_visuals(container: Node2D) -> void:
	for tile in container.get_children():
		if tile is Area2D:
			var grid_pos: Vector2i = tile.grid_pos
			var cell: Dictionary = board[grid_pos.y][grid_pos.x]
			tile.color_id = cell["color"]
			tile.set_locked(cell["state"] == STATE_LOCKED)

## Check if a swap creates at least one 2x2 match
func _is_swap_valid(a: Vector2i, b: Vector2i) -> bool:
	return _has_2x2_match_near(a) or _has_2x2_match_near(b)

## Check if any 2x2 match exists in the 3x3 area around a position
## Searches all four possible 2x2 squares that could include this position
func _has_2x2_match_near(pos: Vector2i) -> bool:
	for dy in range(-1, 1):
		for dx in range(-1, 1):
			var top_left := Vector2i(pos.x + dx, pos.y + dy)
			if _has_2x2_match_at(top_left):
				return true
	return false

## Check if a 2x2 match exists at a specific top-left position
func _has_2x2_match_at(top_left: Vector2i) -> bool:
	var x := top_left.x
	var y := top_left.y
	# Ensure all four cells are within bounds
	if x < 0 or y < 0 or x + 1 >= width or y + 1 >= height:
		return false
	var c0: int = board[y][x]["color"]
	# Empty cells don't count as matches
	if c0 == COLOR_NONE:
		return false
	# Check if all four cells have the same color
	return (
		board[y][x + 1]["color"] == c0
		and board[y + 1][x]["color"] == c0
		and board[y + 1][x + 1]["color"] == c0
	)

## Check if a grid position is within board bounds
func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height

## Find all 2x2 matches on the board
## Returns array of top-left positions for each matching square
## Filters out overlapping squares to ensure each tile is only counted once
func find_all_2x2_matches() -> Array[Vector2i]:
	var all_matches: Array[Vector2i] = []

	# First, find all possible 2x2 squares
	for y in range(height - 1):
		for x in range(width - 1):
			var c0: Dictionary = board[y][x]
			# Skip empty cells
			if c0["color"] == COLOR_NONE:
				continue
			# Skip locked cells - already matched tiles can't be matched again
			if c0["state"] == STATE_LOCKED:
				continue
			var c1: Dictionary = board[y][x + 1]
			var c2: Dictionary = board[y + 1][x]
			var c3: Dictionary = board[y + 1][x + 1]
			# All four cells must have same color
			if c1["color"] != c0["color"] or c2["color"] != c0["color"] or c3["color"] != c0["color"]:
				continue
			# All four cells must be at same height
			if c1["height"] != c0["height"] or c2["height"] != c0["height"] or c3["height"] != c0["height"]:
				continue
			# All four cells must be unlocked (in normal state)
			if c1["state"] != STATE_NORMAL or c2["state"] != STATE_NORMAL or c3["state"] != STATE_NORMAL:
				continue
			all_matches.append(Vector2i(x, y))

	# Filter out overlapping squares - keep only non-overlapping ones
	return _filter_non_overlapping_squares(all_matches)

## Filter a list of 2x2 squares to remove overlaps
## Returns only non-overlapping squares
func _filter_non_overlapping_squares(squares: Array[Vector2i]) -> Array[Vector2i]:
	if squares.size() == 0:
		return []

	var non_overlapping: Array[Vector2i] = []
	var used_cells: Dictionary = {}  # Track which cells are already in a square

	# Process squares in order (top-left to bottom-right)
	for square_pos in squares:
		var cells_in_square: Array[Vector2i] = [
			Vector2i(square_pos.x, square_pos.y),
			Vector2i(square_pos.x + 1, square_pos.y),
			Vector2i(square_pos.x, square_pos.y + 1),
			Vector2i(square_pos.x + 1, square_pos.y + 1),
		]

		# Check if any cell in this square is already used
		var has_overlap := false
		for cell in cells_in_square:
			var key := "%d,%d" % [cell.x, cell.y]
			if key in used_cells:
				has_overlap = true
				break

		# If no overlap, add this square and mark its cells as used
		if not has_overlap:
			non_overlapping.append(square_pos)
			for cell in cells_in_square:
				var key := "%d,%d" % [cell.x, cell.y]
				used_cells[key] = true

	return non_overlapping

## Award points for matched squares without locking them
## Points scale with height: base_points * (height + 1) * combo_multiplier
## combo_multiplier: Cascade depth (1 = normal, 2 = first cascade, 3 = second cascade, etc.)
func award_points_for_matches(positions: Array[Vector2i], points_per_square: int = 10, combo_multiplier: int = 1) -> void:
	var total_points := 0
	for top_left in positions:
		# Validate square is fully on board
		if top_left.x < 0 or top_left.y < 0 or top_left.x + 1 >= width or top_left.y + 1 >= height:
			continue
		var square_height: int = board[top_left.y][top_left.x]["height"]
		# Award points with height multiplier AND combo multiplier
		# Formula: base_points * (height + 1) * combo_multiplier
		total_points += points_per_square * (square_height + 1) * combo_multiplier
		
		# Spawn glow effect at center of 2x2 square
		_spawn_square_glow(top_left, square_height)
		
	if total_points > 0:
		emit_signal("score_awarded", total_points)

## Lock all tiles in the given matched squares (no points awarded)
func lock_squares(positions: Array[Vector2i]) -> void:
	for top_left in positions:
		# Validate square is fully on board
		if top_left.x < 0 or top_left.y < 0 or top_left.x + 1 >= width or top_left.y + 1 >= height:
			continue
		# Define all four tiles in this 2x2 square
		var tiles: Array[Vector2i] = [
			Vector2i(top_left.x, top_left.y),
			Vector2i(top_left.x + 1, top_left.y),
			Vector2i(top_left.x, top_left.y + 1),
			Vector2i(top_left.x + 1, top_left.y + 1),
		]
		# Lock each tile in the square
		for pos in tiles:
			_set_locked(pos)

## Lock a single cell, returns true if state changed
func _set_locked(pos: Vector2i) -> bool:
	if not _in_bounds(pos):
		return false
	var cell: Dictionary = board[pos.y][pos.x]
	# Don't lock already locked cells
	if cell["state"] == STATE_LOCKED:
		return false
	cell["state"] = STATE_LOCKED
	return true

## Clear locked squares from the board (set to empty)
## Used in cascade mode to remove matched squares from play
func clear_locked_squares(positions: Array[Vector2i]) -> void:
	for top_left in positions:
		# Validate square is fully on board
		if top_left.x < 0 or top_left.y < 0 or top_left.x + 1 >= width or top_left.y + 1 >= height:
			continue
		# Define all four tiles in this 2x2 square
		var tiles: Array[Vector2i] = [
			Vector2i(top_left.x, top_left.y),
			Vector2i(top_left.x + 1, top_left.y),
			Vector2i(top_left.x, top_left.y + 1),
			Vector2i(top_left.x + 1, top_left.y + 1),
		]
		# Clear each tile (set to empty)
		for pos in tiles:
			if _in_bounds(pos):
				set_cell(pos.x, pos.y, COLOR_NONE, 0, STATE_NORMAL)

## Apply gravity: tiles drop into empty spaces below them
## Returns array of moves that occurred: [{from: Vector2i, to: Vector2i}]
func apply_gravity() -> Array[Dictionary]:
	var moves: Array[Dictionary] = []

	# Process each column from bottom to top
	for x in range(width):
		# Start from bottom row, look for empty cells
		for y in range(height - 1, -1, -1):
			var cell := get_cell(x, y)
			if cell["color"] == COLOR_NONE:
				# Find the first non-empty tile above this empty space
				for y_above in range(y - 1, -1, -1):
					var above := get_cell(x, y_above)
					if above["color"] != COLOR_NONE:
						# Move tile down
						set_cell(x, y, above["color"], above["height"], above["state"])
						set_cell(x, y_above, COLOR_NONE, 0, STATE_NORMAL)
						moves.append({
							"from": Vector2i(x, y_above),
							"to": Vector2i(x, y)
						})
						break

	return moves

## Spawn new random tiles to fill empty spaces
## colors: Array of color IDs to randomly choose from
## Returns array of positions where new tiles were spawned
func refill_empty_spaces(colors: Array[int]) -> Array[Vector2i]:
	var spawned: Array[Vector2i] = []

	# Scan entire board for empty cells
	for y in range(height):
		for x in range(width):
			var cell := get_cell(x, y)
			if cell["color"] == COLOR_NONE:
				# Spawn random color
				var random_color: int = colors[randi() % colors.size()]
				set_cell(x, y, random_color, 0, STATE_NORMAL)
				spawned.append(Vector2i(x, y))

	return spawned

## Load a level and spawn tiles into the tile container
## tile_scene: PackedScene reference to Tile.tscn
## tile_container: Node2D to add tiles to
## level: LevelData to load
## tile_width, tile_height: Size of tile in pixels for isometric positioning
## height_step: Vertical offset per height level
## input_router: Optional InputRouter to connect tile signals
func load_level(tile_scene: PackedScene, p_tile_container: Node2D, level: LevelData,
				p_tile_width: float = 64.0, p_tile_height: float = 32.0, height_step: float = 8.0,
				input_router: Node = null) -> void:
	# Store references for glow spawning
	tile_container = p_tile_container
	tile_width = p_tile_width
	tile_height = p_tile_height
	
	# Clear existing tiles
	for child in tile_container.get_children():
		child.queue_free()

	# Resize board to match level dimensions
	width = level.width
	height = level.height
	_init_board(level.width, level.height)

	# Validate starting_grid is properly sized
	if level.starting_grid.size() == 0:
		push_error("Level starting_grid is empty")
		return
	if level.starting_grid.size() != level.height:
		push_error("Level starting_grid height mismatch: expected %d, got %d" % [level.height, level.starting_grid.size()])
		return
	if level.starting_grid[0].size() != level.width:
		push_error("Level starting_grid width mismatch: expected %d, got %d" % [level.width, level.starting_grid[0].size()])
		return

	# Populate board data from level starting grid
	for y in range(level.height):
		for x in range(level.width):
			var color_id: int = level.starting_grid[y][x]
			# Set cell data (assuming height 0 for now, can be extended later)
			set_cell(x, y, color_id, 0, STATE_NORMAL)

	# Spawn tile visuals for each non-empty cell
	print("Spawning tiles with dimensions: %fx%f, height_step: %f" % [tile_width, tile_height, height_step])
	for y in range(height):
		for x in range(width):
			var cell: Dictionary = get_cell(x, y)
			if cell["color"] != COLOR_NONE:
				var tile := tile_scene.instantiate() as Area2D

				# Set tile properties
				tile.grid_pos = Vector2i(x, y)
				tile.color_id = cell["color"]
				tile.height = cell["height"]

				# Debug color assignment
				if (x == 0 and y == 0) or (x == 1 and y == 0) or (x == 2 and y == 0):
					print("  Tile [%d,%d] color_id: %d" % [x, y, cell["color"]])

				# Position tile in isometric space
				var iso_pos := grid_to_iso(y, x, cell["height"],
											tile_width, tile_height, height_step)
				tile.position = iso_pos

				# Set z-index for proper isometric depth sorting
				# Tiles closer to camera (higher y+x) need higher z-index to render on top
				tile.z_index = y + x

				# Debug output for corners
				if (x == 0 and y == 0) or (x == width-1 and y == 0) or (x == 0 and y == height-1):
					print("  Tile [%d,%d] -> iso_pos: %v, z_index: %d" % [x, y, iso_pos, tile.z_index])

				# Add to container
				tile_container.add_child(tile)

				# Connect tile to input router if provided
				if input_router != null and input_router.has_method("connect_tile"):
					input_router.connect_tile(tile)
	
	# Debug: Check for matches immediately after spawn
	_debug_check_starting_matches()

## Debug function to check if any 2x2 matches exist on the board after spawn
func _debug_check_starting_matches() -> void:
	print("\n=== DEBUG: Checking for starting matches ===")
	var matches_found: Array[Vector2i] = []
	
	# Check all possible 2x2 positions
	for y in range(height - 1):
		for x in range(width - 1):
			var c0: int = board[y][x]["color"]
			
			# Skip empty cells
			if c0 == COLOR_NONE:
				continue
			
			# Check if all four cells match
			if (board[y][x + 1]["color"] == c0 and
				board[y + 1][x]["color"] == c0 and
				board[y + 1][x + 1]["color"] == c0):
				matches_found.append(Vector2i(x, y))
				print("  ⚠️  MATCH FOUND at position (%d, %d) - Color: %d" % [x, y, c0])
	
	if matches_found.size() == 0:
		print("  ✅ No starting matches detected - puzzle is valid!")
	else:
		print("  ❌ ERROR: %d starting matches found - puzzle should not have matches at spawn!" % matches_found.size())
		# Print the full board for debugging
		print("\nBoard state:")
		for y in range(height):
			var row_str := "  "
			for x in range(width):
				var color: int = board[y][x]["color"]
				row_str += str(color) + " "
			print(row_str)
	
	print("=== END DEBUG ===\n")

## Spawn a SquareGlow effect at the center of a 2x2 matched square
func _spawn_square_glow(top_left: Vector2i, square_height: int) -> void:
	if tile_container == null:
		return
	
	# Calculate center of 2x2 square in grid coordinates
	# Center is at (top_left.x + 0.5, top_left.y + 0.5) but we need the iso center
	# which is the average of all 4 tile positions
	var center_row := top_left.y + 0.5
	var center_col := top_left.x + 0.5
	
	# Convert to isometric position
	var center_iso := grid_to_iso(center_row, center_col, square_height, tile_width, tile_height, 8.0)
	
	# Get color from one of the matched tiles
	var color_id: int = board[top_left.y][top_left.x]["color"]
	var glow_color := _get_color_for_id(color_id)
	
	# Spawn glow
	var glow := square_glow_scene.instantiate()
	glow.position = center_iso
	glow.z_index = 100  # Render on top
	tile_container.add_child(glow)
	glow.play(glow_color)

## Get a Color for a color_id (for glow effect)
func _get_color_for_id(color_id: int) -> Color:
	match color_id:
		0: return Color.RED
		1: return Color.GREEN
		2: return Color.BLUE
		3: return Color.YELLOW
		4: return Color.PURPLE
		5: return Color.ORANGE
		_: return Color.WHITE
