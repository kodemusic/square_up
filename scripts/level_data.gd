extends Node

## ========================================================================
##  LEVEL DATA - Puzzle Level Definition & Generation System
## ========================================================================
## Manages level creation using reverse-solve technique to guarantee
## solvable puzzles. Supports caching, procedural generation, and
## template-based level design.
##
## Usage:
##   var level = LevelData.create_level(1)  # Get Level 1
##   LevelData.pre_generate_levels(1, 10)   # Pre-cache levels 1-10
## ========================================================================

class_name LevelData

# ========================================================================
# CONSTANTS
# ========================================================================
const DEFAULT_WIDTH := 5
const DEFAULT_HEIGHT := 5
const DEFAULT_COLORS := 3
const MAX_GENERATION_ATTEMPTS := 15
const FALLBACK_ATTEMPTS := 10

# ========================================================================
# STATIC PROPERTIES - Cache & Generation Control
# ========================================================================
static var level_cache: Dictionary = {}  # level_id -> LevelData
static var auto_generate: bool = true    # Auto-generate on create_level() call?
static var prefer_handcrafted: bool = true  # Use handcrafted levels when available (default: true)

## Enable/disable caching in debug mode (set to false to always regenerate levels)
static var enable_debug_cache: bool = true  # Default: enabled for normal play

# ========================================================================
# INSTANCE PROPERTIES
# ========================================================================

## Level metadata
var level_id: int = 0
var level_name: String = ""
var move_limit: int = 0  # 0 = unlimited
var target_score: int = 0
var squares_goal: int = 0  # Number of 2x2 squares needed to win

## Board configuration
var width: int = DEFAULT_WIDTH
var height: int = DEFAULT_HEIGHT
var num_colors: int = DEFAULT_COLORS
var starting_grid: Array = []  # [y][x] -> color_id (2D array)
var initial_heights: Array = []  # [y][x] -> height (2D array, optional)

## Solution data (optional, for reverse-solving)
var solution_moves: Array[Dictionary] = []  # [{from: Vector2i, to: Vector2i}]

## Gameplay mechanics configuration
var lock_on_match: bool = true       # Lock matched squares?
var clear_locked_squares: bool = false  # Remove locked squares from board?
var enable_gravity: bool = false     # Tiles drop down into gaps?
var refill_from_top: bool = false    # Spawn new tiles at top?


# ========================================================================
# GRID HELPER FUNCTIONS - Utility functions for grid manipulation
# ========================================================================

## Deep copy a 2D grid array
static func _copy_grid(grid: Array) -> Array:
	if grid.size() == 0:
		push_warning("Attempting to copy empty grid")
		return []
	
	var copy: Array = []
	for y in range(grid.size()):
		var row: Array = []
		for x in range(grid[y].size()):
			row.append(grid[y][x])
		copy.append(row)
	return copy

## Swap two cells in a grid (modifies in place)
static func _swap_cells(grid: Array, a: Vector2i, b: Vector2i) -> void:
	if grid.size() == 0 or a.y >= grid.size() or b.y >= grid.size():
		push_error("Invalid grid or position for swap")
		return
	
	var temp: int = grid[a.y][a.x]
	grid[a.y][a.x] = grid[b.y][b.x]
	grid[b.y][b.x] = temp

## Print grid for debugging
func print_grid(grid: Array) -> void:
	print("Grid %dx%d:" % [width, height])
	for y in range(grid.size()):
		var row_str := ""
		for x in range(grid[y].size()):
			var color_id: int = grid[y][x]
			row_str += ". " if color_id < 0 else str(color_id) + " "
		print(row_str)

## Generate a random grid with no 2x2 matches
## Uses backtracking to ensure no color creates a square when placed
static func generate_grid_no_squares(rows: int, cols: int, color_count: int, use_bag: bool = true) -> Array:
	if rows <= 0 or cols <= 0 or color_count <= 0:
		push_error("Invalid grid parameters: rows=%d, cols=%d, colors=%d" % [rows, cols, color_count])
		return []

	# Create color bag for better distribution (bag multiplier = 2x for good variety)
	var bag: ColorBag = null
	if use_bag:
		bag = ColorBag.create_default(color_count, 2)

	var grid: Array = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			var tries := 0
			var color_id: int

			# Draw from bag or use pure random
			if bag:
				color_id = bag.draw()
			else:
				color_id = randi() % color_count

			# Keep trying random colors until we find one that doesn't create a square
			while _creates_square(grid, row, r, c, color_id) and tries < 20:
				if bag:
					color_id = bag.draw()
				else:
					color_id = randi() % color_count
				tries += 1

			# Failsafe: if too constrained, find any non-square color
			if tries >= 20:
				color_id = _pick_non_square_color(grid, row, r, c, color_count)

			row.append(color_id)
		grid.append(row)
	return grid

