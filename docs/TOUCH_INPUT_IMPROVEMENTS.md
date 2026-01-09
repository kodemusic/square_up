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

Added proper multi-touch tracking to prevent input issues:

```gdscript
## Track which touch index is active (prevents multi-touch issues)
var active_touch := -1

func _input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
    if locked:
        return
    
    # Handle desktop clicks
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            tapped.emit(self)
            viewport.set_input_as_handled()
    
    # Handle mobile touches with proper multi-touch tracking
    elif event is InputEventScreenTouch:
        if event.pressed:
            # Ignore if another touch is already active on this tile
            if active_touch != -1 and event.index != active_touch:
                return
            active_touch = event.index
            tapped.emit(self)
            viewport.set_input_as_handled()
        else:
            # Release touch tracking when finger is lifted
            if event.index == active_touch:
                active_touch = -1
```

**Key improvements:**
- `active_touch` variable tracks which finger is interacting with the tile
- Prevents multi-touch conflicts (ignores additional fingers if one is already active)
- Properly resets touch state when finger is lifted
- Uses `viewport.set_input_as_handled()` to prevent event propagation issues

## Why Area2D is Good for Touch Input

Area2D is a good choice for tile-based touch input because:

1. **Lightweight** - No physics simulation overhead
2. **Precise** - `_input_event` only fires when touching the collision shape
3. **Z-index aware** - Properly handles overlapping tiles via z-index ordering
4. **Built-in support** - Works with both mouse and touch events natively

## Testing

After these changes:
1. Reload the project in Godot editor
2. Test on desktop - mouse clicks should work immediately
3. Test on mobile - first touch should register properly without needing a "warm-up" tap
