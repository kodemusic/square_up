# Lazy Generation & Caching System

## Overview

Control **when** and **how** levels are generated to prevent stuttering during gameplay.

---

## Quick Start

### Option 1: Auto-Generate with Cache (Default)

```gdscript
# Default behavior - auto-generates and caches on demand
var level = LevelData.create_level(5)  # Generates on first call
var level2 = LevelData.create_level(5) # Returns cached version (instant)
```

**Pros:** Simple, no setup
**Cons:** First access may stutter

---

### Option 2: Pre-Generate at Startup (Recommended)

```gdscript
func _ready():
    # Pre-generate levels 1-10 at startup
    LevelData.pre_generate_levels(1, 10)

    # Now all calls are instant (from cache)
    var level1 = LevelData.create_level(1)  # Instant ⚡
    var level5 = LevelData.create_level(5)  # Instant ⚡
```

**Pros:** No in-game stuttering
**Cons:** Slower startup

---

### Option 3: Manual Control (Full Control)

```gdscript
func _ready():
    # Disable auto-generation
    LevelData.configure_generation(false, true)

    # Pre-generate when YOU want
    LevelData.pre_generate_levels(1, 20)

# Later in gameplay...
func load_level(id: int):
    if LevelData.is_cached(id):
        return LevelData.create_level(id)  # Instant
    else:
        # Not cached - you decide what to do
        print("Level not ready!")
        return null
```

**Pros:** Complete control, no surprises
**Cons:** More code to manage

---

## API Reference

### Configuration

```gdscript
# Enable/disable auto-generation and caching
LevelData.configure_generation(
    enable_auto_gen: bool = true,  # Auto-generate on create_level()?
    enable_cache: bool = true       # Use cache?
)
```

**Examples:**

```gdscript
# Default: auto-gen + cache
LevelData.configure_generation(true, true)

# Manual: no auto-gen, but use cache
LevelData.configure_generation(false, true)

# No cache: always regenerate (testing)
LevelData.configure_generation(true, false)
```

---

### Pre-Generation

```gdscript
# Pre-generate levels 1 to 50
LevelData.pre_generate_levels(1, 50)

# Pre-generate specific range
LevelData.pre_generate_levels(10, 20)
```

**Performance:**
- ~10-100ms per level (depends on difficulty)
- 10 levels ≈ 100-1000ms
- 50 levels ≈ 500-5000ms

---

### Cache Management

```gdscript
# Check if level is cached
if LevelData.is_cached(5):
    print("Level 5 ready!")

# Get cache size
var count = LevelData.get_cache_size()
print("%d levels cached" % count)

# Clear cache (frees memory)
LevelData.clear_cache()
```

---

### Creating Levels

```gdscript
# Main function - respects settings
var level = LevelData.create_level(5)

# Returns:
# - Cached level if available
# - Generated level if auto_generate = true
# - Placeholder if auto_generate = false and not cached
```

---

## Usage Patterns

### Pattern 1: Pre-Generate All at Startup

```gdscript
# main.gd or autoload
func _ready():
    print("Generating levels...")
    LevelData.pre_generate_levels(1, 50)
    print("Ready!")
```

**Best for:** Small level counts (< 50)

---

### Pattern 2: Pre-Generate in Batches

```gdscript
# Generate levels 1-10 immediately
func _ready():
    LevelData.pre_generate_levels(1, 10)
    _current_batch = 1

# Generate next batch when player reaches level 8
func on_level_completed(level_id: int):
    if level_id >= _current_batch * 10 - 2:
        _generate_next_batch()

func _generate_next_batch():
    _current_batch += 1
    var start = (_current_batch - 1) * 10 + 1
    var end = _current_batch * 10
    LevelData.pre_generate_levels(start, end)
```

**Best for:** Large level counts (100+)

---

### Pattern 3: Background Generation (Advanced)

```gdscript
# Use a thread for generation
var generation_thread: Thread

func _ready():
    generation_thread = Thread.new()
    generation_thread.start(_generate_levels_background)

func _generate_levels_background():
    LevelData.pre_generate_levels(1, 100)
    print("Background generation complete!")

func _exit_tree():
    if generation_thread.is_alive():
        generation_thread.wait_to_finish()
```

**Best for:** Very large level counts, no startup delay

---

### Pattern 4: Testing Mode

```gdscript
# Disable cache for testing - always regenerate
func _ready():
    LevelData.configure_generation(true, false)

    # Each call generates fresh
    var level1a = LevelData.create_level(5)
    var level1b = LevelData.create_level(5)  # Different puzzle!
```

**Best for:** Testing variety, debugging

---

## Performance Comparison

| Method | First Access | Subsequent Access | Startup Time |
|--------|-------------|-------------------|--------------|
| Auto-Gen (default) | 10-100ms | < 1ms | Instant |
| Pre-Generate (startup) | < 1ms | < 1ms | 500-5000ms |
| Manual Control | N/A | < 1ms | Variable |
| No Cache | 10-100ms | 10-100ms | Instant |

---

## Examples

### Example 1: Mobile Game (Fast Startup)

```gdscript
# Pre-gen first 5 levels, lazy-load rest
func _ready():
    LevelData.pre_generate_levels(1, 5)

# Trigger generation when unlocking new worlds
func unlock_world_2():
    LevelData.pre_generate_levels(6, 10)
```

---

### Example 2: PC Game (Pre-Gen Everything)

```gdscript
# Show loading screen and pre-gen all
func _ready():
    show_loading_screen()
    LevelData.pre_generate_levels(1, 100)
    hide_loading_screen()
```

---

### Example 3: Testing/Debug Mode

```gdscript
# Regenerate each time for variety
func _ready():
    if OS.is_debug_build():
        LevelData.configure_generation(true, false)
```

---

### Example 4: Conditional Generation

```gdscript
# Only generate when user presses "Play"
func _ready():
    LevelData.configure_generation(false, true)

func on_play_button_pressed():
    if not LevelData.is_cached(current_level):
        show_generating_ui()
        LevelData.pre_generate_levels(current_level, current_level + 5)
        hide_generating_ui()

    start_level(current_level)
```

---

## Best Practices

1. **Pre-generate at loading screens** - players expect wait times
2. **Cache aggressively** - memory is cheap, stuttering is bad
3. **Generate in batches** - don't generate all 100 levels at once
4. **Monitor cache size** - clear if memory is tight
5. **Use manual mode for testing** - easier to debug

---

## Troubleshooting

**Q: Levels still stutter on first access**
- Call `pre_generate_levels()` at startup

**Q: Too much memory used**
- Clear cache: `LevelData.clear_cache()`
- Generate in smaller batches

**Q: Startup is slow**
- Reduce pre-generation count
- Use background thread
- Generate in batches

**Q: Want different puzzles each playthrough**
- Disable cache: `configure_generation(true, false)`

---

## Summary

**Default Behavior:**
```gdscript
var level = LevelData.create_level(5)
// Auto-generates, caches, may stutter on first call
```

**Recommended for Production:**
```gdscript
func _ready():
    LevelData.pre_generate_levels(1, 20)
// No stuttering, fast gameplay, slightly slower startup
```

**Full Manual Control:**
```gdscript
func _ready():
    LevelData.configure_generation(false, true)
    # Generate only when YOU say so
```

Choose the pattern that fits your game!
