extends Node

## Test the lightweight solver with various board states
## NOTE: Only runs in debug builds to avoid production issues

func _ready() -> void:
	if not OS.is_debug_build():
		return  # Don't run tests in production builds
	
	print("\n=== Solver Tests ===\n")

	test_already_solved()
	test_one_move_solution()
	test_two_move_solution()
	test_unsolvable()
	test_validate_level_solution()

	print("\n=== All Tests Complete ===")

## Test 1: Board already has a match
func test_already_solved() -> void:
	print("Test 1: Already solved board")
	var grid: Array = [
		[0, 0, 1, 2],
		[0, 0, 2, 1],
		[1, 2, 1, 2],
		[2, 1, 2, 1],
	]

	var solvable := Solver.can_solve(grid, 1)
	print("  Can solve in 1 move: %s (expected: true)" % solvable)
	print()

## Test 2: Simple one-move solution
func test_one_move_solution() -> void:
	print("Test 2: One-move solution")
	var grid: Array = [
		[1, 0, 1, 2],  # Swap (0,0) <-> (1,0) creates match
		[0, 0, 2, 1],
		[1, 2, 1, 2],
		[2, 1, 2, 1],
	]

	var solvable := Solver.can_solve(grid, 1)
	print("  Can solve in 1 move: %s (expected: true)" % solvable)

	var solution := Solver.find_solution(grid, 1)
	if solution.size() > 0:
		print("  Solution found:")
		for i in range(solution.size()):
			var move: Dictionary = solution[i]
			print("    Move %d: (%d,%d) <-> (%d,%d)" % [
				i + 1,
				move["from"].x, move["from"].y,
				move["to"].x, move["to"].y
			])
	print()

## Test 3: Two-move solution
func test_two_move_solution() -> void:
	print("Test 3: Two-move solution")
	var grid: Array = [
		[1, 0, 1, 2],
		[0, 2, 2, 1],
		[1, 0, 1, 2],
		[2, 1, 2, 1],
	]

	var solvable_1 := Solver.can_solve(grid, 1)
	var solvable_2 := Solver.can_solve(grid, 2)
	print("  Can solve in 1 move: %s (expected: false)" % solvable_1)
	print("  Can solve in 2 moves: %s (expected: true)" % solvable_2)

	var solution := Solver.find_solution(grid, 2)
	if solution.size() > 0:
		print("  Solution found (%d moves):" % solution.size())
		for i in range(solution.size()):
			var move: Dictionary = solution[i]
			print("    Move %d: (%d,%d) <-> (%d,%d)" % [
				i + 1,
				move["from"].x, move["from"].y,
				move["to"].x, move["to"].y
			])
	print()

## Test 4: Unsolvable board (all different colors)
func test_unsolvable() -> void:
	print("Test 4: Unsolvable board")
	var grid: Array = [
		[0, 1, 2, 3],
		[1, 2, 3, 0],
		[2, 3, 0, 1],
		[3, 0, 1, 2],
	]

	var solvable := Solver.can_solve(grid, 3)
	print("  Can solve in 3 moves: %s (expected: false)" % solvable)
	print()

## Test 5: Validate the example level's solution
func test_validate_level_solution() -> void:
	print("Test 5: Validate level solution")
	var level: LevelData = LevelData.create_level(1)

	var is_valid := Solver.validate_solution(level.starting_grid, level.solution_moves)
	print("  Level solution is valid: %s (expected: true)" % is_valid)

	print("  Starting grid:")
	_print_grid(level.starting_grid)

	print("  Solution: %d moves" % level.solution_moves.size())
	for i in range(level.solution_moves.size()):
		var move: Dictionary = level.solution_moves[i]
		print("    Move %d: (%d,%d) <-> (%d,%d)" % [
			i + 1,
			move["from"].x, move["from"].y,
			move["to"].x, move["to"].y
		])
	print()

## Helper to print a grid
func _print_grid(grid: Array) -> void:
	for y in range(grid.size()):
		var row_str := "    "
		for x in range(grid[y].size()):
			row_str += str(grid[y][x]) + " "
		print(row_str)
