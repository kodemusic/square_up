extends Node

## Puzzle solver and level validator using breadth-first search
## Key features:
## - BFS/DFS with depth limit (moves_limit) and hash-based deduplication
## - Finds shortest solution path
## - Validates no trivial (1-move) alternate solutions exist
## - Checks puzzle is solvable within move limit

class_name Solver

## Simple board state representation for BFS
## Uses a flat array for speed: grid[y * width + x]
class BoardState:
	var grid: PackedInt32Array
	var width: int
	var height: int
	var move_count: int = 0
	var last_move: Dictionary = {}  # {from: Vector2i, to: Vector2i}
	var parent: BoardState = null   # For path reconstruction

	## Create from 2D array
	static func from_2d_array(grid_2d: Array) -> BoardState:
		var state := BoardState.new()
		state.height = grid_2d.size()
		
		# Validate grid is not empty
		if state.height == 0 or grid_2d[0].size() == 0:
			push_error("Cannot create BoardState from empty grid")
			return state
		
		state.width = grid_2d[0].size()
		state.grid = PackedInt32Array()

		for y in range(state.height):
			for x in range(state.width):
				state.grid.append(grid_2d[y][x])

		return state
	
	## Convert back to 2D array
	func to_2d_array() -> Array:
		var grid_2d: Array = []
		for y in range(height):
			var row: Array = []
			for x in range(width):
				row.append(get_color(x, y))
			grid_2d.append(row)
		return grid_2d

	## Get color at position
	func get_color(x: int, y: int) -> int:
		return grid[y * width + x]

	## Set color at position
	func set_color(x: int, y: int, color: int) -> void:
		grid[y * width + x] = color

	## Create a copy of this state with a swap applied
	func apply_swap(from: Vector2i, to: Vector2i) -> BoardState:
		var new_state := BoardState.new()
		new_state.width = width
		new_state.height = height
		new_state.grid = grid.duplicate()
		new_state.move_count = move_count + 1
		new_state.last_move = {"from": from, "to": to}
		new_state.parent = self

		# Perform the swap
		var temp := new_state.get_color(from.x, from.y)
		new_state.set_color(from.x, from.y, new_state.get_color(to.x, to.y))
		new_state.set_color(to.x, to.y, temp)

		return new_state

	## Check if this state has any 2x2 matches
	func has_any_match() -> bool:
		for y in range(height - 1):
			for x in range(width - 1):
				var c0 := get_color(x, y)
				if c0 < 0:  # Skip empty cells
					continue
				if (get_color(x + 1, y) == c0 and
					get_color(x, y + 1) == c0 and
					get_color(x + 1, y + 1) == c0):
					return true
		return false
	
	## Count how many 2x2 matches exist
	func count_matches() -> int:
		var count := 0
		for y in range(height - 1):
			for x in range(width - 1):
				var c0 := get_color(x, y)
				if c0 < 0:
					continue
				if (get_color(x + 1, y) == c0 and
					get_color(x, y + 1) == c0 and
					get_color(x + 1, y + 1) == c0):
					count += 1
		return count

	## Get hash for state deduplication (simple but effective)
	func get_hash() -> int:
		var hash_value := 0
		for i in range(grid.size()):
			hash_value = (hash_value * 31 + grid[i]) % 1000000007
		return hash_value

## Result structure for detailed solve info
class SolveResult:
	var solvable: bool = false
	var solution_length: int = -1
	var solution_path: Array[Dictionary] = []
	var states_explored: int = 0
	var has_trivial_solution: bool = false  # True if 1-move solution exists
	var trivial_move_count: int = 0         # Shortest solution found

## Check if a board can be solved within max_moves
## Returns true if a solution exists, false otherwise
static func can_solve(start_grid: Array, max_moves: int) -> bool:
	var result := solve_detailed(start_grid, max_moves)
	return result.solvable

## Detailed solve with full diagnostics
## Returns SolveResult with solution path and stats
static func solve_detailed(start_grid: Array, max_moves: int, max_states: int = 10000) -> SolveResult:
	var result := SolveResult.new()
	var start_state := BoardState.from_2d_array(start_grid)

	# Early exit: already has a match (0-move solution)
	if start_state.has_any_match():
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
	# OPTIMIZATION: Add max_states limit to prevent explosion
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
					var next_state := current.apply_swap(from, to)
					var state_hash := next_state.get_hash()

					if not visited.has(state_hash):
						visited[state_hash] = true

						# Check if we found a match
						if next_state.has_any_match():
							if solution_state == null:
								solution_state = next_state
							# Check for trivial solution
							if next_state.move_count <= 1:
								result.has_trivial_solution = true
								result.trivial_move_count = next_state.move_count
							# Don't break - continue to find all solutions for trivial check
							if solution_state.move_count <= 1:
								continue
							break
						
						queue.append(next_state)

				# Try swapping down
				if y + 1 < current.height:
					var from := Vector2i(x, y)
					var to := Vector2i(x, y + 1)
					var next_state := current.apply_swap(from, to)
					var state_hash := next_state.get_hash()

					if not visited.has(state_hash):
						visited[state_hash] = true

						# Check if we found a match
						if next_state.has_any_match():
							if solution_state == null:
								solution_state = next_state
							# Check for trivial solution
							if next_state.move_count <= 1:
								result.has_trivial_solution = true
								result.trivial_move_count = next_state.move_count
							if solution_state.move_count <= 1:
								continue
							break
						
						queue.append(next_state)

			if solution_state != null and solution_state.move_count > 1:
				break

		if solution_state != null and solution_state.move_count > 1:
			break

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
static func find_solution(start_grid: Array, max_moves: int) -> Array[Dictionary]:
	var result := solve_detailed(start_grid, max_moves)
	return result.solution_path

