# Type Annotation Fix - Array[Array] Issue

## Problem

**Error Message:**
```
Trying to return an array of type "Array" where expected return type is "Array[Array]".
```

**Location:** [scripts/level_data.gd](../scripts/level_data.gd)
- Line 207: `_get_level_1_grid()`
- Line 250: `_get_level_2_grid()`

---

## Root Cause

### Incorrect Type Declaration

```gdscript
static func _get_level_1_grid() -> Array[Array]:
	var puzzle_pool: Array[Array] = [  # ❌ WRONG
		[  # This is a 2D grid (Array[Array])
			[0, 1, 0, 1],
			[1, 0, 1, 0],
			[0, 1, 0, 1],
			[1, 0, 1, 0]
		],
		# More 2D grids...
	]
	return puzzle_pool[randi() % puzzle_pool.size()]
```

### The Issue Explained

1. **Function Return Type**: `Array[Array]` (a 2D grid)
2. **puzzle_pool Declared As**: `Array[Array]` (an array of Arrays)
3. **puzzle_pool Actually Contains**: Multiple `Array[Array]` items (array of 2D grids)

**Type Mismatch:**
- `Array[Array]` means "an array containing Array items"
- But we're storing items that are themselves `Array[Array]` (2D grids)
- So puzzle_pool is actually `Array[Array[Array]]` or more accurately `Array` containing `Array[Array]` items

When we return `puzzle_pool[index]`, we return one of these `Array[Array]` items (which is correct), but Godot's type checker sees `puzzle_pool` is declared as `Array[Array]` and thinks we're returning an `Array`, not an `Array[Array]`.

---

## Solution

### Change puzzle_pool to Untyped Array

```gdscript
static func _get_level_1_grid() -> Array[Array]:
	var puzzle_pool: Array = [  # ✅ CORRECT (untyped)
		[  # This is a 2D grid (Array[Array])
			[0, 1, 0, 1],
			[1, 0, 1, 0],
			[0, 1, 0, 1],
			[1, 0, 1, 0]
		],
		# More 2D grids...
	]
	return puzzle_pool[randi() % puzzle_pool.size()] as Array[Array]  # Cast required
```

### Why This Works

- `puzzle_pool` is now untyped `Array`, which can hold any items
- The items are `Array[Array]` (2D grids)
- When we return `puzzle_pool[index]`, we cast it with `as Array[Array]`
- The cast tells the type checker we're returning the correct type
- This matches the function's return type `-> Array[Array]`
- Type checker is satisfied!

---

## Applied Fixes

