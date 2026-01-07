extends Node

## ========================================================================
##  LAYOUT MANAGER - Golden Rule Dual-Layout System
## ========================================================================
## Implements the "Golden Rule" architecture for orientation-aware layouts.
## Detects portrait vs landscape orientation and switches between layouts
## without reloading scenes or duplicating game logic.
##
## Principles:
## - One game scene, two layout wrappers, zero duplicated gameplay
## - Separate GAME from LAYOUT (board logic never changes)
## - Runtime orientation detection based on aspect ratio
## - Layout-relative positioning (never position board to screen directly)
##
## Usage:
##   var board_anchor = layout_manager.get_active_board_anchor()
##   tile_container.global_position = board_anchor center
## ========================================================================

## Emitted when orientation changes (portrait <-> landscape)
signal orientation_changed(is_portrait: bool)

## References to layout containers
@onready var portrait_layout: Control = $PortraitLayout
@onready var landscape_layout: Control = $LandscapeLayout

## Current orientation state
var current_is_portrait: bool = false

## Called when node enters scene tree
func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("  LAYOUT MANAGER - Golden Rule System Initialized")
	print("=".repeat(60))

	# Detect initial orientation
	_detect_and_apply_orientation()

	# Listen for window resize events
	get_tree().root.size_changed.connect(_on_viewport_size_changed)

	print("  Initial orientation: %s" % ("Portrait" if current_is_portrait else "Landscape"))
	print("=".repeat(60) + "\n")

## Detect orientation based on viewport aspect ratio and apply layout
func _detect_and_apply_orientation() -> void:
	var viewport_size := get_viewport_rect().size
	var aspect_ratio := viewport_size.x / viewport_size.y

	# Portrait if height > width (aspect ratio < 1.0)
	var is_portrait := aspect_ratio < 1.0

	# Only switch if orientation actually changed
	if is_portrait != current_is_portrait:
		current_is_portrait = is_portrait
		_switch_layout(is_portrait)
		orientation_changed.emit(is_portrait)

## Switch between portrait and landscape layouts
func _switch_layout(is_portrait: bool) -> void:
	if is_portrait:
		portrait_layout.visible = true
		landscape_layout.visible = false
		print("[LayoutManager] Switched to PORTRAIT layout")
	else:
		portrait_layout.visible = false
		landscape_layout.visible = true
		print("[LayoutManager] Switched to LANDSCAPE layout")

## Get the active layout's BoardAnchor for positioning the board
func get_active_board_anchor() -> Control:
	if current_is_portrait:
		return portrait_layout.get_node("BoardAnchor") as Control
	else:
		return landscape_layout.get_node("BoardAnchor") as Control

## Check if current orientation is portrait
func is_portrait() -> bool:
	return current_is_portrait

## Handle viewport size changes (window resize)
func _on_viewport_size_changed() -> void:
	_detect_and_apply_orientation()
