extends Node

## Level definition for puzzle levels
## Supports reverse-solving: define goal state + solution, generate start state
class_name LevelData

## Level metadata
var level_id: int = 0
var level_name: String = ""
var move_limit: int = 0  # 0 = unlimited
var target_score: int = 0
var squares_goal: int = 0  # Number of 2x2 squares needed to win

## Board configuration
var width: int = 4
var height: int = 4
var starting_grid: Array[Array] = []  # [y][x] -> color_id

## Solution data (optional, for reverse-solving)
var solution_moves: Array[Dictionary] = []  # [{from: Vector2i, to: Vector2i}]

## Gameplay mechanics configuration
var lock_on_match: bool = true       # Lock matched squares?
var clear_locked_squares: bool = false  # Remove locked squares from board?
var enable_gravity: bool = false     # Tiles drop down into gaps?
var refill_from_top: bool = false    # Spawn new tiles at top?

## Create a simple level from a goal state by reverse-solving
## goal_grid: 2D array of color IDs representing the solved state
## moves: Array of swap dictionaries in forward order: [{from: Vector2i, to: Vector2i}]
static func create_reverse_solved(goal_grid: Array[Array], moves: Array[Dictionary]) -> LevelData:
	var level := LevelData.new()
	level.width = goal_grid[0].size()
	level.height = goal_grid.size()
	level.solution_moves = moves.duplicate()

	# Copy goal state to working grid
	var working_grid: Array[Array] = _copy_grid(goal_grid)

	# Apply moves in reverse order to get starting state
	for i in range(moves.size() - 1, -1, -1):
		var move: Dictionary = moves[i]
		var from: Vector2i = move["from"]
		var to: Vector2i = move["to"]
		# Swap is its own inverse
		_swap_cells(working_grid, from, to)

	level.starting_grid = working_grid
	return level

## Helper: Deep copy a 2D grid
static func _copy_grid(grid: Array[Array]) -> Array[Array]:
	var copy: Array[Array] = []
	for y in range(grid.size()):
		var row: Array = []
		for x in range(grid[y].size()):
			row.append(grid[y][x])
		copy.append(row)
	return copy

## Helper: Swap two cells in a grid
static func _swap_cells(grid: Array[Array], a: Vector2i, b: Vector2i) -> void:
	var temp: int = grid[a.y][a.x]
	grid[a.y][a.x] = grid[b.y][b.x]
	grid[b.y][b.x] = temp

## Generate a random grid with no 2x2 matches
## Uses backtracking to ensure no color creates a square when placed
static func generate_grid_no_squares(rows: int, cols: int, num_colors: int) -> Array[Array]:
	var grid: Array[Array] = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			var tries := 0
			var color_id := randi() % num_colors

			# Keep trying random colors until we find one that doesn't create a square
			while _creates_square(grid, row, r, c, color_id) and tries < 20:
				color_id = randi() % num_colors
				tries += 1

			# Failsafe: if too constrained, find any non-square color
			if tries >= 20:
				color_id = _pick_non_square_color(grid, row, r, c, num_colors)

			row.append(color_id)
		grid.append(row)
	return grid

## Check if placing a color at position (r, c) would create a 2x2 square
## Only checks the top-left square where (r, c) would be bottom-right corner
## grid: completed rows, current_row: row being built, r/c: position
static func _creates_square(grid: Array[Array], current_row: Array, r: int, c: int, color_id: int) -> bool:
	# Can't form a square if we're in the first row or column
	if r == 0 or c == 0:
		return false

	# Need to check the previous row (which is in grid) and current row
	# The square pattern is:
	#   [r-1][c-1]  [r-1][c]   <- previous row (in grid)
	#   [r][c-1]    [r][c]     <- current row (being built)

	var top_left: int = grid[r - 1][c - 1]
	var top_right: int = grid[r - 1][c]
	var bottom_left: int = current_row[c - 1]

	return (top_left == color_id and top_right == color_id and bottom_left == color_id)

## Find a color that doesn't create a square at position (r, c)
## Returns the first valid color found, or 0 as fallback
static func _pick_non_square_color(grid: Array[Array], current_row: Array, r: int, c: int, num_colors: int) -> int:
	for color_id in range(num_colors):
		if not _creates_square(grid, current_row, r, c, color_id):
			return color_id
	return 0  # Fallback (should be rare if num_colors >= 3)

## Print the grid for debugging/visualization
func print_grid(grid: Array[Array]) -> void:
	print("Grid %dx%d:" % [width, height])
	for y in range(grid.size()):
		var row_str := ""
		for x in range(grid[y].size()):
			var color_id: int = grid[y][x]
			if color_id < 0:
				row_str += ". "
			else:
				row_str += str(color_id) + " "
		print(row_str)

