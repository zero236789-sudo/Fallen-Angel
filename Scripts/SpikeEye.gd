extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 2.0        # Dispara lento (básico tiene 0.5)
@export var bullets_per_shot: int = 8     # Muchas balas en anillo
@export var spread_angle: float = 360.0   # Anillo completo
@export var aim_at_player: bool = false   # No apunta, dispara en todas direcciones
@export var max_health: int = 60          # Mucha vida (básico tiene 16)
@export var points: int = 300             # Da más puntos por ser difícil

var current_health: int
var player: Node2D
var can_shoot := false
var is_dead := false

func _ready():
	current_health = max_health
	add_to_group("enemy")

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_error("Player not found")

	# Arranca la animación
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.animation = "default"
		sprite.play()

	start_shooting()

# SHOOTING
func start_shooting():
	if can_shoot:
		return
	can_shoot = true
	shoot_loop()

func shoot_loop() -> void:
	while is_instance_valid(self) and not is_dead:
		shoot()
		await get_tree().create_timer(fire_rate).timeout

func shoot():
	if bullet_scene == null:
		push_error("bullet_scene is not assigned in TankEnemy!")
		return

	# Dispara en anillo completo repartiendo las balas uniformemente
	for i in range(bullets_per_shot):
		var angle = (TAU / bullets_per_shot) * i
		spawn_bullet(Vector2(cos(angle), sin(angle)))

func spawn_bullet(dir: Vector2):
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position

	if "direction" in bullet:
		bullet.direction = dir.normalized()

	get_tree().current_scene.add_child.call_deferred(bullet)

# DAÑO
func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health -= amount
	flash_damage()
	if current_health <= 0:
		die()

func flash_damage() -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if sprite:
		sprite.modulate = Color.WHITE

func die() -> void:
	if is_dead:
		return
	is_dead = true
	queue_free()
