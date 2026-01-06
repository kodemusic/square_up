# Nested Array Type Annotation Fix

**Date:** January 6, 2026  
**Issue:** GDScript nested array type errors preventing game execution

## Problem

GDScript does not fully support nested typed collections. Type annotations like `Array[Array]` or `Array[Array[int]]` are not strictly enforced at compile time in all scenarios, causing runtime errors that prevented the game from starting.

### Error Symptoms
- Game would not launch
- Array type annotation errors in level_data.gd and related files
- Compile-time type inference failures with nested array access

## Root Cause

GDScript's type system doesn't fully support nested collection types. While `Array[SomeType]` works for simple types, `Array[Array]` creates ambiguity because:
1. The engine cannot enforce the inner array's type at compile time
2. Type inference fails when accessing elements from untyped nested arrays
3. Runtime type checking becomes unreliable with deeply nested structures

## Solution

**Changed all `Array[Array]` type annotations to untyped `Array`**

This is the recommended approach for 2D grids and nested arrays in GDScript. The untyped `Array` still provides full functionality but without strict compile-time type checking for nested structures.

### Additional Fixes
Where type inference failed after removing type annotations (e.g., `var width := grid[0].size()`), added explicit type annotations:
```gdscript
// Before:
var width := grid[0].size()  // Error: Cannot infer type

// After:
var width: int = grid[0].size()  // Explicit int type
```

## Files Modified

### Core Game Files

#### 1. scripts/solver.gd
**10+ changes** - Fixed all nested array type annotations in solver logic

**Function Signatures Changed:**
- `from_2d_array(grid_2d: Array)` - was `Array[Array]`
- `to_2d_array() -> Array` - was `-> Array[Array]`
- `can_solve(start_grid: Array, max_moves: int)` - was `Array[Array]`
- `solve_detailed(start_grid: Array, max_moves: int)` - was `Array[Array]`
- `find_solution(start_grid: Array, max_moves: int)` - was `Array[Array]`
- `validate_solution(start_grid: Array, moves: Array[Dictionary])` - was `Array[Array]`
- `validate_level(start_grid: Array, move_limit: int, min_solution_depth: int = 2)` - was `Array[Array]`
- `generate_validated_puzzle(goal_grid: Array, spine_moves: Array[Dictionary], ...)` - was `Array[Array]`
- `_get_critical_cells(moves: Array[Dictionary], goal_grid: Array)` - was `Array[Array]`
- `_copy_grid_static(grid: Array) -> Array` - was `Array[Array]` for both
- `_swap_cells_static(grid: Array, a: Vector2i, b: Vector2i)` - was `Array[Array]`

**Variables Changed:**
- Line 38: `var grid_2d: Array = []` - was `Array[Array]`
- Line 306: `var width: int = goal_grid[0].size()` - added explicit type
- Line 359: `var width: int = goal_grid[0].size()` - added explicit type
- Line 373: `var copy: Array = []` - was `Array[Array]`

#### 2. scripts/board.gd
**1 change** - Fixed board storage variable

**Variable Changed:**
- Line 29: `var board: Array = []` - was `Array[Array]`

### Test Files

#### 3. scripts/test_solver.gd
**5 changes** - Fixed test grid declarations

**Variables Changed:**
- Line 19: `var grid: Array = [...]` - was `Array[Array]`
- Line 33: `var grid: Array = [...]` - was `Array[Array]`
- Line 58: `var grid: Array = [...]` - was `Array[Array]`
- Line 85: `var grid: Array = [...]` - was `Array[Array]`

**Function Changed:**
- Line 118: `func _print_grid(grid: Array)` - was `Array[Array]`

#### 4. scripts/test_level_1.gd
**4 changes** - Fixed test helper functions

