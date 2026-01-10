## Minimal solver test to isolate parse issues
class_name SolverUtil

static func test_board_rules() -> bool:
	print("Testing BoardRules...")

	# Create a simple grid
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

	# Test find_squares
	var squares := BoardRules.find_squares(grid)
	print("  Found %d squares" % squares.size())

	# Test Rules creation
	var rules := BoardRules.Rules.new()
	print("  Created rules: %s" % rules)

	return true
