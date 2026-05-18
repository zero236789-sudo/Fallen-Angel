extends Node2D

@export var damage: int = 1
@export var max_length: float = 1000.0
@export var ray_duration: float = 0.15  # segundos que dura el rayo
@export var zigzag_segments: int = 12   # cantidad de puntos del zigzag
@export var zigzag_amplitude: float = 4.0  # ancho del zigzag

@onready var ray_line: Line2D = $Line2D
@onready var glow_line: Line2D = $GlowLine2D
@onready var ray_cast: RayCast2D = $RayCast2D
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var timer: Timer = $Timer

var hit_length: float = 0.0

func _ready() -> void:
	# Configurar RayCast hacia arriba
	ray_cast.target_position = Vector2(0, -max_length)
	ray_cast.enabled = true
	ray_cast.force_raycast_update()

	# Calcular longitud real (con o sin colisión)
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		var hit_point = ray_cast.get_collision_point()
		hit_length = global_position.distance_to(hit_point)

		# Aplicar daño
		if collider.has_method("take_damage"):
			collider.take_damage(damage)
		elif collider.is_in_group("enemy") and collider.has_method("take_damage"):
			collider.take_damage(damage)

		# Chispas en el punto de impacto
		particles.global_position = hit_point
		particles.emitting = true
	else:
		hit_length = max_length
		particles.emitting = false

	_draw_ray(hit_length)

	timer.wait_time = ray_duration
	timer.one_shot = true
	timer.start()
	timer.timeout.connect(queue_free)

func _process(_delta: float) -> void:
	# Animar el zigzag cada frame para efecto eléctrico vivo
	_draw_ray(hit_length)

func _draw_ray(length: float) -> void:
	var points_main: Array[Vector2] = []
	var points_glow: Array[Vector2] = []

	var segments = zigzag_segments
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var y = -length * t
		var x_offset = 0.0

		# Zigzag solo en los puntos intermedios
		if i > 0 and i < segments:
			x_offset = randf_range(-zigzag_amplitude, zigzag_amplitude)

		points_main.append(Vector2(x_offset, y))
		points_glow.append(Vector2(x_offset * 0.5, y))  # glow más centrado

	ray_line.points = points_main
	glow_line.points = points_glow