## Quick validation: check if a level's solution actually works
static func validate_solution(start_grid: Array, moves: Array[Dictionary]) -> bool:
	var state := BoardState.from_2d_array(start_grid)

	# Apply each move
	for move in moves:
		var from: Vector2i = move["from"]
		var to: Vector2i = move["to"]
		state = state.apply_swap(from, to)

	# Check if final state has a match
	return state.has_any_match()

## Validate a level is well-designed:
## 1. Solvable within move_limit
## 2. No trivial 1-move solutions (unless intended)
## 3. Starting state has no matches
## Returns a dictionary with validation results
static func validate_level(start_grid: Array, move_limit: int, min_solution_depth: int = 2) -> Dictionary:
	var validation := {
		"valid": true,
		"solvable": false,
		"has_starting_match": false,
		"has_trivial_solution": false,
		"shortest_solution": -1,
		"states_explored": 0,
		"errors": []
	}
	
	var state := BoardState.from_2d_array(start_grid)
	
	# Check for starting matches
	if state.has_any_match():
		validation["has_starting_match"] = true
		validation["valid"] = false
		validation["errors"].append("Starting grid already has a match")
		return validation
	
	# Run detailed solve
	var result := solve_detailed(start_grid, move_limit)
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

## Generate a validated puzzle using reverse-solve + noise
## goal_grid: The solved state with 2x2 match
## spine_moves: Core solution moves (in forward order)
## num_colors: Number of colors for noise tiles
## Returns: A validated starting grid, or empty array if generation failed
static func generate_validated_puzzle(
	goal_grid: Array, 
	spine_moves: Array[Dictionary],
	num_colors: int = 3,
	max_attempts: int = 10
) -> Array:
	var height := goal_grid.size()
	
	# Validate goal_grid is not empty
	if height == 0 or goal_grid[0].size() == 0:
		push_error("Cannot generate puzzle from empty goal_grid")
		return []
	
	var width: int = goal_grid[0].size()
	
	for attempt in range(max_attempts):
		# Step 1: Apply spine moves in reverse to get base starting state
		var working_grid := _copy_grid_static(goal_grid)
		for i in range(spine_moves.size() - 1, -1, -1):
			var move: Dictionary = spine_moves[i]
			var from: Vector2i = move["from"]
			var to: Vector2i = move["to"]
			_swap_cells_static(working_grid, from, to)
		
		# Step 2: Add noise to non-critical cells (cells not involved in solution)
		var critical_cells := _get_critical_cells(spine_moves, goal_grid)
		for y in range(height):
			for x in range(width):
				var pos := Vector2i(x, y)
				if not critical_cells.has(pos):
					# Try random colors that don't create matches
					for _try in range(10):
						var new_color := randi() % num_colors
						var old_color: int = working_grid[y][x]
						working_grid[y][x] = new_color
						
						# Check if this creates a match
						var state := BoardState.from_2d_array(working_grid)
						if state.has_any_match():
							working_grid[y][x] = old_color  # Revert
						else:
							break  # Keep new color
		
		# Step 3: Validate the puzzle
		var validation := validate_level(working_grid, spine_moves.size() + 2, spine_moves.size())
		
		if validation["valid"]:
			print("Generated valid puzzle on attempt %d" % (attempt + 1))
			return working_grid
		else:
			print("Attempt %d failed: %s" % [attempt + 1, validation["errors"]])
	
	print("Failed to generate valid puzzle after %d attempts" % max_attempts)
	return []

## Get cells that are critical to the solution (involved in spine moves or goal match)
static func _get_critical_cells(moves: Array[Dictionary], goal_grid: Array) -> Dictionary:
	var critical := {}  # Vector2i -> true
	
	# Add all cells involved in moves
	for move in moves:
		critical[move["from"]] = true
		critical[move["to"]] = true
	
	# Add cells in the goal match (find 2x2 matches in goal)
	var height := goal_grid.size()
	if height == 0 or goal_grid[0].size() == 0:
		return critical
	
	var width: int = goal_grid[0].size()
	for y in range(height - 1):
		for x in range(width - 1):
			var c0: int = goal_grid[y][x]
			if c0 >= 0 and goal_grid[y][x + 1] == c0 and goal_grid[y + 1][x] == c0 and goal_grid[y + 1][x + 1] == c0:
				critical[Vector2i(x, y)] = true
				critical[Vector2i(x + 1, y)] = true
				critical[Vector2i(x, y + 1)] = true
				critical[Vector2i(x + 1, y + 1)] = true
	
	return critical

## Helper: Deep copy a 2D grid (static version)
static func _copy_grid_static(grid: Array) -> Array:
	var copy: Array = []
	for y in range(grid.size()):
		var row: Array = []
		for x in range(grid[y].size()):
			row.append(grid[y][x])
		copy.append(row)
	return copy

## Helper: Swap two cells in a grid (static version)
static func _swap_cells_static(grid: Array, a: Vector2i, b: Vector2i) -> void:
	var temp: int = grid[a.y][a.x]
	grid[a.y][a.x] = grid[b.y][b.x]
	grid[b.y][b.x] = temp