**Functions Changed:**
- Line 138: `func _test_swap_creates_match(grid: Array, from: Vector2i, to: Vector2i)` - was `Array[Array]`
- Line 144: `func _find_matches(grid: Array) -> Array[Vector2i]` - was `Array[Array]`
- Line 162: `func _apply_moves(grid: Array, moves: Array[Dictionary]) -> Array` - was `Array[Array]` for both
- Line 169: `func _print_grid_colored(grid: Array)` - was `Array[Array]`

**Variable Changed:**
- Line 147: `var w: int = grid[0].size()` - added explicit type

#### 5. scripts/test_level_2.gd
**3 changes** - Fixed test helper functions

**Functions Changed:**
- Line 81: `func _test_swap_creates_match(grid: Array, from: Vector2i, to: Vector2i)` - was `Array[Array]`
- Line 103: `func _apply_moves(grid: Array, moves: Array[Dictionary]) -> Array` - was `Array[Array]` for both
- Line 110: `func _print_grid(grid: Array)` - was `Array[Array]`

**Variable Changed:**
- Line 88: `var width: int = test_grid[0].size()` - added explicit type

#### 6. scripts/test_reverse_solve.gd
**1 change** - Fixed print helper

**Function Changed:**
- Line 43: `func _print_simple_grid(grid: Array)` - was `Array[Array]`

## Impact Assessment

### ✅ Positive Changes
- **Game now compiles and runs** - All type errors resolved
- **No runtime changes** - Arrays still work identically at runtime
- **Code remains clear** - Function purpose is still obvious from context
- **Maintains functionality** - All grid operations work as before

### ⚠️ Trade-offs
- **Less compile-time safety** - Can't catch inner array type mismatches at compile time
- **Lost IDE hints** - Some autocomplete may be less specific for nested array elements
- **Manual validation needed** - Developer must ensure grid structure consistency

### 🔒 No Breaking Changes
- All existing code continues to work
- No gameplay logic affected
- Level data structures unchanged
- API contracts maintained (just less strict typing)

## Best Practices for GDScript 2D Arrays

Based on this fix, follow these guidelines for 2D arrays in GDScript:

### ❌ Don't Use
```gdscript
var grid: Array[Array] = []              # Causes errors
var nested: Array[Array[int]] = []       # Not supported
func process(data: Array[Array]) -> void # Problematic
```

### ✅ Do Use
```gdscript
var grid: Array = []                     # Untyped array
var width: int = grid[0].size()         # Explicit types for inferred values
func process(data: Array) -> void       # Simple, works reliably
```

### 📝 Documentation Strategy
When using untyped arrays for 2D grids, add clear comments:
```gdscript
## 2D array storing cell data: board[y][x] -> {color, height, state}
var board: Array = []

## Apply moves to a grid
## grid: 2D array where grid[y][x] is a color_id (int)
func _apply_moves(grid: Array, moves: Array[Dictionary]) -> Array:
```

## Testing Performed

- ✅ No compile errors in any .gd files
- ✅ All type inference errors resolved
- ✅ Game launches successfully
- ✅ Level data loads correctly
- ✅ Board initialization works
- ✅ Solver functions operate normally

## Related Documentation

- [TYPE_ANNOTATION_FIX.md](TYPE_ANNOTATION_FIX.md) - Previous type annotation fixes
- [HYBRID_LEVEL_GENERATION.md](HYBRID_LEVEL_GENERATION.md) - Level generation system
- [SOLVER_VALIDATION_SYSTEM.md](SOLVER_VALIDATION_SYSTEM.md) - Solver implementation

## Conclusion

This fix resolves a fundamental compatibility issue between GDScript's type system and nested array structures. By using untyped `Array` for 2D grids, the code now follows GDScript best practices and runs without errors while maintaining all functionality.

The trade-off of losing some compile-time type safety is acceptable because:
1. 2D grid structures are well-defined in the codebase
2. Runtime behavior is unchanged
3. Clear documentation compensates for lost type hints
4. The game now actually runs (most important!)
