extends Node2D

@onready var music = $BattleMusic

func _ready():
	await get_tree().process_frame
	var boss = get_node_or_null("Skull")
	music.play()
	if boss == null:
		return
	# Ya no conectamos la barra, el HUD se encargará de eso
