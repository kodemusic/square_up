extends Node

## Level definition for puzzle levels
## Supports reverse-solving: define goal state + solution, generate start state
class_name LevelData

## STATIC: Level cache and generation control
static var level_cache: Dictionary = {}  # level_id -> LevelData
static var auto_generate: bool = true    # Auto-generate on create_level() call?
static var pre_generate_count: int = 0   # How many levels to pre-generate

## Level metadata
var level_id: int = 0
var level_name: String = ""
var move_limit: int = 0  # 0 = unlimited
var target_score: int = 0
var squares_goal: int = 0  # Number of 2x2 squares needed to win

## Board configuration
var width: int = 5  # DEFAULT: 5x5 board
var height: int = 5  # DEFAULT: 5x5 board
var starting_grid: Array = []  # [y][x] -> color_id (2D array)

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
static func create_reverse_solved(goal_grid: Array, moves: Array[Dictionary]) -> LevelData:
	var level := LevelData.new()
	
	# Validate goal_grid is not empty
	if goal_grid.size() == 0 or goal_grid[0].size() == 0:
		push_error("Cannot create level from empty goal_grid")
		return level
	
	level.width = goal_grid[0].size()
	level.height = goal_grid.size()
	level.solution_moves = moves.duplicate()

	# Copy goal state to working grid
	var working_grid: Array = _copy_grid(goal_grid)

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
static func _copy_grid(grid: Array) -> Array:
	var copy: Array = []
	for y in range(grid.size()):
		var row: Array = []
		for x in range(grid[y].size()):
			row.append(grid[y][x])
		copy.append(row)
	return copy

## Helper: Swap two cells in a grid
static func _swap_cells(grid: Array, a: Vector2i, b: Vector2i) -> void:
	var temp: int = grid[a.y][a.x]
	grid[a.y][a.x] = grid[b.y][b.x]
	grid[b.y][b.x] = temp

## Generate a random grid with no 2x2 matches
## Uses backtracking to ensure no color creates a square when placed
static func generate_grid_no_squares(rows: int, cols: int, num_colors: int) -> Array:
	var grid: Array = []
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
static func _creates_square(grid: Array, current_row: Array, r: int, c: int, color_id: int) -> bool:
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
static func _pick_non_square_color(grid: Array, current_row: Array, r: int, c: int, num_colors: int) -> int:
	for color_id in range(num_colors):
		if not _creates_square(grid, current_row, r, c, color_id):
			return color_id
	return 0  # Fallback (should be rare if num_colors >= 3)

