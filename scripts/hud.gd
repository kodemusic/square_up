extends Control

## Mobile-friendly HUD for Square Up puzzle game
## Displays score, moves remaining, and level completion banners

## Emitted when user wants to restart the current level
signal restart_requested

## Emitted when user wants to undo last move
signal undo_requested

## Emitted when user wants to go to next level
signal next_level_requested

## Current game score
var current_score := 0

## Number of moves made by player
var moves_made := 0

## Move limit for current level (0 = unlimited)
var move_limit := 0

## Current squares completed
var squares_completed := 0

## Target squares to complete
var squares_goal := 0

## References to UI elements (cached in _ready)
@onready var score_label := get_node("TopBar/ScoreBox/VBox/ScoreValue") as Label
@onready var moves_label := get_node("TopBar/MovesBox/VBox/MovesValue") as Label
@onready var goal_label := get_node("TopBar/GoalBox/VBox/GoalValue") as Label
@onready var banner := get_node("CenterBanner") as CenterContainer
@onready var banner_title := get_node("CenterBanner/Panel/VBox/BannerTitle") as Label
@onready var banner_message := get_node("CenterBanner/Panel/VBox/BannerMessage") as Label
@onready var popup := get_node("SquareUpPopup") as CenterContainer
@onready var popup_text := get_node("SquareUpPopup/Panel/VBox/PopupText") as Label
@onready var popup_points := get_node("SquareUpPopup/Panel/VBox/PopupPoints") as Label
@onready var retry_button := get_node("CenterBanner/Panel/VBox/ButtonContainer/RetryButton") as Button
@onready var next_level_button := get_node("CenterBanner/Panel/VBox/ButtonContainer/NextLevelButton") as Button
@onready var undo_button := get_node("BottomBar/UndoButton") as Button

## Whether undo has been used this level (only 1 undo per level for now)
var undo_used := false

## Combo indicator label (created dynamically)
var combo_label: Label = null

func _ready() -> void:
	# Hide banner initially
	banner.visible = false

	# Connect button signals
	retry_button.pressed.connect(_on_retry_pressed)
	next_level_button.pressed.connect(_on_next_level_pressed)
	undo_button.pressed.connect(_on_undo_pressed)

	# Initialize display
	update_score(0)
	update_moves(0)
	update_undo_button()
	
	# Create combo label
	_create_combo_label()

## Update the score display
## points: New total score to display
func update_score(points: int) -> void:
	current_score = points
	if score_label != null:
		score_label.text = str(current_score)

## Update the moves counter
## moves: Number of moves made
func update_moves(moves: int) -> void:
	moves_made = moves
	if moves_label != null:
		if move_limit > 0:
			# Show "X / Y" format when there's a limit
			moves_label.text = "%d / %d" % [moves_made, move_limit]
		else:
			# Show just the count for unlimited moves
			moves_label.text = str(moves_made)

## Set the move limit for the current level
## limit: Maximum moves allowed (0 = unlimited)
func set_move_limit(limit: int) -> void:
	move_limit = limit
	update_moves(moves_made)

## Show level complete banner with final score
func show_level_complete() -> void:
	banner_title.text = "LEVEL COMPLETE!"
	banner_message.text = "Score: %d" % current_score
	banner.visible = true

## Show level complete with star rating
## stars: Number of stars earned (1-3)
## moves_remaining: How many moves were left
func show_level_complete_with_stars(stars: int, moves_remaining: int) -> void:
	var star_text := ""
	for i in range(stars):
		star_text += "★ "
	for i in range(3 - stars):
		star_text += "☆ "

	banner_title.text = "LEVEL COMPLETE!"
	banner_message.text = "%s\nScore: %d\nMoves Left: %d" % [star_text, current_score, moves_remaining]

	# Show both buttons on win
	retry_button.visible = true
	next_level_button.visible = true

	# Slide in animation
	banner.position.y = -200
	banner.modulate = Color(1, 1, 1, 0)
	banner.visible = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner, "position:y", 0, 0.5)\
		 .set_trans(Tween.TRANS_BACK)\
		 .set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)

## Show level failed banner (ran out of moves)
func show_level_failed() -> void:
	banner_title.text = "OUT OF MOVES"
	banner_message.text = "Try Again?"

	# Only show retry button on fail
	retry_button.visible = true
	next_level_button.visible = false

	banner.visible = true
	banner.visible = true

