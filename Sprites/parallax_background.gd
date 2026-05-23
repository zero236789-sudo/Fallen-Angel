extends ParallaxBackground

@export var scroll_speed: float = 500.0  # píxeles por segundo

func _process(delta: float) -> void:
	scroll_offset.y += scroll_speed * delta
