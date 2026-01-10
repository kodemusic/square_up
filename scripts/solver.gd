## Puzzle solver and level validator using breadth-first search
## Key features:
## - BFS with depth limit and hash-based deduplication
## - Only explores valid swaps (must create at least one 2×2 square)
## - Uses BoardRules for cascade simulation
## - Finds shortest solution path
## - Validates no trivial (1-move) alternate solutions exist
##
## Updated to use shared BoardRules logic for consistency with gameplay

class_name Solver

## Board state representation for BFS
## Now stores full cell data (color + height + state) instead of just colors
class BoardState:
	var grid: Array = []            # 2D array of cell dictionaries {color, height, state}
	var width: int
	var height: int
	var move_count: int = 0
	var squares_completed: int = 0  # Total squares matched in this state
	var last_move: Dictionary = {}  # {from: Vector2i, to: Vector2i}
	var parent: BoardState = null   # For path reconstruction

	## Create from 2D array of simple color IDs
	## Converts simple grid to full cell structure
	static func from_simple_grid(grid_2d: Array) -> BoardState:
		var state := BoardState.new()
		state.height = grid_2d.size()

		# Validate grid is not empty
		if state.height == 0 or grid_2d[0].size() == 0:
			push_error("Cannot create BoardState from empty grid")
			return state

		state.width = grid_2d[0].size()
		state.grid = []

		# Convert simple color array to full cell structure
		for y in range(state.height):
			var row: Array = []
			for x in range(state.width):
				var color: int = grid_2d[y][x]
				row.append({
					"color": color,
					"height": 1 if color >= 0 else 0,  # Default height 1 for normal tiles
					"state": BoardRules.STATE_NORMAL
				})
			state.grid.append(row)

		return state

	## Create from full cell grid
	static func from_cell_grid(grid_2d: Array) -> BoardState:
		var state := BoardState.new()
		state.height = grid_2d.size()

		if state.height == 0 or grid_2d[0].size() == 0:
			push_error("Cannot create BoardState from empty grid")
			return state

		state.width = grid_2d[0].size()
		state.grid = BoardRules._copy_grid(grid_2d)

		return state

	## Convert back to simple 2D color array (for backwards compatibility)
	func to_simple_grid() -> Array:
		var grid_2d: Array = []
		for y in range(height):
			var row: Array = []
			for x in range(width):
				row.append(grid[y][x]["color"])
			grid_2d.append(row)
		return grid_2d

	## Create a copy of this state with a swap applied and resolved
	## Uses BoardRules.resolve() to handle cascades properly
	func apply_swap_and_resolve(from: Vector2i, to: Vector2i, rules: BoardRules.Rules, rng: RandomNumberGenerator) -> BoardState:
		var new_state := BoardState.new()
		new_state.width = width
		new_state.height = height
		new_state.move_count = move_count + 1
		new_state.last_move = {"from": from, "to": to}
		new_state.parent = self

		# Copy grid and perform swap
		new_state.grid = BoardRules._copy_grid(grid)
		BoardRules.swap_cells(new_state.grid, from, to)

		# Resolve the board (cascades, gravity, refill)
		var resolve_result := BoardRules.resolve(new_state.grid, rules, rng)

		# Update state with resolved board
		new_state.grid = resolve_result.final_state
		new_state.squares_completed = squares_completed + resolve_result.squares_created

		return new_state

	## Check if this swap would create at least one square (BEFORE cascades)
	## This validates the swap is legal per game rules
	func would_swap_create_square(from: Vector2i, to: Vector2i) -> bool:
		# Create temporary copy and swap
		var temp_grid := BoardRules._copy_grid(grid)
		BoardRules.swap_cells(temp_grid, from, to)

		# Check if any squares exist immediately after swap
		var squares := BoardRules.find_squares(temp_grid)
		return squares.size() > 0

	## Get hash for state deduplication
	## Hash based on color + height layout
	func get_hash() -> int:
		var hash_value := 0
		for y in range(height):
			for x in range(width):
				var cell: Dictionary = grid[y][x]
				var cell_hash: int = cell["color"] * 100 + cell["height"]
				hash_value = (hash_value * 31 + cell_hash) % 1000000007
		return hash_value

## Result structure for detailed solve info
class SolveResult:
	var solvable: bool = false
	var solution_length: int = -1
	var solution_path: Array[Dictionary] = []
	var states_explored: int = 0
	var valid_swaps_found: int = 0     # How many valid swaps were explored
	var has_trivial_solution: bool = false  # True if 1-move solution exists
	var trivial_move_count: int = 0         # Shortest solution found
	var total_squares: int = 0              # Total squares created in solution

