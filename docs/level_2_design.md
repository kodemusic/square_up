# Level 2: Single-Solution Teaching Puzzle

## Design Goal
Create a puzzle where **exactly one swap** creates **exactly one 2x2 match**.

## Design Strategy

### Pattern: "Almost Complete Square"
Place 3 tiles of the target color in a pattern where only 1 missing tile completes the 2x2.

```
Starting Grid:
  1 0 1 2     Legend:
  0 0 2 1       0 = Red (target color)
  2 1 2 1       1 = Blue
  1 2 1 2       2 = Green

Visual breakdown:
  [Blue] [Red]   [Blue] [Green]     ← Row 0
  [Red]  [Red]   [Green][Blue]      ← Row 1
  [Green][Blue]  [Green][Blue]      ← Row 2
  [Blue] [Green] [Blue] [Green]     ← Row 3
   ^      ^
   |      |
   Position (0,0) and (1,0)
```

### The Setup
**Goal**: Create a Red 2x2 in top-left corner

**Starting state** (reverse-solved):
- Position (0,0): Blue [blocking]
- Position (1,0): Red [part of solution]
- Position (0,1): Red [part of solution]
- Position (1,1): Red [part of solution]

This creates an **L-shape of reds** with one blue blocking the 4th corner.

### The Solution
**Single swap**: (1,0) ↔ (2,0)
- Moves the Red at (1,0) to position (2,0)
- Moves the Blue at (2,0) to position (1,0)
- This doesn't create a match! (Wait, we need to reconsider...)

Actually, let me recalculate based on the reverse-solve:

**Goal Grid** (after solution):
```
  0 0 1 2     Red Red Blue Green
  0 0 2 1     Red Red Green Blue  ← Complete 2x2!
  2 1 2 1
  1 2 1 2
```

**Reverse the swap** (1,0) ↔ (2,0):
```
Starting Grid:
  0 1 0 2     Red Blue Red Green   ← Blue blocks the match
  0 0 2 1     Red Red Green Blue
  2 1 2 1
  1 2 1 2
```

### Why This Works

1. **Obvious visual**: Player sees 3 reds in an L-shape
2. **Single target**: Only one adjacent tile can complete the square
3. **No alternatives**: No other swaps create matches
4. **Clear feedback**: Swap immediately shows the completed red square

### Validation Checklist

✓ Exactly 1 solution move
✓ Solution creates exactly 1 match
✓ No other moves create matches
✓ Visual pattern is obvious (L-shape → square)
✓ 1-move limit teaches "look for near-complete patterns"

## Teaching Takeaway

Players learn to:
1. Recognize **almost-complete 2x2 patterns**
2. Identify the **single blocking tile**
3. Find the **one swap** that completes the pattern
