extends Area2D

@export var speed: float = 600
@export var damage: int = 1

var lifetime: float = 5.0  # ⏱ Tiempo máximo de vida (seguridad extra)

func _ready():
	# ✅ Conecta señales solo si no están ya conectadas
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	set_deferred("monitoring", true)
	add_to_group("player_bullet")  # 🔹 Para que NodeCleaner pueda rastrearla

	# ⏱ Timer interno para eliminar balas que no salgan de pantalla
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()


func _process(delta: float) -> void:
	position += Vector2.UP * speed * delta

	# 🔹 Limpieza por posición (seguridad adicional)
	if position.y < -100:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		body.take_damage(damage)
		queue_free()


func _on_screen_exited():
	queue_free()


func _on_particles_finished():
	queue_free()
