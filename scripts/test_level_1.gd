extends Node

## Test and validate Level 1 (first teaching level)
## 4x4 board with 2 colors, 1-move solution

func _ready() -> void:
	print("\n=== Level 1 Validation (4x4, 2 Colors) ===\n")

	var level := LevelData.create_level_1()

	print("Level: %s (ID: %d)" % [level.level_name, level.level_id])
	print("Board size: %dx%d" % [level.width, level.height])
	print("Colors used: 2 (Red=0, Blue=1)")
	print("Move limit: %d\n" % level.move_limit)

	# Show starting grid
	print("STARTING GRID:")
	_print_grid_colored(level.starting_grid)

	# Test 1: Validate the intended solution works
	print("\nTEST 1: Validate Intended Solution")
	var is_valid := Solver.validate_solution(level.starting_grid, level.solution_moves)
	print("  Solution is valid: %s" % ("✓ PASS" if is_valid else "✗ FAIL"))

	if is_valid:
		print("  Intended solution:")
		for i in range(level.solution_moves.size()):
			var move: Dictionary = level.solution_moves[i]
			print("    Move %d: (%d,%d) <-> (%d,%d)" % [
				i + 1,
				move["from"].x, move["from"].y,
				move["to"].x, move["to"].y
			])

	# Test 2: Count all possible 1-move solutions
	print("\nTEST 2: Find All Possible 1-Move Solutions")
	var solution_count := 0
	var solutions: Array[Dictionary] = []

	for y in range(level.height):
		for x in range(level.width):
			# Try swapping right
			if x + 1 < level.width:
				var from := Vector2i(x, y)
				var to := Vector2i(x + 1, y)
				if _test_swap_creates_match(level.starting_grid, from, to):
					solution_count += 1
					solutions.append({"from": from, "to": to})

			# Try swapping down
			if y + 1 < level.height:
				var from := Vector2i(x, y)
				var to := Vector2i(x, y + 1)
				if _test_swap_creates_match(level.starting_grid, from, to):
					solution_count += 1
					solutions.append({"from": from, "to": to})

	print("  Total 1-move solutions found: %d" % solution_count)

	if solution_count == 1:
		print("  ✓ EXCELLENT: Exactly one solution (perfect teaching level)")
	elif solution_count > 1:
		print("  ⚠ WARNING: Multiple solutions found:")
		for i in range(solutions.size()):
			var move: Dictionary = solutions[i]
			print("    Solution %d: (%d,%d) <-> (%d,%d)" % [
				i + 1,
				move["from"].x, move["from"].y,
				move["to"].x, move["to"].y
			])
	else:
		print("  ✗ ERROR: No solutions found (level is broken)")

	# Test 3: Use solver to verify solvability
	print("\nTEST 3: Solver Verification")
	var can_solve_1 := Solver.can_solve(level.starting_grid, 1)
	print("  Can solve in 1 move: %s" % ("✓ YES" if can_solve_1 else "✗ NO"))

	var solver_solution := Solver.find_solution(level.starting_grid, 1)
	if solver_solution.size() > 0:
		print("  Solver found solution:")
		for i in range(solver_solution.size()):
			var move: Dictionary = solver_solution[i]
			print("    Move %d: (%d,%d) <-> (%d,%d)" % [
				i + 1,
				move["from"].x, move["from"].y,
				move["to"].x, move["to"].y
			])

	# Test 4: Verify color distribution
	print("\nTEST 4: Color Distribution Analysis")
	var color_counts := {}
	for y in range(level.height):
		for x in range(level.width):
			var color: int = level.starting_grid[y][x]
			if color_counts.has(color):
				color_counts[color] += 1
			else:
				color_counts[color] = 1

	for color in color_counts:
		var count: int = color_counts[color]
		var color_name := "Red" if color == 0 else "Blue"
		print("  %s (color %d): %d tiles (%.1f%%)" % [
			color_name, color, count, (count / 16.0) * 100.0
		])

	# Test 5: Show solution result
	print("\nTEST 5: Solution Result")
	print("GRID AFTER SOLUTION:")
	var result_grid := _apply_moves(level.starting_grid, level.solution_moves)
	_print_grid_colored(result_grid)

	# Find matches in result
	var matches := _find_matches(result_grid)
	print("\nMatches found: %d" % matches.size())
	for match_pos in matches:
		print("  2x2 match at (%d,%d)" % [match_pos.x, match_pos.y])

	# Final verdict
	print("\n=== FINAL VERDICT ===")
	var perfect := is_valid and can_solve_1 and solution_count == 1
	if perfect:
		print("✓✓✓ LEVEL 1 IS PERFECT ✓✓✓")
		print("Ready for players!")
	else:
		print("⚠ Level needs adjustments")
		if not is_valid:
			print("  - Intended solution doesn't work")
		if not can_solve_1:
			print("  - Cannot be solved in 1 move")
		if solution_count != 1:
			print("  - Does not have exactly 1 solution")

	print("\n=== Validation Complete ===")

## Test if a swap creates any 2x2 match
func _test_swap_creates_match(grid: Array, from: Vector2i, to: Vector2i) -> bool:
	var test_grid := LevelData._copy_grid(grid)
	LevelData._swap_cells(test_grid, from, to)
	return _find_matches(test_grid).size() > 0

## Find all 2x2 matches in a grid
func _find_matches(grid: Array) -> Array[Vector2i]:
	var matches: Array[Vector2i] = []
	var h := grid.size()
	var w: int = grid[0].size()

	for y in range(h - 1):
		for x in range(w - 1):
			var c0: int = grid[y][x]
			if c0 < 0:
				continue
			if (grid[y][x + 1] == c0 and
				grid[y + 1][x] == c0 and
				grid[y + 1][x + 1] == c0):
				matches.append(Vector2i(x, y))

	return matches

## Apply moves to a grid
func _apply_moves(grid: Array, moves: Array[Dictionary]) -> Array:
	var result := LevelData._copy_grid(grid)
	for move in moves:
		LevelData._swap_cells(result, move["from"], move["to"])
	return result

## Print grid with color names
func _print_grid_colored(grid: Array) -> void:
	for y in range(grid.size()):
		var row_str := "  "
		for x in range(grid[y].size()):
			var color_id: int = grid[y][x]
			if color_id == 0:
				row_str += "[R] "  # Red
			elif color_id == 1:
				row_str += "[B] "  # Blue
			else:
				row_str += "[ ] "  # Empty
		print(row_str)
