extends Node2D

func _ready():
	await get_tree().process_frame
	$BattleMusic.finished.connect(_on_battle_music_finished)
	$BattleMusic.play()

func _on_battle_music_finished() -> void:
	$AngelMusic.play()