## Check if placing a color at position would create a 2x2 square
static func _creates_square(grid: Array, current_row: Array, r: int, c: int, color_id: int) -> bool:
	# Can't form a square if we're in the first row or column
	if r == 0 or c == 0:
		return false

	# Check if this would complete a 2x2 square:
	#   [r-1][c-1]  [r-1][c]   <- previous row (in grid)
	#   [r][c-1]    [r][c]     <- current row (being built)
	var top_left: int = grid[r - 1][c - 1]
	var top_right: int = grid[r - 1][c]
	var bottom_left: int = current_row[c - 1]

	return (top_left == color_id and top_right == color_id and bottom_left == color_id)

## Find a color that doesn't create a square at position
static func _pick_non_square_color(grid: Array, current_row: Array, r: int, c: int, color_count: int) -> int:
	for color_id in range(color_count):
		if not _creates_square(grid, current_row, r, c, color_id):
			return color_id
	return 0  # Fallback (should be rare if color_count >= 3)


# ========================================================================
# LEVEL FACTORY FUNCTIONS - Create specific level instances
# ========================================================================

## Level 1: Tutorial - 1-move puzzle with 2 colors
static func create_level_1() -> LevelData:
	var level := LevelData.new()
	level.level_id = 1
	level.level_name = "First Match"
	level.width = 4
	level.height = 4
	level.num_colors = 2
	level.move_limit = 0 	# Unlimited
	level.target_score = 10
	level.squares_goal = 1

	# Generate using reverse-solve (guaranteed solvable)
	level.starting_grid = _get_level_1_grid()
	
	# Verify solvability in debug
	if OS.is_debug_build():
		var rules := BoardRules.Rules.from_level_data(level)
		var can_solve := Solver.can_solve(level.starting_grid, level.move_limit, rules)
		print("[Level 1] Generated puzzle - solvable: %s" % str(can_solve))

	# Tutorial mode: no cascade mechanics
	# Player learns basic matching without complications
	level.lock_on_match = false
	level.clear_locked_squares = false
	level.enable_gravity = false
	level.refill_from_top = false

	return level

## Level 2: Intermediate - Multi-move puzzle with 2 colors
static func create_level_2() -> LevelData:
	var level := LevelData.new()
	level.level_id = 2
	level.level_name = "Two Colors"
	level.width = 5
	level.height = 5
	level.num_colors = 2
	level.move_limit = 0 # Unlimited
	level.target_score = 20
	level.squares_goal = 2

	# Generate using hybrid approach
	level.starting_grid = generate_grid_no_squares(5, 5, 2)

	# Verify solvability in debug
	if OS.is_debug_build():
		var rules := BoardRules.Rules.from_level_data(level)
		var can_solve := Solver.can_solve(level.starting_grid, level.move_limit, rules)
		print("[Level 2] Generated puzzle - solvable: %s" % str(can_solve))

	# Introduce full cascade mechanics: clear → gravity → refill → combo chains
	# Player experiences the core satisfying gameplay loop
	level.lock_on_match = true
	level.clear_locked_squares = true
	level.enable_gravity = true
	level.refill_from_top = true
	
	return level

