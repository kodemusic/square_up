# Golden Rule Architecture Documentation

## Overview

This document describes the **Golden Rule dual-layout system** implemented in Square Up. This architectural pattern enables elegant support for both portrait (mobile) and landscape (desktop) orientations without duplicating game logic or reloading scenes.

## Table of Contents

1. [The Golden Rule Principles](#the-golden-rule-principles)
2. [Architecture Overview](#architecture-overview)
3. [How It Works](#how-it-works)
4. [Implementation Details](#implementation-details)
5. [Testing Guide](#testing-guide)
6. [Troubleshooting](#troubleshooting)
7. [Extending the System](#extending-the-system)

---

## The Golden Rule Principles

### Core Philosophy

> **One game scene. Two layout wrappers. Zero duplicated gameplay.**

The Golden Rule ensures that:

1. **Board logic never changes** - Only the presentation container changes
2. **Layouts exist simultaneously** - Both portrait and landscape layouts are always present, only one is visible
3. **Runtime orientation detection** - Aspect ratio determines which layout is active
4. **Layout-relative positioning** - Board is positioned relative to layout containers, never directly to screen coordinates
5. **Board at native scale** - 64x32 tile dimensions at 1x scale; layouts decide placement, not size

### Why This Matters

**Without Golden Rule:**
- Hardcoded positions break when resolution changes
- Portrait and landscape require separate scenes or complex conditionals
- Tablet, foldable, and ultra-wide displays cause positioning chaos
- Refactoring becomes a nightmare

**With Golden Rule:**
- Resolution-independent positioning
- Orientation changes handled automatically
- Clean separation of game logic and presentation
- Future-proof for new device types

---

## Architecture Overview

### Scene Hierarchy

```
Game (Node)
 ├─ Camera2D (960, 540) - Centered for 1920x1080 viewport
 │
 ├─ LayoutManager (Node) - Orientation detection & switching
 │   ├─ PortraitLayout (Control) - Mobile/portrait container
 │   │   ├─ BoardAnchor (CenterContainer) - Board positioning area
 │   │   └─ UIAnchor (Control) - Future layout-specific UI
 │   │
 │   └─ LandscapeLayout (Control) - Desktop/landscape container
 │       ├─ BoardAnchor (CenterContainer) - Board positioning area
 │       └─ UIAnchor (Control) - Future layout-specific UI
 │
 ├─ BoardRoot (Node) - Pure game logic (UNCHANGED)
 │   ├─ BoardController
 │   ├─ TileContainer (Node2D) - Position controlled by active layout
 │   ├─ Overlay
 │   └─ TweenHost
 │
 ├─ FXLayer (CanvasLayer)
 │
 ├─ UILayer (CanvasLayer)
 │   └─ Hud (Control) - Uses anchors, auto-adapts
 │
 ├─ InputRouter (Node)
 │
 └─ Audio (Node2D)
```

### Component Responsibilities

| Component | Responsibility | Type |
|-----------|----------------|------|
| **Game.gd** | Main controller, connects layout to board | Controller |
| **LayoutManager** | Orientation detection, layout switching | Presentation Logic |
| **PortraitLayout** | Portrait container with vertical positioning | Layout Container |
| **LandscapeLayout** | Landscape container with centered positioning | Layout Container |
| **BoardRoot** | Game logic (solver, grid, matching) | Game Logic |
| **HUD** | UI overlay (already responsive via anchors) | UI |

---

## How It Works

### 1. Orientation Detection

**When:** On startup and window resize

**How:** Calculate aspect ratio of viewport

```gdscript
var viewport_size = get_viewport_rect().size
var aspect_ratio = viewport_size.x / viewport_size.y

if aspect_ratio < 1.0:
    # Height > Width = Portrait
    show PortraitLayout
else:
    # Width >= Height = Landscape
    show LandscapeLayout
```

**Edge Case:** Square viewports (1920x1920) use Landscape (aspect = 1.0)

### 2. Layout Switching

**Trigger:** Orientation change detected

**Process:**
1. LayoutManager detects aspect ratio change
2. Hides current layout
3. Shows appropriate layout
4. Emits `orientation_changed` signal
5. Game repositions board via `_position_board_in_layout()`

**Result:** Seamless switch without scene reload

### 3. Board Positioning

**Before (Hardcoded - Bad):**
```gdscript
tile_container.position = Vector2(640, 200)  # Breaks on different resolutions!
```

**After (Layout-Relative - Good):**
```gdscript
var board_anchor = layout_manager.get_active_board_anchor()
var anchor_center = board_anchor.global_position + (board_anchor.size / 2.0)
tile_container.global_position = anchor_center
```

**Benefits:**
- ✅ Resolution-independent
- ✅ Orientation-aware
- ✅ Easy to adjust (just move BoardAnchor in editor)
- ✅ Clean separation of concerns

### 4. BoardAnchor Configuration

#### Portrait Layout BoardAnchor

**Purpose:** Position board in upper-center area

**Settings:**
- **Anchors:** Center (preset 8)
- **Offset:** -300, -500 to 300, 300 (600x800 area)
- **Result:** Board centered horizontally, positioned in upper half

**Why:** Leaves space for bottom UI elements (buttons, controls)

#### Landscape Layout BoardAnchor

**Purpose:** Position board in perfect center

**Settings:**
- **Anchors:** Center (preset 8)
- **Offset:** -500, -300 to 500, 300 (1000x600 area)
- **Result:** Board centered both horizontally and vertically

**Why:** Horizontal space allows board to breathe, flanked by UI on sides

---

## Implementation Details

### Files Created

1. **`scripts/layout_manager.gd`** (~100 lines)
   - Orientation detection logic
   - Layout switching
   - Signal emissions
   - API for getting active BoardAnchor

2. **`scenes/PortraitLayout.tscn`**
   - Portrait layout container
   - BoardAnchor with vertical offset (-100)
   - UIAnchor placeholder

3. **`scenes/LandscapeLayout.tscn`**
   - Landscape layout container
   - BoardAnchor centered
   - UIAnchor placeholder

4. **`docs/GOLDEN_RULE_ARCHITECTURE.md`** (this file)
   - Comprehensive documentation
   - Architecture diagrams
   - Testing and troubleshooting guides

### Files Modified

1. **`scenes/Game.tscn`**
   - **Removed:** Camera2D2 (duplicate camera)
   - **Updated:** Camera2D position from (960, 537) to (960, 540)
   - **Added:** LayoutManager node with PortraitLayout and LandscapeLayout children

2. **`scripts/game.gd`**
   - **Added:** `layout_manager` reference
   - **Removed:** Hardcoded `tile_container.position = Vector2(640, 200)`
   - **Added:** `_position_board_in_layout()` method
   - **Added:** `_on_orientation_changed()` handler
   - **Added:** Signal connection to LayoutManager

### Files Unchanged (Critical)

- **`scripts/board.gd`** - Game logic unchanged ✅
- **`scripts/input_router.gd`** - Input handling unchanged ✅
- **`scenes/BoardRoot.tscn`** - Board structure unchanged ✅
- **`scenes/HUD.tscn`** - Already uses anchors (auto-adapts) ✅

---

## Testing Guide

### Manual Testing Checklist

#### Test 1: Desktop (1920x1080 Landscape)

**Steps:**
1. Launch game at 1920x1080 resolution
2. Observe which layout is active

**Expected Results:**
- ✅ LandscapeLayout is visible
- ✅ PortraitLayout is hidden
- ✅ Board appears centered horizontally and vertically
- ✅ HUD overlays on edges
- ✅ Console shows: "Switched to LANDSCAPE layout"

#### Test 2: Mobile Portrait (1080x1920)

**Steps:**
1. Resize window to 1080x1920 (portrait)
2. Or test on mobile device

**Expected Results:**
- ✅ PortraitLayout is visible
- ✅ LandscapeLayout is hidden
- ✅ Board appears centered horizontally, offset upward
- ✅ HUD has space at bottom
- ✅ Console shows: "Switched to PORTRAIT layout"

#### Test 3: Window Resize (Runtime Switching)

**Steps:**
1. Start game in landscape (1920x1080)
2. Resize window to portrait (1080x1920)
3. Resize back to landscape

**Expected Results:**
- ✅ Layout switches smoothly without lag
- ✅ Board repositions instantly
- ✅ Gameplay continues uninterrupted
- ✅ No visual glitches or flashing
- ✅ Console shows orientation change messages

#### Test 4: Gameplay Continuity

**Steps:**
1. Start a level in landscape
2. Make several swaps
3. Resize window to portrait mid-game
4. Continue playing

**Expected Results:**
- ✅ Game state preserved (score, moves, grid)
- ✅ Tiles maintain correct isometric positions
- ✅ Swap animations work correctly
- ✅ Match detection functions normally
- ✅ HUD updates correctly

#### Test 5: Edge Case (Square Viewport)

**Steps:**
1. Resize window to 1920x1920 (square)

**Expected Results:**
- ✅ LandscapeLayout is active (aspect = 1.0 uses landscape)
- ✅ Board is centered

### Automated Testing

**Console Output to Verify:**

```
============================================================
  LAYOUT MANAGER - Golden Rule System Initialized
============================================================
  Initial orientation: Landscape
============================================================

[LayoutManager] Switched to LANDSCAPE layout
[Game] Board positioned at: (960, 540) (layout-relative)
```

**On Resize to Portrait:**

```
[LayoutManager] Switched to PORTRAIT layout
[Game] Orientation changed: Portrait
[Game] Board positioned at: (960, 440) (layout-relative)
```

---

## Troubleshooting

### Issue: Board Not Appearing

**Symptoms:**
- Black screen or tiles not visible
- Console shows board positioned at (0, 0)

**Causes:**
1. BoardAnchor not set up correctly in layout scene
2. Layout visibility issue
3. LayoutManager not initialized

**Solutions:**
1. Open PortraitLayout.tscn and LandscapeLayout.tscn in Godot editor
2. Verify BoardAnchor exists and has proper anchors (preset 8)
3. Check that one layout is visible on startup
4. Verify console shows "Layout Manager Initialized"

### Issue: Orientation Not Switching

**Symptoms:**
- Resizing window doesn't change layout
- Same layout always shown

**Causes:**
1. `size_changed` signal not connected
2. Aspect ratio calculation issue
3. LayoutManager not detecting changes

**Solutions:**
1. Check `layout_manager.gd` has:
   ```gdscript
   get_tree().root.size_changed.connect(_on_viewport_size_changed)
   ```
2. Add debug print in `_detect_and_apply_orientation()`:
   ```gdscript
   print("Aspect ratio: %f, Is portrait: %s" % [aspect_ratio, is_portrait])
   ```
3. Restart game after code changes

### Issue: Board Position Wrong

**Symptoms:**
- Board too high/low or off-center
- Board position changes unexpectedly

**Causes:**
1. BoardAnchor size or offset incorrect
2. Positioning calculation timing issue
3. Hardcoded position still in code

**Solutions:**
1. Open layout scenes in editor, adjust BoardAnchor offset values
2. Verify `_position_board_in_layout()` has `await get_tree().process_frame`
3. Search game.gd for `Vector2(640, 200)` - should not exist

### Issue: Gameplay Broken After Resize

**Symptoms:**
- Can't swap tiles after orientation change
- Tiles disappear or duplicate
- Matches not detected

**Causes:**
1. board.gd or input_router.gd accidentally modified
2. TileContainer moved but tiles didn't follow
3. Grid coordinates out of sync

**Solutions:**
1. Verify board.gd and input_router.gd unchanged from git
2. Check that tiles are children of TileContainer (shouldn't reparent)
3. Grid positions are game-logic-relative (not affected by visual position)

### Issue: HUD Overlapping Board

**Symptoms:**
- HUD buttons cover tiles
- Can't click tiles under UI

**Causes:**
1. HUD not using proper anchors
2. BoardAnchor positioned too high
3. Z-index issue

**Solutions:**
1. Verify HUD.tscn uses anchor presets (not fixed positions)
2. Adjust BoardAnchor vertical offset in PortraitLayout.tscn
3. HUD is in CanvasLayer (should always render on top)

---

## Extending the System

### Adding a New Layout (e.g., Tablet)

**Steps:**

1. **Create TabletLayout.tscn:**
   ```
   TabletLayout (Control)
    ├─ BoardAnchor (CenterContainer)
    └─ UIAnchor (Control)
   ```

2. **Modify layout_manager.gd:**
   ```gdscript
   @onready var tablet_layout: Control = $TabletLayout

   func _detect_and_apply_orientation() -> void:
       var viewport_size = get_viewport_rect().size
       var aspect_ratio = viewport_size.x / viewport_size.y

       # Tablet: 4:3 or 3:2 aspect ratio
       if aspect_ratio > 1.2 and aspect_ratio < 1.5:
           _switch_to_tablet()
       elif aspect_ratio < 1.0:
           _switch_to_portrait()
       else:
           _switch_to_landscape()
   ```

3. **Add to Game.tscn:**
   - Instance TabletLayout as child of LayoutManager

4. **Test on tablet device or simulator**

### Adding Layout-Specific UI

**Use Case:** Different button layouts for portrait vs landscape

**Steps:**

1. **Create UI elements in layout scenes:**
   - PortraitLayout.tscn: Add bottom toolbar to UIAnchor
   - LandscapeLayout.tscn: Add side panel to UIAnchor

2. **Connect signals in game.gd:**
   ```gdscript
   func _on_orientation_changed(is_portrait: bool) -> void:
       _position_board_in_layout()
       _update_layout_specific_ui(is_portrait)

   func _update_layout_specific_ui(is_portrait: bool) -> void:
       if is_portrait:
           # Configure portrait UI
           pass
       else:
           # Configure landscape UI
           pass
   ```

### Smooth Orientation Transitions

**Add animation when layout switches:**

```gdscript
# In _position_board_in_layout()
func _position_board_in_layout(animate: bool = false) -> void:
    await get_tree().process_frame

    var board_anchor = layout_manager.get_active_board_anchor()
    var anchor_center = board_anchor.global_position + (board_anchor.size / 2.0)

    if animate:
        var tween = create_tween()
        tween.set_trans(Tween.TRANS_CUBIC)
        tween.set_ease(Tween.EASE_OUT)
        tween.tween_property(tile_container, "global_position", anchor_center, 0.3)
    else:
        tile_container.global_position = anchor_center
```

**Call with animation:**
```gdscript
func _on_orientation_changed(is_portrait: bool) -> void:
    _position_board_in_layout(true)  # Animate = true
```

---

## Technical Deep Dive

### Why Node2D for TileContainer?

**Question:** Why position TileContainer instead of BoardRoot?

**Answer:** BoardRoot is a `Node` (not `Node2D`), so it doesn't have a `position` property. TileContainer is a `Node2D`, which is the visual container for all tile sprites.

**Implication:** Positioning TileContainer moves all child tiles together (desired behavior).

### Isometric Coordinate System

**Question:** Does layout positioning affect isometric grid calculations?

**Answer:** No. Isometric calculations (`grid_to_iso()`) are relative to TileContainer's position. As long as TileContainer is positioned correctly, all tiles follow.

**Code Reference:**
```gdscript
# board.gd - grid_to_iso function
func grid_to_iso(gx: int, gy: int) -> Vector2:
    var iso_x = (gx - gy) * (tile_width / 2.0)
    var iso_y = (gx + gy) * (tile_height / 2.0)
    return Vector2(iso_x, iso_y)
```

This returns **local** positions relative to TileContainer.

### Z-Index and Depth Sorting

**Question:** Does global_position affect tile z-index?

**Answer:** No. Z-index is relative, not absolute:

```gdscript
# input_router.gd
tile_a.z_index = tile_a.grid_pos.y + tile_a.grid_pos.x
```

Changing TileContainer's global_position doesn't affect relative z-ordering.

### Performance Considerations

**Layout Switching Cost:** O(1)
- Show/hide operations are instant
- No scene reloading
- No tile repositioning (local positions unchanged)

**Board Repositioning Cost:** O(1)
- Single vector assignment
- No iteration over tiles
- Tiles follow parent automatically

**Total Overhead:** Negligible (~1-2ms on resize)

---

## Best Practices

### ✅ Do's

1. **Always position board via `_position_board_in_layout()`**
   - Never set `tile_container.position` directly elsewhere

2. **Test both orientations during development**
   - Resize Godot window frequently
   - Verify board positioning in both layouts

3. **Keep board logic in board.gd**
   - Don't add layout awareness to game logic
   - Layout is purely presentational

4. **Use anchor presets for UI**
   - HUD should use anchor-based layout
   - Don't hardcode UI positions

5. **Document layout-specific changes**
   - If you modify BoardAnchor, note the reason
   - Update this document when extending

### ❌ Don'ts

1. **Don't hardcode screen positions**
   - Bad: `position = Vector2(640, 200)`
   - Good: `position = board_anchor center`

2. **Don't modify board.gd for layout purposes**
   - Board logic should never know about orientation
   - Keep separation of concerns

3. **Don't create layout-specific game logic**
   - Game rules shouldn't change based on orientation
   - Only presentation changes

4. **Don't manually switch layouts**
   - Let LayoutManager handle orientation detection
   - Don't force portrait/landscape in game code

5. **Don't skip the `await` in `_position_board_in_layout()`**
   - Needed to ensure layout nodes are ready
   - Removing causes positioning errors

---

## Summary

The Golden Rule dual-layout system provides:

✅ **Clean architecture** - Separation of game logic and presentation
✅ **Resolution-independent** - Works on any screen size
✅ **Orientation-aware** - Automatically adapts portrait/landscape
✅ **Runtime switching** - No scene reloads or duplicated logic
✅ **Future-proof** - Easy to extend for new layouts
✅ **Maintainable** - Clear responsibilities and minimal coupling

**The puzzle remains the hero in every orientation.**

---

## Additional Resources

- **The Golden Rule Document:** `i:\GODOT GAMES\squareUp\The Golden Rule.txt`
- **Implementation Plan:** `C:\Users\bango\.claude\plans\twinkly-tumbling-raccoon.md`
- **Layout Manager Source:** `scripts/layout_manager.gd`
- **Game Controller Source:** `scripts/game.gd`

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2026-01-06 | 1.0 | Initial implementation of Golden Rule architecture |
|  |  | - Created PortraitLayout and LandscapeLayout scenes |
|  |  | - Implemented LayoutManager with orientation detection |
|  |  | - Updated Game.tscn (removed duplicate camera, centered at 960,540) |
|  |  | - Modified game.gd for layout-relative positioning |
|  |  | - Comprehensive documentation created |

---

**Maintained by:** Claude Sonnet 4.5
**Last Updated:** January 6, 2026
**Project:** Square Up - Isometric Puzzle Game
