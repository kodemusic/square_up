# Solver Validation System

## Overview

The solver has been enhanced with configurable validation parameters that control puzzle difficulty on a **per-level basis**. This allows fine-tuning of puzzle generation to ensure appropriate challenge for each level.

## Key Parameter: `min_solution_depth`

The `min_solution_depth` parameter controls the **minimum number of moves** required to solve a puzzle. This prevents trivial puzzles from being generated.

### How It Works

```gdscript
Solver.validate_level(grid, move_limit, min_solution_depth)
```

**Parameters:**
- `grid`: The starting puzzle grid
- `move_limit`: Maximum moves allowed to solve (e.g., 10)
- `min_solution_depth`: Minimum moves required for solution (e.g., 2)

**Example:**
```gdscript
# Reject puzzles solvable in less than 2 moves
var validation = Solver.validate_level(grid, 10, 2)

if validation["valid"]:
    print("Puzzle requires %d moves" % validation["shortest_solution"])
else:
    print("Too easy - solvable in %d moves" % validation["shortest_solution"])
```

## Per-Level Configuration

### Level 1: Tutorial (Easy)
```gdscript
min_solution_depth = 1  # Allow 1-move solutions
```
- **Goal**: Teach basic mechanics
- **Difficulty**: Very easy
- **Rationale**: New players need simple puzzles to learn

### Level 2: Introduction (Medium)
```gdscript
min_solution_depth = 2  # Require at least 2 moves
```
- **Goal**: Introduce planning ahead
- **Difficulty**: Moderate
- **Rationale**: Players must think 2 moves ahead

### Level 3+ (Challenging)
```gdscript
min_solution_depth = 3  # Require at least 3 moves
```
- **Goal**: Real puzzle-solving challenge
- **Difficulty**: Hard
- **Rationale**: Deep planning required

## Adjustable Depth Example

The system was designed to be flexible per level:

```gdscript
# Easy tutorial level - accept simpler puzzles
level.starting_grid = _generate_validated_grid(4, 4, 2, level.move_limit, 1)

# Medium difficulty - require 2+ move solutions
level.starting_grid = _generate_validated_grid(4, 4, 3, level.move_limit, 2)

# Hard challenge - require 3+ move solutions
level.starting_grid = _generate_validated_grid(5, 5, 4, level.move_limit, 3)
```

## Why This Matters

### Without min_solution_depth:
- Solver might generate a puzzle solvable in 1 move
- Player makes one obvious swap and wins
- No challenge, no satisfaction

### With min_solution_depth = 2:
- Solver rejects 1-move solutions
- Only accepts puzzles requiring 2+ moves
- Player must plan ahead
- More engaging gameplay

## Validation Dictionary

The `validate_level()` function returns detailed feedback:

```gdscript
{
    "valid": true/false,              # Is puzzle acceptable?
    "solvable": true/false,           # Can it be solved?
    "has_starting_match": true/false, # Already solved at start?
    "has_trivial_solution": true/false, # Too easy?
    "shortest_solution": int,         # Minimum moves needed
    "states_explored": int,           # BFS performance metric
    "errors": Array[String]           # Why puzzle was rejected
}
```

## Example Validation Results

### Valid Puzzle (Accepted)
```gdscript
{
    "valid": true,
    "solvable": true,
    "has_starting_match": false,
    "has_trivial_solution": false,
    "shortest_solution": 3,
    "states_explored": 145,
    "errors": []
}
```
✅ Accepted: Requires 3 moves, no issues

### Invalid Puzzle (Too Easy)
```gdscript
{
    "valid": false,
    "solvable": true,
    "has_starting_match": false,
    "has_trivial_solution": true,
    "shortest_solution": 1,
    "states_explored": 8,
    "errors": ["Solution too short: 1 moves (min: 2)"]
}
```
❌ Rejected: Only requires 1 move (below minimum of 2)

