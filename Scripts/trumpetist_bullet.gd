# ════════════════════════════════════════════════════════════
# TRUMPETIST BULLET - Nota musical con movimiento zigzag
# ════════════════════════════════════════════════════════════
extends Area2D

@export var speed: float = 300
@export var zigzag_amplitude: float = 80.0  # Qué tan ancho es el zigzag
@export var zigzag_frequency: float = 3.0   # Qué tan rápido oscila

var direction: Vector2 = Vector2.DOWN
var can_hit: bool = false
var time: float = 0.0
var side: float = 1.0  # 1.0 o -1.0, para alternar lado del zigzag

func _ready():
	add_to_group("enemy_bullet")

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# Arranca la animación de la nota
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.animation = "default"
		sprite.play()

	await get_tree().create_timer(0.1).timeout
	can_hit = true

func _process(delta: float) -> void:
	time += delta

	# Movimiento principal hacia adelante
	var forward = direction * speed * delta

	# Movimiento lateral oscilante (zigzag)
	var perpendicular = Vector2(-direction.y, direction.x)
	var lateral = perpendicular * sin(time * zigzag_frequency) * zigzag_amplitude * delta * side

	position += forward + lateral

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
