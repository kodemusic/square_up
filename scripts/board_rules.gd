## ========================================================================
##  BOARD RULES - Pure Logic Module (No Nodes, No Visuals, No Signals)
## ========================================================================
## Shared game rules used by both the game engine and solver.
## Provides deterministic board resolution with seeded RNG for validation.
##
## Design Philosophy:
## - Every swap must create at least one 2×2 square
## - Cascades are bonus consequences, not substitutes for skill
## - Board state is represented as simple data structures
## - All logic is deterministic with seeded RNG
##
## Usage:
##   var result = BoardRules.resolve(state, rules, rng)
##   if result.squares_created > 0:
##       # Valid move!
## ========================================================================

class_name BoardRules

## Cell structure constants (matches board.gd)
const STATE_NORMAL := 0
const STATE_LOCKED := 1
const STATE_CLEARING := 2
const COLOR_NONE := -1

## ========================================================================
## DATA STRUCTURES
## ========================================================================

## Represents a matched 2×2 square
class Square:
	var top_left: Vector2i  # Top-left position of the square
	var color: int          # Color of the matched tiles
	var height: int         # Stack height of the tiles

	func _init(pos: Vector2i, col: int, h: int):
		top_left = pos
		color = col
		height = h

	## Get all four cell positions in this square
	func get_cells() -> Array[Vector2i]:
		return [
			top_left,
			Vector2i(top_left.x + 1, top_left.y),
			Vector2i(top_left.x, top_left.y + 1),
			Vector2i(top_left.x + 1, top_left.y + 1)
		]

## Result of resolving a swap with cascades
class ResolveResult:
	var final_state: Array = []         # Final board state after all cascades
	var squares_created: int = 0        # Total squares created (initial + cascades)
	var cascade_depth: int = 0          # How many cascade waves occurred
	var total_score: int = 0            # Total score earned
	var stable: bool = true             # Whether board reached stable state
	var events: Array[Dictionary] = []  # Event log for animations (optional)

	func add_event(type: String, data: Dictionary) -> void:
		events.append({"type": type, "data": data})

## Game rules configuration
class Rules:
	var lock_on_match: bool = false
	var clear_locked_squares: bool = false
	var enable_gravity: bool = false
	var refill_from_top: bool = false
	var num_colors: int = 3
	var cascade_score_multiplier: float = 1.5  # Each cascade wave multiplies score

	## Create rules from level data (accepts any object with the required properties)
	static func from_level_data(level) -> Rules:
		var rules := Rules.new()
		rules.lock_on_match = level.lock_on_match
		rules.clear_locked_squares = level.clear_locked_squares
		rules.enable_gravity = level.enable_gravity
		rules.refill_from_top = level.refill_from_top
		rules.num_colors = level.num_colors
		return rules

## ========================================================================
## CORE LOGIC FUNCTIONS
## ========================================================================

## Find all 2×2 matching squares on the board
## Only considers NORMAL state tiles (not locked or clearing)
## Returns array of Square objects
static func find_squares(state: Array) -> Array[Square]:
	var squares: Array[Square] = []

	if state.size() == 0:
		return squares

	var height: int = state.size()
	var width: int = state[0].size()

	# Scan for all possible 2×2 squares
	for y in range(height - 1):
		for x in range(width - 1):
			var c0: Dictionary = state[y][x]

			# Skip empty cells
			if c0["color"] == COLOR_NONE:
				continue

			# Skip locked cells - already matched tiles can't match again
			if c0["state"] == STATE_LOCKED:
				continue

			# Get the other three cells
			var c1: Dictionary = state[y][x + 1]
			var c2: Dictionary = state[y + 1][x]
			var c3: Dictionary = state[y + 1][x + 1]

			# All four must match color
			if c1["color"] != c0["color"] or c2["color"] != c0["color"] or c3["color"] != c0["color"]:
				continue

			# All four must be same height (stack depth)
			if c1["height"] != c0["height"] or c2["height"] != c0["height"] or c3["height"] != c0["height"]:
				continue

			# All four must be in normal state (not locked or clearing)
			if c1["state"] != STATE_NORMAL or c2["state"] != STATE_NORMAL or c3["state"] != STATE_NORMAL:
				continue

			# Valid square found!
			squares.append(Square.new(Vector2i(x, y), c0["color"], c0["height"]))

	# Filter overlapping squares (same as board.gd logic)
	return _filter_non_overlapping_squares(squares, state)

