# Level Rules System Guide

## Overview

The Level Rules system allows you to define difficulty parameters and generate levels procedurally based on those rules. This replaces manual level design with data-driven generation.

## Quick Start

### Automatic Generation (Recommended)

Just call `LevelData.create_level(id)` - it automatically assigns difficulty based on level number:

```gdscript
# Automatically generates levels with progressive difficulty
var level_1 = LevelData.create_level(1)  # Difficulty 1 - tutorial
var level_5 = LevelData.create_level(5)  # Difficulty 3 - medium
var level_10 = LevelData.create_level(10) # Difficulty 5 - hard
```

**Progression:**
- Levels 1-2: Difficulty 1 (tutorial)
- Levels 3-4: Difficulty 2 (easy)
- Levels 5-6: Difficulty 3 (medium)
- Levels 7-8: Difficulty 4 (medium-hard)
- Levels 9+: Difficulty 5 (hard)

### Custom Rules

Create your own difficulty settings:

```gdscript
# Method 1: Start from a preset
var rules = LevelRules.create_for_difficulty(3)
rules.board_width = 6  # Override specific values
rules.num_colors = 4

# Method 2: Build from scratch
var custom_rules = LevelRules.custom()
custom_rules.board_width = 5
custom_rules.board_height = 5
custom_rules.num_colors = 3
custom_rules.min_solution_moves = 2
custom_rules.max_solution_moves = 4
custom_rules.squares_goal = 1
custom_rules.move_limit = 10
custom_rules.lock_on_match = true

# Generate level from rules
var level = LevelData.create_from_rules(42, custom_rules)
```

## LevelRules Properties

### Board Configuration

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `board_width` | int | Grid width | `4` |
| `board_height` | int | Grid height | `4` |
| `num_colors` | int | Number of tile colors | `3` |
| `allowed_colors` | Array[int] | Color IDs to use | `[0, 1, 2]` |

### Solution Constraints

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `min_solution_moves` | int | Minimum moves to solve | `2` |
| `max_solution_moves` | int | Maximum moves to solve | `5` |
| `target_solution_moves` | int | Preferred solution length | `3` |

### Win Conditions

| Property | Type | Description | Example |
|----------|------|-------------|---------|
| `squares_goal` | int | 2x2 squares needed to win | `1` |
| `move_limit` | int | Player move limit (0 = unlimited) | `10` |
| `target_score` | int | Target score for completion | `20` |

### Gameplay Mechanics

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `lock_on_match` | bool | Lock matched tiles? | `false` |
| `clear_locked_squares` | bool | Remove locked tiles? | `false` |
| `enable_gravity` | bool | Apply gravity after clears? | `false` |
| `refill_from_top` | bool | Spawn new tiles from top? | `false` |

### Advanced Options

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `use_templates` | bool | Use hand-crafted templates? | `true` |
| `templates` | Array | Custom goal+solution pairs | `[]` |
| `max_generation_attempts` | int | Retries before fallback | `50` |
| `allow_procedural_fallback` | bool | Use pure procedural if templates fail? | `true` |

## Difficulty Presets

### Difficulty 1: Tutorial
```
Board: 4x4
Colors: 2
Solution: 1 move
Goal: 1 square
Move limit: 1
Locking: No
```

### Difficulty 2: Easy
```
Board: 4x4
Colors: 3
Solution: 2-4 moves
Goal: 1 square
Move limit: 8
Locking: Yes
```

### Difficulty 3: Medium
```
Board: 5x5
Colors: 3
Solution: 3-5 moves
Goal: 1 square
Move limit: 10
Locking: Yes
```

### Difficulty 4: Medium-Hard
```
Board: 5x5
Colors: 4
Solution: 3-6 moves
Goal: 2 squares
Move limit: 12
Locking: Yes
```

### Difficulty 5: Hard
```
Board: 6x6
Colors: 4
Solution: 4-8 moves
Goal: 2 squares
Move limit: 15
Locking: Yes
```

## Advanced: Template-Based Generation

