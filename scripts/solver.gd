extends Node

## Lightweight puzzle solver using breadth-first search
## Checks if a board state can reach a valid match within N moves
## Not optimal - just needs to find *a* solution, not the best one

class_name Solver

## Simple board state representation for BFS
## Uses a flat array for speed: grid[y * width + x]
class BoardState:
	var grid: PackedInt32Array
	var width: int
	var height: int
	var move_count: int = 0
	var last_move: Dictionary = {}  # {from: Vector2i, to: Vector2i}

	## Create from 2D array
	static func from_2d_array(grid_2d: Array[Array]) -> BoardState:
		var state := BoardState.new()
		state.height = grid_2d.size()
		state.width = grid_2d[0].size()
		state.grid = PackedInt32Array()

		for y in range(state.height):
			for x in range(state.width):
				state.grid.append(grid_2d[y][x])

		return state

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

	## Get hash for state deduplication (simple but effective)
	func get_hash() -> int:
		var hash_value := 0
		for i in range(grid.size()):
			hash_value = (hash_value * 31 + grid[i]) % 1000000007
		return hash_value

## Check if a board can be solved within max_moves
## Returns true if a solution exists, false otherwise
static func can_solve(start_grid: Array[Array], max_moves: int) -> bool:
	var start_state := BoardState.from_2d_array(start_grid)

	# Early exit: already has a match
	if start_state.has_any_match():
		return true

	# BFS setup
	var queue: Array[BoardState] = [start_state]
	var visited: Dictionary = {}  # Hash -> bool
	visited[start_state.get_hash()] = true

	# BFS search
	while queue.size() > 0:
		var current: BoardState = queue.pop_front()

		# Depth limit reached
		if current.move_count >= max_moves:
			continue

		# Try all possible swaps
		for y in range(current.height):
			for x in range(current.width):
				# Try swapping right
				if x + 1 < current.width:
					var from := Vector2i(x, y)
					var to := Vector2i(x + 1, y)
					var next_state := current.apply_swap(from, to)

					# Check if we found a match
					if next_state.has_any_match():
						return true

					# Add to queue if not visited
					var state_hash := next_state.get_hash()
					if not visited.has(state_hash):
						visited[state_hash] = true
						queue.append(next_state)

				# Try swapping down
				if y + 1 < current.height:
					var from := Vector2i(x, y)
					var to := Vector2i(x, y + 1)
					var next_state := current.apply_swap(from, to)

					# Check if we found a match
					if next_state.has_any_match():
						return true

					# Add to queue if not visited
					var state_hash := next_state.get_hash()
					if not visited.has(state_hash):
						visited[state_hash] = true
						queue.append(next_state)

	# No solution found within max_moves
	return false

## Find a solution path (returns array of moves, or empty if none found)
## More expensive than can_solve since it tracks the full path
static func find_solution(start_grid: Array[Array], max_moves: int) -> Array[Dictionary]:
	var start_state := BoardState.from_2d_array(start_grid)

	# Early exit: already has a match
	if start_state.has_any_match():
		return []

	# BFS setup with parent tracking
	var queue: Array[BoardState] = [start_state]
	var visited: Dictionary = {}  # Hash -> BoardState (parent)
	visited[start_state.get_hash()] = null

	var solution_state: BoardState = null

	# BFS search
	while queue.size() > 0:
		var current: BoardState = queue.pop_front()

		# Depth limit reached
		if current.move_count >= max_moves:
			continue

		# Try all possible swaps
		for y in range(current.height):
			for x in range(current.width):
				# Try swapping right
				if x + 1 < current.width:
					var from := Vector2i(x, y)
					var to := Vector2i(x + 1, y)
					var next_state := current.apply_swap(from, to)

					var state_hash := next_state.get_hash()
					if not visited.has(state_hash):
						visited[state_hash] = current

						# Check if we found a match
						if next_state.has_any_match():
							solution_state = next_state
							break

						queue.append(next_state)

				# Try swapping down
				if y + 1 < current.height:
					var from := Vector2i(x, y)
					var to := Vector2i(x, y + 1)
					var next_state := current.apply_swap(from, to)

					var state_hash := next_state.get_hash()
					if not visited.has(state_hash):
						visited[state_hash] = current

						# Check if we found a match
						if next_state.has_any_match():
							solution_state = next_state
							break

						queue.append(next_state)

			if solution_state != null:
				break

		if solution_state != null:
			break

	# No solution found
	if solution_state == null:
		return []

	# Reconstruct path by following parent chain
	var path: Array[Dictionary] = []
	var path_current := solution_state

	while path_current != null and path_current.last_move.size() > 0:
		path.push_front(path_current.last_move)
		var parent_hash := 0
		# Find parent by checking visited dictionary
		for state_hash in visited:
			if visited[state_hash] != null and visited[state_hash].get_hash() == path_current.get_hash():
				parent_hash = state_hash
				break
		path_current = visited.get(parent_hash)

	return path

## Quick validation: check if a level's solution actually works
static func validate_solution(start_grid: Array[Array], moves: Array[Dictionary]) -> bool:
	var state := BoardState.from_2d_array(start_grid)

	# Apply each move
	for move in moves:
		var from: Vector2i = move["from"]
		var to: Vector2i = move["to"]
		state = state.apply_swap(from, to)

	# Check if final state has a match
	return state.has_any_match()
