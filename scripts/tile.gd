extends Area2D

## Emitted when the tile is tapped/clicked by the player
signal tapped(tile: Area2D)

## Grid coordinates of this tile (x, y position on the game board)
@export var grid_pos := Vector2i.ZERO
## Color identifier (used for matching logic)
@export var color_id := 0:
	set(value):
		color_id = value
		_update_color()
## Current height/stack level of this tile
@export var height := 0

## Scene to instance for each vertical stack slice (isometric depth effect)
@export var slice_scene: PackedScene
## Vertical pixel offset between each height slice
@export var slice_y_step := 8.0

## Default color tint for normal state
@export var normal_modulate := Color(1, 1, 1, 1)
## Dimmed color tint when tile is locked (matched and scored)
@export var locked_modulate := Color(0.7, 0.7, 0.7, 1)
## Bright tint when tile is selected/highlighted
@export var highlight_modulate := Color(1, 1, 0.6, 1)

## True when tile has been matched and can't be interacted with
var locked := false
## True when tile is currently selected by player
var highlighted := false
## Container node holding all height stack slices
var slices_root: Node2D
## Track which touch index is active (prevents multi-touch issues)
var active_touch := -1

func _ready() -> void:
	# Initialize the tile's visual appearance on spawn
	_ensure_slices_root()
	_build_height_stack()
	_update_color()  # Apply color first
	_update_visual()  # Then apply state tinting

func _input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	# Ignore input if tile is locked (already matched)
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

## Lock or unlock this tile (locked tiles can't be swapped)
func set_locked(value: bool) -> void:
	locked = value
	_update_visual()

## Change the tile's height and rebuild the visual stack
func set_height(value: int) -> void:
	if OS.is_debug_build() and height != value:
		print("[Tile %v] Height changed: %d -> %d" % [grid_pos, height, value])
	height = value
	_build_height_stack()

## Highlight or unhighlight this tile (for selection feedback)
func set_highlighted(value: bool) -> void:
	highlighted = value
	_update_visual()

## Create or get the container node that holds height stack slices
func _ensure_slices_root() -> void:
	# Use existing HeightStack node from scene if available
	if has_node("HeightStack"):
		slices_root = get_node("HeightStack") as Node2D
		return
	# Otherwise check for Slices node (legacy)
	if has_node("Slices"):
		slices_root = get_node("Slices") as Node2D
		return
	# Otherwise create a new one
	slices_root = Node2D.new()
	slices_root.name = "Slices"
	add_child(slices_root)

## Build the vertical stack of slices based on current height
## Height 0 = no slices, height 1 = no slices, height 2+ = adds (height-1) slices
func _build_height_stack() -> void:
	if slices_root == null:
		_ensure_slices_root()
	# Clear any existing slices
	for child in slices_root.get_children():
		child.queue_free()
	if slice_scene == null:
		return
	# Add one slice for each height level above the base
	var extra_slices: int = max(height - 1, 0)
	for i in range(extra_slices):
		var slice := slice_scene.instantiate() as Node2D
		# Stack slices upward (negative Y in isometric view)
		slice.position = Vector2(0, -slice_y_step * float(i + 1))
		slices_root.add_child(slice)

## Update the tile's color tint based on its current state
## Priority: locked > highlighted > normal
func _update_visual() -> void:
	if locked:
		modulate = locked_modulate
	elif highlighted:
		modulate = highlight_modulate
	else:
		modulate = normal_modulate

## Update the tile's visual color based on color_id
## Uses a simple color mapping: 0=Red, 1=Blue, 2=Green
func _update_color() -> void:
	if not is_node_ready():
		return

	var sprite := get_node_or_null("visual/Sprite2D") as Sprite2D
	if sprite == null:
		return

	# Map color_id to actual colors
	var color_map := {
		0: Color(1.0, 0.3, 0.3),  # Red
		1: Color(0.3, 0.5, 1.0),  # Blue
		2: Color(0.3, 1.0, 0.3),  # Green
		3: Color(1.0, 1.0, 0.3),  # Yellow
		4: Color(1.0, 0.3, 1.0),  # Magenta
	}

	# Apply color based on color_id using self_modulate
	# self_modulate is not affected by parent modulation
	if color_id in color_map:
		sprite.self_modulate = color_map[color_id]
	else:
		sprite.self_modulate = Color.WHITE
