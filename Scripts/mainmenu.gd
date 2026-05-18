extends Control

@onready var play_button = $CenterContainer2/VBoxContainer/Play
@onready var quit_button = $CenterContainer2/VBoxContainer/Quit
@onready var settings_button = $CenterContainer2/VBoxContainer/Settings
@onready var settings_panel = $SettingsPanel
@onready var music_slider = $SettingsPanel/MusicSlider
@onready var sfx_slider = $SettingsPanel/SFXSlider

func _ready():
	play_button.pressed.connect(_on_play)
	quit_button.pressed.connect(_on_quit)
	settings_button.pressed.connect(_on_settings)
	settings_panel.visible = false

	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if music_bus != -1:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus))
	if sfx_bus != -1:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))

	music_slider.value_changed.connect(_on_music_volume)
	sfx_slider.value_changed.connect(_on_sfx_volume)

	for button in [play_button, quit_button, settings_button]:
		button.add_theme_stylebox_override("normal", _make_stylebox(Color(0, 0, 0, 0)))
		button.add_theme_stylebox_override("pressed", _make_stylebox(Color(0, 0, 0, 0)))
		button.custom_minimum_size = Vector2(200, 50)
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))

func _on_play() -> void:
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_quit() -> void:
	get_tree().quit()

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

func _on_button_hover(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "pivot_offset:x", 10.0, 0.1)
	button.add_theme_stylebox_override("normal", _make_stylebox(Color(0.4, 0.4, 0.4, 0.8)))
	button.add_theme_stylebox_override("hover", _make_stylebox(Color(0.4, 0.4, 0.4, 0.8)))

func _on_button_unhover(button: Button) -> void:
	var tween = create_tween()
	tween.tween_property(button, "pivot_offset:x", 0.0, 0.1)
	button.add_theme_stylebox_override("normal", _make_stylebox(Color(0, 0, 0, 0)))
	button.remove_theme_stylebox_override("hover")

func _make_stylebox(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
