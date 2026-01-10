extends Node

## Quick solver test - attach to a Node and run scene (F6)

func _ready() -> void:
	print("\n=== QUICK SOLVER TEST ===\n")

	# Test 1: Simple 1-move puzzle
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
	rules.num_colors = 2

	print("Testing 1-move puzzle...")
	var result := Solver.solve_detailed(grid, 5, rules, 0, 10000, 1)

	print("  ✓ Solvable: %s" % result.solvable)
	print("  ✓ Solution length: %d moves" % result.solution_length)
	print("  ✓ States explored: %d" % result.states_explored)
	print("  ✓ Valid swaps found: %d" % result.valid_swaps_found)

	if result.solvable and result.solution_length == 1:
		print("\n✅ TEST PASSED: Solver works correctly!")
		print("   Solution: %s" % result.solution_path)
	else:
		print("\n❌ TEST FAILED: Expected 1-move solution")

	print("\n=== TEST COMPLETE ===\n")

	# Quit after test (optional)
	get_tree().quit()
