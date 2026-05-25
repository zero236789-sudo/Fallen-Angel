extends CharacterBody2D

signal enemy_died  # << CabraGalega escucha esto

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.5
@export var bullets_per_shot: int = 3
@export var spread_angle: float = 30
@export var aim_at_player: bool = true
@export var max_health: int = 16
@export var points: int = 100
@export var arm_bullet_speed: float = 350.0
@export var arm_fire_rate: float = 0.08

# ─── Fase 2 ───────────────────────────────────────────────────
@export var phase2_fire_rate: float = 0.06
@export var phase2_bullet_speed: float = 600.0
@export var phase2_burst_count: int = 15
@export var phase2_burst_pause: float = 0.5

# ─── Fase 3: Mandala Asíncrona ────────────────────────────────
@export var mandala_ring_counts: Array = [12, 16, 8, 20]
@export var mandala_ring_speeds: Array = [0.43, -0.68, 1.04, -1.43]
@export var mandala_bullet_speeds: Array = [150.0, 220.0, 300.0, 180.0]
@export var mandala_bullet_scales: Array = [1.2, 0.8, 1.5, 0.7]
@export var mandala_ring_delay: float = 0.05
@export var mandala_burst_pause: float = 0.28
@export var mandala_spiral_speed: float = 260.0
@export var mandala_spiral_increment: float = 0.37

# ─── Fase 4: Medusa Negra ─────────────────────────────────────
@export var phase4_tentacle_groups: int = 5
@export var phase4_tentacle_per_group: int = 3
@export var phase4_tentacle_spread: float = 0.18
@export var phase4_tentacle_speed: float = 220.0
@export var phase4_tentacle_fire_rate: float = 0.13
@export var phase4_tentacle_rotate: float = 0.55

@export var phase4_spine_count: int = 18
@export var phase4_spine_speed: float = 310.0
@export var phase4_spine_spiral_inc: float = 0.21
@export var phase4_spine_bursts: int = 6
@export var phase4_spine_burst_rate: float = 0.07

@export var phase4_A_count: int = 3
@export var phase4_AB_pause: float = 0.35

var is_phase2: bool = false
var is_phase3: bool = false
var is_phase4: bool = false

var mandala_angles: Array = [0.0, 0.0, 0.0, 0.0]
var spiral_t: float = 0.0

var _p4_tentacle_angle: float = 0.0
var _p4_spine_angle: float = 0.0

var current_health: int
var player: Node2D
var can_shoot := false
var is_dead := false
var ring_angle := 0.0
var arm_angle := 0.0
var points_current: int
var points_min: int = 100
var timer_active: bool = false
var entered_screen: bool = false


func _ready():
	points_current = points
	current_health = max_health
	add_to_group("enemy")
	add_to_group("right_hand")
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


func _process(delta: float) -> void:
	var screen = get_viewport_rect()
	if screen.has_point(global_position):
		if not entered_screen:
			entered_screen = true
			start_point_timer()
	else:
		if entered_screen and not is_dead:
			stop_point_timer()
			queue_free()

	if is_phase3 and not is_phase4 and not is_dead:
		for i in range(mandala_angles.size()):
			mandala_angles[i] += mandala_ring_speeds[i] * delta

	if is_phase4 and not is_dead:
		_p4_tentacle_angle += phase4_tentacle_rotate * delta

	if not is_phase3 and not is_dead:
		var left_hands = get_tree().get_nodes_in_group("left_hand")
		if left_hands.size() == 0 and entered_screen:
			enter_phase_3()


func get_spawn_points() -> Array:
	var result: Array = []
	_collect(self, result)
	return result


func _collect(node, result: Array) -> void:
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
	while is_instance_valid(self) and not is_dead and not is_phase2 and not is_phase3:
		shoot_ring()
		await get_tree().create_timer(fire_rate).timeout


func arm_loop() -> void:
	while is_instance_valid(self) and not is_dead and not is_phase2 and not is_phase3:
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
		b.direction = dir.normalized()
	get_tree().current_scene.add_child(b)


func spawn_arm_bullet(origin: Vector2, dir: Vector2) -> void:
	if not bullet_scene:
		return
	var b = bullet_scene.instantiate()
	b.global_position = origin
	if "direction" in b:
		b.direction = dir.normalized()
	if "speed" in b:
		b.speed = arm_bullet_speed
	get_tree().current_scene.add_child(b)


func enter_phase_2() -> void:
	if is_phase2:
		return
	is_phase2 = true
	phase2_loop()


func phase2_loop() -> void:
	while is_instance_valid(self) and not is_dead and not is_phase3:
		for i in range(phase2_burst_count):
			shoot_tracking()
			await get_tree().create_timer(phase2_fire_rate).timeout
		await get_tree().create_timer(phase2_burst_pause).timeout


func enter_phase_3() -> void:
	if is_phase3:
		return
	is_phase3 = true
	is_phase2 = true
	mandala_angles = [0.0, 0.0, 0.0, 0.0]
	spiral_t = 0.0
	mandala_loop()