### Fix 1: _get_level_1_grid()
**File:** [scripts/level_data.gd:206-246](../scripts/level_data.gd#L206-L246)

**Before:**
```gdscript
static func _get_level_1_grid() -> Array[Array]:
	var puzzle_pool: Array[Array] = [  # Wrong type
```

**After:**
```gdscript
static func _get_level_1_grid() -> Array[Array]:
	var puzzle_pool: Array = [  # Untyped, can hold Array[Array] items
		# ... puzzles ...
	]
	return puzzle_pool[randi() % puzzle_pool.size()] as Array[Array]  # Cast required
```

### Fix 2: _get_level_2_grid()
**File:** [scripts/level_data.gd:249-289](../scripts/level_data.gd#L249-L289)

**Before:**
```gdscript
static func _get_level_2_grid() -> Array[Array]:
	var puzzle_pool: Array[Array] = [  # Wrong type
```

**After:**
```gdscript
static func _get_level_2_grid() -> Array[Array]:
	var puzzle_pool: Array = [  # Untyped, can hold Array[Array] items
		# ... puzzles ...
	]
	return puzzle_pool[randi() % puzzle_pool.size()] as Array[Array]  # Cast required
```

### Fix 3: board._init_board()
**File:** [scripts/board.gd:35-41](../scripts/board.gd#L35-L41)

**Before:**
```gdscript
func _init_board(w: int, h: int) -> void:
	board.clear()
	for y in range(h):
		var row: Array[Dictionary] = []  # Wrong type
		for x in range(w):
			row.append(_make_cell())
		board.append(row)
```

**After:**
```gdscript
func _init_board(w: int, h: int) -> void:
	board.clear()
	for y in range(h):
		var row: Array = []  # Untyped, can be appended to Array[Array]
		for x in range(w):
			row.append(_make_cell())
		board.append(row)
```

**Explanation:** When appending to `Array[Array]`, the row must be typed as `Array` not `Array[Dictionary]`, even though it contains Dictionary items.

---

## Why Other Array[Array] Declarations Are Correct

### Valid Usage of Array[Array]

These declarations are **correct** because they're declaring actual 2D arrays (not arrays of 2D arrays):

```gdscript
// Creating a new 2D array - CORRECT
var board: Array[Array] = []
var grid: Array[Array] = []

// Declaring a 2D array literal - CORRECT
var goal_grid: Array[Array] = [
	[0, 0, 1, 2],
	[0, 0, 2, 1],
	[1, 2, 1, 2],
	[2, 1, 2, 1]
]
```

These are fine because:
- They're declaring a 2D array directly
- Not declaring an array that holds 2D arrays

---

## Type Hierarchy Explained

```
Array                    // Untyped array, can hold anything
  │
  ├─ Array[int]         // Array of integers
  │
  ├─ Array[String]      // Array of strings
  │
  └─ Array[Array]       // Array of Arrays (2D array)
       │
       └─ Each item is an Array (the rows)

But what we had:
Array[Array]            // Declared as 2D array
  │
  └─ Contains items that are themselves Array[Array] (2D grids)
       │
       └─ This creates Array[Array[Array]] semantically
```

**Solution:** Use untyped `Array` when storing items that are themselves typed arrays.

---

## Testing

### Verify Fix Works

```gdscript
# In Godot console or test script:
var grid1 = LevelData._get_level_1_grid()
print(grid1)  # Should print a 4x4 grid
print(typeof(grid1))  # Should be TYPE_ARRAY

var grid2 = LevelData._get_level_2_grid()
print(grid2)  # Should print a 4x4 grid
print(typeof(grid2))  # Should be TYPE_ARRAY

# Grid should be 4 rows
print(grid1.size())  # Should be 4

# Each row should be 4 items
print(grid1[0].size())  # Should be 4
```

### Expected Output
```
[[0, 1, 0, 1], [1, 0, 1, 0], [0, 1, 0, 1], [1, 0, 1, 0]]
TYPE_ARRAY
[[1, 2, 0, 1], [0, 1, 2, 0], [2, 0, 1, 2], [1, 2, 0, 1]]
TYPE_ARRAY
4
4
```

---

## Best Practices for Future

### When to Use Typed Arrays

**Use `Array[Type]` when:**
- Creating an array of simple types: `Array[int]`, `Array[String]`
- Creating a 2D array directly: `Array[Array]`
- You know exactly what single type the array holds

```gdscript
var numbers: Array[int] = [1, 2, 3]
var names: Array[String] = ["Alice", "Bob"]
var grid: Array[Array] = [[1, 2], [3, 4]]  # 2D array
```

**Use untyped `Array` when:**
- Creating an array of arrays: `Array` holding `Array[Array]` items
- Array contains mixed types
- Complex nested structures
- Godot's type system gets confused

```gdscript
var puzzle_pool: Array = [  # Holds multiple Array[Array] items
	[[1, 2], [3, 4]],  # Grid 1
	[[5, 6], [7, 8]]   # Grid 2
]
```

### Rule of Thumb

If you're creating an "array of typed-arrays", use untyped `Array` for the outer container:

```gdscript
// ❌ WRONG - Will cause type errors
var pools: Array[Array[int]] = [[1,2], [3,4]]  // Not supported

// ✅ CORRECT - Use untyped outer array
var pools: Array = [[1,2], [3,4]]  // Works fine
```

---

## Related Files

All these files use `Array[Array]` correctly:
- ✅ [scripts/board.gd](../scripts/board.gd) - 2D board array
- ✅ [scripts/level_data.gd](../scripts/level_data.gd) - Level grids (except puzzle_pool)
- ✅ [scripts/solver.gd](../scripts/solver.gd) - Grid operations
- ✅ [scripts/test_solver.gd](../scripts/test_solver.gd) - Test grids

---

## Summary

### Issue
- `puzzle_pool` was incorrectly typed as `Array[Array]`
- It actually holds multiple `Array[Array]` items (grids)
- Returning an item from `puzzle_pool` caused type mismatch

### Fix
- Changed `puzzle_pool` to untyped `Array`
- Can now properly hold `Array[Array]` items
- Returns work correctly with function signature

### Result
- ✅ No more type errors
- ✅ Code compiles successfully
- ✅ Level generation works properly
- ✅ Type safety maintained where needed

**Status:** FIXED ✅
