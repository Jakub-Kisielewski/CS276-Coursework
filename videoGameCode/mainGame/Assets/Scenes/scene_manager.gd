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
	
	SignalBus.request_room_change.connect(_on_room_change_requested)
	
	_switch_ui_state(SceneType.MENU)

func load_new_scene(scene_path: String, type: SceneType) -> void:
	# disable interaction and fade out
	await _fade_out()
	
	# cleanup old scene
	if current_scene_node:
		current_scene_node.queue_free()
		# wait one frame to ensure queue_free is processed
		await get_tree().process_frame 
	
	# instantiate new scene (skip if we are just switching to a UI-only state like Map)
	if scene_path != "":
		var new_scene_res = load(scene_path)
		if new_scene_res:
			current_scene_node = new_scene_res.instantiate()
			active_scene_container.add_child(current_scene_node)
	
	# update UI context
	_switch_ui_state(type)
	
	# fade in
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

# --- UI State ---
func _switch_ui_state(type: SceneType) -> void:
	ui_main_menu.visible = false
	ui_maze_gen.visible = false
	ui_room.visible = false
	ui_corridor.visible = false
	
	match type:
		SceneType.MENU:
			ui_main_menu.visible = true
		SceneType.MAZE_GEN:
			ui_maze_gen.visible = true
		SceneType.ROOM:
			ui_room.visible = true
		SceneType.CORRIDOR:
			ui_corridor.visible = true

# --- Signal Listeners ---
func _on_room_change_requested(next_room_path: String, is_combat: bool) -> void:
	var type = SceneType.ROOM if is_combat else SceneType.CORRIDOR
	load_new_scene(next_room_path, type)

# called by start game button in main menu
func start_run() -> void:
	load_new_scene("", SceneType.MAZE_GEN)
