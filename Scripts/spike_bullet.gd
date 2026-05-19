# ════════════════════════════════════════════════════════════
# SPIKE BULLET - Proyectil disparado por el SpikeEye
# ════════════════════════════════════════════════════════════
extends Area2D

# ─── Configuración exportable ────────────────────────────────
@export var speed: float = 250  # Un poco más lenta que la normal (300)

# ─── Variables internas ──────────────────────────────────────
var direction: Vector2 = Vector2.DOWN
var can_hit: bool = false

# ─── Inicialización ──────────────────────────────────────────
func _ready():
	add_to_group("enemy_bullet")

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Rotar el sprite para que apunte en la dirección que va
	rotation = direction.angle() - PI / 2

	await get_tree().create_timer(0.1).timeout
	can_hit = true

# ─── Movimiento ──────────────────────────────────────────────
func _process(delta: float) -> void:
	position += direction * speed * delta

# ─── Colisiones ──────────────────────────────────────────────
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
