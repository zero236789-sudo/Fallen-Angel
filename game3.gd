extends Node2D

func _ready():
	# Para la música persistente de game
	var persistent = get_tree().root.get_node_or_null("PersistentMusic")
	if persistent:
		persistent.queue_free()
	# Arranca la música del boss
	$FinalBossTheme.play()
