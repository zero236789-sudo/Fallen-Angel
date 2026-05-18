extends CharacterBody2D

@export var speed: float = 200.0
@export var stop_y: float = 150.0
@export var bullet_scene: PackedScene
@export var shoot_cooldown: float = 0.15
@export var spread_angle: float = 15.0 

var has_stopped: bool = false
var has_shooting_loop_started: bool = false
var player: Node2D = null


const FIXED_WAIT_TIME: float = 0.25 

func _ready():
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
		await _shoot_loop(4) 
		
		
		await get_tree().create_timer(FIXED_WAIT_TIME).timeout


func _shoot_loop(times: int) -> void:
	for i in range(times):
		
		if is_instance_valid(player):
			var base_direction = global_position.direction_to(player.global_position)
			shoot_spread(base_direction)
		else:
			break
		await get_tree().create_timer(shoot_cooldown).timeout
