# GAME
extends Node2D

var health_bar: ProgressBar

func _ready():
	_setup_ui()
	await get_tree().process_frame
	var boss = get_node_or_null("Skull")
	if boss == null: return
	health_bar.max_value = boss.max_health
	health_bar.value = boss.current_health
	boss.health_changed.connect(func(hp, _m): health_bar.value = hp)

func _setup_ui() -> void:
	var w = get_viewport_rect().size.x
	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.show_percentage = false
	health_bar.size = Vector2(w - 20, 12)
	health_bar.position = Vector2(10, 8)
	var bg_s = StyleBoxFlat.new()
	bg_s.bg_color = Color(0.1, 0.1, 0.1)
	health_bar.add_theme_stylebox_override("background", bg_s)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 1.0, 0.3)
	health_bar.add_theme_stylebox_override("fill", fill)
	add_child(health_bar)