## Example: Create a simple 2-move puzzle
static func create_example_level() -> LevelData:
	# Define goal state: 2x2 match of color 0 in top-left
	var goal_grid: Array[Array] = [
		[0, 0, 1, 2],  # Row 0: Red, Red, Blue, Green
		[0, 0, 2, 1],  # Row 1: Red, Red, Green, Blue
		[1, 2, 1, 2],  # Row 2: Blue, Green, Blue, Green
		[2, 1, 2, 1],  # Row 3: Green, Blue, Green, Blue
	]

	# Define solution moves (forward order)
	var solution: Array[Dictionary] = [
		{"from": Vector2i(0, 0), "to": Vector2i(1, 0)},  # Move 1: swap top-left horizontally
		{"from": Vector2i(0, 1), "to": Vector2i(0, 0)},  # Move 2: swap vertically to complete match
	]

	var level := create_reverse_solved(goal_grid, solution)
	level.level_id = 1
	level.level_name = "Tutorial"
	level.move_limit = 2
	level.target_score = 10

	return level

## Level 1: First teaching level - 4x4 with 2 colors
## Random grid with no starting matches - player must find valid swaps
## Tutorial level: no locking, just learn matching mechanics
static func create_level_1() -> LevelData:
	var level := LevelData.new()
	level.level_id = 1
	level.level_name = "First Match"
	level.width = 4
	level.height = 4
	level.move_limit = 10  # 10 moves to complete
	level.target_score = 20  # 2 squares × 10 points
	level.squares_goal = 1  # Need to complete 1 square

	# Generate a validated random 4x4 grid with 2 colors
	level.starting_grid = _generate_validated_grid(4, 4, 2, level.move_limit, 1)

	# Tutorial mode: no locking, no clearing, no gravity, no refill
	level.lock_on_match = false
	level.clear_locked_squares = false
	level.enable_gravity = false
	level.refill_from_top = false

	return level

## Level 2: Random puzzle with 3 colors
## More complex than Level 1 with additional color
static func create_level_2() -> LevelData:
	var level := LevelData.new()
	level.level_id = 2
	level.level_name = "Three Colors"
	level.width = 4
	level.height = 4
	level.move_limit = 8  # 8 moves for more challenge
	level.target_score = 20  # Need 2 matches (2 squares × 10 points each)
	level.squares_goal = 2  # Need 2 squares

	# Generate a validated random 4x4 grid with 3 colors
	level.starting_grid = _generate_validated_grid(4, 4, 3, level.move_limit, 2)
	
	level.lock_on_match = true  # Lock matches this time
	level.clear_locked_squares = false
	level.enable_gravity = false
	level.refill_from_top = false
	return level

## Generate a grid that is validated to be solvable with no trivial solutions
## rows, cols: grid dimensions
## num_colors: number of tile colors
## max_moves: maximum moves allowed
## min_solution_depth: minimum moves required for solution (prevents trivial puzzles)
static func _generate_validated_grid(rows: int, cols: int, num_colors: int, max_moves: int, min_solution_depth: int = 2) -> Array[Array]:
	var max_attempts := 50
	
	for attempt in range(max_attempts):
		# Generate a random grid with no 2x2 matches
		var grid := generate_grid_no_squares(rows, cols, num_colors)
		
		# Validate using solver
		var validation := Solver.validate_level(grid, max_moves, min_solution_depth)
		
		if validation["valid"]:
			print("Level generated on attempt %d (solution depth: %d, states explored: %d)" % [
				attempt + 1, 
				validation["shortest_solution"],
				validation["states_explored"]
			])
			return grid
		else:
			if attempt % 10 == 9:
				print("Attempt %d failed: %s" % [attempt + 1, validation["errors"]])
	
	# Fallback: return any solvable grid even if trivial
	print("Warning: Could not generate optimal puzzle, using fallback")
	for _fallback in range(20):
		var grid := generate_grid_no_squares(rows, cols, num_colors)
		if Solver.can_solve(grid, max_moves):
			return grid
	
	# Ultimate fallback
	return generate_grid_no_squares(rows, cols, num_colors)

## Endless Mode: Infinite gameplay with cascading matches
## Matches lock → clear → drop → refill → cascade
static func create_level_endless() -> LevelData:
	var level := LevelData.new()
	level.level_id = 999
	level.level_name = "Endless Mode"
	level.width = 4
	level.height = 4
	level.move_limit = 0  # Unlimited moves
	level.target_score = 0  # No target, play forever
	level.squares_goal = 999999  # Effectively infinite

	# Generate a random 4x4 grid with 3 colors and no 2x2 matches
	level.starting_grid = generate_grid_no_squares(4, 4, 3)

	# Full cascade mode: lock → clear → gravity → refill → cascade
	level.lock_on_match = true
	level.clear_locked_squares = true
	level.enable_gravity = true
	level.refill_from_top = true

	return level