## Apply square resolution: lock or clear matched squares
## Modifies state in place
## Returns number of squares resolved
static func apply_square_resolution(state: Array, squares: Array[Square], rules: Rules) -> int:
	if squares.is_empty():
		return 0

	for square in squares:
		var cells := square.get_cells()

		if rules.lock_on_match and not rules.clear_locked_squares:
			# Lock tiles (mark as matched, can't be swapped)
			for cell_pos in cells:
				state[cell_pos.y][cell_pos.x]["state"] = STATE_LOCKED

		elif rules.clear_locked_squares:
			# Clear tiles (reduce stack or remove)
			for cell_pos in cells:
				var cell: Dictionary = state[cell_pos.y][cell_pos.x]
				if cell["height"] > 1:
					# Reduce stack depth
					cell["height"] -= 1
				else:
					# Remove tile completely
					cell["color"] = COLOR_NONE
					cell["height"] = 0
					cell["state"] = STATE_NORMAL

		else:
			# Just mark as normal (simple mode - tiles stay)
			for cell_pos in cells:
				state[cell_pos.y][cell_pos.x]["state"] = STATE_NORMAL

	return squares.size()

## Apply gravity: tiles drop into empty spaces below
## Modifies state in place
## Returns array of moves that occurred: [{from: Vector2i, to: Vector2i}]
static func apply_gravity(state: Array) -> Array[Dictionary]:
	if state.size() == 0:
		return []

	var height: int = state.size()
	var width: int = state[0].size()
	var moves: Array[Dictionary] = []

	# Process each column independently
	for x in range(width):
		# STEP 1: Read all non-null tiles into a list (bottom to top)
		var tiles_in_column: Array[Dictionary] = []
		for y in range(height - 1, -1, -1):  # Bottom to top
			var cell: Dictionary = state[y][x]
			if cell["color"] != COLOR_NONE:
				# Store tile data with original position
				tiles_in_column.append({
					"color": cell["color"],
					"height": cell["height"],
					"state": cell["state"],
					"from_y": y
				})

		# STEP 2: Clear the column
		for y in range(height):
			state[y][x] = _make_cell()

		# STEP 3: Reinsert tiles starting from the bottom
		var insert_y := height - 1  # Start at bottom
		for tile_data in tiles_in_column:
			state[insert_y][x] = _make_cell(
				tile_data["color"],
				tile_data["height"],
				tile_data["state"]
			)

			# Track movement if tile changed position
			if insert_y != tile_data["from_y"]:
				moves.append({
					"from": Vector2i(x, tile_data["from_y"]),
					"to": Vector2i(x, insert_y)
				})

			insert_y -= 1  # Move up for next tile

	return moves

## Apply refill: spawn new tiles in empty spaces
## Modifies state in place
## Uses seeded RNG for deterministic results
## Returns number of tiles spawned
static func apply_refill(state: Array, rng: RandomNumberGenerator, rules: Rules) -> int:
	if state.size() == 0:
		return 0

	var height: int = state.size()
	var width: int = state[0].size()
	var spawned := 0

	# Fill empty cells with random colors
	for y in range(height):
		for x in range(width):
			var cell: Dictionary = state[y][x]
			if cell["color"] == COLOR_NONE:
				# Spawn new tile with random color
				var new_color := rng.randi_range(0, rules.num_colors - 1)
				cell["color"] = new_color
				cell["height"] = 1  # New tiles always have height 1
				cell["state"] = STATE_NORMAL
				spawned += 1

	return spawned