## Check if a board can be solved within max_moves
## Returns true if a solution exists, false otherwise
static func can_solve(start_grid: Array, max_moves: int, rules: BoardRules.Rules = null) -> bool:
	var result := solve_detailed(start_grid, max_moves, rules)
	return result.solvable

## Detailed solve with full diagnostics
## Returns SolveResult with solution path and stats
## Uses BoardRules.resolve() for cascade simulation
## CRITICAL: Only explores swaps that create at least one 2×2 square
static func solve_detailed(
	start_grid: Array,
	max_moves: int,
	rules: BoardRules.Rules = null,
	seed_value: int = 0,
	max_states: int = 10000,
	goal_squares: int = 1  # Win condition: how many squares needed
) -> SolveResult:
	var result := SolveResult.new()

	# Create default rules if not provided
	if rules == null:
		rules = BoardRules.Rules.new()
		rules.lock_on_match = false
		rules.clear_locked_squares = false
		rules.enable_gravity = false
		rules.refill_from_top = false
		rules.num_colors = 3

	# Create seeded RNG for deterministic results
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	# Create initial state
	var start_state := BoardState.from_simple_grid(start_grid)

	# Early exit: already has a match (0-move solution)
	var initial_squares := BoardRules.find_squares(start_state.grid)
	if not initial_squares.is_empty():
		result.solvable = true
		result.solution_length = 0
		result.has_trivial_solution = true
		result.trivial_move_count = 0
		return result

	# BFS setup with hash-based deduplication
	var queue: Array[BoardState] = [start_state]
	var visited: Dictionary = {}  # Hash -> true
	visited[start_state.get_hash()] = true

	var solution_state: BoardState = null

	# BFS search - guarantees shortest path
	# ONLY explores valid swaps (must create squares)
	while queue.size() > 0 and result.states_explored < max_states:
		var current: BoardState = queue.pop_front()
		result.states_explored += 1

		# Depth limit reached
		if current.move_count >= max_moves:
			continue

		# Try all possible swaps (right and down only to avoid duplicates)
		for y in range(current.height):
			for x in range(current.width):
				# Try swapping right
				if x + 1 < current.width:
					var from := Vector2i(x, y)
					var to := Vector2i(x + 1, y)

					# ✅ CRITICAL: Only explore if swap creates a square
					if current.would_swap_create_square(from, to):
						result.valid_swaps_found += 1

						# Apply swap and resolve cascades
						var next_state := current.apply_swap_and_resolve(from, to, rules, rng)
						var state_hash := next_state.get_hash()

						if not visited.has(state_hash):
							visited[state_hash] = true

							# Check if we've reached the goal
							if next_state.squares_completed >= goal_squares:
								if solution_state == null or next_state.move_count < solution_state.move_count:
									solution_state = next_state

								# Check for trivial solution
								if next_state.move_count <= 1:
									result.has_trivial_solution = true
									result.trivial_move_count = next_state.move_count

							# Add to queue for further exploration
							queue.append(next_state)

				# Try swapping down
				if y + 1 < current.height:
					var from := Vector2i(x, y)
					var to := Vector2i(x, y + 1)

					# ✅ CRITICAL: Only explore if swap creates a square
					if current.would_swap_create_square(from, to):
						result.valid_swaps_found += 1

						# Apply swap and resolve cascades
						var next_state := current.apply_swap_and_resolve(from, to, rules, rng)
						var state_hash := next_state.get_hash()

						if not visited.has(state_hash):
							visited[state_hash] = true

							# Check if we've reached the goal
							if next_state.squares_completed >= goal_squares:
								if solution_state == null or next_state.move_count < solution_state.move_count:
									solution_state = next_state

								# Check for trivial solution
								if next_state.move_count <= 1:
									result.has_trivial_solution = true
									result.trivial_move_count = next_state.move_count

							# Add to queue for further exploration
							queue.append(next_state)

	# OPTIMIZATION: Early exit if we hit max_states limit
	if result.states_explored >= max_states and solution_state == null:
		result.solvable = false
		return result

	# No solution found
	if solution_state == null:
		result.solvable = false
		return result

	# Reconstruct path
	result.solvable = true
	result.solution_length = solution_state.move_count
	result.solution_path = _reconstruct_path(solution_state)
	result.total_squares = solution_state.squares_completed

	return result

## Reconstruct move path from solution state
static func _reconstruct_path(end_state: BoardState) -> Array[Dictionary]:
	var path: Array[Dictionary] = []
	var current := end_state

	while current != null and current.last_move.size() > 0:
		path.push_front(current.last_move)
		current = current.parent

	return path

## Find a solution path (returns array of moves, or empty if none found)
## Uses solve_detailed internally
static func find_solution(start_grid: Array, max_moves: int, rules: BoardRules.Rules = null) -> Array[Dictionary]:
	var result := solve_detailed(start_grid, max_moves, rules)
	return result.solution_path

