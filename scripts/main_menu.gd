extends Control

## Simple main menu for testing level progression
## Uses GameManager autoload to manage level selection

## Maximum level available (update as you add levels)
const MAX_LEVEL := 2

## UI references
@onready var level_label := $VBoxContainer/Level as Label
@onready var play_button := $VBoxContainer/PlayBtn as Button
@onready var prev_button := $VBoxContainer/LevelNav/PrevBtn as Button
@onready var next_button := $VBoxContainer/LevelNav/NextBtn as Button
@onready var restart_button := $VBoxContainer/RestartBtn as Button
@onready var endless_button := $VBoxContainer/EndlessBtn as Button
@onready var quit_button := $VBoxContainer/QuitBtn as Button

## Current selected level
var selected_level := 1

func _ready() -> void:
	# Get current level from GameManager if available
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		selected_level = gm.player_progress["current_level"]
	
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	endless_button.pressed.connect(_on_endless_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Focus play button for keyboard navigation
	play_button.grab_focus()
	
	# Update display
	_update_ui()

func _update_ui() -> void:
	level_label.text = "Level: %d" % selected_level
	
	# Disable prev/next at boundaries
	prev_button.disabled = (selected_level <= 1)
	next_button.disabled = (selected_level >= MAX_LEVEL)

func _on_play_pressed() -> void:
	_load_selected_level()

func _on_prev_pressed() -> void:
	if selected_level > 1:
		selected_level -= 1
		_update_ui()

func _on_next_pressed() -> void:
	if selected_level < MAX_LEVEL:
		selected_level += 1
		_update_ui()

func _on_restart_pressed() -> void:
	# Reset to level 1
	selected_level = 1
	_update_ui()

func _on_endless_pressed() -> void:
	# Load endless mode (level 999)
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		gm.load_endless_mode()
	else:
		# Fallback: set test level to endless and load game
		get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _load_selected_level() -> void:
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		gm.load_level(selected_level)
	else:
		# Fallback: just load Game.tscn directly
		get_tree().change_scene_to_file("res://scenes/Game.tscn")

## Keyboard shortcuts for level navigation
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_on_prev_pressed()
	elif event.is_action_pressed("ui_right"):
		_on_next_pressed()
