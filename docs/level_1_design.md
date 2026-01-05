# Level 1: First Match - Design Document

## Overview
**Size**: 4x4
**Colors**: 2 (Red=0, Blue=1)
**Moves**: 1
**Difficulty**: Tutorial

## Goal
Teach the player to recognize an "almost complete" 2x2 square and make the one swap to complete it.

## Visual Design

### Goal State (After Solution)
```
[R] [R] [B] [B]
[R] [R] [B] [B]  ← Red 2x2 match complete!
[B] [B] [R] [R]
[B] [B] [R] [R]
```

### Starting State (What Player Sees)
```
[R] [B] [R] [B]
[R] [R] [B] [B]  ← 3 Reds in L-shape
[B] [B] [R] [R]
[B] [B] [R] [R]
      ↑
   Blocking tile
```

**Pattern Recognition**:
- Position (0,0): Red ✓
- Position (1,0): Blue ✗ (blocking!)
- Position (0,1): Red ✓
- Position (1,1): Red ✓

## The Solution

**Single Swap**: Position (1,0) ↔ (2,0)

**What happens**:
1. Blue at (1,0) moves right to (2,0)
2. Red at (2,0) moves left to (1,0)
3. This completes the Red 2x2 in top-left corner

```
Before:           After:
[R] [B] [R] ...   [R] [R] [B] ...
[R] [R] ...   →   [R] [R] ...
     ↕                  ✓✓
  Swap here        Match!
```

## Teaching Goals

This level teaches:
1. **Visual Pattern Recognition**: Spot 3 tiles of same color in L-shape
2. **Identify the Blocker**: Find the one tile preventing the match
3. **Simple Swap**: Understand that swapping adjacent tiles can create matches
4. **2x2 Match Concept**: Learn that 2x2 (not lines) is the goal

## Design Validation

### Requirements Checklist
- ✓ 4x4 board
- ✓ 2 colors only
- ✓ Exactly 1 solution
- ✓ 1 move to solve
- ✓ Visually obvious pattern
- ✓ No accidental matches in starting state
- ✓ Symmetric color distribution (8 red, 8 blue)

### Why This Design Works

**Balanced Color Distribution**:
- 8 Red tiles (50%)
- 8 Blue tiles (50%)

**Clear Visual Hierarchy**:
- The L-shaped red pattern immediately draws the eye
- Only one tile "doesn't belong"
- Player instinctively wants to "fix" the pattern

**No Alternative Solutions**:
- Only this one swap creates a 2x2 match
- No distractions or false leads
- Clear success feedback when solved

## Alternative Starting Patterns

If you want variety while keeping the same difficulty:

### Variation A: Bottom-Right Red Square
```
[B] [B] [R] [R]
[B] [B] [R] [R]
[R] [R] [B] [B]
[R] [B] [R] [B]  ← L-shape here
```

### Variation B: Blue Square Instead
```
[B] [R] [B] [R]
[B] [B] [R] [R]  ← Blue L-shape
[R] [R] [B] [B]
[R] [R] [B] [B]
```

## Implementation Notes

The level uses **reverse-solving**:
1. Define the goal state (complete red square)
2. Define the solution move
3. Apply the move in reverse to get the starting state

This guarantees the level is always solvable and has exactly the intended solution.
