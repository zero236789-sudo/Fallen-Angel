# ENEMY (Skull)
extends CharacterBody2D

signal health_changed(new_hp: int, max_hp: int)
signal phase_changed(phase: int)

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.5
@export var bullets_per_shot: int = 3
@export var spread_angle: float = 30
@export var aim_at_player: bool = true
@export var max_health: int = 16
@export var points: int = 100
@export var arm_bullet_speed: float = 350.0
@export var arm_fire_rate: float = 0.08  # velocidad del loop del molinillo

var current_health: int
var player: Node2D
var can_shoot := false
var is_dead := false
var current_phase := 3
var ring_angle := 0.0
var arm_angle := 0.0

func _ready():
	current_health = max_health
	add_to_group("enemy")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	await get_tree().create_timer(0.5).timeout
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.animation = "default"
		sprite.play()
	start_shooting()

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

func shoot_loop() -> void:
	while is_instance_valid(self) and not is_dead:
		match current_phase:
			3: shoot_phase3()
			2: shoot_phase2()
			1: await shoot_phase1()
		await get_tree().create_timer(fire_rate).timeout

# Loop independiente del molinillo — corre en paralelo
func arm_loop() -> void:
	while is_instance_valid(self) and not is_dead and current_phase == 2:
		var arms := 16
		for i in range(arms):
			var angle = arm_angle + (TAU / arms) * i
			spawn_arm_bullet(global_position, Vector2(cos(angle), sin(angle)))
		arm_angle += deg_to_rad(15.0)
		await get_tree().create_timer(arm_fire_rate).timeout

func shoot_phase3() -> void:
	var pts = get_spawn_points()
	if pts.is_empty():
		fire_spread(global_position, bullets_per_shot, spread_angle)
	else:
		for sp in pts:
			fire_spread(sp.global_position, bullets_per_shot, spread_angle)
	for i in range(64):
		var angle = (TAU / 8.0) * i
		spawn_bullet(global_position, Vector2(cos(angle), sin(angle)))

func shoot_phase2() -> void:
	for i in range(22):
		var angle = ring_angle + (TAU / 22.0) * i
		spawn_bullet(global_position, Vector2(cos(angle), sin(angle)))
	ring_angle += deg_to_rad(12.0)

func shoot_phase1() -> void:
	for _i in range(4):
		fire_spread(global_position, 8, 25.0)
		await get_tree().create_timer(0.1).timeout
	for i in range(40):
		var angle = ring_angle + (TAU / 40.0) * i
		spawn_bullet(global_position, Vector2(cos(angle), sin(angle)))
	ring_angle += deg_to_rad(18.0)

func fire_spread(origin: Vector2, count: int, angle_range: float) -> void:
	var base = get_base_dir(origin)
	if count <= 1:
		spawn_bullet(origin, base)
		return
	var step = angle_range / (count - 1)
	for i in range(count):
		spawn_bullet(origin, base.rotated(deg_to_rad(-angle_range * 0.5 + step * i)))

func get_base_dir(origin: Vector2) -> Vector2:
	if aim_at_player and is_instance_valid(player):
		return origin.direction_to(player.global_position)
	return Vector2.DOWN

func spawn_bullet(origin: Vector2, dir: Vector2) -> void:
	var b = bullet_scene.instantiate()
	b.global_position = origin
	if "direction" in b:
		b.direction = dir.normalized()
	get_tree().current_scene.add_child(b)

func spawn_arm_bullet(origin: Vector2, dir: Vector2) -> void:
	var b = bullet_scene.instantiate()
	b.global_position = origin
	if "direction" in b:
		b.direction = dir.normalized()
	if "speed" in b:
		b.speed = arm_bullet_speed
	get_tree().current_scene.add_child(b)

func _get_phase() -> int:
	var pct = float(current_health) / float(max_health)
	if pct > 0.66: return 3
	elif pct > 0.33: return 2
	else: return 1

func _check_phase() -> void:
	var p = _get_phase()
	if p != current_phase:
		current_phase = p
		emit_signal("phase_changed", current_phase)
		if current_phase == 2:
			arm_loop()  # arranca el loop al entrar en fase 2
		flash_phase()

func flash_phase() -> void:
	var s1 = get_node_or_null("Sprite2D")
	var s2 = get_node_or_null("Sprite2D2")
	for _i in range(4):
		if s1: s1.modulate = Color.WHITE * 2.5
		if s2: s2.modulate = Color.WHITE * 2.5
		await get_tree().create_timer(0.08).timeout
		if s1: s1.modulate = Color.WHITE
		if s2: s2.modulate = Color.WHITE
		await get_tree().create_timer(0.08).timeout

func flash_damage() -> void:
	var s1 = get_node_or_null("Sprite2D")
	var s2 = get_node_or_null("Sprite2D2")
	if s1: s1.modulate = Color.RED
	if s2: s2.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if s1: s1.modulate = Color.WHITE
	if s2: s2.modulate = Color.WHITE

func take_damage(amount: int) -> void:
	if is_dead: return
	current_health -= amount
	emit_signal("health_changed", current_health, max_health)
	flash_damage()
	_check_phase()
	if current_health <= 0:
		die()

func die() -> void:
	if is_dead: return
	is_dead = true
	GameManager.add_score(points)
	queue_free()
