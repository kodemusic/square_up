# GameManager Setup Instructions

## Step 1: Register GameManager as Autoload (Singleton)

1. Open your project in Godot
2. Go to **Project → Project Settings**
3. Click on the **Autoload** tab
4. Click the folder icon next to "Path"
5. Navigate to and select: `scripts/main.gd`
6. In the "Node Name" field, enter: `GameManager`
7. Click **Add**
8. Close Project Settings

The GameManager will now be available globally as `/root/GameManager` from any script.

## Step 2: Test the Integration

Run your game. You should see console output like:
```
Player Progress Loaded:
  Current Level: 1
  Highest Unlocked: 1
  Total Score: 0
Loading level 1 from GameManager
```

## Step 3: Save File Location

Your progress is automatically saved to:
- **Windows**: `%APPDATA%\Godot\app_userdata\square_up\square_up_save.json`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/square_up/square_up_save.json`
- **Linux**: `~/.local/share/godot/app_userdata/square_up/square_up_save.json`

## Features Now Available

### Automatic Progress Tracking
- When you complete Level 1, Level 2 unlocks automatically
- Stars and high scores are saved per level
- Progress persists between game sessions

### GameManager API (accessible from any script)

```gdscript
# Access the GameManager
var gm = get_node("/root/GameManager")

# Check if a level is unlocked
if gm.is_level_unlocked(2):
    print("Level 2 is unlocked!")

# Get stars for a level
var stars = gm.get_level_stars(1)  # Returns 0-3

# Get high score for a level
var high_score = gm.get_level_high_score(1)

# Load specific level
gm.load_level(2)

# Load next level
gm.load_next_level()

# Restart current level
gm.restart_current_level()

# Reset all progress (for debugging)
gm.reset_progress()
```

### What Happens When You Complete a Level

1. Game calls `GameManager.complete_level(level_id, score, moves_remaining)`
2. GameManager:
   - Calculates and saves stars (1-3 based on moves remaining)
   - Updates high score if you beat your previous best
   - Unlocks the next level
   - Saves progress to disk automatically

### Level Progression Example

```
Start Game → Load Level 1 (tutorial, no locking)
Complete Level 1 → Level 2 unlocks
Load Level 2 → (3 colors, unlimited moves)
Complete Level 2 → Level 3 unlocks
...
Any time → Can play Level 999 (Endless Mode)
```

## Adding More Levels

To add Level 3, 4, etc.:

1. Create level factory methods in `scripts/level_data.gd`:
```gdscript
static func create_level_3() -> LevelData:
    var level := LevelData.new()
    level.level_id = 3
    level.level_name = "Introducing Locking"
    # ... configure level ...

    # Enable locking for the first time
    level.lock_on_match = true
    level.clear_locked_squares = false
    level.enable_gravity = false
    level.refill_from_top = false

    return level
```

2. Update `_load_level_by_id()` in `scripts/game.gd`:
```gdscript
func _load_level_by_id(level_id: int) -> LevelData:
    match level_id:
        1:
            return LevelData.create_level_1()
        2:
            return LevelData.create_level_2()
        3:
            return LevelData.create_level_3()  # Add this
        999:
            return LevelData.create_level_endless()
        _:
            print("Warning: Unknown level_id %d" % level_id)
            return LevelData.create_level_1()
```

3. GameManager will automatically handle progression!

## Debugging Commands

Add these to your game for testing:

```gdscript
# In game.gd _input() or _ready():
func _input(event):
    if event is InputEventKey and event.pressed:
        var gm = get_node("/root/GameManager")

        if event.keycode == KEY_R:
            gm.reset_progress()  # Reset all progress

        if event.keycode == KEY_N:
            gm.load_next_level()  # Skip to next level

        if event.keycode == KEY_E:
            gm.load_endless_mode()  # Jump to endless mode
```

## Current Level Configuration

### Level 1 (Tutorial)
- 4x4 grid, 2 colors
- 10 moves limit
- Goal: 2 squares
- **No locking** - learn matching mechanics
- No clearing, no gravity, no refill

### Level 2 (Three Colors)
- 4x4 grid, 3 colors
- Unlimited moves
- Goal: 2 squares
- Uses default locking behavior

### Level 999 (Endless Mode)
- 4x4 grid, 3 colors
- Unlimited moves
- Goal: Infinite (999999 squares)
- **Full cascade**: lock → clear → gravity → refill → cascade
- Play forever, high score challenge!

## Next Steps

1. Set up GameManager as autoload (see Step 1)
2. Test level completion and progression
3. Add more levels with progressive difficulty
4. Create a level select UI (optional)
5. Add buttons to HUD for "Restart" and "Next Level"
