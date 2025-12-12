class_name RunManager extends Node

@export var scene_manager: SceneManager
#@export var ui_event_overlay: Control
@export var possible_events: Array[EventData]
@export var player_scene: PackedScene
@export var enemy_pool: Array[PackedScene]


@export_group("Rooms")
@export var start_room_scene: PackedScene
@export var available_basicArena_scenes: Array[PackedScene]
@export var available_advancedArena_scenes: Array[PackedScene]
@export var puzzle_scene: PackedScene
@export var centre_scene: PackedScene

var current_difficulty: int = 10

#func _ready():
	#ui_event_overlay.option_selected.connect(_apply_event_effect)

func start_new_run():
	# locate the "Start" room 
	var start_found = false
	for y in range(GameData.map_height):
		for x in range(GameData.map_width):
			if GameData.maze_map[y][x].get("type") == "Start":
				GameData.player_coords = Vector2i(x, y)
				start_found = true
				break
		if start_found: break
	
	if not start_found:
		printerr("RunManager: No 'Start' room found in maze_map!")
		return
	
	# mark it as active and explored
	var start_cell = GameData.maze_map[GameData.player_coords.y][GameData.player_coords.x]
	start_cell["active"] = true
	start_cell["explored"] = true
	
	if start_room_scene:
		load_room_scene(start_room_scene)
	else:
		print("RunManager: No start_room_scene assigned! Loading random.")
		start_run_or_next_room()

var is_transitioning: bool = false # Add this flag

func load_room_scene(room_packed: PackedScene):
	if is_transitioning: return # Guard against double calls
	is_transitioning = true     # Lock
	
	var room_instance = room_packed.instantiate() as RoomBase
	
	var setup_logic = func():
		spawn_player_in_room(room_instance)
		room_instance.setup_room(current_difficulty, enemy_pool)
		room_instance.room_cleared.connect(_on_room_complete)
		scene_manager.on_start_game_ui()
	
	await scene_manager.swap_content_scene(room_instance, setup_logic)
	is_transitioning = false    # Unlock

func load_room_from_type(type_name: String) -> void:
	print("RunManager: Loading room type: ", type_name)
	
	var scene_to_load: PackedScene = null
	
	match type_name:
		"basicArena":
			if available_basicArena_scenes.size() > 0:
				scene_to_load = available_basicArena_scenes.pick_random()
			
		"advancedArena":
			if available_advancedArena_scenes.size() > 0:
				scene_to_load = available_advancedArena_scenes.pick_random()
		
		"puzzleRoom":
			if puzzle_scene:
				scene_to_load = puzzle_scene
				
		"Centre":
			if centre_scene:
				scene_to_load = centre_scene
			
		_:
			printerr("RunManager: Unknown room type ", type_name)
			return

	if scene_to_load:
		load_room_scene(scene_to_load)

func start_run_or_next_room():
	var room_packed = available_basicArena_scenes.pick_random()
	load_room_scene(room_packed)

func spawn_player_in_room(room: RoomBase):
	var player = player_scene.instantiate()
	
	if room.has_node("PlayerSpawn"):
		player.global_position = room.get_node("PlayerSpawn").global_position
	else:
		printerr("Room is missing 'PlayerSpawn' Marker2D!")
		player.global_position = Vector2.ZERO
	
	room.add_child(player)

func _on_room_complete():
	if scene_manager.current_ui_state != SceneManager.SceneType.ROOM:
		return
	
	print("Room Cleared!")
	
	# update game data
	var coords = GameData.player_coords
	# check bounds
	if coords.y < GameData.maze_map.size() and coords.x < GameData.maze_map[0].size():
		var cell = GameData.maze_map[coords.y][coords.x]
		cell["cleared"] = true
		cell["active"] = false
		GameData.save_game()
	
	load_corridor_ui()

func load_corridor_ui():
	if is_transitioning: return # Guard against double calls
	is_transitioning = true     # Lock
	
	# swap to an empty node to clear the previous room from the scene tree
	var placeholder = Node2D.new()
	placeholder.name = "CorridorState"
	
	# Define the UI switch as a callback to happen WHILE screen is black
	var switch_ui_callback = func():
		scene_manager.on_show_corridor_ui()

	# Pass the callback to swap_content_scene
	await scene_manager.swap_content_scene(placeholder, switch_ui_callback)
	
	is_transitioning = false    # Unlock

# --- Emergent Events ---
#func trigger_random_event():
	#var random_event = possible_events.pick_random()
	#ui_event_overlay.show_event(random_event)
#
#func _apply_event_effect(effect_id: String):
	#match effect_id:
		#"gain_gold":
			#GameData.currency += 50
			#print("Player gained gold!")
		#"heal":
			#GameData.current_health += 20
		#"gain_damage":
			#GameData.damage += 5
		#_:
			#print("Effect not found: ", effect_id)
	#
