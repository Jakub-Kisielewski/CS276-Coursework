extends Control

signal new_game_pressed
signal settings_pressed

func _ready() -> void:
	
	var btn_new = $BtnNewGame 
	var btn_settings = $BtnSettings
	
	btn_new.pressed.connect(func(): new_game_pressed.emit())
	btn_settings.pressed.connect(func(): settings_pressed.emit())
