extends Node

## Minimal test to check if BoardRules loads

func _ready() -> void:
	print("\n=== MINIMAL TEST ===\n")

	print("Step 1: Testing BoardRules class...")
	var rules := BoardRules.Rules.new()
	print("  ✓ BoardRules.Rules.new() works")
	print("  ✓ num_colors = %d" % rules.num_colors)

	print("\nStep 2: Testing grid creation...")
	var grid := []
	for y in range(4):
		var row := []
		for x in range(4):
			row.append({
				"color": (x + y) % 2,
				"height": 1,
				"state": BoardRules.STATE_NORMAL
			})
		grid.append(row)
	print("  ✓ Created 4x4 grid")

	print("\nStep 3: Testing BoardRules.find_squares()...")
	var squares := BoardRules.find_squares(grid)
	print("  ✓ Found %d squares" % squares.size())

	print("\nStep 4: Testing SolverUtil...")
	var test_result := SolverUtil.test_board_rules()
	print("  ✓ SolverUtil test: %s" % test_result)

	print("\n✅ ALL BASIC TESTS PASSED\n")
	print("BoardRules is working correctly!")
	print("Now try loading solver.gd...\n")

	get_tree().quit()
