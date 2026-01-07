extends Node

## ========================================================================
##  LEVEL GENERATOR - Standalone Puzzle Generation Tool
## ========================================================================
## Generates valid Square Up puzzles with guaranteed solutions using
## reverse-solve technique and bag randomization for even color distribution.
##
## Run this script directly in Godot to generate test levels:
##   1. Attach to a Node in the scene tree
##   2. Press F6 to run the current scene
##   3. Check console output for generated puzzles
##
## Or call from code:
##   var generator = LevelGenerator.new()
##   var level = generator.generate_level(width, height, num_colors, moves)
## ========================================================================

class_name LevelGenerator

# Dependencies
const ColorBag = preload("res://scripts/color_bag.gd")

## Generation settings
var use_bag_randomization: bool = true
var bag_multiplier: int = 2
var max_attempts: int = 50
var debug_output: bool = true

## Statistics tracking
var generation_attempts: int = 0
var failed_attempts: int = 0
var total_generated: int = 0

## Run when script is executed directly
func _ready() -> void:
	print("\n" + "=".repeat(70))
	print("  SQUARE UP LEVEL GENERATOR")
	print("=".repeat(70) + "\n")

	# Generate example levels
	_generate_examples()

	print("\n" + "=".repeat(70))
	print("  GENERATION COMPLETE")
	print("  Total Generated: %d" % total_generated)
	print("  Total Attempts: %d" % generation_attempts)
	print("  Failed Attempts: %d" % failed_attempts)
	print("=".repeat(70) + "\n")

## Generate example levels to demonstrate capabilities
func _generate_examples() -> void:
	print("Generating example levels...\n")

	# Example 1: Simple 4x4, 2 colors, 1 move (like Level 1)
	print("--- Example 1: Tutorial Level (4x4, 2 colors, 1 move) ---")
	var level1 := generate_level(4, 4, 2, 1)
	if level1:
		_print_level(level1)

	# Example 2: Intermediate 5x5, 3 colors, 1 move
	print("\n--- Example 2: Intermediate Level (5x5, 3 colors, 1 move) ---")
	var level2 := generate_level(5, 5, 3, 1)
	if level2:
		_print_level(level2)

	# Example 3: Advanced 6x6, 4 colors, 1 move
	print("\n--- Example 3: Advanced Level (6x6, 4 colors, 1 move) ---")
	var level3 := generate_level(6, 6, 4, 1)
	if level3:
		_print_level(level3)

	# Example 4: Generate multiple variations
	print("\n--- Example 4: Generate 3 Variations (4x4, 2 colors, 1 move) ---")
	for i in range(3):
		var variant := generate_level(4, 4, 2, 1)
		if variant:
			print("Variant %d:" % (i + 1))
			_print_grid(variant["starting_grid"])
			print()

## Generate a complete level with guaranteed solution
## Returns a Dictionary with level data or null if generation failed
func generate_level(width: int, height: int, num_colors: int, target_moves: int) -> Dictionary:
	generation_attempts += 1

	var level := {
		"width": width,
		"height": height,
		"num_colors": num_colors,
		"target_moves": target_moves,
		"starting_grid": [],
		"solution_moves": [],
		"is_valid": false
	}

	# Use reverse-solve technique
	var result := _generate_via_reverse_solve(width, height, num_colors, target_moves)

	if result:
		level["starting_grid"] = result["starting_grid"]
		level["solution_moves"] = result["solution_moves"]
		level["is_valid"] = true
		total_generated += 1
		return level
	else:
		failed_attempts += 1
		return {}

