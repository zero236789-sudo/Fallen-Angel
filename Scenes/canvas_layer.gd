extends CanvasLayer

@onready var hearts = [
	$HeartsContainer/Heart1,
	$HeartsContainer/Heart2,
	$HeartsContainer/Heart3
]
@onready var score_label = $ScoreLabel

@export var heart_full: Texture2D
@export var heart_empty: Texture2D

func _ready():
	# Aplicar textura inicial a todos los corazones
	for heart in hearts:
		heart.texture = heart_full
	
	GameManager.lives_changed.connect(update_lives)
	GameManager.score_changed.connect(update_score)
	update_lives(GameManager.lives)
	update_score(GameManager.score)

func update_lives(current_lives: int) -> void:
	for i in range(hearts.size()):
		hearts[i].visible = (i < current_lives)

func update_score(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)
