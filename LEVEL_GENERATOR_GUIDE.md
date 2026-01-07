# Square Up Level Generator Guide

## Overview

The Level Generator is a standalone tool for creating valid Square Up puzzles with guaranteed solutions using reverse-solve techniques and bag randomization for even color distribution.

## Handcrafted Levels First! 🎨

**IMPORTANT:** The game always uses handcrafted levels when available (`prefer_handcrafted = true` by default).

### Workflow for Adding Handcrafted Levels

1. **Generate a level** using the Level Generator
2. **Copy the GDScript code** from the console output
3. **Paste into** `scripts/level_data.gd`
4. **Customize** the level parameters (name, moves, score, etc.)
5. **Add to match statement** in `_generate_level_internal()`

The generator outputs ready-to-paste code that you can directly add to `level_data.gd`!

## Quick Start

### Method 1: Run in Godot Editor

1. Open Godot and load the Square Up project
2. In the FileSystem panel, navigate to `scenes/LevelGeneratorTest.tscn`
3. Double-click to open the scene
4. Press **F6** to run the current scene
5. Check the **Output** panel for generated puzzles

### Method 2: Use from Code

```gdscript
# Create generator instance
var generator = LevelGenerator.new()

# Generate a level
var level = generator.generate_level(width, height, num_colors, target_moves)

# Check if generation succeeded
if level and level["is_valid"]:
    print("Starting Grid:")
    for row in level["starting_grid"]:
        print(row)
```

### Method 3: Attach to a Node

1. Create a Node in your scene
2. Attach `scripts/level_generator.gd` as a script
3. Run the scene - it will automatically generate example levels

## Features

### 🎲 Shuffled Bag Randomization

The generator uses a **ColorBag** system (similar to Tetris piece selection) to ensure even color distribution:

- Colors are drawn from a shuffled bag
- When the bag is empty, it refills and reshuffles
- Prevents color clustering
- Creates more balanced puzzles

**Example:**
```gdscript
# Create a bag with 3 colors, bag size 2x (6 colors total per bag)
var bag = ColorBag.new([0, 1, 2], 2)

# Draw colors - guarantees even distribution
var color1 = bag.draw()  # Random from shuffled bag
var color2 = bag.draw()  # Different color (more likely)
```

### 🔄 Reverse-Solve Technique

Puzzles are guaranteed solvable because they're created backwards:

1. Generate a random **goal state** WITH a 2x2 match
2. Define **solution moves** that break the match
3. Apply moves in **reverse** to create the starting grid
4. Verify starting grid has **no matches**

This ensures every puzzle has a known solution!

### ✅ Validation

Generated puzzles are validated to ensure:
- ✓ Starting grid has NO 2x2 matches
- ✓ Solution moves are valid
- ✓ Applying solution creates the expected match
- ✓ Color distribution is balanced

## Generator Settings

The `LevelGenerator` class has configurable settings:

```gdscript
var generator = LevelGenerator.new()

# Enable/disable bag randomization (default: true)
generator.use_bag_randomization = true

# Bag multiplier - how many color sets per bag (default: 2)
generator.bag_multiplier = 2

# Maximum generation attempts before giving up (default: 50)
generator.max_attempts = 50

# Enable debug output (default: true)
generator.debug_output = true
```

## Level Parameters

When generating a level, you specify:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `width` | Board width in tiles | 4, 5, 6 |
| `height` | Board height in tiles | 4, 5, 6 |
| `num_colors` | Number of different colors | 2, 3, 4 |
| `target_moves` | Solution length in moves | 1, 3, 5 |

**Recommendations:**
- **Tutorial levels**: 4x4, 2 colors, 1 move
- **Intermediate**: 5x5, 3 colors, 3 moves
- **Advanced**: 6x6, 4 colors, 5 moves

## Complete Example: Adding a Handcrafted Level

### Step 1: Generate the Level

Run `LevelGeneratorTest.tscn` (F6) and you'll see:

