class_name RunManager extends Node

@export var scene_manager: SceneManager
#@export var ui_event_overlay: Control
@export var possible_events: Array[EventData]
@export var player_scene: PackedScene

@export_group("Rooms")
@export var start_room_scene: PackedScene
@export var available_basicArena_scenes: Array[PackedScene]
@export var available_advancedArena_scenes: Array[PackedScene]
@export var puzzle_scene: PackedScene
@export var centre_scene: PackedScene

@export var sword_data : WeaponData
@export var spear_data : WeaponData
@export var bow_data : WeaponData

@export_group("Enemy Pools")
@export var start_room_enemies: Array[PackedScene]
@export var basicArena_enemies: Array[PackedScene]
@export var advancedArena_enemies: Array[PackedScene]
@export var puzzle_enemies: Array[PackedScene]
@export var centre_enemies: Array[PackedScene]

enum RoomType {
	START,
	BASIC_ARENA,
	ADVANCED_ARENA,
	PUZZLE,
	CENTRE
}

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
		load_room_scene(start_room_scene, RoomType.START)
		if GameData.current_weapons.is_empty():
			GameData.add_weapon(sword_data)
			GameData.add_weapon(spear_data)
			GameData.add_weapon(bow_data)
	

var is_transitioning: bool = false # Add this guard variable

func load_room_scene(room_packed: PackedScene, room_type: RoomType):
	if is_transitioning: return # Block if already loading
	is_transitioning = true
	
	var room_instance = room_packed.instantiate() as RoomBase
	
	var enemy_pool_for_room: Array[PackedScene]
	match room_type:
		RoomType.START:
			enemy_pool_for_room = start_room_enemies
		RoomType.BASIC_ARENA:
			enemy_pool_for_room = basicArena_enemies
		RoomType.ADVANCED_ARENA:
			enemy_pool_for_room = advancedArena_enemies
		RoomType.PUZZLE:
			enemy_pool_for_room = puzzle_enemies
		RoomType.CENTRE:
			enemy_pool_for_room = centre_enemies
	
	# lambda that will be called later
	var setup_callback = _setup_room_logic.bind(room_instance, enemy_pool_for_room)
	
	await scene_manager.swap_content_scene(room_instance, setup_callback)
	is_transitioning = false # Release lock

func _setup_room_logic(room_instance: RoomBase, enemy_pool: Array[PackedScene]):
	spawn_player_in_room(room_instance)
	room_instance.setup_room(10, enemy_pool, GameData.game_difficulty * 2)
	room_instance.room_cleared.connect(_on_room_complete)
	scene_manager.on_start_game_ui()

func load_room_from_type(type_name: String) -> void:
	print("RunManager: Loading room type: ", type_name)
	
	var scene_to_load: PackedScene = null
	var room_type: RoomType
	match type_name:
		"basicArena":
			if available_basicArena_scenes.size() > 0:
				scene_to_load = available_basicArena_scenes.pick_random()
				room_type = RoomType.BASIC_ARENA
			
		"advancedArena":
			if available_advancedArena_scenes.size() > 0:
				scene_to_load = available_advancedArena_scenes.pick_random()
				room_type = RoomType.ADVANCED_ARENA
		
		"puzzleRoom":
			if puzzle_scene:
				scene_to_load = puzzle_scene
				room_type = RoomType.PUZZLE
				
		"Centre":
			if centre_scene:
				scene_to_load = centre_scene
				room_type = RoomType.CENTRE
			
		_:
			printerr("RunManager: Unknown room type ", type_name)
			return
	
	if scene_to_load:
		load_room_scene(scene_to_load, room_type)

func spawn_player_in_room(room: RoomBase):
	var player = player_scene.instantiate()
	
	if room.has_node("PlayerSpawn"):
		player.global_position = room.get_node("PlayerSpawn").global_position
	else:
		printerr("Room is missing 'PlayerSpawn' Marker2D!")
		player.global_position = Vector2.ZERO
	
	room.add_child(player)

var _is_loading_corridor: bool = false

func _on_room_complete():
	if scene_manager.current_ui_state != SceneManager.SceneType.ROOM:
		return
	
	print("Room Cleared!")
	
	var reward_text = GameData.apply_random_completion_reward()
	
	#if scene_manager.ui_corridor and scene_manager.ui_corridor.has_method("set_shop_label_text"):
		#scene_manager.ui_corridor.set_shop_label_text(reward_text)
	
	var coords = GameData.player_coords
	if coords.y < GameData.maze_map.size() and coords.x < GameData.maze_map[0].size():
		var cell = GameData.maze_map[coords.y][coords.x]
		cell["cleared"] = true
		cell["active"] = false
		GameData.save_game()
	
	load_corridor_ui()

func load_corridor_ui():
	# Create the placeholder for the corridor scene
	var placeholder = Node2D.new()
	placeholder.name = "CorridorState"
	
	# 2. Define a function that switches the UI. 
	# This will be passed to scene_manager to run ONLY when the screen is fully black.
	var switch_ui_callback = func():
		scene_manager.on_show_corridor_ui()
	
	# 3. Start the swap, passing the callback
	await scene_manager.swap_content_scene(placeholder, switch_ui_callback)
	
	# Unlock the function now that loading is finished
	_is_loading_corridor = false

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
