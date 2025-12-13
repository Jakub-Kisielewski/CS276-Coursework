extends Control
@onready var master_slider: Slider = %MasterVolumeSlider
@onready var music_slider: Slider = %MusicVolumeSlider
@onready var sfx_slider: Slider = %SFXVolumeSlider
@onready var back_btn: Button = %BackBtn

@onready var btn_god_mode: Button = %GodModeCheck
@onready var btn_mouse_aim: Button = %AimCheck

signal settings_pressed

func _ready() -> void:
	
	back_btn.pressed.connect(_on_settings_pressed)
	
	master_slider.min_value = -40.0
	master_slider.max_value = 0.0
	music_slider.min_value = -40.0
	music_slider.max_value = 0.0
	sfx_slider.min_value = -40.0
	sfx_slider.max_value = 0.0

	# Load from GameData
	master_slider.value = GameData.master_volume_db
	music_slider.value = GameData.music_volume_db
	sfx_slider.value = GameData.sfx_volume_db

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	
	btn_god_mode.pressed.connect(_on_god_mode_pressed)
	btn_mouse_aim.pressed.connect(_on_mouse_aim_pressed)
	

	_update_option_buttons()

func _on_settings_pressed() -> void:
	settings_pressed.emit()


func _update_option_buttons() -> void:

	btn_god_mode.text = "God Mode: " + ( "ON" if GameData.god_mode_enabled else "OFF" )
	btn_mouse_aim.text = "Aim: " + ( "MOUSE" if GameData.mouse_aiming else "KEYS" )



func _on_god_mode_pressed() -> void:
	GameData.god_mode_enabled = !GameData.god_mode_enabled
	if GameData.god_mode_enabled:
		GameData.current_health = 999999
		GameData.max_health = 999999
	else:

		GameData.max_health = 1000.0
		GameData.current_health = min(GameData.current_health, GameData.max_health)
	GameData.player_stats_changed.emit()
	_update_option_buttons()

func _on_mouse_aim_pressed() -> void:
	GameData.mouse_aiming = !GameData.mouse_aiming
	_update_option_buttons()
	
func _on_master_changed(value: float) -> void:
	GameData.master_volume_db = value
	var bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, value)

func _on_music_changed(value: float) -> void:
	GameData.music_volume_db = value
	var bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus, value)

func _on_sfx_changed(value: float) -> void:
	GameData.sfx_volume_db = value
	var bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus, value)
