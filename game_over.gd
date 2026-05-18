extends Control
@onready var final_score = $Panel/FinalScore
@onready var highscore_label = $Panel/Highscore
@onready var retry_button = $Panel/RetryButton
@onready var menu_button = $Panel/MenuButton
@onready var settings_button = $Panel/SettingsButton
@onready var settings_panel = $SettingsPanel
@onready var music_slider = $SettingsPanel/MusicSlider
@onready var sfx_slider = $SettingsPanel/SFXSlider

func _ready():
	final_score.text = "Puntuación: " + str(GameManager.score)
	highscore_label.text = "Máximo: " + str(GameManager.highscore)
	settings_panel.visible = false

	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)
	settings_button.pressed.connect(_on_settings)

	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01

	# ✅ Verificar que el bus existe antes de usarlo
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")

	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus)) if music_bus != -1 else 1.0
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus)) if sfx_bus != -1 else 1.0

	music_slider.value_changed.connect(_on_music_volume)
	sfx_slider.value_changed.connect(_on_sfx_volume)

func _on_retry() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_menu() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _on_settings() -> void:
	settings_panel.visible = !settings_panel.visible

func _on_music_volume(value: float) -> void:
	var bus = AudioServer.get_bus_index("Music")
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, linear_to_db(value))

func _on_sfx_volume(value: float) -> void:
	var bus = AudioServer.get_bus_index("SFX")
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, linear_to_db(value))
