extends Node

## Test the LevelRules system and automatic level generation

func _ready() -> void:
	print("\n=== Testing Level Rules System ===\n")

	# Test 1: Generate levels 1-10 with automatic difficulty progression
	print("TEST 1: Automatic Difficulty Progression")
	print("=" * 50)
	for i in range(1, 11):
		var level := LevelData.create_level(i)
		print("Level %d: %dx%d board, %d colors, goal=%d squares, limit=%d moves" % [
			level.level_id,
			level.width,
			level.height,
			_count_colors(level.starting_grid),
			level.squares_goal,
			level.move_limit
		])

	# Test 2: Create custom rules
	print("\n\nTEST 2: Custom Rules")
	print("=" * 50)
	var custom_rules := LevelRules.custom()
	custom_rules.board_width = 5
	custom_rules.board_height = 5
	custom_rules.num_colors = 4
	custom_rules.min_solution_moves = 3
	custom_rules.max_solution_moves = 6
	custom_rules.squares_goal = 2
	custom_rules.move_limit = 15
	custom_rules.lock_on_match = true

	print("Custom rules:")
	custom_rules.print_rules()

	var custom_level := LevelData.create_from_rules(99, custom_rules)
	print("\nGenerated custom level %d:" % custom_level.level_id)
	print("Grid size: %dx%d" % [custom_level.width, custom_level.height])
	_print_grid(custom_level.starting_grid)

	# Check for starting matches
	var matches := _find_matches(custom_level.starting_grid)
	if matches.size() > 0:
		print("❌ ERROR: Starting grid has %d matches!" % matches.size())
	else:
		print("✅ No starting matches")

	# Test 3: Verify difficulty presets
	print("\n\nTEST 3: Difficulty Presets")
	print("=" * 50)
	for difficulty in range(1, 6):
		var rules := LevelRules.create_for_difficulty(difficulty)
		print("\nDifficulty %d:" % difficulty)
		print("  Board: %dx%d" % [rules.board_width, rules.board_height])
		print("  Colors: %d" % rules.num_colors)
		print("  Solution: %d-%d moves (target: %d)" % [
			rules.min_solution_moves,
			rules.max_solution_moves,
			rules.target_solution_moves
		])
		print("  Goal: %d square(s), limit: %d moves" % [rules.squares_goal, rules.move_limit])
		print("  Locking: %s" % ("Yes" if rules.lock_on_match else "No"))

	print("\n=== All Tests Complete ===")

func _count_colors(grid: Array) -> int:
	var colors := {}
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var color: int = grid[y][x]
			if color >= 0:
				colors[color] = true
	return colors.size()

func _find_matches(grid: Array) -> Array[Vector2i]:
	var matches: Array[Vector2i] = []
	if grid.size() == 0:
		return matches
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
