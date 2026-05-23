extends Node

signal score_changed(new_score: int)
signal lives_changed(new_lives: int)

var score: int = 0
var highscore: int = 0
var lives: int = 3

func add_score(points: int) -> void:
	score += points
	if score > highscore:
		highscore = score
	score_changed.emit(score)

func reset() -> void:
	score = 0
	lives = 3
	score_changed.emit(score)
	lives_changed.emit(lives)

func take_damage(amount: int) -> void:
	lives -= amount
	lives_changed.emit(lives)
