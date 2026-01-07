# GameManager Setup Instructions

> **Note**: For solver algorithm and safety verification, see [docs/SOLVER_SAFETY_VERIFICATION.md](docs/SOLVER_SAFETY_VERIFICATION.md)

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
---

## Recent Changes (January 7, 2026)

### Level Generation System Updates ✅

**Handcrafted-Only Mode Enforced:**

Modified level generation to strictly use handcrafted factory functions when `prefer_handcrafted = true`:

**Files Modified:**
- `scripts/level_data.gd`: 
  - Changed `auto_generate = true` (was false) to enable on-demand generation
  - Updated `_generate_level_internal()` to error if no handcrafted factory exists
  - Added default case `_:` in match statement for missing level IDs

**Behavior Changes:**
```gdscript
# When prefer_handcrafted = true (DEFAULT):
LevelData.create_level(1)   # ✅ Uses create_level_1() factory
LevelData.create_level(2)   # ✅ Uses create_level_2() factory  
LevelData.create_level(999) # ✅ Uses create_level_endless() factory
LevelData.create_level(3)   # ❌ ERROR: No factory function, falls back to Level 1

# When prefer_handcrafted = false:
LevelData.create_level(3)   # ✅ Uses procedural generation with rules
```

**Configuration Flags:**
- `auto_generate = true`: Levels generate on-demand (no need to pre-cache)
- `prefer_handcrafted = true`: Only uses factory functions, never procedural

**Adding New Handcrafted Levels:**
1. Create factory function in "LEVEL FACTORY FUNCTIONS" section:
   ```gdscript
   static func create_level_3() -> LevelData:
       var level := LevelData.new()
       level.level_id = 3
       # ... configure level ...
       return level
   ```

2. Add to match statement in `_generate_level_internal()`:
   ```gdscript
   match id:
       1: return create_level_1()
       2: return create_level_2()
       3: return create_level_3()  # Add this
       999: return create_level_endless()
   ```

### Cascade System Implementation ✅

Implemented full cascade gameplay loop with combo multiplier system:

**Core Mechanics:**
- Match detection → Lock → Clear → Gravity → Refill → Check for new matches (recursive)
- Combo multiplier tracks cascade depth (x1, x2, x3, x4...)
- Score formula: `base_points × (height + 1) × combo_multiplier`

**Files Modified:**
- `scripts/input_router.gd`: Added `_check_cascade_matches(combo_depth)` with recursive loop
- `scripts/board.gd`: Updated `award_points_for_matches()` to accept combo multiplier
- `scripts/hud.gd`: Added `show_combo()` method with animated "COMBO xN" indicator

**Visual Feedback:**
- Combo indicator appears on 2nd+ cascade (scales up, fades out)
- Gold text with black outline for visibility
- Animation: scale 0.5→1.2→1.5 with fade in/out

### Level Configuration Updates ✅

Configured cascade mechanics on per-level basis for progressive difficulty:

**Level 1 (Tutorial):**
```gdscript
lock_on_match = false
clear_locked_squares = false
enable_gravity = false
refill_from_top = false
```
- Players learn basic matching without cascade complications

**Level 2 (Main Gameplay):**
```gdscript
lock_on_match = true
clear_locked_squares = true
enable_gravity = true
refill_from_top = true
```
- Introduces full cascade system with combo chains
- Players experience satisfying chain reactions

**Level 999 (Endless Mode):**
- Full cascade enabled (unchanged)
- Infinite score attack mode

### Testing Progression ✅

Added automatic level progression for testing without GameManager:

**Files Modified:**
- `scripts/game.gd`: Added `test_level_id` static variable and fallback progression
- Progression flow: Level 1 → Level 2 → Level 999 (Endless)
- Level ID persists across scene reloads using static variable

**Behavior:**
- If GameManager exists: Uses standard progression system
- If no GameManager: Uses testing fallback (Level 1→2→999 loop)

### Implementation Notes

**Cascade Loop Logic:**
```gdscript
func _check_cascade_matches(combo_depth: int = 1) -> void:
    var matches = find_matches()
    if matches.size() > 0:
        flash_matches()
        award_points(matches, combo_depth)  # Multiplier applied here
        if combo_depth > 1:
            show_combo_indicator(combo_depth)
        lock → clear → gravity → refill
        await _check_cascade_matches(combo_depth + 1)  # Recursive
```

**Score Calculation:**
- Base match: 10 points per square
- Height multiplier: Each height level adds +1× (height 0 = 1×, height 1 = 2×)
- Combo multiplier: Each cascade depth multiplies score (combo 2 = 2×, combo 3 = 3×)
- Example: Match at height 1 on 3rd cascade = 10 × 2 × 3 = 60 points

**Testing Checklist:**
- [x] Cascade system recursively checks for matches after refill
- [x] Combo multiplier increases with each cascade level
- [x] HUD displays combo indicator for cascades
- [x] Level 1 has no cascade (tutorial)
- [x] Level 2 has full cascade (main gameplay)
- [x] Level progression works without GameManager
- [ ] Test cascade in-game with Level 2
- [ ] Verify combo scores are correct
- [ ] Ensure cascade terminates when no matches found