## Show custom banner message
## title: Main banner text
## message: Secondary message text
func show_banner(title: String, message: String = "") -> void:
	banner_title.text = title
	banner_message.text = message
	banner.visible = true

## Hide the center banner
func hide_banner() -> void:
	banner.visible = false

## Set the squares goal for the current level
## goal: Number of squares needed to complete level
func set_squares_goal(goal: int) -> void:
	squares_goal = goal
	update_squares(0)

## Update the squares completed counter
## squares: Number of squares completed
func update_squares(squares: int) -> void:
	squares_completed = squares
	if goal_label != null:
		goal_label.text = "%d / %d" % [squares_completed, squares_goal]

## Increment squares counter by given amount
## Returns true if goal reached
func add_squares(count: int) -> bool:
	squares_completed += count
	update_squares(squares_completed)
	return squares_completed >= squares_goal

## Show "SQUARE UP!" popup with points
## points: Points awarded for this square
func show_square_popup(points: int) -> void:
	if popup == null:
		return

	popup_text.text = "SQUARE UP!"
	popup_points.text = "+%d" % points

	# Start above center, invisible
	popup.modulate = Color(1, 1, 1, 0)
	popup.position.y = -100
	popup.visible = true

	# Fade in and slide to center
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "modulate:a", 1.0, 0.2)
	tween.tween_property(popup, "position:y", 0, 0.3)\
		 .set_trans(Tween.TRANS_BACK)\
		 .set_ease(Tween.EASE_OUT)

	# Hold for a moment
	tween.chain().tween_interval(0.8)

	# Fade out
	tween.tween_property(popup, "modulate:a", 0.0, 0.3)

	# Hide when done
	await tween.finished
	popup.visible = false

## Calculate star rating based on moves remaining
## moves_remaining: Number of moves left after completing level
func calculate_stars(moves_remaining: int) -> int:
	if moves_remaining >= 4:
		return 3
	elif moves_remaining >= 2:
		return 2
	else:
		return 1

## Reset HUD for new level
func reset() -> void:
	current_score = 0
	moves_made = 0
	squares_completed = 0
	undo_used = false
	update_score(0)
	update_moves(0)
	update_squares(0)
	update_undo_button()
	hide_banner()

## Update undo button state (disabled if already used)
func update_undo_button() -> void:
	if undo_button != null:
		undo_button.disabled = undo_used
		undo_button.text = "UNDO USED" if undo_used else "UNDO"

## Mark undo as used
func mark_undo_used() -> void:
	undo_used = true
	update_undo_button()

## Button callbacks
func _on_retry_pressed() -> void:
	emit_signal("restart_requested")

func _on_next_level_pressed() -> void:
	emit_signal("next_level_requested")

func _on_undo_pressed() -> void:
	if not undo_used:
		emit_signal("undo_requested")

## Create the combo indicator label
func _create_combo_label() -> void:
	combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_label.position = Vector2(get_viewport_rect().size.x / 2 - 100, get_viewport_rect().size.y / 2 - 100)
	combo_label.size = Vector2(200, 100)
	combo_label.add_theme_font_size_override("font_size", 48)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Gold color
	combo_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	combo_label.add_theme_constant_override("outline_size", 4)
	combo_label.visible = false
	combo_label.modulate.a = 0.0
	add_child(combo_label)

## Show combo indicator with animation
## combo: The combo multiplier (2, 3, 4, etc.)
func show_combo(combo: int) -> void:
	if combo_label == null:
		return
	
	combo_label.text = "COMBO x%d" % combo
	combo_label.visible = true
	combo_label.scale = Vector2(0.5, 0.5)
	combo_label.modulate.a = 0.0
	
	# Animate in: scale up and fade in
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(combo_label, "scale", Vector2(1.2, 1.2), 0.2)\
		 .set_trans(Tween.TRANS_BACK)\
		 .set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_label, "modulate:a", 1.0, 0.2)
	
	# Hold for a moment
	tween.chain().tween_interval(0.5)
	
	# Animate out: scale up more and fade out
	tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.3)\
		 .set_trans(Tween.TRANS_QUAD)\
		 .set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(combo_label, "modulate:a", 0.0, 0.3)
	
	# Hide after animation
	await tween.finished
	combo_label.visible = false