func mandala_loop() -> void:
	while is_instance_valid(self) and not is_dead and not is_phase4:
		for ring_idx in range(mandala_angles.size()):
			shoot_mandala_ring(ring_idx)
			await get_tree().create_timer(mandala_ring_delay).timeout
		shoot_double_spiral()
		await get_tree().create_timer(mandala_burst_pause).timeout


func shoot_mandala_ring(ring_idx: int) -> void:
	if not bullet_scene:
		return
	var spawn = get_node_or_null("spawnpos")
	var origin = spawn.global_position if spawn else global_position
	var n = mandala_ring_counts[ring_idx]
	var spd = mandala_bullet_speeds[ring_idx]
	var sz = mandala_bullet_scales[ring_idx]
	var base = mandala_angles[ring_idx]
	for i in range(n):
		var angle = base + (TAU / n) * i
		var dir = Vector2(cos(angle), sin(angle))
		var b = bullet_scene.instantiate()
		b.global_position = origin
		if "direction" in b:
			b.direction = dir.normalized()
		if "speed" in b:
			b.speed = spd
		if "scale" in b:
			b.scale = Vector2(sz, sz)
		get_tree().current_scene.add_child(b)


func shoot_double_spiral() -> void:
	if not bullet_scene:
		return
	var spawn = get_node_or_null("spawnpos")
	var origin = spawn.global_position if spawn else global_position
	spiral_t += mandala_spiral_increment
	for arm in range(2):
		var base_angle = spiral_t + arm * PI
		for i in range(6):
			var angle = base_angle + (TAU / 6.0) * i
			var dir = Vector2(cos(angle), sin(angle))
			var b = bullet_scene.instantiate()
			b.global_position = origin
			if "direction" in b:
				b.direction = dir.normalized()
			if "speed" in b:
				b.speed = mandala_spiral_speed
			get_tree().current_scene.add_child(b)


# ─── Fase 4: Medusa Negra ─────────────────────────────────────────────────────

func enter_phase_4() -> void:
	if is_phase4:
		return
	is_phase4 = true
	_p4_tentacle_angle = 0.0
	_p4_spine_angle = 0.0
	phase4_loop()


func phase4_loop() -> void:
	while is_instance_valid(self) and not is_dead:
		for _a in range(phase4_A_count):
			if is_dead or not is_instance_valid(self):
				return
			_shoot_tentacles()
			await get_tree().create_timer(phase4_tentacle_fire_rate).timeout

		await get_tree().create_timer(phase4_AB_pause).timeout

		for _b in range(phase4_spine_bursts):
			if is_dead or not is_instance_valid(self):
				return
			_shoot_spines()
			_p4_spine_angle += phase4_spine_spiral_inc
			await get_tree().create_timer(phase4_spine_burst_rate).timeout

		await get_tree().create_timer(phase4_AB_pause).timeout


func _shoot_tentacles() -> void:
	if not bullet_scene:
		return
	var spawn = get_node_or_null("spawnpos")
	var origin: Vector2 = spawn.global_position if spawn else global_position

	for g in range(phase4_tentacle_groups):
		var group_base: float = _p4_tentacle_angle + (TAU / phase4_tentacle_groups) * g
		for k in range(phase4_tentacle_per_group):
			var half: float = (phase4_tentacle_per_group - 1) / 2.0
			var offset: float = (k - half) * phase4_tentacle_spread
			var angle: float = group_base + offset
			var dir := Vector2(cos(angle), sin(angle))
			var b = bullet_scene.instantiate()
			b.global_position = origin
			if "direction" in b:
				b.direction = dir
			if "speed" in b:
				b.speed = phase4_tentacle_speed - abs(k - half) * 30.0
			get_tree().current_scene.call_deferred("add_child", b)


func _shoot_spines() -> void:
	if not bullet_scene:
		return
	var spawn = get_node_or_null("spawnpos")
	var origin: Vector2 = spawn.global_position if spawn else global_position

	for i in range(phase4_spine_count):
		var angle: float = _p4_spine_angle + (TAU / phase4_spine_count) * i
		var speed_mod: float = phase4_spine_speed if i % 2 == 0 else phase4_spine_speed * 0.78
		var dir := Vector2(cos(angle), sin(angle))
		var b = bullet_scene.instantiate()
		b.global_position = origin
		if "direction" in b:
			b.direction = dir
		if "speed" in b:
			b.speed = speed_mod
		get_tree().current_scene.call_deferred("add_child", b)


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
	# << FIX: cast a float para evitar integer division warning
	if not is_phase4 and current_health <= int(max_health / 2.0) and current_health > 0:
		enter_phase_4()
	if current_health <= 0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	stop_point_timer()
	GameManager.add_score(points_current)
	enemy_died.emit()  # << avisa a CabraGalega
	queue_free()


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