## Generate using reverse-solve: start from goal, work backwards
func _generate_via_reverse_solve(width: int, height: int, num_colors: int, moves: int) -> Dictionary:
	# NOTE: Currently only 1-move solutions are implemented
	# For multi-move requests, generate a 1-move puzzle as fallback
	var target_moves := moves
	var attempted_moves := moves

	# If multi-move requested, warn user and use 1-move
	if moves > 1:
		if debug_output:
			print("  ⚠ Multi-move generation not yet implemented, using 1-move fallback")
		attempted_moves = 1

	for attempt in range(max_attempts):
		# Step 1: Generate a random goal state WITH at least one 2x2 match
		var goal_grid := _generate_goal_grid(width, height, num_colors)

		# Step 2: Find the 2x2 match(es) in the goal
		var matches := _find_all_matches(goal_grid)
		if matches.is_empty():
			continue  # No match found, try again

		# Step 3: Pick one match to "break" with our solution
		var target_match: Vector2i = matches[randi() % matches.size()]

		# Step 4: Generate move sequence that breaks the match (currently 1-move only)
		var solution := _generate_solution_moves(goal_grid, target_match, attempted_moves)
		if solution.is_empty():
			continue  # Couldn't generate valid solution

		# Step 5: Apply moves in reverse to get starting grid
		var starting_grid := _copy_grid(goal_grid)
		for i in range(solution.size() - 1, -1, -1):
			var move: Dictionary = solution[i]
			_swap_cells(starting_grid, move["from"], move["to"])

		# Step 6: Verify starting grid has NO matches
		if _has_any_match(starting_grid):
			continue  # Starting grid has match, invalid

		# Success!
		if debug_output:
			print("  ✓ Generated valid puzzle in %d attempts" % (attempt + 1))
			if target_moves != attempted_moves:
				print("  ℹ Requested %d moves, generated %d move solution" % [target_moves, attempted_moves])

		return {
			"starting_grid": starting_grid,
			"solution_moves": solution,
			"goal_grid": goal_grid
		}

	# Failed after max attempts
	if debug_output:
		push_warning("  ✗ Failed to generate after %d attempts" % max_attempts)

	return {}

## Generate a random goal grid WITH at least one 2x2 match
func _generate_goal_grid(width: int, height: int, num_colors: int) -> Array:
	var grid := []

	# Initialize with bag randomization or pure random
	var bag: ColorBag = null
	if use_bag_randomization:
		bag = ColorBag.create_default(num_colors, bag_multiplier)

	# Fill grid
	for y in range(height):
		var row: Array[int] = []
		for x in range(width):
			var color: int
			if bag:
				color = bag.draw()
			else:
				color = randi() % num_colors
			row.append(color)
		grid.append(row)

	# Ensure at least one 2x2 match by forcing one
	_force_one_match(grid, num_colors)

	return grid

## Force at least one 2x2 match in the grid
func _force_one_match(grid: Array, num_colors: int) -> void:
	var height: int = grid.size()
	var width: int = grid[0].size()

	# Pick random position for top-left of match (must have room for 2x2)
	if width < 2 or height < 2:
		return  # Grid too small

	var x: int = randi() % (width - 1)
	var y: int = randi() % (height - 1)

	# Pick random color
	var color := randi() % num_colors

	# Set all 4 cells to same color
	grid[y][x] = color
	grid[y][x + 1] = color
	grid[y + 1][x] = color
	grid[y + 1][x + 1] = color

## Generate solution moves that break a specific match
func _generate_solution_moves(goal_grid: Array, match_pos: Vector2i, _num_moves: int) -> Array:
	# For now, implement simple 1-move solution
	# TODO: Extend for multi-move solutions

	var moves: Array[Dictionary] = []

	# Find a tile in the match to swap with a tile outside
	var match_cells := [
		Vector2i(match_pos.x, match_pos.y),
		Vector2i(match_pos.x + 1, match_pos.y),
		Vector2i(match_pos.x, match_pos.y + 1),
		Vector2i(match_pos.x + 1, match_pos.y + 1)
	]

	# Pick one cell from the match
	var from_cell: Vector2i = match_cells[randi() % match_cells.size()]

	# Find adjacent cells NOT in the match
	var adjacent := _get_adjacent_cells(from_cell, goal_grid[0].size(), goal_grid.size())
	var valid_targets: Array[Vector2i] = []

	for adj in adjacent:
		if not adj in match_cells:
			valid_targets.append(adj)

	if valid_targets.is_empty():
		return []  # No valid swap target

	# Pick random target
	var to_cell: Vector2i = valid_targets[randi() % valid_targets.size()]

	moves.append({"from": from_cell, "to": to_cell})

	return moves

## Get adjacent cells (up, down, left, right)
func _get_adjacent_cells(pos: Vector2i, width: int, height: int) -> Array[Vector2i]:
	var adjacent: Array[Vector2i] = []

	var directions := [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]

	for dir in directions:
		var new_pos: Vector2i = pos + dir
		if new_pos.x >= 0 and new_pos.x < width and new_pos.y >= 0 and new_pos.y < height:
			adjacent.append(new_pos)

	return adjacent

