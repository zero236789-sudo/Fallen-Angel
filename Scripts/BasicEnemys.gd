extends CharacterBody2D

@export var bullet_scene: PackedScene

@export var fire_rate: float = 0.5
@export var bullets_per_shot: int = 3
@export var spread_angle: float = 30
@export var aim_at_player: bool = true

@export var max_health: int = 16

var current_health: int
var player: Node2D
var can_shoot := false


func _ready():
	current_health = max_health
	
	add_to_group("enemy")
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_error("Player not found")
	
	start_shooting()

# SHOOTING

func start_shooting():
	if can_shoot:
		return
	can_shoot = true
	shoot_loop()


func shoot_loop() -> void:
	while is_instance_valid(player):
		shoot()
		await get_tree().create_timer(fire_rate).timeout


func shoot():
	if bullet_scene == null:
		push_error("bullet_scene is not assigned in Enemy!")
		return

	var base_dir = get_base_direction()

	if bullets_per_shot <= 1:
		spawn_bullet(base_dir)
		return

	var step = spread_angle / (bullets_per_shot - 1)
	var start = -spread_angle * 0.5

	for i in range(bullets_per_shot):
		var angle = deg_to_rad(start + step * i)
		spawn_bullet(base_dir.rotated(angle))


func get_base_direction() -> Vector2:
	if aim_at_player and is_instance_valid(player):
		return global_position.direction_to(player.global_position)
	else:
		return Vector2.DOWN


func spawn_bullet(dir: Vector2):
	if bullet_scene == null:
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	
	if bullet.has_method("set") and "direction" in bullet:
		bullet.direction = dir.normalized()
	
	get_tree().current_scene.add_child.call_deferred(bullet)


func take_damage(amount: int) -> void:
	current_health -= amount
	
	flash_damage()
	
	if current_health <= 0:
		die()


func flash_damage() -> void:
	# Cambiar color de los sprites
	var sprite1 = get_node_or_null("Sprite2D")
	var sprite2 = get_node_or_null("Sprite2D2")
	
	if sprite1:
		sprite1.modulate = Color.RED
	if sprite2:
		sprite2.modulate = Color.RED
	
	await get_tree().create_timer(0.1).timeout
	
	if sprite1:
		sprite1.modulate = Color.WHITE
	if sprite2:
		sprite2.modulate = Color.WHITE


func die() -> void:
	# Aquí puedes añadir efectos de explosión, sonido, puntos, etc.
	queue_free()
