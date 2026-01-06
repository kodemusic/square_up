# Level Progression System

**Date:** January 6, 2026  
**Purpose:** Define how grid size, colors, and mechanics scale across levels

## Overview

Square Up uses a progressive difficulty system where multiple parameters change between levels:
1. **Grid Size** (width × height)
2. **Number of Colors** (tile variety)
3. **Move Limits** (constrains player actions)
4. **Game Mechanics** (locking, gravity, cascading)
5. **Win Conditions** (score targets, squares needed)

## Level Configuration Matrix

| Level | Grid Size | Colors | Moves | Squares Goal | Score Target | Mechanics Enabled |
|-------|-----------|--------|-------|--------------|--------------|-------------------|
| **1** | 4×4 | 2 | 1 | 1 | 10 | None (tutorial) |
| **2** | 4×4 | 3 | 8 | 2 | 20 | Lock on match |
| **999** | 4×4 | 3 | ∞ | ∞ | ∞ | Full cascade |

### Future Level Template

| Level | Grid Size | Colors | Moves | Squares Goal | Score Target | Mechanics |
|-------|-----------|--------|-------|--------------|--------------|-----------|
| **3** | 5×5 | 3 | 10 | 2 | 20 | Lock + Clear |
| **4** | 5×5 | 4 | 12 | 3 | 30 | Lock + Clear + Gravity |
| **5** | 6×6 | 4 | 15 | 4 | 40 | Full cascade |

## Parameter Details

### 1. Grid Size (width × height)

**Purpose:** Controls board complexity and puzzle space

**Implementation:**
```gdscript
var width: int = 4   # Number of columns
var height: int = 4  # Number of rows
```

**Scaling Strategy:**
- **4×4** (Levels 1-2): Tutorial and early learning
- **5×5** (Levels 3-5): Intermediate challenge
- **6×6** (Levels 6-10): Advanced puzzles
- **8×8** (Levels 11+): Expert difficulty

**Impact:**
- Larger grids = more possible moves
- More cells = longer solution paths
- Increased visual complexity

**Code Location:** `scripts/level_data.gd` - `create_level_X()` functions

---

### 2. Number of Colors

**Purpose:** Determines tile variety and matching difficulty

**Color Definitions:**
- **0** = Red
- **1** = Blue  
- **2** = Green
- **3** = Yellow
- **4** = Purple
- **5** = Orange

**Scaling Strategy:**
- **2 colors** (Level 1): Simplest - checkerboard-like patterns
- **3 colors** (Levels 2-5): Moderate - requires planning
- **4 colors** (Levels 6-10): Challenging - multiple matching paths
- **5+ colors** (Levels 11+): Expert - complex color management

**Code Impact:**
```gdscript
# Grid generation
level.starting_grid = generate_grid_no_squares(rows, cols, num_colors)

# Puzzle pool design - each puzzle must balance colors
var puzzle_pool: Array = [
    # 2-color puzzle (Level 1)
    [[0,1,0,1], [1,0,1,0], ...],  # 8 red, 8 blue
    
    # 3-color puzzle (Level 2)
    [[0,1,2,0], [2,0,1,2], ...],  # ~5-6 of each
]
```

**Validation Rules:**
- All puzzles must have NO 2×2 matches at start
- Colors should be reasonably balanced (no color >60% of tiles)
- More colors = easier to avoid starting matches

---

### 3. Move Limits

**Purpose:** Constrains puzzle difficulty and enforces specific solutions

**Implementation:**
```gdscript
var move_limit: int = 0  # 0 = unlimited
```

**Scaling Strategy:**
- **1 move** (Level 1): Pure pattern recognition tutorial
- **5-10 moves** (Levels 2-5): Tactical thinking required
- **15-20 moves** (Levels 6-10): Strategic planning needed
- **Unlimited** (Endless): Relaxed sandbox play

**Game Impact:**
- Strict limits force optimal solutions
- Loose limits allow exploration
- HUD displays: "Moves: X / Y"