Templates let you define the goal state and solution moves, while the system fills in the rest:

```gdscript
var rules = LevelRules.create_for_difficulty(2)

# Define a custom template
rules.templates = [
	{
		"goal": [
			[0, 0, 1, 2],
			[0, 0, 2, 1],
			[1, 2, 1, 2],
			[2, 1, 2, 1]
		],
		"moves": [
			{"from": Vector2i(1, 0), "to": Vector2i(2, 0)},
			{"from": Vector2i(0, 0), "to": Vector2i(1, 0)}
		]
	}
]

var level = LevelData.create_from_rules(10, rules)
```

The system will:
1. Apply moves in reverse to get base starting state
2. Identify critical cells (involved in solution)
3. Randomize non-critical cells
4. Validate the puzzle is solvable
5. Fall back to procedural if validation fails

## Generation Methods

The system uses a hybrid approach:

```
┌─────────────────────────────────┐
│   create_level(id)              │
│   or create_from_rules(id, rules)│
└────────────┬────────────────────┘
             │
             ▼
    ┌────────────────┐
    │ Templates set? │
    └───┬────────┬───┘
        │ YES    │ NO
        ▼        ▼
   ┌─────────┐  ┌──────────────┐
   │ Hybrid  │  │ Procedural   │
   │ Method  │  │ Method       │
   └────┬────┘  └──────┬───────┘
        │              │
        ▼              ▼
   ┌─────────────────────┐
   │ Solver.generate_    │
   │ validated_puzzle()  │
   └─────────┬───────────┘
             │
             ▼
        ┌─────────┐
        │ Success?│
        └───┬─┬───┘
            │ │
         YES│ │NO
            │ └───────────┐
            ▼             ▼
      ┌──────────┐  ┌──────────────┐
      │ Return   │  │ Procedural   │
      │ Level    │  │ Fallback     │
      └──────────┘  └──────────────┘
```

## Examples

### Example 1: Create 10 Progressive Levels

```gdscript
func load_campaign() -> void:
	for i in range(1, 11):
		var level = LevelData.create_level(i)
		levels.append(level)
		print("Level %d: %dx%d, %d colors" % [i, level.width, level.height, ???])
```

### Example 2: Custom Challenge Level

```gdscript
func create_challenge_level() -> LevelData:
	var rules = LevelRules.custom()
	rules.board_width = 6
	rules.board_height = 6
	rules.num_colors = 5
	rules.min_solution_moves = 5
	rules.max_solution_moves = 10
	rules.squares_goal = 3
	rules.move_limit = 20
	rules.lock_on_match = true

	return LevelData.create_from_rules(999, rules)
```

### Example 3: Modify Preset

```gdscript
func create_custom_easy_level() -> LevelData:
	var rules = LevelRules.create_for_difficulty(2)
	rules.board_width = 5  # Make it slightly bigger
	rules.move_limit = 12  # Give more moves

	return LevelData.create_from_rules(50, rules)
```

## Tips

1. **Start with presets**: Use `create_for_difficulty()` and tweak from there
2. **Test generation**: The solver validates puzzles automatically
3. **Use templates for curated difficulty**: Templates ensure specific solution paths
4. **Fallback is safe**: If template fails, procedural generation kicks in
5. **Balance solution moves with move limit**: Give players 2-3x the minimum moves

## Troubleshooting

**Q: Level generation is slow**
- Reduce `max_generation_attempts` (default: 50)
- Use simpler constraints (fewer colors, smaller board)

**Q: Levels are too easy/hard**
- Adjust `min_solution_moves` and `max_solution_moves`
- Change `num_colors` (more colors = harder)
- Modify `move_limit`

**Q: Generation keeps failing**
- Check your templates have valid 2x2 matches in goal state
- Ensure constraints aren't too strict (e.g., 1-move solution on 6x6 board)
- Enable `allow_procedural_fallback`

**Q: Want consistent difficulty**
- Use templates instead of pure procedural
- Templates guarantee specific solution paths
