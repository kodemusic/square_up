extends Control

## Mobile-friendly HUD for Square Up puzzle game
## Displays score, moves remaining, and level completion banners

## Emitted when user wants to restart the current level
signal restart_requested

## Emitted when user wants to undo last move
signal undo_requested

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

func _ready() -> void:
	# Hide banner initially
	banner.visible = false

	# Initialize display
	update_score(0)
	update_moves(0)

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
	update_score(0)
	update_moves(0)
	update_squares(0)
	hide_banner()
