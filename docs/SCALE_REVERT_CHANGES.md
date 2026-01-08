# Scale Revert Changes - Tile.tscn

## Date: January 8, 2026

## Summary
Reverted scale changes that were attempted to follow Godot 4 best practices. The original approach of using node scales instead of camera zoom alone was correct for this project's isometric tile architecture.

## Changes Reverted/Confirmed

### Tile.tscn

All scale values have been **restored to original working values**:

1. **visual node**
   - Scale: `Vector2(0.27, 0.12)` ✅ RESTORED
   - Position: `Vector2(-0.099998474, 0.20000076)`
   - Purpose: Scales down the isometric tile visual to proper size

2. **Sprite2D (child of visual)**
   - Scale: `Vector2(0.989746, 1.0509642)` ✅ ORIGINAL
   - Position: `Vector2(5.3148155, 123.33333)`
   - Purpose: Fine-tuning for isometric perspective

3. **base_playfield**
   - Scale: `Vector2(0.95, 0.4)` ✅ ORIGINAL
   - Position: `Vector2(0, 49)`
   - Purpose: Flattened isometric shadow/base

4. **HeightStack**
   - Position: `Vector2(2, 42.000004)` ✅ ORIGINAL
   - Purpose: Stack slice positioning for multi-height tiles

### stacked_root.tscn

**Original values maintained**:
- Root scale: `Vector2(0.25, 0.12)` ✅
- Stack_slice2 scale: `Vector2(0.25, 0.12)` ✅
- Stack_slice2 position: `Vector2(0, 30.000004)` ✅

## Reason for Revert

The attempted change to remove all scales and use only camera zoom was based on a misunderstanding of the architecture:

- These scales are **not for sizing** - they're for **isometric projection**
- The tiles use pre-rendered orthographic sprites that need scaling to create the isometric view
- Camera zoom is **still used** for board-to-screen fitting (see game.gd)
- The combination of both techniques is correct for this hybrid approach

## Current Architecture (CORRECT)

```
Visual Scaling Hierarchy:
1. Tile.visual scale (0.27, 0.12) - Creates isometric tile dimensions
2. Camera2D.zoom (dynamic) - Fits board to screen anchor
3. Content scale factor - Mobile/desktop scaling (main.gd)
```

## Files Affected
- ✅ `scenes/Tile.tscn` - visual node scale restored
- ✅ `scenes/stacked_root.tscn` - kept original scales
- ✅ `scenes/Game.tscn` - kept original camera zoom ranges
- ✅ `scripts/game.gd` - kept original zoom parameters

## Testing Required
- [x] Verify tiles appear at correct proportions
- [ ] Test on multiple screen sizes
- [ ] Test portrait/landscape orientation switches
- [ ] Verify camera zoom fits board correctly

## Notes

The project uses a **hybrid scaling approach** which is appropriate for isometric 2D games:
- Node scales for isometric geometry transformation
- Camera zoom for viewport fitting
- Content scale for device DPI handling

This is a valid Godot 4 pattern for isometric games.
