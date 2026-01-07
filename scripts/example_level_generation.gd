extends Node

## Complete example showing all ways to generate levels
## NOTE: Only runs in debug builds to avoid production issues

func _ready() -> void:
	if not OS.is_debug_build():
		return  # Don't run examples in production builds
	
	print("\n" + "=".repeat(60))
	print("  LEVEL GENERATION SYSTEM - COMPLETE EXAMPLES")
	print("=".repeat(60) + "\n")

	# EXAMPLE 1: Simple automatic generation (recommended)
	example_1_automatic()

	# EXAMPLE 2: Custom rules from preset
	example_2_custom_from_preset()

	# EXAMPLE 3: Build rules from scratch
	example_3_build_from_scratch()

	# EXAMPLE 4: Custom templates
	example_4_custom_templates()

	# EXAMPLE 5: Generate campaign (levels 1-10)
	example_5_campaign()

	print("\n" + "=".repeat(60))
	print("  ALL EXAMPLES COMPLETE")
	print("=".repeat(60) + "\n")

## EXAMPLE 1: Automatic generation - simplest approach
func example_1_automatic() -> void:
	print("\n--- EXAMPLE 1: Automatic Generation ---")
	print("Just call create_level(id) - difficulty assigned automatically\n")

	var level := LevelData.create_level(5)
	print("Generated Level %d:" % level.level_id)
	print("  Board: %dx%d" % [level.width, level.height])
	print("  Move limit: %d" % level.move_limit)
	print("  Squares goal: %d" % level.squares_goal)
	print("  Locking: %s" % ("Yes" if level.lock_on_match else "No"))

## EXAMPLE 2: Start from preset and customize
func example_2_custom_from_preset() -> void:
	print("\n--- EXAMPLE 2: Customize from Preset ---")
	print("Start with difficulty preset, then tweak specific values\n")

	# Start with difficulty 3 (medium) preset
	var rules := LevelRules.create_for_difficulty(3)

	# Customize specific values
	rules.board_width = 6  # Make it wider
	rules.num_colors = 4   # Add another color
	rules.move_limit = 15  # Give more moves

	var level := LevelData.create_from_rules(50, rules)
	print("Generated Custom Level %d:" % level.level_id)
	print("  Board: %dx%d (customized from 5x5)" % [level.width, level.height])
	print("  Colors: 4 (customized from 3)")
	print("  Move limit: %d (customized from 10)" % level.move_limit)

## EXAMPLE 3: Build rules completely from scratch
func example_3_build_from_scratch() -> void:
	print("\n--- EXAMPLE 3: Build Rules from Scratch ---")
	print("Create LevelRules with complete custom configuration\n")

	var rules := LevelRules.custom()

	# Board configuration
	rules.board_width = 7
	rules.board_height = 7
	rules.num_colors = 5
	rules.allowed_colors = [0, 1, 2, 3, 4]

	# Solution constraints
	rules.min_solution_moves = 5
	rules.max_solution_moves = 10
	rules.target_solution_moves = 7

	# Win conditions
	rules.squares_goal = 3
	rules.move_limit = 20
	rules.target_score = 30

	# Gameplay mechanics
	rules.lock_on_match = true
	rules.clear_locked_squares = false
	rules.enable_gravity = false
	rules.refill_from_top = false

	var level := LevelData.create_from_rules(999, rules)
	print("Generated Expert Level %d:" % level.level_id)
	print("  Board: %dx%d" % [level.width, level.height])
	print("  Colors: %d" % rules.num_colors)
	print("  Solution range: %d-%d moves" % [rules.min_solution_moves, rules.max_solution_moves])
	print("  Goal: %d squares in %d moves" % [level.squares_goal, level.move_limit])

## EXAMPLE 4: Use custom templates for curated difficulty
func example_4_custom_templates() -> void:
	print("\n--- EXAMPLE 4: Custom Templates ---")
	print("Define exact goal state and solution moves\n")

	var rules := LevelRules.create_for_difficulty(2)

	# Add custom template - this ensures exact solution path
	rules.templates = [
		{
			"goal": [
				[1, 1, 0, 2],
				[1, 1, 2, 0],
				[0, 2, 1, 2],
				[2, 0, 0, 1]
			],
			"moves": [
				{"from": Vector2i(0, 0), "to": Vector2i(1, 0)},
				{"from": Vector2i(0, 1), "to": Vector2i(0, 0)}
			]
		}
	]

	var level := LevelData.create_from_rules(100, rules)
	print("Generated Template Level %d:" % level.level_id)
	print("  Uses hand-crafted goal state with 2-move solution")
	print("  Non-critical tiles randomized for variety")
	print("  Guaranteed solvable with exact difficulty")

## EXAMPLE 5: Generate full campaign (levels 1-10)
func example_5_campaign() -> void:
	print("\n--- EXAMPLE 5: Generate Campaign ---")
	print("Create progressive levels 1-10 with automatic difficulty\n")

	var campaign: Array[LevelData] = []

	for i in range(1, 11):
		var level := LevelData.create_level(i)
		campaign.append(level)

	print("Generated 10-level campaign:")
	print("\n  Lvl | Board | Clrs | Goal | Limit | Lock")
	print("  " + "-".repeat(46))
	for level in campaign:
		print("  %2d  | %dx%d  |  %d   |  %d   |  %2d   | %s" % [
			level.level_id,
			level.width,
			level.height,
			_count_colors(level.starting_grid),
			level.squares_goal,
			level.move_limit,
			"Yes" if level.lock_on_match else "No "
		])

	print("\n  Difficulty progression:")
	print("    Levels 1-2: Tutorial (1-move, 2 colors)")
	print("    Levels 3-4: Easy (2-4 moves, 3 colors)")
	print("    Levels 5-6: Medium (3-5 moves, 3 colors, larger board)")
	print("    Levels 7-8: Medium-Hard (3-6 moves, 4 colors, 2 squares)")
	print("    Levels 9-10: Hard (4-8 moves, 4 colors, 6x6 board)")

## Helper: Count unique colors in grid
func _count_colors(grid: Array) -> int:
	if grid.size() == 0:
		return 0
	var colors := {}
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var color: int = grid[y][x]
			if color >= 0:
				colors[color] = true
	return colors.size()
