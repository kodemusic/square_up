extends RefCounted

## ========================================================================
##  COLOR BAG - Shuffled Bag Randomization for Color Distribution
## ========================================================================
## Implements Tetris-style bag randomization to ensure even color
## distribution and prevent clustering. Colors are drawn from a shuffled
## bag, and when the bag is empty, it's refilled and reshuffled.
##
## Usage:
##   var bag = ColorBag.new([0, 1, 2], 2)  # 3 colors, bag size 2x
##   var color = bag.draw()                # Get next color
##   bag.reset()                           # Start over with new shuffle
## ========================================================================

class_name ColorBag

## Available color IDs
var colors: Array[int] = []

## Bag size multiplier (how many sets of colors in each bag)
var bag_multiplier: int = 1

## Current bag contents
var _current_bag: Array[int] = []

## Constructor
## colors: Array of color IDs to use (e.g., [0, 1, 2] for 3 colors)
## multiplier: How many complete sets of colors per bag (default 1)
func _init(p_colors: Array[int], multiplier: int = 1) -> void:
	colors = p_colors.duplicate()
	bag_multiplier = max(1, multiplier)
	_refill_bag()

## Draw the next color from the bag
## Returns a color ID and automatically refills when empty
func draw() -> int:
	if _current_bag.is_empty():
		_refill_bag()

	# Pop from the end for efficiency
	return _current_bag.pop_back()

## Peek at the next color without removing it
func peek() -> int:
	if _current_bag.is_empty():
		_refill_bag()

	return _current_bag.back()

## Draw multiple colors at once
## Returns an array of color IDs
func draw_multiple(count: int) -> Array[int]:
	var result: Array[int] = []
	for i in range(count):
		result.append(draw())
	return result

## Reset the bag (refill and reshuffle)
func reset() -> void:
	_refill_bag()

## Get remaining colors in current bag
func get_remaining() -> int:
	return _current_bag.size()

## Check if bag needs refilling
func is_empty() -> bool:
	return _current_bag.is_empty()

## Refill and shuffle the bag
func _refill_bag() -> void:
	_current_bag.clear()

	# Add complete sets of colors based on multiplier
	for _set in range(bag_multiplier):
		for color in colors:
			_current_bag.append(color)

	# Shuffle using Fisher-Yates algorithm
	_shuffle(_current_bag)

## Fisher-Yates shuffle algorithm
func _shuffle(array: Array) -> void:
	var n := array.size()
	for i in range(n - 1, 0, -1):
		var j := randi() % (i + 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp

## Create a bag with default settings for a given number of colors
static func create_default(num_colors: int, multiplier: int = 2) -> ColorBag:
	var color_array: Array[int] = []
	for i in range(num_colors):
		color_array.append(i)
	return ColorBag.new(color_array, multiplier)

## Print debug info about current bag state
func debug_print() -> void:
	print("ColorBag Debug:")
	print("  Colors: ", colors)
	print("  Multiplier: ", bag_multiplier)
	print("  Current bag: ", _current_bag)
	print("  Remaining: ", get_remaining())
