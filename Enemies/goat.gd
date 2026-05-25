extends CharacterBody2D

@export var bullet_scene: PackedScene
@export var homing_bullet_scene: PackedScene
@export var fire_rate: float = 0.5
@export var bullets_per_shot: int = 3
@export var spread_angle: float = 30
@export var aim_at_player: bool = true
@export var max_health: int = 16
@export var points: int = 100
@export var arm_bullet_speed: float = 350.0
@export var arm_fire_rate: float = 0.08

signal cabra_started_attacking  # << las Spiders escuchan esto

var current_health: int
var player: Node2D
var can_shoot := false
var is_dead := false
var ring_angle := 0.0
var arm_angle := 0.0
var righthand_dead := false
var _can_fire_homing := true

func _ready():
	current_health = max_health
	add_to_group("enemy")
	add_to_group("cabra_galega")  # << las Spiders la encuentran por este grupo
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	await get_tree().process_frame
	_try_connect_righthand()
	await get_tree().create_timer(0.5).timeout
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.animation = "default"
		sprite.play()

func _try_connect_righthand() -> void:
	var righthand_list = get_tree().get_nodes_in_group("right_hand")
	if righthand_list.size() == 0:
		await get_tree().process_frame
		_try_connect_righthand()
		return
	for rh in righthand_list:
		if rh.has_signal("enemy_died"):
			if not rh.enemy_died.is_connected(_on_righthand_died):
				rh.enemy_died.connect(_on_righthand_died)

func _on_righthand_died() -> void:
	if righthand_dead:
		return
	righthand_dead = true
	cabra_started_attacking.emit()  # << avisa a las Spiders
	_start_openmoutn_attack()

func _start_openmoutn_attack() -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	sprite.animation = "OpenMouth"
	sprite.play()
	if not sprite.frame_changed.is_connected(_on_openmoutn_frame_changed):
		sprite.frame_changed.connect(_on_openmoutn_frame_changed)

func _on_openmoutn_frame_changed() -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if not sprite:
		return
	if sprite.frame == 6 and _can_fire_homing:
		_can_fire_homing = false
		_shoot_homing_bullet()
	elif sprite.frame != 6:
		_can_fire_homing = true

func _shoot_homing_bullet() -> void:
	if not homing_bullet_scene:
		push_warning("CabraGalega: homing_bullet_scene no asignada en el Inspector")
		return
	var bullet = homing_bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.speed = 300.0
	bullet.lifetime = 10.0
	get_tree().current_scene.call_deferred("add_child", bullet)

func get_spawn_points() -> Array:
	var result: Array = []
	_collect(self, result)
	return result

func _collect(node: Node, result: Array) -> void:
	for child in node.get_children():
		if child.name.begins_with("spawnpos"):
			result.append(child)
		_collect(child, result)

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
	flash_damage()
	if current_health <= 0:
		die()

func die() -> void:
	if is_dead: return
	is_dead = true
	GameManager.add_score(points)
	queue_free()
