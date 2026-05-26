extends Node2D

func _ready():
	# Música
	var persistent = get_tree().root.get_node_or_null("PersistentMusic")
	if persistent:
		persistent.queue_free()
	$FinalBossTheme.play()

	# Fade de entrada: negro -> transparente
	var canvas = CanvasLayer.new()
	canvas.layer = 99
	add_child(canvas)

	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 1)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)

	var tween = create_tween()
	tween.tween_property(rect, "color:a", 0.0, 1.2)
	await tween.finished

	# Limpiamos cuando ya no hace falta
	canvas.queue_free()