## Find all 2x2 matches in a grid (returns top-left positions)
func _find_all_matches(grid: Array) -> Array[Vector2i]:
	var matches: Array[Vector2i] = []
	var height: int = grid.size()
	var width: int = grid[0].size()

	for y in range(height - 1):
		for x in range(width - 1):
			var c: int = grid[y][x]
			if (grid[y][x + 1] == c and
				grid[y + 1][x] == c and
				grid[y + 1][x + 1] == c):
				matches.append(Vector2i(x, y))

	return matches

## Check if grid has any 2x2 match
func _has_any_match(grid: Array) -> bool:
	return not _find_all_matches(grid).is_empty()

## Copy a 2D grid
func _copy_grid(grid: Array) -> Array:
	var copy: Array = []
	for row in grid:
		copy.append(row.duplicate())
	return copy

## Swap two cells in a grid
func _swap_cells(grid: Array, a: Vector2i, b: Vector2i) -> void:
	var temp = grid[a.y][a.x]
	grid[a.y][a.x] = grid[b.y][b.x]
	grid[b.y][b.x] = temp

## Print level information
func _print_level(level: Dictionary) -> void:
	if not level or not level.get("is_valid", false):
		print("  ✗ Invalid level")
		return

	print("  Dimensions: %dx%d" % [level["width"], level["height"]])
	print("  Colors: %d" % level["num_colors"])
	print("  Target Moves: %d" % level["target_moves"])
	print("  Solution Moves: %d" % level["solution_moves"].size())

	print("\n  Starting Grid:")
	_print_grid(level["starting_grid"])

	if level.has("solution_moves") and not level["solution_moves"].is_empty():
		print("\n  Solution:")
		for i in range(level["solution_moves"].size()):
			var move: Dictionary = level["solution_moves"][i]
			print("    Move %d: Swap (%d,%d) ↔ (%d,%d)" %
				[i + 1, move["from"].x, move["from"].y, move["to"].x, move["to"].y])

	# Verify no starting matches
	var starting_matches := _find_all_matches(level["starting_grid"])
	if starting_matches.is_empty():
		print("\n  ✓ No starting matches (valid puzzle)")
	else:
		print("\n  ✗ WARNING: %d starting matches found!" % starting_matches.size())

	# COPY-PASTE CODE FOR level_data.gd
	print("\n" + "=".repeat(60))
	print("  📋 COPY-PASTE CODE (add to level_data.gd)")
	print("=".repeat(60))
	_print_gdscript_code(level)
	print("=".repeat(60))

## Print a grid in readable format
func _print_grid(grid: Array) -> void:
	for row in grid:
		var row_str := "    "
		for cell in row:
			row_str += str(cell) + " "
		print(row_str)

## Generate copy-pasteable GDScript code for level_data.gd
func _print_gdscript_code(level: Dictionary) -> void:
	if not level or not level.get("is_valid", false):
		return

	var w: int = level["width"]
	var h: int = level["height"]
	var colors: int = level["num_colors"]
	var grid: Array = level["starting_grid"]
	var solution: Array = level["solution_moves"]

	print("")
	print("## Level X: [Your Description Here]")
	print("static func create_level_X() -> LevelData:")
	print("\tvar level := LevelData.new()")
	print("\tlevel.level_id = X")
	print("\tlevel.level_name = \"[Your Level Name]\"")
	print("\tlevel.width = %d" % w)
	print("\tlevel.height = %d" % h)
	print("\tlevel.num_colors = %d" % colors)
	print("\tlevel.move_limit = %d  # Adjust as needed" % solution.size())
	print("\tlevel.target_score = 10  # Adjust as needed")
	print("\tlevel.squares_goal = 1  # Adjust as needed")
	print("")
	print("\t# Starting grid (generated with bag randomization)")
	print("\tlevel.starting_grid = [")
	for i in range(grid.size()):
		var row_str := "\t\t["
		for j in range(grid[i].size()):
			row_str += str(grid[i][j])
			if j < grid[i].size() - 1:
				row_str += ", "
		row_str += "]"
		if i < grid.size() - 1:
			row_str += ","
		print(row_str)
	print("\t]")
	print("")
	print("\t# Game mechanics (adjust as needed)")
	print("\tlevel.lock_on_match = false")
	print("\tlevel.clear_locked_squares = false")
	print("\tlevel.enable_gravity = false")
	print("\tlevel.refill_from_top = false")
	print("")
	print("\treturn level")
	print("")
