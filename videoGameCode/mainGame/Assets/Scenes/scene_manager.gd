class_name SceneManager extends Node

@export_group("Scene Container")
@export var active_scene_container: Node

@export_group("UI Layers")
@export var transition_screen: ColorRect
@export var ui_main_menu: Control
@export var ui_maze_gen: Control
@export var ui_room: Control
@export var ui_corridor: Control

var current_scene_node: Node = null
enum SceneType { MENU, MAZE_GEN, ROOM, CORRIDOR, SETTINGS }

func _ready() -> void:
	transition_screen.visible = true
	transition_screen.modulate.a = 0.0
	

func swap_content_scene(new_scene_node: Node) -> void:
	await _fade_out()
	
	for child in active_scene_container.get_children():
		child.queue_free()
	
	active_scene_container.add_child(new_scene_node)
	
	await _fade_in()

# --- Fade Effects ---
func _fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(transition_screen, "modulate:a", 1.0, 0.5)
	await tween.finished

func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(transition_screen, "modulate:a", 0.0, 0.5)
	await tween.finished
