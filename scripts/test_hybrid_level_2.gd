extends Node

## Test the hybrid Level 2 generation system
## NOTE: Only runs in debug builds to avoid production issues

func _ready() -> void:
	if not OS.is_debug_build():
		return  # Don't run tests in production builds
	
	print("\n=== Testing Hybrid Level 2 Generation ===\n")

	# Test Template 1
	var goal: Array = [
		[0, 0, 1, 2],
		[0, 0, 2, 1],
		[1, 2, 1, 2],
		[2, 1, 2, 1]
	]

	var spine_moves: Array[Dictionary] = [
		{"from": Vector2i(1, 0), "to": Vector2i(2, 0)},
		{"from": Vector2i(0, 0), "to": Vector2i(1, 0)}
	]

	print("Template goal grid:")
	_print_grid(goal)

	print("\nCritical cells (involved in solution):")
	var critical := Solver._get_critical_cells(spine_moves, goal)
	for cell in critical:
		print("  (%d, %d)" % [cell.x, cell.y])

	print("\nGenerating puzzle using hybrid method...")
	var starting_grid := Solver.generate_validated_puzzle(goal, spine_moves, 3, 10)

	if starting_grid.size() == 0:
		print("❌ FAILED: Could not generate valid puzzle")
		return

	print("\n✅ SUCCESS: Generated starting grid:")
	_print_grid(starting_grid)

	# Check for starting matches
	var matches := _find_matches(starting_grid)
	if matches.size() > 0:
		print("\n❌ ERROR: Starting grid has %d matches!" % matches.size())
		for match_pos in matches:
			print("  Match at (%d,%d)" % [match_pos.x, match_pos.y])
	else:
		print("\n✅ No starting matches")

	# Verify solvability
	var can_solve := Solver.can_solve(starting_grid, spine_moves.size() + 2)
	print("Can solve: %s" % ("✅ YES" % can_solve if can_solve else "❌ NO"))

	# Find actual solution
	var solution := Solver.find_solution(starting_grid, spine_moves.size() + 2)
	print("Solution length: %d moves" % solution.size())
	for i in range(solution.size()):
		var move: Dictionary = solution[i]
		print("  Move %d: (%d,%d) <-> (%d,%d)" % [
			i + 1,
			move["from"].x, move["from"].y,
			move["to"].x, move["to"].y
		])

	print("\n=== Test Complete ===")

func _find_matches(grid: Array) -> Array[Vector2i]:
	var matches: Array[Vector2i] = []
	var h := grid.size()
	if h == 0:
		return matches
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

func _print_grid(grid: Array) -> void:
	for y in range(grid.size()):
		var row_str := "  "
		for x in range(grid[y].size()):
			var color_id: int = grid[y][x]
			row_str += str(color_id) + " "
		print(row_str)
