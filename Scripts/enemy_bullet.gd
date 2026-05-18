# ════════════════════════════════════════════════════════════
# BULLET - Proyectil disparado por enemigos
# ════════════════════════════════════════════════════════════
extends Area2D

# ─── Configuración exportable ────────────────────────────────
@export var speed: float = 300

# ─── Variables internas ──────────────────────────────────────
var direction: Vector2 = Vector2.DOWN
var can_hit: bool = false

# ─── Inicialización ──────────────────────────────────────────
func _ready():
	add_to_group("enemy_bullet")

	# Conectar señales de colisión solo si no están ya conectadas
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Pequeña espera para evitar que la bala se destruya al nacer
	# si colisiona con el propio enemigo que la disparó
	await get_tree().create_timer(0.1).timeout
	can_hit = true

# ─── Movimiento ──────────────────────────────────────────────
func _process(delta: float) -> void:
	position += direction * speed * delta

# ─── Colisiones ──────────────────────────────────────────────

# Impacto contra un Area2D del jugador
func _on_area_entered(area: Area2D) -> void:
	if not can_hit:
		return
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(1)
		queue_free()

# Impacto contra un CharacterBody2D / RigidBody2D del jugador
func _on_body_entered(body: Node2D) -> void:
	if not can_hit:
		return
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
