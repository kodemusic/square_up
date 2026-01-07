extends Node

## Debug script to find which Level 2 puzzle definition creates starting matches
## NOTE: Only runs in debug builds to avoid production issues

func _ready() -> void:
	if not OS.is_debug_build():
		return  # Don't run tests in production builds
	
	print("\n=== Level 2 Puzzle Validation ===\n")

	# All puzzle definitions from _get_level_2_grid
	var puzzle_defs: Array = [
		# Puzzle 1
		{
			"name": "Puzzle 1",
			"goal": [
				[0, 0, 1, 2],
				[0, 0, 2, 1],
				[1, 2, 1, 0],
				[2, 1, 0, 2]
			],
			"moves": [
				{"from": Vector2i(0, 0), "to": Vector2i(1, 0)},
				{"from": Vector2i(0, 1), "to": Vector2i(0, 0)}
			]
		},
		# Puzzle 2
		{
			"name": "Puzzle 2",
			"goal": [
				[1, 2, 0, 1],
				[2, 0, 1, 2],
				[0, 1, 1, 1],
				[2, 0, 1, 1]
			],
			"moves": [
				{"from": Vector2i(2, 2), "to": Vector2i(3, 2)},
				{"from": Vector2i(2, 3), "to": Vector2i(2, 2)}
			]
		},
		# Puzzle 3
		{
			"name": "Puzzle 3",
			"goal": [
				[2, 1, 0, 2],
				[0, 2, 2, 1],
				[1, 2, 2, 0],
				[2, 0, 1, 1]
			],
			"moves": [
				{"from": Vector2i(1, 1), "to": Vector2i(2, 1)},
				{"from": Vector2i(1, 2), "to": Vector2i(1, 1)},
				{"from": Vector2i(2, 2), "to": Vector2i(1, 2)}
			]
		},
		# Puzzle 4
		{
			"name": "Puzzle 4",
			"goal": [
				[1, 0, 2, 1],
				[2, 1, 1, 0],
				[0, 1, 1, 2],
				[1, 2, 0, 0]
			],
			"moves": [
				{"from": Vector2i(1, 1), "to": Vector2i(2, 1)},
				{"from": Vector2i(1, 2), "to": Vector2i(1, 1)}
			]
		},
		# Puzzle 5
		{
			"name": "Puzzle 5",
			"goal": [
				[0, 0, 2, 1],
				[0, 0, 1, 2],
				[1, 2, 0, 1],
				[2, 1, 2, 0]
			],
			"moves": [
				{"from": Vector2i(0, 0), "to": Vector2i(0, 1)},
				{"from": Vector2i(1, 0), "to": Vector2i(0, 0)},
				{"from": Vector2i(1, 1), "to": Vector2i(1, 0)}
			]
		}
	]

	for puzzle_def in puzzle_defs:
		print("=== %s ===" % puzzle_def["name"])

		# Show goal grid
		print("GOAL GRID:")
		_print_grid(puzzle_def["goal"])

		# Check goal has match
		var goal_matches := _find_matches(puzzle_def["goal"])
		print("Goal matches: %d" % goal_matches.size())
		for match_pos in goal_matches:
			print("  Match at (%d,%d)" % [match_pos.x, match_pos.y])

		# Apply reverse-solve
		var starting_grid := LevelData._copy_grid(puzzle_def["goal"])
		var moves: Array = puzzle_def["moves"]

		print("\nApplying moves in REVERSE:")
		for i in range(moves.size() - 1, -1, -1):
			var move: Dictionary = moves[i]
			var from: Vector2i = move["from"]
			var to: Vector2i = move["to"]
			print("  Swap (%d,%d) <-> (%d,%d)" % [from.x, from.y, to.x, to.y])
			LevelData._swap_cells(starting_grid, from, to)

		# Show starting grid
		print("\nSTARTING GRID:")
		_print_grid(starting_grid)

		# Check starting grid for matches
		var starting_matches := _find_matches(starting_grid)
		if starting_matches.size() == 0:
			print("✅ VALID: No starting matches\n")
		else:
			print("❌ BROKEN: %d starting matches found!" % starting_matches.size())
			for match_pos in starting_matches:
				var color: int = starting_grid[match_pos.y][match_pos.x]
				print("  Match at (%d,%d) with color %d" % [match_pos.x, match_pos.y, color])
			print("")

	print("=== Validation Complete ===")

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

func _print_grid(grid: Array) -> void:
	for y in range(grid.size()):
		var row_str := "  "
		for x in range(grid[y].size()):
			var color_id: int = grid[y][x]
			row_str += str(color_id) + " "
		print(row_str)
