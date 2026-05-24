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