**Code Location:** `scripts/game.gd` - tracks `moves_count` vs `current_level.move_limit`

---

### 4. Win Conditions

**Purpose:** Define success criteria for level completion

**Components:**

#### A. Squares Goal
```gdscript
var squares_goal: int = 0  # Number of 2×2 squares needed
```

**Scaling:**
- Level 1: **1 square** (10 points)
- Level 2: **2 squares** (20 points)
- Level 3+: **2-5 squares** based on grid size
- Endless: **999999** (effectively infinite)

#### B. Target Score
```gdscript
var target_score: int = 0  # Points needed to win
```

**Formula:** `target_score = squares_goal × 10`

**Scoring System:**
- Each 2×2 match = 10 points
- Cascading matches = combo bonuses (future)
- No penalty for extra moves (encourages learning)

---

### 5. Game Mechanics

**Purpose:** Introduce complexity gradually through level progression

#### Mechanic Flags
```gdscript
var lock_on_match: bool = true       # Lock matched squares?
var clear_locked_squares: bool = false  # Remove locked squares?
var enable_gravity: bool = false     # Tiles drop into gaps?
var refill_from_top: bool = false    # Spawn new tiles?
```

#### Progression Table

| Mechanic | Level Introduced | Effect |
|----------|------------------|--------|
| **None** | Level 1 | Pure matching tutorial |
| **Lock on Match** | Level 2 | Matched tiles become immovable |
| **Clear Locked** | Level 3 | Locked tiles disappear from board |
| **Gravity** | Level 4 | Tiles fall down into gaps |
| **Refill** | Level 5 | New tiles spawn at top |
| **Full Cascade** | Endless | All mechanics = chain reactions |

#### Cascade Sequence (Full Mode)
```
Player swaps tiles
   ↓
Match found (2×2)
   ↓
Tiles lock (visual feedback)
   ↓
Locked tiles clear (disappear)
   ↓
Remaining tiles drop (gravity)
   ↓
New tiles spawn (refill)
   ↓
Check for new matches (cascade)
   ↓
Repeat until no matches
```

---

## Puzzle Pool System

### Why Handcrafted Puzzles?

**Pros:**
- ✓ Guaranteed quality and solvability
- ✓ Controlled difficulty curve
- ✓ Instant loading (no solver delays)
- ✓ Specific teaching moments

**Cons:**
- ✗ Requires manual design
- ✗ Limited variety per level
- ✗ Can't adapt to player skill

### Hybrid Approach (Current)

```gdscript
static func _get_level_1_grid() -> Array:
    var puzzle_pool: Array = [
        # 5 handcrafted puzzles
    ]
    return puzzle_pool[randi() % puzzle_pool.size()]
```

**Benefits:**
1. Random selection provides replay value
2. All puzzles validated by hand
3. Fallback to procedural if needed (future)

---

## Puzzle Validation Checklist

When creating puzzles for any level, verify:

### ✅ Required Checks

1. **No Starting Matches**
   ```python
   # Check all 2×2 positions
   for y in range(height - 1):
       for x in range(width - 1):
           # Ensure grid[y][x] != grid[y][x+1] != grid[y+1][x] != grid[y+1][x+1]
   ```

2. **Color Balance**
   - Count each color in puzzle
   - No color should be >60% of total tiles
   - For 2 colors: aim for 50/50 split
   - For 3 colors: aim for 33/33/33 split

3. **Solvability**
   - Use Solver.can_solve(grid, move_limit)
   - Verify solution exists within move limit
   - Check solution isn't trivial (too easy)

4. **Grid Size Matches Level**
   - Level 1-2: 4×4 grids only
   - Verify puzzle array is `[height][width]`

5. **Color Count Matches Level**
   - Level 1: colors 0-1 only (Red, Blue)
   - Level 2: colors 0-2 only (Red, Blue, Green)
   - Verify no invalid color IDs in puzzle

---

