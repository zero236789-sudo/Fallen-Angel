# WaveManager.gd
# Pon este archivo en res://Scripts/WaveManager.gd
# Añade un nodo Node2D a tu escena GAME, asígnale este script,
# y configura las oleadas desde el Inspector

class_name WaveManager
extends Node2D

# ─── SEÑALES ───────────────────────────────────────────────────────────────
signal wave_started(wave_index: int, wave_name: String)
signal wave_cleared(wave_index: int)
signal all_waves_cleared()

# ─── EXPORTS (configurables desde el Inspector) ────────────────────────────

## Lista de oleadas en orden. Arrastra los .tres de WaveData aquí
@export var waves: Array[WaveData] = []

## Si es true, empieza automáticamente al entrar a la escena
@export var auto_start: bool = true

## Nodo donde se añaden los enemigos (si está vacío, usa la escena raíz)
@export var enemies_container: Node = null

## Label de la UI para mostrar mensajes de oleada (opcional)
@export var wave_label: NodePath = ""

# ─── ESTADO INTERNO ────────────────────────────────────────────────────────
var current_wave_index: int = -1
var is_running: bool = false
var _wave_label_node: Label = null

# ─── INICIO ────────────────────────────────────────────────────────────────
func _ready() -> void:
	if wave_label != "":
		_wave_label_node = get_node_or_null(wave_label)
	
	if auto_start:
		start_waves()

# ─── API PÚBLICA ───────────────────────────────────────────────────────────

func start_waves() -> void:
	if is_running:
		return
	is_running = true
	current_wave_index = -1
	_run_next_wave()

func stop_waves() -> void:
	is_running = false

# ─── LÓGICA INTERNA ────────────────────────────────────────────────────────

func _run_next_wave() -> void:
	if not is_running:
		return
	
	current_wave_index += 1
	
	if current_wave_index >= waves.size():
		_on_all_waves_cleared()
		return
	
	var wave: WaveData = waves[current_wave_index]
	
	# Espera antes de la oleada
	if wave.delay_before_wave > 0:
		await get_tree().create_timer(wave.delay_before_wave).timeout
	
	# Muestra mensaje si tiene
	if wave.wave_message != "" and _wave_label_node:
		_show_wave_message(wave.wave_message)
	
	emit_signal("wave_started", current_wave_index, wave.wave_name)
	print("[WaveManager] Iniciando: ", wave.wave_name)
	
	# Spawnea todos los grupos de la oleada
	for group in wave.enemy_groups:
		_spawn_group(group)
		if group.group_delay > 0:
			await get_tree().create_timer(group.group_delay).timeout
	
	# Si debe esperar a que mueran todos los enemigos
	if wave.wait_for_clear:
		await _wait_for_enemies_dead()
	
	emit_signal("wave_cleared", current_wave_index)
	print("[WaveManager] Oleada limpia: ", wave.wave_name)
	
	_run_next_wave()

func _spawn_group(group: EnemySpawnGroup) -> void:
	if group.enemy_scene == null:
		push_error("[WaveManager] EnemySpawnGroup sin enemy_scene asignada!")
		return
	
	# Espera el retardo del grupo si lo tiene
	if group.group_delay > 0:
		await get_tree().create_timer(group.group_delay).timeout
	
	var positions_x: Array[float] = []
	
	if group.random_x:
		# Posiciones X aleatorias
		for i in range(group.count):
			positions_x.append(randf_range(group.spawn_x_min, group.spawn_x_max))
	else:
		# Posiciones X distribuidas uniformemente
		if group.count == 1:
			positions_x.append((group.spawn_x_min + group.spawn_x_max) * 0.5)
		else:
			var step = (group.spawn_x_max - group.spawn_x_min) / (group.count - 1)
			for i in range(group.count):
				positions_x.append(group.spawn_x_min + step * i)
	
	for i in range(group.count):
		var enemy = group.enemy_scene.instantiate()
		var spawn_pos = Vector2(positions_x[i], group.spawn_y)
		enemy.global_position = spawn_pos
		
		var container = enemies_container if enemies_container else get_tree().current_scene
		container.add_child(enemy)
		
		if group.spawn_interval > 0 and i < group.count - 1:
			await get_tree().create_timer(group.spawn_interval).timeout

func _wait_for_enemies_dead() -> void:
	# Espera hasta que no quede ningún nodo en el grupo "enemy"
	while true:
		var enemies = get_tree().get_nodes_in_group("enemy")
		if enemies.is_empty():
			break
		await get_tree().create_timer(0.5).timeout

func _on_all_waves_cleared() -> void:
	is_running = false
	emit_signal("all_waves_cleared")
	print("[WaveManager] ¡Todas las oleadas completadas!")

func _show_wave_message(msg: String) -> void:
	if _wave_label_node == null:
		return
	_wave_label_node.text = msg
	_wave_label_node.visible = true
	await get_tree().create_timer(2.0).timeout
	_wave_label_node.visible = false