```
--- Example 1: Tutorial Level (4x4, 2 colors, 1 move) ---
  ✓ Generated valid puzzle in 3 attempts
  Dimensions: 4x4
  Colors: 2
  Target Moves: 1

  Starting Grid:
    0 1 1 0
    1 0 1 1
    0 1 0 0
    1 1 0 1

  ✓ No starting matches (valid puzzle)

============================================================
  📋 COPY-PASTE CODE (add to level_data.gd)
============================================================

## Level X: [Your Description Here]
static func create_level_X() -> LevelData:
	var level := LevelData.new()
	level.level_id = X
	level.level_name = "[Your Level Name]"
	level.width = 4
	level.height = 4
	level.num_colors = 2
	level.move_limit = 1  # Adjust as needed
	level.target_score = 10  # Adjust as needed
	level.squares_goal = 1  # Adjust as needed

	# Starting grid (generated with bag randomization)
	level.starting_grid = [
		[0, 1, 1, 0],
		[1, 0, 1, 1],
		[0, 1, 0, 0],
		[1, 1, 0, 1]
	]

	# Game mechanics (adjust as needed)
	level.lock_on_match = false
	level.clear_locked_squares = false
	level.enable_gravity = false
	level.refill_from_top = false

	return level

============================================================
```

### Step 2: Copy and Customize

Copy the generated code and paste it into `level_data.gd`. Then customize:

```gdscript
## Level 3: Intermediate Puzzle
static func create_level_3() -> LevelData:
	var level := LevelData.new()
	level.level_id = 3
	level.level_name = "First Challenge"
	level.width = 4
	level.height = 4
	level.num_colors = 2
	level.move_limit = 1
	level.target_score = 10
	level.squares_goal = 1

	# Starting grid (generated and validated)
	level.starting_grid = [
		[0, 1, 1, 0],
		[1, 0, 1, 1],
		[0, 1, 0, 0],
		[1, 1, 0, 1]
	]

	# Tutorial mode mechanics
	level.lock_on_match = false
	level.clear_locked_squares = false
	level.enable_gravity = false
	level.refill_from_top = false

	return level
```

### Step 3: Register in Match Statement

Add your new level to the match statement in `_generate_level_internal()`:

```gdscript
if prefer_handcrafted:
	match id:
		1:
			return create_level_1()
		2:
			return create_level_2()
		3:
			return create_level_3()  # ← Add your new level here!
		999:
			return create_level_endless()
```

### Step 4: Test Your Level

Run the game and it will use your handcrafted level!

```gdscript
var level = LevelData.create_level(3)  # Uses your handcrafted version!
```

### Step 5: Toggle Behavior (Optional)

To use procedural generation instead:

```gdscript
# In your code, before loading levels:
LevelData.prefer_handcrafted = false  # Use procedural generation

var level = LevelData.create_level(3)  # Now uses rule-based generation
```

## Example Output

```
======================================================================
  SQUARE UP LEVEL GENERATOR
======================================================================

Generating example levels...

--- Example 1: Tutorial Level (4x4, 2 colors, 1 move) ---
  ✓ Generated valid puzzle in 3 attempts
  Dimensions: 4x4
  Colors: 2
  Target Moves: 1
  Solution Moves: 1

  Starting Grid:
    0 1 1 0
    1 0 1 1
    0 1 0 0
    1 1 0 1

  Solution:
    Move 1: Swap (1,0) ↔ (2,0)

  ✓ No starting matches (valid puzzle)

======================================================================
  GENERATION COMPLETE
  Total Generated: 3
  Total Attempts: 12
  Failed Attempts: 0
======================================================================
```

## ColorBag API

The `ColorBag` class provides bag randomization:

### Constructor
```gdscript
ColorBag.new(colors: Array[int], multiplier: int = 1)
```