## Master resolution function: resolve swap with full cascade simulation
## Loops until board is stable: find → resolve → gravity → refill → repeat
## Returns ResolveResult with final state and statistics
static func resolve(
	initial_state: Array,
	rules: Rules,
	rng: RandomNumberGenerator,
	max_cascades: int = 10
) -> ResolveResult:
	var result := ResolveResult.new()

	# Deep copy initial state
	result.final_state = _copy_grid(initial_state)

	var cascade_wave := 0
	var base_score_per_square := 10

	while cascade_wave < max_cascades:
		# Find squares in current state
		var squares := find_squares(result.final_state)

		if squares.is_empty():
			# No more squares - board is stable
			result.stable = true
			break

		# Track squares created
		result.squares_created += squares.size()

		# Calculate score with cascade multiplier
		var wave_multiplier := pow(rules.cascade_score_multiplier, cascade_wave)
		var wave_score := int(squares.size() * base_score_per_square * wave_multiplier)
		result.total_score += wave_score

		# Log event
		result.add_event("squares_matched", {
			"count": squares.size(),
			"cascade_wave": cascade_wave,
			"score": wave_score
		})

		# Resolve squares (lock or clear)
		apply_square_resolution(result.final_state, squares, rules)
		result.add_event("squares_resolved", {"count": squares.size()})

		# If tiles aren't locked or cleared, board won't change - exit now
		if not rules.lock_on_match and not rules.clear_locked_squares:
			result.stable = true
			break

		# Apply gravity if enabled
		if rules.enable_gravity:
			var gravity_moves := apply_gravity(result.final_state)
			if gravity_moves.size() > 0:
				result.add_event("gravity_applied", {"moves": gravity_moves})

		# Apply refill if enabled
		if rules.refill_from_top:
			var spawned := apply_refill(result.final_state, rng, rules)
			if spawned > 0:
				result.add_event("tiles_refilled", {"count": spawned})

		# Increment cascade depth
		cascade_wave += 1
		result.cascade_depth = cascade_wave

	# Check if we hit max cascades (board didn't stabilize)
	if cascade_wave >= max_cascades:
		result.stable = false
		push_warning("Board did not stabilize after %d cascades" % max_cascades)

	return result

## ========================================================================
## HELPER FUNCTIONS
## ========================================================================

## Filter overlapping squares to ensure each tile is only counted once
## Keeps squares in priority order (first in list wins)
static func _filter_non_overlapping_squares(squares: Array[Square], state: Array) -> Array[Square]:
	if squares.is_empty():
		return []

	var non_overlapping: Array[Square] = []
	var used_cells: Dictionary = {}  # Track which cells are already in a square

	# Process squares in order
	for square in squares:
		var cells := square.get_cells()

		# Check if any cell is already used
		var has_overlap := false
		for cell_pos in cells:
			if used_cells.has(cell_pos):
				has_overlap = true
				break

		# If no overlap, keep this square and mark cells as used
		if not has_overlap:
			non_overlapping.append(square)
			for cell_pos in cells:
				used_cells[cell_pos] = true

	return non_overlapping

## Deep copy a grid (2D array of cell dictionaries)
static func _copy_grid(grid: Array) -> Array:
	var copy: Array = []
	for y in range(grid.size()):
		var row: Array = []
		for x in range(grid[y].size()):
			var cell: Dictionary = grid[y][x]
			row.append({
				"color": cell["color"],
				"height": cell["height"],
				"state": cell["state"]
			})
		copy.append(row)
	return copy

## Create a cell dictionary
static func _make_cell(color: int = COLOR_NONE, height: int = 0, state: int = STATE_NORMAL) -> Dictionary:
	return {
		"color": color,
		"height": height,
		"state": state
	}

## Swap two cells in a grid (modifies in place)
static func swap_cells(state: Array, a: Vector2i, b: Vector2i) -> void:
	if state.size() == 0 or a.y >= state.size() or b.y >= state.size():
		push_error("Invalid grid or position for swap")
		return

	var temp: Dictionary = state[a.y][a.x].duplicate()
	state[a.y][a.x] = state[b.y][b.x].duplicate()
	state[b.y][b.x] = temp
