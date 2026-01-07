# Handcrafted Levels Workflow

## Quick Reference

**System:** Handcrafted levels are ALWAYS used first (when `prefer_handcrafted = true`, which is default)

**Workflow:**
1. Generate → 2. Copy → 3. Paste → 4. Customize → 5. Register

## How It Works

### Priority System

The game checks for handcrafted levels FIRST:

```gdscript
if prefer_handcrafted:
    match id:
        1: return create_level_1()  # Handcrafted
        2: return create_level_2()  # Handcrafted
        3: return create_level_3()  # Handcrafted (if you add it)
        # ... add more here
```

If no handcrafted version exists, it falls back to procedural generation.

### Toggle Flag

```gdscript
# Default behavior (use handcrafted when available)
LevelData.prefer_handcrafted = true

# Force procedural generation for all levels
LevelData.prefer_handcrafted = false
```

## Adding a New Handcrafted Level

### 1. Generate the Level

Run the Level Generator:

**Option A:** Run scene
- Open `scenes/LevelGeneratorTest.tscn`
- Press **F6**

**Option B:** From code
```gdscript
var generator = LevelGenerator.new()
var level = generator.generate_level(5, 5, 3, 3)  # 5x5, 3 colors, 3 moves
```

### 2. Copy the Output

The generator outputs ready-to-paste GDScript code:

```
============================================================
  📋 COPY-PASTE CODE (add to level_data.gd)
============================================================

## Level X: [Your Description Here]
static func create_level_X() -> LevelData:
    var level := LevelData.new()
    level.level_id = X
    level.level_name = "[Your Level Name]"
    level.width = 5
    level.height = 5
    level.num_colors = 3
    level.move_limit = 3
    level.target_score = 30
    level.squares_goal = 3

    level.starting_grid = [
        [0, 1, 2, 0, 1],
        [2, 0, 1, 2, 0],
        [1, 2, 0, 1, 2],
        [0, 1, 2, 0, 1],
        [2, 0, 1, 2, 0]
    ]

    level.lock_on_match = false
    level.clear_locked_squares = false
    level.enable_gravity = false
    level.refill_from_top = false

    return level

============================================================
```

### 3. Paste into level_data.gd

Open `scripts/level_data.gd` and paste the function somewhere in the file (near the other `create_level_X` functions).

### 4. Customize the Level

Edit the pasted code to match your needs:

```gdscript
## Level 3: First Real Challenge
static func create_level_3() -> LevelData:
    var level := LevelData.new()
    level.level_id = 3  # ← Change X to actual level number
    level.level_name = "Triple Threat"  # ← Give it a name
    level.width = 5
    level.height = 5
    level.num_colors = 3
    level.move_limit = 5  # ← Adjust difficulty
    level.target_score = 50  # ← Set score goal
    level.squares_goal = 5  # ← How many squares needed

    # Keep the generated grid (it's already validated!)
    level.starting_grid = [
        [0, 1, 2, 0, 1],
        [2, 0, 1, 2, 0],
        [1, 2, 0, 1, 2],
        [0, 1, 2, 0, 1],
        [2, 0, 1, 2, 0]
    ]

    # Choose game mechanics
    level.lock_on_match = true  # ← Enable locking?
    level.clear_locked_squares = true  # ← Clear squares?
    level.enable_gravity = true  # ← Enable gravity?
    level.refill_from_top = true  # ← Refill tiles?

    return level
```

### 5. Register in Match Statement

Find the `_generate_level_internal` function and add your level:

```gdscript
if prefer_handcrafted:
    match id:
        1:
            return create_level_1()
        2:
            return create_level_2()
        3:
            return create_level_3()  # ← ADD THIS LINE
        999:
            return create_level_endless()
```

### 6. Test It!

```gdscript
var level = LevelData.create_level(3)  # Uses your handcrafted level!
```

## Best Practices

### ✅ Do's

- **Generate first** - Use the generator to create valid grids
- **Customize after** - Adjust parameters to match your vision
- **Keep grids** - Don't modify the generated `starting_grid` (it's validated!)
- **Test early** - Run the level in-game to verify difficulty
- **Document levels** - Add meaningful names and comments

### ❌ Don'ts

- **Don't modify grids manually** - You might create starting matches
- **Don't skip validation** - Always use generated grids
- **Don't reuse grids** - Generate unique ones for each level
- **Don't forget to register** - Add to match statement!

## Level Configuration Guide

### Move Limit

```gdscript
level.move_limit = 1   # Tutorial: 1 move
level.move_limit = 3   # Easy: 3 moves
level.move_limit = 5   # Medium: 5 moves
level.move_limit = 8   # Hard: 8 moves
level.move_limit = 0   # Endless: unlimited
```

### Game Mechanics

```gdscript
# Tutorial Mode (no complications)
level.lock_on_match = false
level.clear_locked_squares = false
level.enable_gravity = false
level.refill_from_top = false

# Cascade Mode (like Candy Crush)
level.lock_on_match = true
level.clear_locked_squares = true
level.enable_gravity = true
level.refill_from_top = true

# Lock Mode (tiles stay locked)
level.lock_on_match = true
level.clear_locked_squares = false
level.enable_gravity = false
level.refill_from_top = false
```

### Difficulty Progression

```gdscript
# Levels 1-5: Tutorial
- 2 colors
- 4x4 boards
- 1-2 moves
- Simple mechanics

# Levels 6-10: Easy
- 3 colors
- 5x5 boards
- 3-5 moves
- Introduce locking

# Levels 11-20: Medium
- 3-4 colors
- 5x5 or 6x6 boards
- 5-8 moves
- Cascade mechanics

# Levels 21-30: Hard
- 4-5 colors
- 6x6 or larger
- 8+ moves
- Full cascade mode
```

## Troubleshooting

### "Starting matches detected!"

**Problem:** You modified the grid manually and created a match.

**Solution:** Re-generate the grid using the Level Generator.

### "Level not loading"

**Problem:** Forgot to register in match statement.

**Solution:** Add your level to the match statement in `_generate_level_internal()`.

### "Too easy/hard"

**Problem:** Need to adjust difficulty.

**Solution:** Change `move_limit`, `target_score`, or `squares_goal`.

### "Want different grid"

**Problem:** Don't like the generated grid.

**Solution:** Run the generator again! Each run creates a new random grid.

## Example: Complete Level

Here's a complete example with all customizations:

```gdscript
## Level 5: Color Chaos
static func create_level_5() -> LevelData:
    var level := LevelData.new()
    level.level_id = 5
    level.level_name = "Color Chaos"
    level.width = 5
    level.height = 5
    level.num_colors = 4
    level.move_limit = 6
    level.target_score = 60
    level.squares_goal = 6

    # Generated and validated grid
    level.starting_grid = [
        [0, 1, 2, 3, 0],
        [2, 3, 0, 1, 2],
        [1, 0, 3, 2, 1],
        [3, 2, 1, 0, 3],
        [0, 1, 2, 3, 0]
    ]

    # Introduce cascade mechanics
    level.lock_on_match = true
    level.clear_locked_squares = true
    level.enable_gravity = true
    level.refill_from_top = false  # No refill yet

    return level
```

## Summary

**Workflow:** Generate → Copy → Paste → Customize → Register

**Key Files:**
- `scenes/LevelGeneratorTest.tscn` - Run to generate levels
- `scripts/level_data.gd` - Add handcrafted levels here
- `scripts/level_generator.gd` - Generator logic

**Remember:** Handcrafted levels ALWAYS take priority over procedural generation!

Happy level crafting! 🎮✨
