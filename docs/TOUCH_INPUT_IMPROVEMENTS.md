# Touch Input Improvements

## Date: January 8, 2026

## Problem
Touch input required tapping the screen first before tile selection would work properly. This created a poor user experience on mobile devices.

## Changes Made

### 1. Project Settings (`project.godot`)

Added touch emulation settings under `[input_devices]`:

```ini
[input_devices]

pointing/emulate_touch_from_mouse=true
pointing/emulate_mouse_from_touch=true
```

- `emulate_touch_from_mouse` - Allows testing touch behavior on desktop with mouse
- `emulate_mouse_from_touch` - Ensures touch events trigger mouse-like behavior for Area2D input detection

### 2. Tile Collision Area (`scenes/Tile.tscn`)

Enlarged the collision polygon for better touch targets:

**Before:**
```
polygon = PackedVector2Array(1.0999985, -11.200001, 31.099998, -4.200001, 2.0999985, 5.799999, -27.900002, -1.2000008)
```

**After:**
```
polygon = PackedVector2Array(1.0999985, -20, 40, -8, 2.0999985, 12, -38, -4)
```

The collision area is now approximately 30% larger, making it easier to tap tiles on mobile devices.

### 3. Touch Input Handling (`scripts/tile.gd`)

Implemented platform-specific input handling to prevent double-tap issues:

```gdscript
func _input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
    if locked:
        return
    
    var is_mobile := OS.has_feature("mobile")
    
    # On mobile: accept ONLY real touch events
    if is_mobile:
        if event is InputEventScreenTouch and event.pressed:
            tapped.emit(self)
            viewport.set_input_as_handled()
        return
    
    # On desktop: accept ONLY mouse clicks
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        tapped.emit(self)
        viewport.set_input_as_handled()
        return
```

**Key improvements:**
- Platform detection using `OS.has_feature("mobile")` separates mobile and desktop input paths
- **Mobile**: Only accepts `InputEventScreenTouch` - prevents emulated mouse events from triggering
- **Desktop**: Only accepts `InputEventMouseButton` - cleaner for testing
- **Prevents double-tap**: By separating input types, the same physical touch won't trigger both touch and emulated mouse events
- Uses `viewport.set_input_as_handled()` to prevent event propagation issues

## Why Area2D is Good for Touch Input

Area2D is a good choice for tile-based touch input because:

1. **Lightweight** - No physics simulation overhead
2. **Precise** - `_input_event` only fires when touching the collision shape
3. **Z-index aware** - Properly handles overlapping tiles via z-index ordering
4. **Built-in support** - Works with both mouse and touch events natively

### 4. Gravity Animation Fix (`scripts/input_router.gd`)

Improved `_apply_gravity()` to prevent tile tracking issues during animations:

```gdscript
func _apply_gravity() -> void:
    # Freeze input during gravity
    set_input_enabled(false)
    
    var moves: Array[Dictionary] = board.apply_gravity()
    if moves.is_empty():
        set_input_enabled(true)
        return
    
    # 1) Snapshot: map original positions -> tile nodes BEFORE changing any grid_pos
    var tiles_by_pos: Dictionary = {}
    for child in tile_container.get_children():
        if child is Area2D:
            var t := child as Area2D
            tiles_by_pos[t.grid_pos] = t
    
    # 2) Animate all moves using the snapshot map
    var tweens: Array[Tween] = []
    for move in moves:
        var from_pos: Vector2i = move["from"]
        var to_pos: Vector2i = move["to"]
        var tile: Area2D = tiles_by_pos.get(from_pos, null)
        if tile == null:
            continue
        
        # Create tween animation
        var tween := create_tween()
        tween.tween_property(tile, "position", target_pos, 0.3)
        tweens.append(tween)
        
        # Update grid_pos AFTER we grabbed the tile from the snapshot
        tile.grid_pos = to_pos
        tile.z_index = to_pos.y + to_pos.x
    
    # 3) Wait for all tweens to finish
    for t in tweens:
        await t.finished
    
    set_input_enabled(true)
```

**Key improvements:**
- **Snapshots positions first** - creates dictionary mapping before updating any grid_pos values
- **Freezes input** during animation to prevent mid-animation interactions
- **Tracks all tweens** - waits for actual tween completion instead of arbitrary timers
- **Prevents lost tiles** - snapshot ensures tiles are found even during complex multi-tile movements

## Testing

After these changes:
1. Reload the project in Godot editor
2. Test on desktop - mouse clicks should work immediately without double-taps
3. Test on mobile - first touch should register properly without needing a "warm-up" tap
4. Test gravity - tiles should animate smoothly and remain interactive after animation completes
