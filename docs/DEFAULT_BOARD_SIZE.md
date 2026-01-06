# Default Board Size: 5x5

## Overview

**All levels now default to 5x5 boards** unless explicitly overridden.

---

## Changes Made

### 1. LevelData Default (level_data.gd)
```gdscript
// Before
var width: int = 4
var height: int = 4

// After
var width: int = 5  // DEFAULT: 5x5 board
var height: int = 5  // DEFAULT: 5x5 board
```

### 2. LevelRules Default (level_rules.gd)
```gdscript
// Before
var board_width: int = 4
var board_height: int = 4

// After
var board_width: int = 5  // DEFAULT: 5x5 board
var board_height: int = 5  // DEFAULT: 5x5 board
```

---

## Current Level Configuration

| Level | Size | Override? | Colors | Goal |
|-------|------|-----------|--------|------|
| **Level 1** | 4x4 | ✅ Yes (hardcoded) | 2 | 1 sq |
| **Level 2** | 5x5 | ❌ Uses default | 3 | 2 sq |
| **Levels 3+** | 5x5 | ❌ Uses default (via rules) | 3-4 | 1-2 sq |

---

## How It Works

### Hardcoded Levels (1-2)
```gdscript
static func create_level_1() -> LevelData:
    var level := LevelData.new()
    level.width = 4   // Explicitly set to 4x4
    level.height = 4
    // ...
```

### Rule-Based Levels (3+)
```gdscript
// Difficulty 2 preset (used by levels 3-4)
rules.board_width = 4  // Explicitly 4x4
rules.board_height = 4

// Difficulty 3-5 presets (used by levels 5+)
rules.board_width = 5  // Use 5x5
rules.board_height = 5
```

### Custom Levels
```gdscript
// Uses default 5x5
var level = LevelData.new()
// level.width and level.height are 5 by default

// Or override
var level = LevelData.new()
level.width = 6
level.height = 6
```

---

## Benefits

✅ **Consistent default** - 5x5 is standard unless specified
✅ **Better performance** - 5x5 is optimal for BFS solver
✅ **More interesting** - Bigger than 4x4, smaller than 6x6
✅ **Easy to override** - Just set width/height explicitly

---

## Progression

Current difficulty curve:

```
Level 1:    4x4, 2 colors, 1 move     (Tutorial)
Level 2:    5x5, 3 colors, 8 moves    (Easy - Default kicks in)
Levels 3-4: 4x4, 3 colors             (Easy via Difficulty 2)
Levels 5-6: 5x5, 3 colors             (Medium via Difficulty 3)
Levels 7+:  5x5, 4 colors, 2 goals    (Hard)
```

---

## Creating Custom Levels

### Use Default (5x5)
```gdscript
var rules = LevelRules.custom()
// width and height are already 5x5
rules.num_colors = 3
var level = LevelData.create_from_rules(10, rules)
```

### Override to 4x4
```gdscript
var rules = LevelRules.custom()
rules.board_width = 4
rules.board_height = 4
rules.num_colors = 2
var level = LevelData.create_from_rules(10, rules)
```

### Override to 6x6 (not recommended - slow BFS)
```gdscript
var rules = LevelRules.custom()
rules.board_width = 6
rules.board_height = 6
rules.max_solution_moves = 3  // Keep low to avoid stuttering!
var level = LevelData.create_from_rules(10, rules)
```

---

## Summary

**Default board size is now 5x5 across the entire system.**

- Level 1 explicitly uses 4x4 (tutorial)
- Level 2+ default to 5x5 unless overridden
- 5x5 provides best balance of difficulty and performance
- Easy to override for special levels

This ensures consistency while allowing flexibility! ✅
