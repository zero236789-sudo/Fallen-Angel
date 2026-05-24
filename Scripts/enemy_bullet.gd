extends Area2D

@export var speed: float = 300
@export var lifetime: float = 8.0   # ⏱ Seguridad extra

var direction: Vector2 = Vector2.DOWN
var can_hit: bool = false

func _ready():
	# Grupo para NodeCleaner
	add_to_group("enemy_bullet")

	# Conectar señales solo si no están conectadas
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Evitar colisión inmediata con el enemigo que la dispara
	await get_tree().create_timer(0.05).timeout
	can_hit = true

	# ⏱ Timer interno de seguridad
	_cleanup_timer()


func _process(delta: float) -> void:
	position += direction * speed * delta

	# Seguridad adicional por si sale por los lados
	if position.y > 2000 or position.y < -2000:
		queue_free()
	if position.x > 2000 or position.x < -2000:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not can_hit:
		return

	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(1)
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not can_hit:
		return

	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()

	elif body.is_in_group("wall"):
		queue_free()


func _on_screen_exited():
	queue_free()


# ─── Timer interno de limpieza ───────────────────────────────
func _cleanup_timer():
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()
 