## Adding New Levels

### Step-by-Step Guide

#### 1. Define Level Parameters

```gdscript
static func create_level_3() -> LevelData:
    var level := LevelData.new()
    level.level_id = 3
    level.level_name = "Bigger Board"
    level.width = 5        # ← New size!
    level.height = 5       # ← New size!
    level.move_limit = 10
    level.target_score = 20
    level.squares_goal = 2
```

#### 2. Create Puzzle Pool Function

```gdscript
static func _get_level_3_grid() -> Array:
    var puzzle_pool: Array = [
        # Puzzle 1: 5×5 grid with 3 colors
        [
            [0, 1, 2, 0, 1],
            [2, 0, 1, 2, 0],
            [1, 2, 0, 1, 2],
            [0, 1, 2, 0, 1],
            [2, 0, 1, 2, 0]
        ],
        # Add 4-5 more puzzles
    ]
    return puzzle_pool[randi() % puzzle_pool.size()]
```

#### 3. Validate All Puzzles

```python
# Run validation script
python validate_puzzles.py --level 3
```

#### 4. Set Game Mechanics

```gdscript
    # Introduce clearing mechanic
    level.lock_on_match = true
    level.clear_locked_squares = true  # ← New mechanic!
    level.enable_gravity = false
    level.refill_from_top = false
    
    return level
```

#### 5. Update Factory Function

```gdscript
static func create_level(id: int) -> LevelData:
    match id:
        1:
            return create_level_1()
        2:
            return create_level_2()
        3:
            return create_level_3()  # ← Add new level
        999:
            return create_level_endless()
        _:
            return create_level_1()
```

---

## Procedural Generation (Future)

### When to Use Procedural

- **Endless Mode** - already implemented
- **Daily Challenges** - unique puzzles per day
- **Difficulty Scaling** - adapt to player skill
- **Level 10+** - too many levels to handcraft

### Generation Parameters

```gdscript
static func generate_grid_no_squares(
    rows: int,       # Grid height
    cols: int,       # Grid width  
    num_colors: int  # Tile variety
) -> Array:
```

**Algorithm:**
1. Generate grid row-by-row
2. For each cell, try random colors
3. Check if color creates 2×2 match
4. If yes, try different color (max 20 attempts)
5. Fallback to first non-matching color

**Validation:**
```gdscript
# After generation, verify puzzle is solvable
var validation := Solver.validate_level(grid, max_moves, min_solution_depth)
if not validation["valid"]:
    # Regenerate or use fallback puzzle
```

---

## Current Implementation Status

### ✅ Implemented Levels

#### Level 1: "First Match"
- Grid: 4×4
- Colors: 2 (Red, Blue)
- Moves: 1
- Goal: 1 square (10 points)
- Mechanics: None (tutorial)
- Puzzles: 5 handcrafted, all validated ✓

#### Level 2: "Three Colors"
- Grid: 4×4
- Colors: 3 (Red, Blue, Green)
- Moves: 8
- Goal: 2 squares (20 points)
- Mechanics: Lock on match
- Puzzles: 5 handcrafted, all validated ✓

#### Level 999: "Endless Mode"
- Grid: 4×4
- Colors: 3
- Moves: Unlimited
- Goal: Infinite
- Mechanics: Full cascade (lock, clear, gravity, refill)
- Puzzles: Procedural generation ✓

---

## Design Guidelines

### Color Selection Per Grid Size

| Grid Size | Recommended Colors | Reasoning |
|-----------|-------------------|-----------|
| 4×4 | 2-3 | Tight space, few cells |
| 5×5 | 3-4 | Moderate space, good variety |
| 6×6 | 4-5 | Large space, needs complexity |
| 8×8 | 5-6 | Maximum space, maximum variety |

### Move Limit Calculation

**Formula:** `move_limit ≈ (grid_area / 4) + squares_goal`

