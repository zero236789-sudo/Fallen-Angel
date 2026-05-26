extends CharacterBody2D

@onready var _animated_sprite = $Prota

@export var speed: float = 400.0
@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@onready var bullet_sound = $Bulletsound

# --- Bombas ---
@export var bomb_cooldown: float = 1.0
@export var boss_damage: int = 200

@onready var bomb_label := get_tree().get_first_node_in_group("BombLabel")
var bombs_container

var bombs_max: int = 2
var bombs_current: int = 2
var _last_bomb_time: float = -999.0

# --- Reinicio ---
var tiempo_reinicio = 2.0
var temporizador = 0.0
var reiniciando = false

# --- Tuyo ---
var can_shoot: bool = true
var invincible: bool = false

func _ready():
	add_to_group("player")
	GameManager.lives_changed.connect(_on_lives_changed)

	bombs_container = get_tree().get_first_node_in_group("BombsContainer")
	update_bomb_label()
	update_bomb_icons()

func update_bomb_label() -> void:
	if bomb_label:
		bomb_label.text = "Bombas: %d" % bombs_current

func update_bomb_icons() -> void:
	if bombs_container:
		for i in range(bombs_container.get_child_count()):
			var bomb_icon = bombs_container.get_child(i)
			bomb_icon.visible = i < bombs_current

func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		if Input.is_action_pressed("slow"):
			velocity = direction * (speed / 2)
		else:
			velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
func _process(_delta):
	# Disparo (ARREGLADO)
	if Input.is_action_pressed("shoot") and can_shoot:
		spawn_bullet()

	# Bomba
	if Input.is_action_just_pressed("bomb"):
		use_bomb()

	# Reinicio de nivel
	if Input.is_action_pressed("reiniciar_nivel") and not reiniciando:
		temporizador += _delta
		if temporizador >= tiempo_reinicio:
			reiniciar()
	else:
		temporizador = 0.0

# -------------------------
#     SISTEMA DE BOMBAS
# -------------------------

func can_use_bomb() -> bool:
	if bombs_current <= 0:
		return false
	if (Time.get_ticks_msec() / 1000.0) - _last_bomb_time < bomb_cooldown:
		return false
	return true
const PLAY_AREA_X_MIN = 590.0
const PLAY_AREA_X_MAX = 1324.0
const PLAY_AREA_Y_MIN = -8.0
const PLAY_AREA_Y_MAX = 1085.0

func use_bomb() -> void:
	if not can_use_bomb():
		return

	bombs_current -= 1
	_last_bomb_time = Time.get_ticks_msec() / 1000.0
	update_bomb_label()
	update_bomb_icons()

	# 1. Matar enemigos normales (solo dentro del área de juego)
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e.has_method("is_boss") and e.is_boss():
			continue
		var pos = e.global_position
		if pos.x >= PLAY_AREA_X_MIN and pos.x <= PLAY_AREA_X_MAX \
		and pos.y >= PLAY_AREA_Y_MIN and pos.y <= PLAY_AREA_Y_MAX:
			if e.has_method("take_damage"):
				e.take_damage(200)
			else:
				e.queue_free()

	# 2. Limpiar proyectiles (todos, estén donde estén)
	var bullet_groups = ["enemy_bullet", "SkullBullet", "spider_bullet", "AngelBullet"]
	for group_name in bullet_groups:
		var projectiles = get_tree().get_nodes_in_group(group_name)
		for p in projectiles:
			p.queue_free()

	# 3. Daño al jefe
	var bosses = get_tree().get_nodes_in_group("boss")
	for b in bosses:
		if b.has_method("take_damage"):
			b.take_damage(boss_damage)

	# 4. FX
	play_bomb_fx()
	
func play_bomb_fx() -> void:
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)

# -------------------------
#     RESTO DE TU CÓDIGO
# -------------------------

func spawn_bullet() -> void:
	var spawns = [$Spawnposition, $Spawnposition2]
	for sp in spawns:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = sp.global_position
		get_tree().current_scene.add_child(bullet)
	
	# 🔊 sonido
	bullet_sound.play()

	can_shoot = false
	$Timer.start()

func take_damage(amount: int) -> void:
	if invincible:
		return
	GameManager.take_damage(amount)
	if GameManager.lives <= 0:
		die()
	else:
		_start_invincibility()

func _on_lives_changed(_new_lives: int) -> void:
	pass

func _start_invincibility() -> void:
	invincible = true
	for i in range(6):
		_animated_sprite.modulate.a = 0.3
		await get_tree().create_timer(0.15).timeout
		_animated_sprite.modulate.a = 1.0
		await get_tree().create_timer(0.15).timeout
	invincible = false

func die() -> void:
	var persistent = get_tree().root.get_node_or_null("PersistentMusic")
	if persistent:
		persistent.queue_free()
	call_deferred("_change_to_gameover")

func _change_to_gameover() -> void:
	if not is_inside_tree():
		return
	var path = "res://Scenes/Gameover.tscn"
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		push_error("No se encuentra la escena: " + path)

func _on_timer_timeout():
	can_shoot = true

# -------------------------
#     SUBIDA DE NIVEL
# -------------------------

func on_level_complete() -> void:
	bombs_max += 1
	bombs_current = bombs_max
	update_bomb_label()
	update_bomb_icons()

# -------------------------
#     REINICIO DE NIVEL
# -------------------------

func reiniciar():
	reiniciando = true
	GameManager.lives = 3   # Reinicia las vidas a 3
	bombs_current = bombs_max   # Reinicia las bombas
	get_tree().reload_current_scene()
