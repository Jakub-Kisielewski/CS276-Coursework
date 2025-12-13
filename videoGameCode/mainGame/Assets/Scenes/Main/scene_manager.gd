class_name SceneManager extends Node

@onready var music_player : MusicPlayer = get_node("../MusicPlayer")

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
@export var ui_settings: Control

var current_scene_node: Node = null

enum SceneType { MENU, MAZE_GEN, ROOM, CORRIDOR, DEATH }
var current_ui_state: SceneType = SceneType.MENU

func _ready() -> void:
	set_scene_music_category(current_ui_state) # initially the menu music
	
	transition_screen.visible = false
	transition_screen.modulate.a = 0.0
	
	# Hide settings initially (it's an overlay, not a scene)
	if ui_settings:
		ui_settings.visible = false
	
	_switch_ui_state(current_ui_state)

func swap_content_scene(new_scene_node: Node, on_black_screen: Callable = Callable()) -> void:
	await _fade_out()
	
	for child in active_scene_container.get_children():
		child.queue_free()
	
	active_scene_container.add_child(new_scene_node)
	
	# executes the UI switch while the screen is black
	if on_black_screen.is_valid(): 
		on_black_screen.call()
	
	await get_tree().process_frame
	
	await _fade_in()

# --- Fade Effects ---
func _fade_out() -> void:
	transition_screen.visible = true
	var tween = create_tween()
	tween.tween_property(transition_screen, "modulate:a", 1.0, 0.8)
	await tween.finished

func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(transition_screen, "modulate:a", 0, 0.8)
	await tween.finished
	transition_screen.visible = false

func _switch_ui_state(scene_type: SceneType) -> void:
	current_ui_state = scene_type
	
	# changing music as well here
	set_scene_music_category(scene_type)
	
	# resetting the visibility to false (settings excluded - it's an overlay)
	if ui_main_menu: ui_main_menu.visible = false
	if ui_maze_gen: ui_maze_gen.visible = false
	if ui_room: ui_room.visible = false
	if ui_corridor: ui_corridor.visible = false
	if ui_pause_menu: ui_pause_menu.visible = false
	if ui_death: ui_death.visible = false
	
	# now set visibility to true
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

func on_start_game_ui() -> void:
	_switch_ui_state(SceneType.ROOM)

func on_show_corridor_ui() -> void:
	_switch_ui_state(SceneType.CORRIDOR)

func on_return_to_menu() -> void:
	for child in active_scene_container.get_children():
		child.queue_free()
	
	_switch_ui_state(SceneType.MENU)

# when you change scene call this function with the new scene type as parameter
func set_scene_music_category(scene_type : SceneType):
	match scene_type:
		SceneType.MENU, SceneType.MAZE_GEN:
			music_player.set_category(MusicPlayer.Category.MENU_SETTINGS)
		SceneType.ROOM:
			music_player.set_category(MusicPlayer.Category.ROOMS)
		SceneType.CORRIDOR:
			music_player.set_category(MusicPlayer.Category.CORRIDORS)
