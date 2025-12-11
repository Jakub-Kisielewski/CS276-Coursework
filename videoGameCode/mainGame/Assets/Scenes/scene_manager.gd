class_name SceneManager extends Node

@export_group("Scene Container")
@export var active_scene_container: Node

@export_group("UI Layers")
@export var transition_screen: ColorRect
@export var ui_main_menu: Control
@export var ui_maze_gen: Control
@export var ui_room: Control
@export var ui_corridor: Control
@export var ui_pause_menu: Control
@export var ui_death: Control

var current_scene_node: Node = null
enum SceneType { MENU, MAZE_GEN, ROOM, CORRIDOR, SETTINGS, DEATH }
var current_ui_state: SceneType = SceneType.MENU

func _ready() -> void:
	transition_screen.visible = false
	transition_screen.modulate.a = 0.0

func swap_content_scene(new_scene_node: Node, on_black_screen: Callable = Callable()) -> void:
	await _fade_out()
	
	for child in active_scene_container.get_children():
		child.queue_free()
	
	active_scene_container.add_child(new_scene_node)
	
	if on_black_screen.is_valid(): # spawn players and enemies
		on_black_screen.call()
	
	await get_tree().process_frame
	
	await _fade_in()

# --- Fade Effects ---
func _fade_out() -> void:
	transition_screen.visible = true
	var tween = create_tween()
	tween.tween_property(transition_screen, "modulate:a", 1.0, 1.5)
	await tween.finished

func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(transition_screen, "modulate:a", 0.0, 1.5)
	await tween.finished
	transition_screen.visible = false

func _switch_ui_state(scene_type: SceneType) -> void:
	current_ui_state = scene_type
	
	if ui_main_menu: ui_main_menu.visible = false
	if ui_maze_gen: ui_maze_gen.visible = false
	if ui_room: ui_room.visible = false
	if ui_corridor: ui_corridor.visible = false
	if ui_pause_menu: ui_pause_menu.visible = false
	if ui_death: ui_death.visible = false
	
	match scene_type:
		SceneType.MENU:
			if ui_main_menu: ui_main_menu.visible = true
		SceneType.MAZE_GEN:
			if ui_maze_gen: ui_maze_gen.visible = true
		SceneType.ROOM:
			if ui_room: ui_room.visible = true
		SceneType.CORRIDOR:
			if ui_corridor: ui_corridor.visible = true
		SceneType.DEATH:
			if ui_death: 
				if ui_death.has_method("start_death_sequence"):
					ui_death.start_death_sequence()
				else:
					ui_death.visible = true
		SceneType.SETTINGS:
			pass

func on_start_game_ui() -> void:
	_switch_ui_state(SceneType.ROOM)

func on_return_to_menu() -> void:
	for child in active_scene_container.get_children():
		child.queue_free()
	
	_switch_ui_state(SceneType.MENU)
