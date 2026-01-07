extends Node

## Test Level 2 design to ensure it has exactly one obvious solution
## NOTE: Only runs in debug builds to avoid production issues

func _ready() -> void:
	if not OS.is_debug_build():
		return  # Don't run tests in production builds
	
	print("\n=== Level 2 Validation ===\n")

	var level := LevelData.create_level_2()

	print("Level: %s (ID: %d)" % [level.level_name, level.level_id])
	print("Move limit: %d\n" % level.move_limit)

	# Show the starting grid
	print("STARTING GRID:")
	_print_grid(level.starting_grid)

	# Test: Count how many 1-move solutions exist
	print("\nFINDING ALL POSSIBLE 1-MOVE SOLUTIONS:")
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
					print("  Solution %d: (%d,%d) <-> (%d,%d)" % [
						solution_count, from.x, from.y, to.x, to.y
					])

			# Try swapping down
			if y + 1 < level.height:
				var from := Vector2i(x, y)
				var to := Vector2i(x, y + 1)
				if _test_swap_creates_match(level.starting_grid, from, to):
					solution_count += 1
					solutions.append({"from": from, "to": to})
					print("  Solution %d: (%d,%d) <-> (%d,%d)" % [
						solution_count, from.x, from.y, to.x, to.y
					])

	print("\nTOTAL SOLUTIONS FOUND: %d" % solution_count)

	if solution_count == 1:
		print("✓ SUCCESS: Exactly one solution (obvious teaching puzzle)")
	elif solution_count == 0:
		print("✗ ERROR: No solutions found (unsolvable)")
	else:
		print("⚠ WARNING: Multiple solutions (%d) - not ideal for teaching" % solution_count)

	# Validate the intended solution
	print("\nVALIDATING INTENDED SOLUTION:")
	var is_valid := Solver.validate_solution(level.starting_grid, level.solution_moves)
	print("  Intended solution works: %s" % is_valid)

	if is_valid and solution_count == 1:
		print("\n✓✓ LEVEL 2 DESIGN IS PERFECT ✓✓")

	# Show the solution
	print("\nINTENDED SOLUTION:")
	for i in range(level.solution_moves.size()):
		var move: Dictionary = level.solution_moves[i]
		print("  Move %d: (%d,%d) <-> (%d,%d)" % [
			i + 1,
			move["from"].x, move["from"].y,
			move["to"].x, move["to"].y
		])

	# Show result grid
	print("\nGRID AFTER SOLUTION:")
	var result_grid := _apply_moves(level.starting_grid, level.solution_moves)
	_print_grid(result_grid)

	print("\n=== Validation Complete ===")

## Test if a swap creates any 2x2 match
func _test_swap_creates_match(grid: Array, from: Vector2i, to: Vector2i) -> bool:
	# Create a copy and apply the swap
	var test_grid := LevelData._copy_grid(grid)
	LevelData._swap_cells(test_grid, from, to)

	# Check for any 2x2 matches
	var height := test_grid.size()
	var width: int = test_grid[0].size()

	for y in range(height - 1):
		for x in range(width - 1):
			var c0: int = test_grid[y][x]
			if c0 < 0:
				continue
			if (test_grid[y][x + 1] == c0 and
				test_grid[y + 1][x] == c0 and
				test_grid[y + 1][x + 1] == c0):
				return true

	return false

## Apply a sequence of moves to a grid
func _apply_moves(grid: Array, moves: Array[Dictionary]) -> Array:
	var result := LevelData._copy_grid(grid)
	for move in moves:
		LevelData._swap_cells(result, move["from"], move["to"])
	return result

## Print a grid
func _print_grid(grid: Array) -> void:
	for y in range(grid.size()):
		var row_str := "  "
		for x in range(grid[y].size()):
			var color_id: int = grid[y][x]
			if color_id < 0:
				row_str += ". "
			else:
				row_str += str(color_id) + " "
		print(row_str)
