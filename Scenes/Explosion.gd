extends Node2D

func _ready():
	# Reproduce la animación y el sonido al instanciarse
	$AnimatedSprite2D.play("default")
	$AudioStreamPlayer2D.play()

	# Calcula automáticamente la duración total según los frames y FPS
	var sprite = $AnimatedSprite2D
	var frames_count = sprite.sprite_frames.get_frame_count("default")
	var fps = sprite.sprite_frames.get_animation_speed("default")
	var duracion = float(frames_count) / float(fps)

	# Espera a que termine la animación antes de eliminar el nodo
	await get_tree().create_timer(duracion).timeout
	queue_free()
