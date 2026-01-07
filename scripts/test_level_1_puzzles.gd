extends Node

## Test script to verify all Level 1 puzzle definitions don't create starting matches

func _ready() -> void:
	print("\n=== Testing All Level 1 Puzzle Definitions ===\n")

	# All 5 puzzle definitions from level_data.gd
	var puzzle_defs: Array = [
		# Puzzle 1
		{
			"name": "Puzzle 1",
			"goal": [
				[0, 0, 1, 1],
				[0, 0, 1, 0],
				[1, 0, 1, 0],
				[1, 1, 0, 1]
			],
			"moves": [{"from": Vector2i(1, 0), "to": Vector2i(2, 0)}]
		},
		# Puzzle 2
		{
			"name": "Puzzle 2",
			"goal": [
				[0, 0, 1, 0],
				[0, 0, 1, 1],
				[1, 1, 0, 1],
				[0, 1, 1, 0]
			],
			"moves": [{"from": Vector2i(0, 1), "to": Vector2i(0, 2)}]
		},
		# Puzzle 3
		{
			"name": "Puzzle 3",
			"goal": [
				[0, 1, 0, 1],
				[0, 1, 1, 0],
				[1, 1, 1, 0],
				[0, 0, 1, 1]
			],
			"moves": [{"from": Vector2i(2, 1), "to": Vector2i(3, 1)}]
		},
		# Puzzle 4
		{
			"name": "Puzzle 4",
			"goal": [
				[0, 1, 0, 1],
				[1, 0, 1, 0],
				[0, 1, 1, 1],
				[1, 0, 1, 1]
			],
			"moves": [{"from": Vector2i(2, 2), "to": Vector2i(2, 3)}]
		},
		# Puzzle 5
		{
			"name": "Puzzle 5",
			"goal": [
				[1, 0, 0, 0],
				[0, 1, 0, 0],
				[1, 0, 1, 1],
				[0, 1, 1, 0]
			],
			"moves": [{"from": Vector2i(2, 0), "to": Vector2i(3, 0)}]
		}
	]

	for def in puzzle_defs:
		_test_puzzle(def)

	print("\n=== Test Complete ===\n")

func _test_puzzle(def: Dictionary) -> void:
	print("Testing %s:" % def["name"])

	# Copy goal grid
	var starting_grid: Array = _copy_grid(def["goal"])
	var moves: Array = def["moves"]

	# Reverse the moves
	for i in range(moves.size() - 1, -1, -1):
		var move: Dictionary = moves[i]
		var from: Vector2i = move["from"]
		var to: Vector2i = move["to"]
		_swap_cells(starting_grid, from, to)

	# Print starting grid
	print("  Starting grid:")
	for row in starting_grid:
		print("    ", row)

	# Check for matches
	var matches := _find_matches(starting_grid)

	if matches.size() == 0:
		print("  ✅ VALID: No starting matches\n")
	else:
		print("  ❌ BROKEN: %d starting matches found!" % matches.size())
		for match_pos in matches:
			var color: int = starting_grid[match_pos.y][match_pos.x]
			print("    - Match at (%d,%d) with color %d" % [match_pos.x, match_pos.y, color])
		print()

func _copy_grid(grid: Array) -> Array:
	var copy: Array = []
	for row in grid:
		copy.append(row.duplicate())
	return copy

func _swap_cells(grid: Array, a: Vector2i, b: Vector2i) -> void:
	var temp: int = grid[a.y][a.x]
	grid[a.y][a.x] = grid[b.y][b.x]
	grid[b.y][b.x] = temp

func _find_matches(grid: Array) -> Array[Vector2i]:
	var matches: Array[Vector2i] = []
	var height: int = grid.size()
	var width: int = grid[0].size()

	# Check all possible 2x2 positions
	for y in range(height - 1):
		for x in range(width - 1):
			var c0: int = grid[y][x]

			# Check if all four cells match
			if (grid[y][x + 1] == c0 and
				grid[y + 1][x] == c0 and
				grid[y + 1][x + 1] == c0):
				matches.append(Vector2i(x, y))

	return matches