## Level 3: Advanced - 3 colors with cascades
static func create_level_3() -> LevelData:
	var level := LevelData.new()
	level.level_id = 3
	level.level_name = "Three Colors"
	level.width = 6
	level.height = 5
	level.num_colors = 3
	level.move_limit = 0  # Unlimited
	level.target_score = 30
	level.squares_goal = 3

	# Generate random solvable grid with 3 colors (no invalid color 3)
	level.starting_grid = generate_grid_no_squares(6, 5, 3)

	# Verify solvability in debug
	if OS.is_debug_build():
		var rules := BoardRules.Rules.from_level_data(level)
		var validation := Solver.validate_level(level.starting_grid, 10, rules, 1, 2, level.squares_goal)
		print("[Level 3] Validation:")
		print("  Valid: %s" % validation["valid"])
		print("  Solvable: %s" % validation["solvable"])
		print("  Initial valid moves: %d" % validation["initial_valid_moves"])
		print("  Shortest solution: %d moves" % validation["shortest_solution"])
		if not validation["valid"]:
			push_warning("[Level 3] Validation errors: ", validation["errors"])

	# Full cascade mechanics enabled
	level.lock_on_match = true
	level.clear_locked_squares = true
	level.enable_gravity = true
	level.refill_from_top = true

	return level

## Level 4: Height Tutorial - Teaches that height matters for matching
## 4x4 grid, 2 colors, demonstrates that only tiles of same height can match
static func create_level_4() -> LevelData:
	var level := LevelData.new()
	level.level_id = 4
	level.level_name = "Height Matters"
	level.width = 4
	level.height = 4
	level.num_colors = 2
	level.move_limit = 0  # Unlimited
	level.target_score = 10
	level.squares_goal = 1

	# Color grid: Create a 2x2 red square (color 0) that CAN match
	# But the key lesson: some tiles have different heights
	level.starting_grid = [
		[0, 0, 1, 1],  # Top-left: Red square (but one tile is taller!)
		[0, 1, 1, 0],
		[1, 1, 0, 0],
		[1, 0, 0, 1]
	]

	# Height grid: One tile in top-left is height=2, preventing the match
	# Player must swap to create a 2x2 match with matching heights
	level.initial_heights = [
		[1, 2, 1, 1],  # Second tile (0,1) is stacked higher
		[1, 1, 1, 1],
		[1, 1, 1, 1],
		[1, 1, 1, 1]
	]

	if OS.is_debug_build():
		print("[Level 4] Height tutorial level created")
		print("  Grid: 4x4, 2 colors")
		print("  Key mechanic: Tile at (1,0) has height=2")
		print("  Lesson: 2x2 squares must have same color AND same height")

	# Tutorial mode: no cascades (like Level 1)
	# Focus is purely on learning height mechanic
	level.lock_on_match = false
	level.clear_locked_squares = false
	level.enable_gravity = false
	level.refill_from_top = false

	return level

## Endless Mode: Infinite gameplay with cascading mechanics
static func create_level_endless() -> LevelData:
	var level := LevelData.new()
	level.level_id = 999
	level.level_name = "Endless Mode"
	level.width = 5
	level.height = 5
	level.num_colors = 3
	level.move_limit = 0  # Unlimited
	level.target_score = 0  # No target
	level.squares_goal = 999999  # Infinite

	# For endless mode, use fast generation (no validation needed)
	# Cascades make solvability less important
	level.starting_grid = generate_grid_no_squares(5, 5, 3)

	if OS.is_debug_build():
		print("[Endless Mode] Generated grid (no validation)")

	# Full cascade mode
	level.lock_on_match = true
	level.clear_locked_squares = true
	level.enable_gravity = true
	level.refill_from_top = true

	return level


# ========================================================================
# PUZZLE POOL DEFINITIONS - Reverse-solve templates
# ========================================================================
## These functions return starting grids generated from goal states
## Puzzles are GUARANTEED solvable because they're created by:
## 1. Define a goal state with a 2x2 match
## 2. Define the solution moves
## 3. Apply moves in REVERSE to generate the starting state

