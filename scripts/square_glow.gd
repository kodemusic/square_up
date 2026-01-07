extends Node2D

@export var duration: float = 0.16
@export var rise_px: float = 10.0
@export var scale_to: float = 1.15

# These should match your iso step (the same values you use in grid_to_iso)
@export var tile_w: float = 64.0
@export var tile_h: float = 32.0

func play(color: Color) -> void:
    # Make a 2x2 "footprint diamond" around the center.
    # Single tile diamond corners (relative): (0,-tile_h/2),(tile_w/2,0),(0,tile_h/2),(-tile_w/2,0)
    # For a 2x2 square, double it: (0,-tile_h),(tile_w,0),(0,tile_h),(-tile_w,0)
    var pts := PackedVector2Array([
        Vector2(0, -tile_h),
        Vector2(tile_w, 0),
        Vector2(0, tile_h),
        Vector2(-tile_w, 0),
        Vector2(0, -tile_h) # close loop
    ])

    var line: Line2D = $outline
    line.points = pts
    line.default_color = color

    # Start state
    scale = Vector2.ONE
    modulate = Color(1, 1, 1, 1)

    # Animate: rise + slight scale + fade out
    var t := create_tween()
    t.set_parallel(true)
    t.set_trans(Tween.TRANS_QUAD)
    t.set_ease(Tween.EASE_OUT)

    t.tween_property(self, "position", position + Vector2(0, -rise_px), duration)
    t.tween_property(self, "scale", Vector2(scale_to, scale_to), duration)
    t.tween_property(self, "modulate:a", 0.0, duration)

    t.finished.connect(queue_free)