## Quick validation: check if a level's solution actually works
static func validate_solution(start_grid: Array, moves: Array[Dictionary], rules: BoardRules.Rules = null) -> bool:
	if rules == null:
		rules = BoardRules.Rules.new()

	var rng := RandomNumberGenerator.new()
	rng.seed = 0

	var state := BoardState.from_simple_grid(start_grid)

	# Apply each move
	for move in moves:
		var from: Vector2i = move["from"]
		var to: Vector2i = move["to"]

		# Check if move is valid
		if not state.would_swap_create_square(from, to):
			return false

		state = state.apply_swap_and_resolve(from, to, rules, rng)

	# Check if final state has created squares
	return state.squares_completed > 0

## Validate a level is well-designed:
## 1. Solvable within move_limit
## 2. No trivial 1-move solutions (unless intended)
## 3. Starting state has no matches
## 4. At least min_initial_moves valid moves available at start
## Returns a dictionary with validation results
static func validate_level(
	start_grid: Array,
	move_limit: int,
	rules: BoardRules.Rules = null,
	min_solution_depth: int = 1,
	min_initial_moves: int = 2,
	goal_squares: int = 1
) -> Dictionary:
	var validation := {
		"valid": true,
		"solvable": false,
		"has_starting_match": false,
		"has_trivial_solution": false,
		"shortest_solution": -1,
		"states_explored": 0,
		"initial_valid_moves": 0,
		"is_forced_solution": false,
		"errors": []
	}

	if rules == null:
		rules = BoardRules.Rules.new()

	var state := BoardState.from_simple_grid(start_grid)

	# Check for starting matches
	var starting_squares := BoardRules.find_squares(state.grid)
	if not starting_squares.is_empty():
		validation["has_starting_match"] = true
		validation["valid"] = false
		validation["errors"].append("Starting grid already has %d square(s)" % starting_squares.size())
		return validation

	# Count initial valid moves
	var initial_moves := _count_valid_moves(state)
	validation["initial_valid_moves"] = initial_moves

	if initial_moves == 0:
		validation["valid"] = false
		validation["errors"].append("No valid moves available (dead board)")
		return validation

	if initial_moves == 1:
		validation["is_forced_solution"] = true
		if min_initial_moves > 1:
			validation["valid"] = false
			validation["errors"].append("Only 1 valid move (forced solution)")

	if initial_moves < min_initial_moves:
		validation["valid"] = false
		validation["errors"].append("Only %d valid moves (minimum: %d)" % [initial_moves, min_initial_moves])

	# Run detailed solve
	var result := solve_detailed(start_grid, move_limit, rules, 0, 10000, goal_squares)
	validation["solvable"] = result.solvable
	validation["states_explored"] = result.states_explored

	if not result.solvable:
		validation["valid"] = false
		validation["errors"].append("Puzzle is unsolvable within %d moves" % move_limit)
		return validation

	validation["shortest_solution"] = result.solution_length

	# Check for trivial solutions
	if result.solution_length < min_solution_depth:
		validation["has_trivial_solution"] = true
		validation["valid"] = false
		validation["errors"].append("Solution too short: %d moves (min: %d)" % [result.solution_length, min_solution_depth])

	return validation

## Count how many valid swaps exist in a board state
static func _count_valid_moves(state: BoardState) -> int:
	var count := 0

	# Try all possible swaps
	for y in range(state.height):
		for x in range(state.width):
			# Try swapping right
			if x + 1 < state.width:
				if state.would_swap_create_square(Vector2i(x, y), Vector2i(x + 1, y)):
					count += 1

			# Try swapping down
			if y + 1 < state.height:
				if state.would_swap_create_square(Vector2i(x, y), Vector2i(x, y + 1)):
					count += 1

	return count

## Legacy support functions (for backwards compatibility with old API)

## Generate a validated puzzle using reverse-solve + noise
static func generate_validated_puzzle(
	_goal_grid: Array,
	_spine_moves: Array[Dictionary],
	_num_colors: int = 3,
	_max_attempts: int = 10
) -> Array:
	# This function is deprecated - use LevelGenerator instead
	push_warning("Solver.generate_validated_puzzle() is deprecated - use LevelGenerator instead")
	return []

## Get cells critical to solution
static func _get_critical_cells(moves: Array[Dictionary], _goal_grid: Array) -> Dictionary:
	var critical := {}

	for move in moves:
		critical[move["from"]] = true
		critical[move["to"]] = true

	return critical

## Deep copy grid (static version)
static func _copy_grid_static(grid: Array) -> Array:
	return BoardRules._copy_grid(grid)

## Swap cells (static version)
static func _swap_cells_static(grid: Array, a: Vector2i, b: Vector2i) -> void:
	BoardRules.swap_cells(grid, a, b)
