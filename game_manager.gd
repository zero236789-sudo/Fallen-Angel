extends Node

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)

var score: int = 0
var highscore: int = 0
var lives: int = 3
var bombs: int = 2        # añadido
var bombs_max: int = 2    # añadido

const MAX_LIVES: int = 3  # añadido
const MAX_BOMBS: int = 3  # añadido

func add_score(points: int) -> void:
	score += points
	if score > highscore:
		highscore = score
	score_changed.emit(score)

func reset() -> void:
	score = 0
	lives = 3
	bombs = 2
	bombs_max = 2
	score_changed.emit(score)
	lives_changed.emit(lives)

func take_damage(amount: int) -> void:
	lives -= amount
	lives_changed.emit(lives)

func level_up_bonus() -> void:       # añadido
	lives = min(lives + 1, MAX_LIVES)
	bombs_max = min(bombs_max + 1, MAX_BOMBS)
	bombs = bombs_max
	lives_changed.emit(lives)
