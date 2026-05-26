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
 
# ─── Fase 2 ──────────────────────────────────────────────────
@export var phase2_fire_rate: float = 0.06
@export var phase2_bullet_speed: float = 600.0
@export var phase2_burst_count: int = 15
@export var phase2_burst_pause: float = 0.5
 
var is_phase2: bool = false
var phase2_triggered: bool = false
 
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
	add_to_group("left_hand")
 
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
	while is_instance_valid(self) and not is_dead and not is_phase2:
		shoot_ring()
		await get_tree().create_timer(fire_rate).timeout
 
func arm_loop() -> void:
	while is_instance_valid(self) and not is_dead and not is_phase2:
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
		b.direction = -dir.normalized()
	get_tree().current_scene.add_child(b)
 
func spawn_arm_bullet(origin: Vector2, dir: Vector2) -> void:
	if not bullet_scene:
		return
	var b = bullet_scene.instantiate()
	b.global_position = origin
	if "direction" in b:
		b.direction = -dir.normalized()
	if "speed" in b:
		b.speed = arm_bullet_speed
	get_tree().current_scene.add_child(b)
 
# ─── Fase 2: tracking + balas rápidas ────────────────────────
func enter_phase_2() -> void:
	if is_phase2:
		return
	is_phase2 = true
	phase2_loop()
 
func phase2_loop() -> void:
	while is_instance_valid(self) and not is_dead:
		for i in range(phase2_burst_count):
			shoot_tracking()
			await get_tree().create_timer(phase2_fire_rate).timeout
		await get_tree().create_timer(phase2_burst_pause).timeout
 
func shoot_tracking() -> void:
	if not is_instance_valid(player):
		return
	var spawn = get_node_or_null("spawnpos")
	var origin = spawn.global_position if spawn else global_position
	var dir = origin.direction_to(player.global_position)
	var b = bullet_scene.instantiate()
	b.global_position = origin
	if "direction" in b:
		b.set("direction", dir.normalized())
	if "speed" in b:
		b.set("speed", phase2_bullet_speed)
	get_tree().current_scene.call_deferred("add_child", b)
 
# ─────────────────────────────────────────────────────────────
 

func flash_damage() -> void:
	var s1 = get_node_or_null("AnimatedSprite2D")
	if s1: s1.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if s1: s1.modulate = Color.WHITE
 
func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health -= amount
	flash_damage()
 
	# ── Trigger fase 2 al llegar al 50% ──────────────────────
	if not phase2_triggered and current_health <= max_health / 2.0:
		phase2_triggered = true
		enter_phase_2()
		var right_hands = get_tree().get_nodes_in_group("right_hand")
		for rh in right_hands:
			if rh.has_method("enter_phase_2"):
				rh.enter_phase_2()
 
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
