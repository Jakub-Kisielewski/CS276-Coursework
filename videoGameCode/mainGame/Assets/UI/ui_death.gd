extends Control

@onready var music_player = get_node("../../MusicPlayer")

@export var menutaur_scene : PackedScene
@export var background : ColorRect
var menutaur : Menutaur

signal return_to_menu_pressed
signal quit_pressed

func _ready() -> void:
	visible = false
	
	var btn_menu = find_child("BtnMenu", true, false)
	var btn_quit = find_child("BtnQuit", true, false)
	
	if btn_menu:
		btn_menu.pressed.connect(_on_menu_pressed)
		btn_menu.modulate.a = 0.0
		
	if btn_quit:
		btn_quit.pressed.connect(_on_quit_pressed)
		btn_quit.modulate.a = 0.0

func start_death_sequence() -> void:
	music_player.set_category(MusicPlayer.Category.DEAD) #play the creepy death music
	visible = true
	menutaur = menutaur_scene.instantiate()
	add_child(menutaur)
	menutaur.initialise(background)

func _on_menu_pressed() -> void:
	menutaur.close()
	
	GameData.reset_run_state()
	return_to_menu_pressed.emit()

func _on_quit_pressed() -> void:
	menutaur.close()
	
	GameData.reset_run_state()
	quit_pressed.emit()
