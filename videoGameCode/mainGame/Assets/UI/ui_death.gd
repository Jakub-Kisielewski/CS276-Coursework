extends Control

signal return_to_menu_pressed
signal quit_pressed

@onready var background: ColorRect = $Background
@onready var minotaur_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	
	visible = false
	background.modulate.a = 0.0
	
	var btn_menu = find_child("BtnMenu", true, false)
	var btn_quit = find_child("BtnQuit", true, false)
	
	if btn_menu:
		btn_menu.pressed.connect(func(): 
			GameData.reset_run_state()
			return_to_menu_pressed.emit()
		)
		btn_menu.modulate.a = 0.0
		
	if btn_quit:
		btn_quit.pressed.connect(func(): 
			GameData.reset_run_state()
			quit_pressed.emit()
		)
		btn_quit.modulate.a = 0.0

func start_death_sequence() -> void:
	visible = true
	
	var start_pos = Vector2(-720, 72)
	var end_pos = Vector2(820, 182)
	
	minotaur_sprite.position = start_pos
	minotaur_sprite.play("charge")
	minotaur_sprite.flip_h = false
	
	var move_tween = create_tween()
	move_tween.tween_property(minotaur_sprite, "position", end_pos, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	move_tween.tween_callback(func(): minotaur_sprite.play("idle"))
	
	background.color.a = 0.0
	for child in background.get_children():
		if child is Control:
			child.modulate.a = 0.0
			
	var fade_tween = create_tween()
	fade_tween.tween_property(background, "modulate:a", 1.0, 0.5)
	
	fade_tween.tween_interval(0.5) 
	for child in find_children("", "Button") + find_children("", "Label"):
		fade_tween.parallel().tween_property(child, "modulate:a", 1.0, 0.5)

func _on_menu_pressed() -> void:
	GameData.reset_run_state()
	return_to_menu_pressed.emit()

func _on_quit_pressed() -> void:
	GameData.reset_run_state()
	quit_pressed.emit()
