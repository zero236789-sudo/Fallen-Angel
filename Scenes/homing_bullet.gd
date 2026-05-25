extends Area2D

var speed: float = 300.0
var lifetime: float = 10.0
var target: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var fading: bool = false

func _ready():
	add_to_group("enemy_bullet")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	get_tree().create_timer(lifetime).timeout.connect(_start_fade)
	# << conectar solo si NO está ya conectada desde el Inspector
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if fading:
		return
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
	global_position += velocity * delta
	rotation = velocity.angle()

func _start_fade() -> void:
	fading = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(1)
		queue_free()
