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
## Parameters: is_portrait (bool), tall_ratio (float), is_very_tall (bool)
signal orientation_changed(is_portrait: bool, tall_ratio: float, is_very_tall: bool)

## References to layout containers
@onready var portrait_layout: Control = $PortraitLayout
@onready var landscape_layout: Control = $LandscapeLayout

## Current orientation state
var current_is_portrait: bool = false
var current_tall_ratio: float = 1.0
var current_is_very_tall: bool = false

## Threshold for "very tall" screens (foldables, etc.)
const VERY_TALL_THRESHOLD: float = 2.2

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
	# Use window size for orientation detection (not viewport size)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var window_size: Vector2 = DisplayServer.window_get_size()

	# Separate concerns: orientation vs tall-screen bias
	var new_portrait_mode: bool = window_size.y > window_size.x
	var new_tall_ratio: float = window_size.y / max(1.0, window_size.x)
	var new_is_very_tall: bool = new_tall_ratio > VERY_TALL_THRESHOLD

	# Debug output
	print("[LayoutManager] Orientation detection:")
	print("  Viewport size: %v" % viewport_size)
	print("  Window size: %v" % window_size)
	print("  Portrait mode: %s (height %s width)" % [new_portrait_mode, ">" if new_portrait_mode else "<="])
	print("  Tall ratio: %.2f (height/width)" % new_tall_ratio)
	print("  Very tall screen: %s (threshold: %.1f)" % [new_is_very_tall, VERY_TALL_THRESHOLD])

	# Check if any orientation property changed
	var orientation_changed_flag := (
		new_portrait_mode != current_is_portrait or
		new_is_very_tall != current_is_very_tall
	)

	# Update state
	current_is_portrait = new_portrait_mode
	current_tall_ratio = new_tall_ratio
	current_is_very_tall = new_is_very_tall

	# Only switch layout and emit if something changed
	if orientation_changed_flag:
		_switch_layout(new_portrait_mode)
		orientation_changed.emit(new_portrait_mode, new_tall_ratio, new_is_very_tall)

## Switch between portrait and landscape layouts
func _switch_layout(portrait_mode: bool) -> void:
	if portrait_mode:
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

## Get current tall ratio (height/width)
func get_tall_ratio() -> float:
	return current_tall_ratio

## Check if current screen is very tall (foldables, etc.)
func is_very_tall() -> bool:
	return current_is_very_tall

## Handle viewport size changes (window resize)
func _on_viewport_size_changed() -> void:
	_detect_and_apply_orientation()
