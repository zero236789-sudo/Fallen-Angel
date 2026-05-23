extends CharacterBody2D
@export var speed: float = 200.0
@export var stop_y: float = 150.0
@export var bullet_scene: PackedScene
@export var shoot_cooldown: float = 0.15
@export var spread_angle: float = 15.0
@export var max_health: int = 10
@export var points: int = 200

var has_stopped: bool = false
var has_shooting_loop_started: bool = false
var player: Node2D = null
var current_health: int
var is_dead: bool = false

const FIXED_WAIT_TIME: float = 0.25

func _ready():
	current_health = max_health
	add_to_group("enemy")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		print("Error: Player not found in 'player' group.")

func _physics_process(_delta: float) -> void:
	if not has_stopped:
		velocity = Vector2(0, speed)
		move_and_slide()
		if global_position.y >= stop_y:
			has_stopped = true
			velocity = Vector2.ZERO
			if not has_shooting_loop_started:
				has_shooting_loop_started = true
				_shoot_loop_fixed_time()

func shoot_spread(base_direction: Vector2):
	if player == null or bullet_scene == null:
		return
	var half_spread = spread_angle / 2.0
	var angles = [-half_spread, 0.0, half_spread]
	for angle_degrees in angles:
		var bullet = bullet_scene.instantiate()
		bullet.position = global_position
		bullet.direction = base_direction.rotated(deg_to_rad(angle_degrees))
		get_tree().current_scene.add_child(bullet)

func _shoot_loop_fixed_time() -> void:
	while has_stopped and is_instance_valid(player):
		if not is_instance_valid(self):
			return
		await _shoot_loop(4)
		if not is_instance_valid(self):
			return
		await get_tree().create_timer(FIXED_WAIT_TIME).timeout

func _shoot_loop(times: int) -> void:
	for i in range(times):
		if not is_instance_valid(self) or not is_instance_valid(player):
			return
		var base_direction = global_position.direction_to(player.global_position)
		shoot_spread(base_direction)
		await get_tree().create_timer(shoot_cooldown).timeout

func flash_damage() -> void:
	if is_dead:
		return

	var sprite1 = get_node_or_null("Sprite2D")
	var sprite2 = get_node_or_null("Sprite2D2")

	if sprite1:
		sprite1.modulate = Color.RED
	if sprite2:
		sprite2.modulate = Color.RED

	await get_tree().create_timer(0.08).timeout

	if not is_instance_valid(self) or is_dead:
		return

	if sprite1:
		sprite1.modulate = Color.WHITE
	if sprite2:
		sprite2.modulate = Color.WHITE

func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health -= amount
	flash_damage()
	if current_health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	GameManager.add_score(points)
	queue_free()
