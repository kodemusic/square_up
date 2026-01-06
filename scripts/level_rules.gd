extends RefCounted

## Level generation rules - defines difficulty parameters
## Used to procedurally generate levels with specific constraints

class_name LevelRules

## Board size
var board_width: int = 5  # DEFAULT: 5x5 board
var board_height: int = 5  # DEFAULT: 5x5 board

## Color constraints
var num_colors: int = 2  # Number of different tile colors
var allowed_colors: Array[int] = [0, 1]  # Which color IDs to use

## Solution constraints
var min_solution_moves: int = 1  # Minimum moves to solve
var max_solution_moves: int = 3  # Maximum moves to solve
var target_solution_moves: int = 2  # Preferred solution length

## Win conditions
var squares_goal: int = 1  # Number of 2x2 matches needed
var move_limit: int = 5  # Player move limit (0 = unlimited)
var target_score: int = 10  # Target score for stars/completion

## Gameplay mechanics
var lock_on_match: bool = false  # Lock matched tiles?
var clear_locked_squares: bool = false  # Remove locked tiles?
var enable_gravity: bool = false  # Apply gravity after clears?
var refill_from_top: bool = false  # Spawn new tiles?

## Generation constraints
var max_generation_attempts: int = 10  # REDUCED: How many tries before fallback (was 50)
var allow_procedural_fallback: bool = true  # Use full procedural if hybrid fails?
var skip_validation: bool = false  # Skip solver validation for faster generation (use with caution)

## Template-based generation (optional)
var use_templates: bool = true  # Use hand-crafted templates?
var templates: Array = []  # Custom goal grids + solution moves

## Helper: Create rules for a specific difficulty tier
static func create_for_difficulty(difficulty: int) -> LevelRules:
	var rules := LevelRules.new()

	match difficulty:
		1:  # Tutorial - very easy
			rules.board_width = 4
			rules.board_height = 4
			rules.num_colors = 2
			rules.allowed_colors = [0, 1]
			rules.min_solution_moves = 1
			rules.max_solution_moves = 1
			rules.target_solution_moves = 1
			rules.squares_goal = 1
			rules.move_limit = 1
			rules.lock_on_match = false
			rules.max_generation_attempts = 5  # Fast generation

		2:  # Easy - introduce 3rd color
			rules.board_width = 4
			rules.board_height = 4
			rules.num_colors = 3
			rules.allowed_colors = [0, 1, 2]
			rules.min_solution_moves = 2
			rules.max_solution_moves = 3  # REDUCED from 4 for faster BFS
			rules.target_solution_moves = 2
			rules.squares_goal = 1
			rules.move_limit = 8
			rules.lock_on_match = true
			rules.max_generation_attempts = 10

		3:  # Medium - stay at 4x4 or 5x5
			rules.board_width = 5
			rules.board_height = 5
			rules.num_colors = 3
			rules.allowed_colors = [0, 1, 2]
			rules.min_solution_moves = 2  # REDUCED from 3
			rules.max_solution_moves = 4  # REDUCED from 5 for faster BFS
			rules.target_solution_moves = 3
			rules.squares_goal = 1
			rules.move_limit = 10
			rules.lock_on_match = true
			rules.max_generation_attempts = 10

		4:  # Medium-hard - keep 5x5, add complexity via colors/goals
			rules.board_width = 5
			rules.board_height = 5
			rules.num_colors = 4
			rules.allowed_colors = [0, 1, 2, 3]
			rules.min_solution_moves = 2  # REDUCED from 3
			rules.max_solution_moves = 4  # REDUCED from 6 for faster BFS
			rules.target_solution_moves = 3
			rules.squares_goal = 2  # Difficulty comes from 2 squares, not board size
			rules.move_limit = 12
			rules.lock_on_match = true
			rules.max_generation_attempts = 10

		5:  # Hard - max 5x5, difficulty via mechanics
			rules.board_width = 5  # REDUCED from 6x6 - avoids BFS explosion
			rules.board_height = 5  # REDUCED from 6x6
			rules.num_colors = 4
			rules.allowed_colors = [0, 1, 2, 3]
			rules.min_solution_moves = 2  # REDUCED from 4
			rules.max_solution_moves = 4  # REDUCED from 8 - critical for performance
			rules.target_solution_moves = 3
			rules.squares_goal = 2
			rules.move_limit = 15
			rules.lock_on_match = true
			rules.max_generation_attempts = 10

		_:  # Default to medium
			return create_for_difficulty(3)

	return rules

## Helper: Create custom rules
static func custom() -> LevelRules:
	return LevelRules.new()

## Print rules for debugging
func print_rules() -> void:
	print("=== Level Rules ===")
	print("Board: %dx%d" % [board_width, board_height])
	print("Colors: %d (IDs: %s)" % [num_colors, allowed_colors])
	print("Solution moves: %d-%d (target: %d)" % [min_solution_moves, max_solution_moves, target_solution_moves])
	print("Squares goal: %d" % squares_goal)
	print("Move limit: %d" % move_limit)
	print("Lock on match: %s" % lock_on_match)
	print("==================")
