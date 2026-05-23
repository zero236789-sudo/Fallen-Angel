# ════════════════════════════════════════════════════════════
# TRUMPETITI - Es como el Trompetista pero en mini
# ════════════════════════════════════════════════════════════
extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.5        
@export var max_health: int = 8          # Poca vida, tipo básico
@export var points: int = 75

# ─── Zigzag ──────────────────────────────────────────────────
# Alterna entre izquierda y derecha cada disparo
var zigzag_angles: Array = [0.0]  # Ángulos del zigzag
var zigzag_index: int = 0                 # Cuál toca ahora

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

	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.animation = "default"
		sprite.play()

	start_shooting()

# ─── SHOOTING ────────────────────────────────────────────────
func start_shooting():
	if can_shoot:
		return
	can_shoot = true
	shoot_loop()

func shoot_loop() -> void:
	while is_instance_valid(self) and not is_dead:
		shoot()
		await get_tree().create_timer(fire_rate).timeout

#Función shoot, aqui dispara desde la spawn pos (desde la trompetica)
func shoot():
	if bullet_scene == null:
		push_error("bullet_scene is not assigned in Trumpetist!")
		return

	# Busca el punto de spawn (la trompeta)
	var spawn = get_node_or_null("spawnpos")
	var origin = spawn.global_position if spawn else global_position

	# Dirección base hacia el jugador
	var base_dir = Vector2.DOWN
	if is_instance_valid(player):
		base_dir = origin.direction_to(player.global_position)

	# Alterna el ángulo zigzag en cada disparo
		
	var angle = deg_to_rad(zigzag_angles[zigzag_index])
	zigzag_index = (zigzag_index + 1) % zigzag_angles.size()
	spawn_bullet(origin, base_dir.rotated(angle))  

func spawn_bullet(origin: Vector2, dir: Vector2):
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate()
	bullet.global_position = origin

	if "direction" in bullet:
		bullet.direction = dir.normalized()

	get_tree().current_scene.add_child.call_deferred(bullet)

# ─── DAÑO ────────────────────────────────────────────────────
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
