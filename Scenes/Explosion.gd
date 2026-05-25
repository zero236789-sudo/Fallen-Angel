extends Node2D

func _ready():
	$AnimatedSprite2D.play("default")
	$Bomba.play()
	await $AnimatedSprite2D.animation_finished
	# Saca el audio a la escena principal para que siga sonando
	var audio = $Bomba
	remove_child(audio)
	get_tree().current_scene.add_child(audio)
	audio.finished.connect(audio.queue_free)
	queue_free()