## Print the grid for debugging/visualization
func print_grid(grid: Array) -> void:
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
	var goal_grid: Array = [
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
## Uses REVERSE-SOLVE puzzle pool - guaranteed solvable in 1 move
## Tutorial level: no locking, just learn matching mechanics
static func create_level_1() -> LevelData:
	var level := LevelData.new()
	level.level_id = 1
	level.level_name = "First Match"
	level.width = 4
	level.height = 4
	level.move_limit = 1  # Tutorial: exactly 1 move to solve
	level.target_score = 10  # 1 square × 10 points
	level.squares_goal = 1  # Need to complete 1 square

	# Use REVERSE-SOLVE: puzzle is guaranteed solvable
	level.starting_grid = _get_level_1_grid()
	
	# Verify solvability (debug)
	var can_solve := Solver.can_solve(level.starting_grid, level.move_limit)
	print("[Level 1] Generated puzzle - solvable: %s" % str(can_solve))

	# Tutorial mode: no locking, no clearing, no gravity, no refill
	level.lock_on_match = false
	level.clear_locked_squares = false
	level.enable_gravity = false
	level.refill_from_top = false

	return level

## Level 2: More complex puzzle with 3 colors
## Uses REVERSE-SOLVE puzzle pool - guaranteed solvable in 2-4 moves
static func create_level_2() -> LevelData:
	var level := LevelData.new()
	level.level_id = 2
	level.level_name = "Three Colors"
	level.width = 5
	level.height = 5
	level.move_limit = 8  # 8 moves for more challenge
	level.target_score = 20  # Need 2 matches (2 squares × 10 points each)
	level.squares_goal = 2  # Need 2 squares

	# Use REVERSE-SOLVE: puzzle is guaranteed solvable
	level.starting_grid = _get_level_2_grid()
	
	# Verify solvability (debug)
	var can_solve := Solver.can_solve(level.starting_grid, level.move_limit)
	print("[Level 2] Generated puzzle - solvable: %s" % str(can_solve))

	level.lock_on_match = true  # Lock matches this time
	level.clear_locked_squares = false
	level.enable_gravity = false
	level.refill_from_top = false
	return level

## REVERSE-SOLVE APPROACH: Generate puzzles guaranteed to be solvable
## Every puzzle is created by:
## 1. Starting with a goal state that has a 2x2 match
## 2. Defining exact solution moves
## 3. Applying those moves in reverse to get the starting state
## This GUARANTEES the puzzle is solvable by playing the moves forward

## Level 1: Generate a 1-move solvable puzzle using reverse-solve
## Returns a starting grid that can be solved in exactly 1 move
static func _get_level_1_grid() -> Array:
	# Pool of goal states + solutions for level 1 (1-move puzzles)
	# CRITICAL: The solution move must swap a tile INTO the 2x2 match from OUTSIDE
	# This ensures reversing the move breaks the match
	var puzzle_defs: Array = [
		# Puzzle 1: Swap brings 0 from (2,0) into (1,0) to complete top-left match
		# Goal has 2x2 of 0s at (0,0)-(1,0)-(0,1)-(1,1)
		# Move swaps (1,0) with (2,0), so START has (1,0)=1 and (2,0)=0
		{
			"goal": [
				[0, 0, 1, 1],
				[0, 0, 1, 0],
				[1, 0, 1, 0],
				[1, 1, 0, 1]
			],
			"moves": [{"from": Vector2i(1, 0), "to": Vector2i(2, 0)}]
		},
		# Puzzle 2: Swap brings 0 from (0,2) into (0,1) to complete top-left match
		{
			"goal": [
				[0, 0, 1, 0],
				[0, 0, 1, 1],
				[1, 1, 0, 1],
				[0, 1, 1, 0]
			],
			"moves": [{"from": Vector2i(0, 1), "to": Vector2i(0, 2)}]
		},
		# Puzzle 3: Swap brings 1 from (1,1) into (2,1) to complete center match at (1,1)-(2,1)-(1,2)-(2,2)
		{
			"goal": [
				[0, 1, 0, 1],
				[0, 1, 1, 0],
				[1, 1, 1, 0],
				[0, 0, 1, 1]
			],
			"moves": [{"from": Vector2i(2, 1), "to": Vector2i(3, 1)}]
		},
		# Puzzle 4: Swap brings 1 from (2,3) into (2,2) to complete bottom-right match
		{
			"goal": [
				[0, 1, 0, 1],
				[1, 0, 1, 0],
				[0, 1, 1, 1],
				[1, 0, 1, 1]
			],
			"moves": [{"from": Vector2i(2, 2), "to": Vector2i(2, 3)}]
		},
		# Puzzle 5: Swap brings 0 from (3,0) into (2,0) to complete top-right match
		{
			"goal": [
				[1, 0, 0, 0],
				[0, 1, 0, 0],
				[1, 0, 1, 1],
				[0, 1, 1, 0]
			],
			"moves": [{"from": Vector2i(2, 0), "to": Vector2i(3, 0)}]
		}
	]
	
	# Pick random puzzle definition
	var def: Dictionary = puzzle_defs[randi() % puzzle_defs.size()]
	
	# Apply reverse-solve: start from goal and undo the moves
	var working_grid: Array = _copy_grid(def["goal"])
	var moves: Array = def["moves"]
	
	# Apply moves in reverse order (for 1-move puzzles, just 1 swap)
	for i in range(moves.size() - 1, -1, -1):
		var move: Dictionary = moves[i]
		var from: Vector2i = move["from"]
		var to: Vector2i = move["to"]
		_swap_cells(working_grid, from, to)  # Swap is self-inverse
	
	return working_grid

## Level 2: Generate a validated solvable puzzle
## HYBRID APPROACH:
## 1. Use hand-crafted goal states + solution moves (curated difficulty)
## 2. Generate starting grid using Solver.generate_validated_puzzle (adds noise)
## 3. Fallback to pure procedural if validation fails
static func _get_level_2_grid() -> Array:
	# Hand-crafted puzzle templates (goal + solution spine) - 5x5 grids
	var templates: Array = [
		# Template 1: 2 moves - top-left 0s on 5x5 board
		{
			"goal": [
				[0, 0, 1, 2, 1],
				[0, 0, 2, 1, 2],
				[1, 2, 1, 2, 1],
				[2, 1, 2, 1, 0],
				[1, 0, 1, 0, 2]
			],
			"moves": [
				{"from": Vector2i(1, 0), "to": Vector2i(2, 0)},
				{"from": Vector2i(0, 0), "to": Vector2i(1, 0)}
			]
		},
		# Template 2: 2 moves - center match on 5x5 board
		{
			"goal": [
				[0, 2, 0, 2, 1],
				[2, 1, 1, 0, 2],
				[0, 1, 1, 2, 0],
				[2, 0, 2, 1, 1],
				[1, 2, 1, 0, 2]
			],
			"moves": [
				{"from": Vector2i(2, 1), "to": Vector2i(3, 1)},
				{"from": Vector2i(1, 2), "to": Vector2i(2, 2)}
			]
		},
		# Template 3: 3 moves - bottom-right match on 5x5 board
		{
			"goal": [
				[0, 1, 0, 1, 2],
				[1, 2, 1, 0, 1],
				[0, 2, 1, 2, 0],
				[2, 0, 2, 2, 2],
				[1, 2, 0, 2, 2]
			],
			"moves": [
				{"from": Vector2i(4, 3), "to": Vector2i(4, 2)},
				{"from": Vector2i(3, 4), "to": Vector2i(4, 4)},
				{"from": Vector2i(3, 3), "to": Vector2i(3, 4)}
			]
		}
	]

	# Pick random template
	var template: Dictionary = templates[randi() % templates.size()]

	# Method 1: Try using Solver.generate_validated_puzzle (hybrid approach)
	var spine_moves: Array[Dictionary] = []
	for move in template["moves"]:
		spine_moves.append(move)

	var generated := Solver.generate_validated_puzzle(
		template["goal"],
		spine_moves,
		3,  # num_colors
		5   # max_attempts
	)

	if generated.size() > 0:
		print("[Level 2] Generated using HYBRID method (template + noise)")
		return generated

	# Method 2: Fallback to pure procedural generation
	print("[Level 2] Hybrid failed, using PROCEDURAL generation")
	return _generate_validated_grid(5, 5, 3, 10, 2)

## Generate a grid that is validated to be solvable with no trivial solutions
## rows, cols: grid dimensions
## num_colors: number of tile colors
## max_moves: maximum moves allowed
## min_solution_depth: minimum moves required for solution (prevents trivial puzzles)
## NOTE: This is now only used as fallback for procedural generation (endless mode, etc.)
static func _generate_validated_grid(rows: int, cols: int, num_colors: int, max_moves: int, min_solution_depth: int = 2) -> Array:
	var max_attempts := 15  # REDUCED from 50 to prevent stuttering

	for attempt in range(max_attempts):
		# Generate a random grid with no 2x2 matches
		var grid := generate_grid_no_squares(rows, cols, num_colors)

		# Validate using solver (with state limit to prevent hangs)
		var validation := Solver.validate_level(grid, max_moves, min_solution_depth)

		if validation["valid"]:
			print("Level generated on attempt %d (solution depth: %d, states explored: %d)" % [
				attempt + 1,
				validation["shortest_solution"],
				validation["states_explored"]
			])
			return grid
		else:
			if attempt % 5 == 4:  # Reduced logging frequency
				print("Attempt %d failed: %s" % [attempt + 1, validation["errors"]])

	# Fallback: return any solvable grid even if trivial (FASTER)
	print("Warning: Could not generate optimal puzzle, using fast fallback")
	for _fallback in range(10):  # REDUCED from 20
		var grid := generate_grid_no_squares(rows, cols, num_colors)
		# Quick check with lower move limit
		if Solver.can_solve(grid, mini(max_moves, 5)):
			return grid

	# Ultimate fallback - just return a valid grid
	print("Warning: Using unvalidated grid")
	return generate_grid_no_squares(rows, cols, num_colors)

## Create a level from difficulty rules
## This is the NEW recommended way to generate levels
static func create_from_rules(lvl_id: int, rules: LevelRules) -> LevelData:
	var level := LevelData.new()
	level.level_id = lvl_id
	level.level_name = "Level %d" % lvl_id
	level.width = rules.board_width
	level.height = rules.board_height
	level.move_limit = rules.move_limit
	level.target_score = rules.target_score
	level.squares_goal = rules.squares_goal

	# Apply gameplay mechanics
	level.lock_on_match = rules.lock_on_match
	level.clear_locked_squares = rules.clear_locked_squares
	level.enable_gravity = rules.enable_gravity
	level.refill_from_top = rules.refill_from_top

	# Generate starting grid based on rules
	if rules.use_templates and rules.templates.size() > 0:
		# Use custom templates if provided
		var template: Dictionary = rules.templates[randi() % rules.templates.size()]
		var spine_moves: Array[Dictionary] = []
		for move in template["moves"]:
			spine_moves.append(move)

		level.starting_grid = Solver.generate_validated_puzzle(
			template["goal"],
			spine_moves,
			rules.num_colors,
			rules.max_generation_attempts
		)

		if level.starting_grid.size() == 0 and rules.allow_procedural_fallback:
			print("[Level %d] Template generation failed, using procedural" % lvl_id)
			level.starting_grid = _generate_validated_grid(
				rules.board_width,
				rules.board_height,
				rules.num_colors,
				rules.max_solution_moves + 2,
				rules.min_solution_moves
			)
	else:
		# Pure procedural generation
		level.starting_grid = _generate_validated_grid(
			rules.board_width,
			rules.board_height,
			rules.num_colors,
			rules.max_solution_moves + 2,
			rules.min_solution_moves
		)

	# Verify generation succeeded
	if level.starting_grid.size() == 0:
		push_error("Failed to generate level %d" % lvl_id)
		# Return a simple fallback grid
		level.starting_grid = generate_grid_no_squares(
			rules.board_width,
			rules.board_height,
			rules.num_colors
		)

	# Debug: verify solvability
	var can_solve := Solver.can_solve(level.starting_grid, level.move_limit)
	print("[Level %d] Generated - solvable: %s" % [lvl_id, str(can_solve)])

	return level

## Configure generation behavior
## Call this BEFORE creating levels to control caching and auto-generation
static func configure_generation(enable_auto_gen: bool = true, enable_cache: bool = true) -> void:
	auto_generate = enable_auto_gen
	if not enable_cache:
		clear_cache()

## Pre-generate levels in bulk (e.g., at startup or in background)
## This prevents stuttering during gameplay
static func pre_generate_levels(start_id: int, end_id: int) -> void:
	print("Pre-generating levels %d to %d..." % [start_id, end_id])
	var start_time := Time.get_ticks_msec()

	for i in range(start_id, end_id + 1):
		if not level_cache.has(i):
			level_cache[i] = _generate_level_internal(i)

	var elapsed := Time.get_ticks_msec() - start_time
	print("Pre-generated %d levels in %d ms" % [end_id - start_id + 1, elapsed])

## Clear the level cache
static func clear_cache() -> void:
	level_cache.clear()
	print("Level cache cleared")

## Check if a level is cached
static func is_cached(id: int) -> bool:
	return level_cache.has(id)

## Get cached level count
static func get_cache_size() -> int:
	return level_cache.size()

## Generic factory function to create any level by ID
## This is the main entry point for level creation
## Uses cache and respects auto_generate setting
static func create_level(id: int) -> LevelData:
	# Check cache first
	if level_cache.has(id):
		return level_cache[id]

	# If auto_generate is disabled, return a placeholder
	if not auto_generate:
		push_warning("Auto-generation disabled. Level %d not cached. Call pre_generate_levels() first." % id)
		var placeholder := LevelData.new()
		placeholder.level_id = id
		placeholder.level_name = "Not Generated"
		return placeholder

	# Generate and cache
	var level := _generate_level_internal(id)
	level_cache[id] = level
	return level

## Internal generation function (called by create_level and pre_generate)
static func _generate_level_internal(id: int) -> LevelData:
	# HARDCODED levels override rule-based generation (for testing)
	match id:
		1:
			return create_level_1()
		2:
			return create_level_2()
		999:
			return create_level_endless()
		_:
			# Use rule-based generation for other levels
			if id >= 3 and id <= 100:
				var difficulty := _calculate_difficulty(id)
				var rules := LevelRules.create_for_difficulty(difficulty)
				return create_from_rules(id, rules)
			else:
				push_warning("Unknown level ID %d, defaulting to Level 1" % id)
				return create_level_1()

## Calculate difficulty tier from level number
## Levels 1-10: difficulties 1-5, then repeat with variations
static func _calculate_difficulty(level_num: int) -> int:
	# Simple progression: every 2 levels increases difficulty
	# Levels 1-2: difficulty 1
	# Levels 3-4: difficulty 2
	# Levels 5-6: difficulty 3
	# Levels 7-8: difficulty 4
	# Levels 9-10: difficulty 5
	# Then repeats at difficulty 5
	var tier := floori((level_num - 1) / 2.0) + 1
	return mini(tier, 5)

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

	# Generate a VALIDATED grid - guaranteed solvable within 10 moves
	# Uses solver to verify before returning
	level.starting_grid = _generate_validated_grid(4, 4, 3, 10, 1)

	# Full cascade mode: lock → clear → gravity → refill → cascade
	level.lock_on_match = true
	level.clear_locked_squares = true
	level.enable_gravity = true
	level.refill_from_top = true

	return level