## Get Level 1 puzzle (1-move solvable, 2 colors)
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
		# Puzzle 4: Swap brings 1 from (1,3) into (2,3) to complete bottom-right match
		# Goal has 2x2 of 1s at (2,2)-(3,2)-(2,3)-(3,3)
		# Move swaps (2,3) with (1,3), so START has (2,3)=0 (from position 1,3) and (1,3)=1 (from position 2,3)
		{
			"goal": [
				[0, 1, 0, 1],
				[1, 0, 1, 0],
				[0, 1, 1, 1],
				[1, 0, 1, 1]
			],
			"moves": [{"from": Vector2i(2, 3), "to": Vector2i(1, 3)}]
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
	var puzzle_index := randi() % puzzle_defs.size()
	var def: Dictionary = puzzle_defs[puzzle_index]
	print("[Level 1 Generation] Selected puzzle %d/%d" % [puzzle_index + 1, puzzle_defs.size()])

	# Apply reverse-solve: start from goal and undo the moves
	var working_grid: Array = _copy_grid(def["goal"])
	var moves: Array = def["moves"]
	
	# Apply moves in reverse order (for 1-move puzzles, just 1 swap)
	for i in range(moves.size() - 1, -1, -1):
		var move: Dictionary = moves[i]
		var from: Vector2i = move["from"]
		var to: Vector2i = move["to"]
		print("[Level 1 Generation] Reversing move: swap (%d,%d) <-> (%d,%d)" % [from.x, from.y, to.x, to.y])
		_swap_cells(working_grid, from, to)  # Swap is self-inverse

	print("[Level 1 Generation] Starting grid after reverse:")
	for row in working_grid:
		print("  ", row)

	return working_grid

## Get Level 2 puzzle (2-4 moves solvable, 3 colors, 5x5 board)
## Uses hybrid approach: templates + validation
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

	# Method 2: Fallback to using template directly (apply reverse moves)
	print("[Level 2] Hybrid failed, using TEMPLATE REVERSAL method")
	var goal_grid: Array = template["goal"]
	var grid_from_template := _copy_grid(goal_grid)

	# Apply moves in reverse order to get starting grid
	var moves: Array = template["moves"]
	for i in range(moves.size() - 1, -1, -1):
		var move: Dictionary = moves[i]
		_swap_cells(grid_from_template, move["from"], move["to"])

	return grid_from_template


# ========================================================================
# PROCEDURAL GENERATION - Validated random grid generation
# ========================================================================

## Generate a validated solvable grid
## Used as fallback for procedural generation
static func _generate_validated_grid(rows: int, cols: int, color_count: int, max_moves: int, min_solution_depth: int = 2) -> Array:
	for attempt in range(MAX_GENERATION_ATTEMPTS):
		# Generate a random grid with no 2x2 matches
		var grid := generate_grid_no_squares(rows, cols, color_count)

		# Create default rules for validation (no cascades)
		var rules := BoardRules.Rules.new()
		rules.num_colors = color_count

		# Validate using solver
		var validation := Solver.validate_level(grid, max_moves, rules, min_solution_depth)

		if validation["valid"]:
			if OS.is_debug_build():
				print("Level generated on attempt %d (solution: %d moves, explored: %d states)" % [
					attempt + 1,
					validation["shortest_solution"],
					validation["states_explored"]
				])
			return grid
		elif OS.is_debug_build() and attempt % 5 == 4:
			print("Attempt %d failed: %s" % [attempt + 1, validation["errors"]])

	# Fallback: return any solvable grid
	print("Warning: Could not generate optimal puzzle, using fast fallback")
	var fallback_rules := BoardRules.Rules.new()
	fallback_rules.num_colors = color_count
	for _fallback in range(FALLBACK_ATTEMPTS):
		var grid := generate_grid_no_squares(rows, cols, color_count)
		if Solver.can_solve(grid, mini(max_moves, 5), fallback_rules):
			return grid

	# Ultimate fallback
	push_warning("Using unvalidated grid")
	return generate_grid_no_squares(rows, cols, color_count)


# ========================================================================
# RULE-BASED GENERATION - Create levels from difficulty rules
# ========================================================================

## Create a level from difficulty rules (for levels 3+)
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
	if OS.is_debug_build():
		var solver_rules := BoardRules.Rules.from_level_data(level)
		var can_solve := Solver.can_solve(level.starting_grid, level.move_limit, solver_rules)
		print("[Level %d] Generated - solvable: %s" % [lvl_id, str(can_solve)])

	return level

# ========================================================================
# CACHE & GENERATION SYSTEM - Level caching and batch generation
# ========================================================================

## Configure generation behavior (call before creating levels)
static func configure_generation(enable_auto_gen: bool = true, enable_cache: bool = true) -> void:
	auto_generate = enable_auto_gen
	if not enable_cache:
		clear_cache()

## Pre-generate levels in bulk (prevents gameplay stuttering)
static func pre_generate_levels(start_id: int, end_id: int) -> void:
	if OS.is_debug_build():
		print("Pre-generating levels %d to %d..." % [start_id, end_id])
	var start_time := Time.get_ticks_msec()

	for i in range(start_id, end_id + 1):
		if not level_cache.has(i):
			level_cache[i] = _generate_level_internal(i)

	if OS.is_debug_build():
		var elapsed := Time.get_ticks_msec() - start_time
		print("Pre-generated %d levels in %d ms" % [end_id - start_id + 1, elapsed])

## Clear the level cache
static func clear_cache() -> void:
	level_cache.clear()
	if OS.is_debug_build():
		print("Level cache cleared")

## Clear a specific level from cache (useful for testing factory changes)
static func clear_level_cache(id: int) -> void:
	if level_cache.has(id):
		level_cache.erase(id)
		if OS.is_debug_build():
			print("Level %d cache cleared" % id)

## Check if a level is cached
static func is_cached(id: int) -> bool:
	return level_cache.has(id)

## Get cached level count
static func get_cache_size() -> int:
	return level_cache.size()

## Main entry point: Create any level by ID
## Uses cache and respects auto_generate setting
static func create_level(id: int) -> LevelData:
	# DEVELOPMENT: Disable cache in debug builds to see factory changes immediately
	# This ensures factory function changes are reflected without restarting the editor
	if OS.is_debug_build() and not enable_debug_cache:
		if level_cache.has(id):
			print("[LevelData] DEBUG MODE (cache disabled): Clearing level %d (cache size: %d)" % [id, level_cache.size()])
			level_cache.erase(id)
			print("[LevelData] Cache cleared. Will regenerate from factory.")
		else:
			print("[LevelData] DEBUG MODE (cache disabled): Level %d not cached, will generate fresh" % id)

	# Check cache first
	if level_cache.has(id):
		if OS.is_debug_build():
			print("[LevelData] Returning CACHED level %d (set enable_debug_cache=false to disable caching)" % id)
		return level_cache[id]

	# If auto_generate is disabled, return a placeholder
	if not auto_generate:
		push_warning("Auto-generation disabled. Level %d not cached. Call pre_generate_levels() first." % id)
		var placeholder := LevelData.new()
		placeholder.level_id = id
		placeholder.level_name = "Not Generated"
		return placeholder

	# Generate and cache
	print("[LevelData] Generating level %d from factory function..." % id)
	var level := _generate_level_internal(id)
	level_cache[id] = level
	print("[LevelData] Level %d generated and cached. Lock=%s Clear=%s Gravity=%s Refill=%s" % [id, level.lock_on_match, level.clear_locked_squares, level.enable_gravity, level.refill_from_top])
	return level

## Internal: Generate a level (called by create_level and pre_generate)
static func _generate_level_internal(id: int) -> LevelData:
	# HANDCRAFTED LEVELS ONLY (when prefer_handcrafted = true)
	# Uses factory functions from "LEVEL FACTORY FUNCTIONS" section

	if prefer_handcrafted:
		match id:
			1:
				return create_level_1()
			2:
				return create_level_2()
			3:
				return create_level_3()
			4:
				return create_level_4()
			999:
				return create_level_endless()
			# Add more handcrafted levels here:
			# 5:
			#     return create_level_5()
			_:
				# No handcrafted level exists for this ID
				push_error("Level %d does not have a handcrafted factory function" % id)
				return create_level_1()  # Fallback to Level 1
	
	# PROCEDURAL GENERATION (only when prefer_handcrafted = false)
	if id >= 3 and id <= 100:
		var difficulty := _calculate_difficulty(id)
		var rules := LevelRules.create_for_difficulty(difficulty)
		return create_from_rules(id, rules)
	elif id == 999:
		return create_level_endless()
	else:
		push_warning("Unknown level ID %d, defaulting to Level 1" % id)
		return create_level_1()

## Calculate difficulty tier from level number
static func _calculate_difficulty(level_num: int) -> int:
	# Progression: every 2 levels increases difficulty
	# Levels 1-2: difficulty 1, 3-4: difficulty 2, etc.
	# Max difficulty: 5
	var tier := floori((level_num - 1) / 2.0) + 1
	return mini(tier, 5)