### Invalid Puzzle (Unsolvable)
```gdscript
{
    "valid": false,
    "solvable": false,
    "has_starting_match": false,
    "has_trivial_solution": false,
    "shortest_solution": -1,
    "states_explored": 2048,
    "errors": ["Puzzle is unsolvable within 10 moves"]
}
```
❌ Rejected: Cannot be solved within move limit

## Performance Considerations

### BFS Search Depth
The solver uses **Breadth-First Search** which guarantees finding the shortest solution:

- **min_solution_depth = 1**: Very fast (~10-50 states)
- **min_solution_depth = 2**: Fast (~50-200 states)
- **min_solution_depth = 3**: Moderate (~200-1000 states)
- **min_solution_depth = 4+**: Slow (~1000-5000+ states)

**Why the hybrid approach matters:**
- Generating puzzles with `min_solution_depth = 3` can take 2-5 seconds
- Validating 50 attempts = potential 100-250 second freeze!
- Handcrafted pools avoid this entirely

## Current Implementation

### Hybrid System (Recommended)
```gdscript
# Fast: Use pre-validated handcrafted puzzles
level.starting_grid = _get_level_1_grid()
```

### Procedural System (Fallback)
```gdscript
# Slow: Generate and validate on-the-fly
level.starting_grid = _generate_validated_grid(4, 4, 2, 10, 2)
```

### Simple Generation (Endless Mode)
```gdscript
# Instant: No validation, for endless gameplay
level.starting_grid = generate_grid_no_squares(4, 4, 3)
```

## Testing Your Puzzles

To test if a handcrafted puzzle meets your difficulty requirements:

```gdscript
# Test a custom puzzle
var test_puzzle = [
    [0, 1, 0, 1],
    [1, 0, 1, 0],
    [0, 1, 0, 1],
    [1, 0, 1, 0]
]

# Validate with different min_solution_depth values
for min_depth in [1, 2, 3, 4]:
    var validation = Solver.validate_level(test_puzzle, 10, min_depth)
    print("Min depth %d: %s (solution: %d moves)" % [
        min_depth,
        "VALID" if validation["valid"] else "REJECTED",
        validation["shortest_solution"]
    ])
```

**Example Output:**
```
Min depth 1: VALID (solution: 2 moves)
Min depth 2: VALID (solution: 2 moves)
Min depth 3: REJECTED (solution: 2 moves)
Min depth 4: REJECTED (solution: 2 moves)
```

This tells you the puzzle requires exactly 2 moves to solve.

## Recommended Settings by Level

| Level | Colors | Grid Size | Move Limit | Min Depth | Difficulty |
|-------|--------|-----------|------------|-----------|------------|
| 1 | 2 | 4×4 | 10 | 1 | Tutorial |
| 2 | 3 | 4×4 | 8 | 2 | Easy |
| 3 | 3 | 4×4 | 6 | 2 | Medium |
| 4 | 4 | 4×4 | 8 | 3 | Hard |
| 5+ | 4+ | 5×5 | 10+ | 3+ | Expert |

## Advanced: Solution Path Tracking

The solver also tracks the complete solution path:

```gdscript
var result = Solver.solve_detailed(grid, 10)

if result.solvable:
    print("Solution found in %d moves:" % result.solution_length)
    for i in range(result.solution_path.size()):
        var move = result.solution_path[i]
        print("  Move %d: Swap (%d,%d) with (%d,%d)" % [
            i + 1,
            move["from"].x, move["from"].y,
            move["to"].x, move["to"].y
        ])
```

This is useful for:
- Debugging puzzle designs
- Implementing hint systems
- Auto-play demonstrations
- Replay systems

## Summary

The `min_solution_depth` parameter gives you **precise control** over puzzle difficulty:

- ✅ **Adjustable per level** - Each level can have different requirements
- ✅ **Prevents trivial puzzles** - No boring 1-move solutions
- ✅ **Guarantees challenge** - Players must plan ahead
- ✅ **Testable** - Validate handcrafted puzzles before shipping
- ✅ **Performance aware** - Hybrid system avoids generation delays

The system was originally set to 3 but is now **configurable** to allow proper difficulty progression across levels!