**Examples:**
- 4×4, 1 square: `(16/4) + 1 = 5 moves`
- 5×5, 2 squares: `(25/4) + 2 = 8 moves`
- 6×6, 3 squares: `(36/4) + 3 = 12 moves`

Adjust based on playtesting!

### Puzzle Difficulty Factors

**Easy Puzzle:**
- Few colors (2-3)
- Obvious L-shaped patterns
- Many possible solutions
- Loose move limits

**Hard Puzzle:**
- Many colors (4-5)
- Subtle patterns
- Unique solution only
- Tight move limits
- Requires multi-step planning

---

## Testing Strategy

### Manual Testing Checklist

For each new level:

1. ☐ Load level in game
2. ☐ Verify grid displays correctly
3. ☐ Check no starting matches appear
4. ☐ Confirm color distribution looks balanced
5. ☐ Play through each puzzle in pool
6. ☐ Verify solvable within move limit
7. ☐ Test win condition triggers properly
8. ☐ Check HUD displays correct info
9. ☐ Verify mechanics work as intended
10. ☐ Test edge cases (undo, restart, etc.)

### Automated Testing

```gdscript
# scripts/test_level_X.gd
extends Node

func _ready() -> void:
    var level := LevelData.create_level_X()
    
    # Test 1: No starting matches
    assert(not has_starting_matches(level.starting_grid))
    
    # Test 2: Correct grid size
    assert(level.starting_grid.size() == level.height)
    assert(level.starting_grid[0].size() == level.width)
    
    # Test 3: Solvable
    assert(Solver.can_solve(level.starting_grid, level.move_limit))
    
    print("✓ Level X validated")
```

---

## Future Expansion Ideas

### Dynamic Difficulty Adjustment

Track player performance:
- **Struggling:** Reduce colors, increase moves
- **Excelling:** Add colors, reduce moves, add mechanics

### Procedural Level Generation

```gdscript
static func generate_dynamic_level(
    player_skill: float,  # 0.0 to 1.0
    level_number: int
) -> LevelData:
    # Scale parameters based on skill
    var colors := int(lerp(2, 5, player_skill))
    var grid_size := int(lerp(4, 8, float(level_number) / 20.0))
    var moves := int(grid_size * grid_size / 4) + 2
    
    # Generate and validate
    var grid := generate_grid_no_squares(grid_size, grid_size, colors)
    # ...
```

### Alternative Grid Shapes

- **Hexagonal grids** - 6 neighbors instead of 4
- **Irregular shapes** - L-shape, T-shape boards
- **Multi-layer** - 3D stacking mechanics

### Special Tile Types

- **Locked tiles** - can't be moved
- **Wild tiles** - match any color
- **Bomb tiles** - clear surrounding area
- **Color-change tiles** - transform on match

---

## Related Documentation

- [level_1_design.md](level_1_design.md) - Detailed Level 1 design
- [level_2_design.md](level_2_design.md) - Detailed Level 2 design
- [HYBRID_LEVEL_GENERATION.md](HYBRID_LEVEL_GENERATION.md) - Puzzle pool strategy
- [SOLVER_VALIDATION_SYSTEM.md](SOLVER_VALIDATION_SYSTEM.md) - Solvability checking
- [NESTED_ARRAY_TYPE_FIX.md](NESTED_ARRAY_TYPE_FIX.md) - Technical array handling

---

## Summary

The level progression system provides flexible scaling across multiple dimensions:

1. **Grid Size** - 4×4 → 8×8 (spatial complexity)
2. **Colors** - 2 → 6 (matching difficulty)
3. **Moves** - 1 → ∞ (strategic depth)
4. **Mechanics** - None → Cascade (gameplay variety)
5. **Win Conditions** - Adaptive goals

This modular design allows for:
- ✓ Smooth difficulty curve
- ✓ Replayability through puzzle pools
- ✓ Future expansion without code rewrites
- ✓ Procedural generation when needed
- ✓ Player-adaptive challenges

All parameters are configurable per-level in `scripts/level_data.gd`.
