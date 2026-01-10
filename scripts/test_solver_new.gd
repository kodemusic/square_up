extends Node

## Test script for the updated Solver with BoardRules integration
## Run this script to validate that the solver correctly:
## 1. Only explores valid swaps (that create squares)
## 2. Handles cascade simulations properly
## 3. Validates levels according to design rules

func _ready() -> void:
	print("\n" + "=".repeat(70))
	print("  SOLVER + BOARD RULES TEST SUITE")
	print("=".repeat(70) + "\n")

	test_simple_1_move_puzzle()
	test_no_valid_moves()
	test_multiple_valid_moves()
	test_cascade_level()
	test_level_validation()

	print("\n" + "=".repeat(70))
	print("  ALL TESTS COMPLETE")
	print("=".repeat(70) + "\n")

## Test 1: Simple 1-move puzzle (no cascades)
func test_simple_1_move_puzzle() -> void:
	print("--- Test 1: Simple 1-Move Puzzle (No Cascades) ---")

	# Simple grid where swapping (1,0) with (2,0) creates a 2x2 match of 0s
	var grid := [
		[0, 1, 0, 1],
		[0, 0, 1, 0],
		[1, 0, 1, 0],
		[1, 1, 0, 1]
	]

	# Create simple rules (no cascades)
	var rules := BoardRules.Rules.new()
	rules.lock_on_match = false
	rules.clear_locked_squares = false
	rules.enable_gravity = false
	rules.refill_from_top = false

	var result := Solver.solve_detailed(grid, 5, rules, 0, 10000, 1)

	print("  Solvable: %s" % result.solvable)
	print("  Solution length: %d moves" % result.solution_length)
	print("  States explored: %d" % result.states_explored)
	print("  Valid swaps found: %d" % result.valid_swaps_found)

	if result.solvable and result.solution_length == 1:
		print("  ✅ PASS: Found 1-move solution")
		print("  Solution: %s" % result.solution_path)
	else:
		print("  ❌ FAIL: Expected 1-move solution")

	print()

## Test 2: Dead board (no valid moves)
func test_no_valid_moves() -> void:
	print("--- Test 2: Dead Board (No Valid Moves) ---")

	# Grid where no single swap creates a 2x2 match
	var grid := [
		[0, 1, 0, 1],
		[1, 0, 1, 0],
		[0, 1, 0, 1],
		[1, 0, 1, 0]
	]

	var rules := BoardRules.Rules.new()
	var state := Solver.BoardState.from_simple_grid(grid)
	var valid_moves := Solver._count_valid_moves(state)

	print("  Valid moves: %d" % valid_moves)

	if valid_moves == 0:
		print("  ✅ PASS: Correctly identified dead board")
	else:
		print("  ❌ FAIL: Should have 0 valid moves")

	print()

## Test 3: Multiple valid moves (choice)
func test_multiple_valid_moves() -> void:
	print("--- Test 3: Multiple Valid Moves ---")

	# Grid with multiple possible square-forming swaps
	var grid := [
		[0, 0, 1, 1],
		[0, 1, 1, 0],
		[1, 0, 0, 1],
		[1, 1, 0, 0]
	]

	var rules := BoardRules.Rules.new()
	var state := Solver.BoardState.from_simple_grid(grid)
	var valid_moves := Solver._count_valid_moves(state)

	print("  Valid moves: %d" % valid_moves)

	if valid_moves >= 2:
		print("  ✅ PASS: Found multiple valid moves (player has choice)")
	else:
		print("  ❌ FAIL: Expected at least 2 valid moves")

	# Validate the level
	var validation := Solver.validate_level(grid, 5, rules, 1, 2, 1)
	print("  Validation: %s" % ("PASS" if validation["valid"] else "FAIL"))
	print("  Initial valid moves: %d" % validation["initial_valid_moves"])

	print()

## Test 4: Cascade level simulation
func test_cascade_level() -> void:
	print("--- Test 4: Cascade Level (Gravity + Refill) ---")

	# Simple starting grid
	var grid := [
		[0, 1, 0],
		[0, 0, 1],
		[1, 0, 0]
	]

	# Create cascade rules
	var rules := BoardRules.Rules.new()
	rules.lock_on_match = true
	rules.clear_locked_squares = true
	rules.enable_gravity = true
	rules.refill_from_top = true
	rules.num_colors = 2

	var result := Solver.solve_detailed(grid, 5, rules, 12345, 5000, 1)

	print("  Solvable: %s" % result.solvable)
	print("  Solution length: %d moves" % result.solution_length)
	print("  Total squares created: %d (including cascades)" % result.total_squares)
	print("  States explored: %d" % result.states_explored)

	if result.solvable:
		print("  ✅ PASS: Solver handled cascade mechanics")
	else:
		print("  ⚠ INFO: No solution found (might be unsolvable with this seed)")

	print()

## Test 5: Level validation rules
func test_level_validation() -> void:
	print("--- Test 5: Level Validation Rules ---")

	# Test case 1: Valid level
	print("  Test 5a: Valid level (2+ moves, solvable)")
	var grid1 := [
		[0, 1, 0, 1],
		[0, 0, 1, 0],
		[1, 0, 1, 0],
		[1, 1, 0, 1]
	]

	var rules := BoardRules.Rules.new()
	var validation1 := Solver.validate_level(grid1, 10, rules, 1, 2, 1)
	print("    Valid: %s" % validation1["valid"])
	print("    Errors: %s" % validation1["errors"])

	# Test case 2: Level with starting match (invalid)
	print("\n  Test 5b: Level with starting match (should fail)")
	var grid2 := [
		[0, 0, 1, 1],
		[0, 0, 1, 0],
		[1, 0, 1, 0],
		[1, 1, 0, 1]
	]

	var validation2 := Solver.validate_level(grid2, 10, rules, 1, 2, 1)
	print("    Valid: %s (should be false)" % validation2["valid"])
	print("    Errors: %s" % validation2["errors"])

	if not validation2["valid"] and validation2["has_starting_match"]:
		print("    ✅ PASS: Correctly rejected level with starting match")
	else:
		print("    ❌ FAIL: Should reject level with starting match")

	print()
