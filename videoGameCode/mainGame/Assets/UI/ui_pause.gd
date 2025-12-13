extends Control

signal resume_pressed
signal settings_pressed
signal save_and_quit_pressed

@onready var lbl_time: Label = %LblTime
@onready var btn_resume: Button = %BtnResume
@onready var btn_settings: Button = %BtnSettings
@onready var btn_quit: Button = %BtnSaveQuit

var start_time_msec: int = 0

func _ready() -> void:
	btn_resume.pressed.connect(func(): resume_pressed.emit())
	btn_settings.pressed.connect(func(): settings_pressed.emit())
	btn_quit.pressed.connect(func():
		save_and_quit_pressed.emit()
	)
	
	visible = false

func _process(_delta: float) -> void:
	if visible:
		update_time_label()

func open_menu() -> void:
	visible = true
	if start_time_msec == 0:
		start_time_msec = Time.get_ticks_msec()
	
	update_time_label()

func close_menu() -> void:
	visible = false

func update_time_label() -> void:
	var current_time = Time.get_ticks_msec()
	var diff = current_time - start_time_msec
	
	var seconds = int(diff / 1000) % 60
	var minutes = int(diff / 1000 / 60)
	
	lbl_time.text = "Play Time: %02d:%02d" % [minutes, seconds]
