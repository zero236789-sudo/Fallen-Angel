extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.5
@export var bullets_per_shot: int = 3
@export var spread_angle: float = 30
@export var aim_at_player: bool = true
@export var max_health: int = 16
@export var points: int = 100
@export var arm_bullet_speed: float = 350.0
@export var arm_fire_rate: float = 0.08

var current_health: int
var player: Node2D
var can_shoot := false
var is_dead := false
var ring_angle := 0.0
var arm_angle := 0.0

# ─── Temporizador de puntos ──────────────────────────────────
var points_current: int
var points_min: int = 100
var timer_active: bool = false
var entered_screen: bool = false

func _ready():
	points_current = points
	current_health = max_health
	add_to_group("enemy")

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.animation_finished.connect(_on_sprite_animation_finished)
		sprite.play("fade")
	else:
		start_shooting()

func _on_sprite_animation_finished():
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite and sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		sprite.animation_finished.disconnect(_on_sprite_animation_finished)
	start_shooting()

func _process(_delta: float) -> void:
	var screen = get_viewport_rect()
	if screen.has_point(global_position):
		if not entered_screen:
			entered_screen = true
			start_point_timer()
	else:
		if entered_screen and not is_dead:
			stop_point_timer()
			queue_free()

func get_spawn_points() -> Array:
	var result: Array = []
	_collect(self, result)
	return result

func _collect(node: Node, result: Array) -> void:
	for child in node.get_children():
		if child.name.begins_with("spawnpos"):
			result.append(child)
		_collect(child, result)

func start_shooting():
	if can_shoot:
		return
	can_shoot = true
	shoot_loop()
	arm_loop()

func shoot_loop() -> void:
	while is_instance_valid(self) and not is_dead:
		shoot_ring()
		await get_tree().create_timer(fire_rate).timeout

func arm_loop() -> void:
	while is_instance_valid(self) and not is_dead:
		var arms := 12
		for i in range(arms):
			var angle = arm_angle + (TAU / arms) * i
			var spawn = get_node_or_null("spawnpos")
			var origin = spawn.global_position if spawn else global_position
			spawn_arm_bullet(origin, Vector2(cos(angle), sin(angle)))
		arm_angle += deg_to_rad(15.0)
		await get_tree().create_timer(arm_fire_rate).timeout

func shoot_ring() -> void:
	for i in range(22):
		var angle = ring_angle + (TAU / 22.0) * i
		var spawn = get_node_or_null("spawnpos")
		var origin = spawn.global_position if spawn else global_position
		spawn_bullet(origin, Vector2(cos(angle), sin(angle)))
	ring_angle += deg_to_rad(12.0)

func get_base_dir(origin: Vector2) -> Vector2:
	if aim_at_player and is_instance_valid(player):
		return origin.direction_to(player.global_position)
	return Vector2.DOWN

func spawn_bullet(origin: Vector2, dir: Vector2) -> void:
	if not bullet_scene:
		return
	var b = bullet_scene.instantiate()
	b.global_position = origin
	if "direction" in b:
		b.direction = dir.normalized()  # Sin el - para que vaya en dirección contraria a la izquierda
	get_tree().current_scene.add_child(b)

func spawn_arm_bullet(origin: Vector2, dir: Vector2) -> void:
	if not bullet_scene:
		return
	var b = bullet_scene.instantiate()
	b.global_position = origin
	if "direction" in b:
		b.direction = dir.normalized()  # Sin el - para que vaya en dirección contraria a la izquierda
	if "speed" in b:
		b.speed = arm_bullet_speed
	get_tree().current_scene.add_child(b)

func flash_damage() -> void:
	var s1 = get_node_or_null("Sprite2D")
	var s2 = get_node_or_null("Sprite2D2")
	if s1: s1.modulate = Color.RED
	if s2: s2.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if s1: s1.modulate = Color.WHITE
	if s2: s2.modulate = Color.WHITE

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
	stop_point_timer()
	GameManager.add_score(points_current)
	queue_free()

# ─── TEMPORIZADOR DE PUNTOS ──────────────────────────────────
func start_point_timer() -> void:
	if timer_active:
		return
	timer_active = true
	while timer_active and is_instance_valid(self):
		await get_tree().create_timer(1.0).timeout
		if not timer_active:
			break
		points_current = max(points_min, points_current - 10)

func stop_point_timer() -> void:
	timer_active = false
