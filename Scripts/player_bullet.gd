extends Area2D
@export var speed: float = 600
@export var damage: int = 1

func _ready():
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += Vector2.UP * speed * delta
	if position.y < -100:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):  # ✅ corregido de "Enemies" a "enemy"
		body.take_damage(damage)
		queue_free()