### Methods
```gdscript
# Draw next color from bag (auto-refills when empty)
var color = bag.draw()

# Peek at next color without removing it
var next_color = bag.peek()

# Draw multiple colors at once
var colors = bag.draw_multiple(5)

# Reset and reshuffle the bag
bag.reset()

# Check remaining colors
var remaining = bag.get_remaining()

# Create with defaults (multiplier = 2)
var bag = ColorBag.create_default(num_colors)
```

## Integration with LevelData

The `LevelData.generate_grid_no_squares()` function now supports bag randomization:

```gdscript
# Generate with bag randomization (default)
var grid = LevelData.generate_grid_no_squares(5, 5, 3, true)

# Generate with pure random (old behavior)
var grid_random = LevelData.generate_grid_no_squares(5, 5, 3, false)
```

## Tips for Best Results

### For Tutorial Levels (Easy)
- Use **2 colors** - simplest to understand
- Small boards: **4x4**
- Short solutions: **1 move**
- Bag multiplier: **2x** for variety

### For Intermediate Levels
- Use **3 colors** - balanced difficulty
- Medium boards: **5x5**
- Multi-step solutions: **3 moves**
- Bag multiplier: **2x**

### For Advanced Levels
- Use **4+ colors** - complex patterns
- Larger boards: **6x6** or **7x7**
- Long solutions: **5+ moves**
- Bag multiplier: **3x** for more variety

### Color Distribution

Bag randomization significantly improves color distribution:

**Without Bag (Pure Random):**
```
Grid: 0 0 2 0 1
      1 2 0 0 2
      2 0 1 1 0
```
Note the clustering of 0s in top-left

**With Bag (Multiplier 2):**
```
Grid: 0 1 2 0 1
      2 0 1 2 0
      1 2 0 1 2
```
Much more even distribution!

## Troubleshooting

### "Failed to generate after N attempts"

This can happen when:
- Parameters are too restrictive (e.g., 3x3 with 2 colors, 5 moves)
- Not enough valid swap targets exist

**Solution:** Increase board size or reduce target moves

### "WARNING: X starting matches found!"

The generated puzzle has matches at spawn (invalid).

**Solution:** This is a bug - report it! The validator should catch this.

### Poor Color Distribution

If using `use_bag_randomization = false`, you may see clustering.

**Solution:** Enable bag randomization or increase `bag_multiplier`

## Files

- `scripts/color_bag.gd` - Bag randomization system
- `scripts/level_generator.gd` - Standalone level generator
- `scripts/level_data.gd` - Level data with integrated bag support
- `scenes/LevelGeneratorTest.tscn` - Test scene (run with F6)

## Advanced Usage

### Generate Multiple Variants

```gdscript
var generator = LevelGenerator.new()

for i in range(10):
    var level = generator.generate_level(5, 5, 3, 3)
    if level["is_valid"]:
        print("Variant %d generated!" % (i + 1))
        # Save to file, database, etc.
```

### Custom Validation

```gdscript
func is_puzzle_interesting(level: Dictionary) -> bool:
    var grid = level["starting_grid"]

    # Check for minimum color diversity
    var color_counts = {}
    for row in grid:
        for cell in row:
            color_counts[cell] = color_counts.get(cell, 0) + 1

    # Ensure no color dominates more than 50%
    var total_cells = level["width"] * level["height"]
    for count in color_counts.values():
        if count > total_cells * 0.5:
            return false

    return true
```

## Future Enhancements

Potential improvements to the generator:

- Multi-move solution generation (currently 1-move only)
- Height-level support (3D puzzles)
- Obstacle placement
- Pre-locked tiles
- Custom templates
- Difficulty rating system
- Export to JSON/CSV

## Summary

The Square Up Level Generator provides:

✅ Guaranteed solvable puzzles via reverse-solve
✅ Even color distribution via bag randomization
✅ Configurable difficulty parameters
✅ Standalone tool - no game integration required
✅ Easy to use - run scene or call from code

Happy level creating! 🎮
