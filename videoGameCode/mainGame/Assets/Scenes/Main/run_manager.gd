class_name RunManager extends Node

@export var scene_manager: SceneManager
@export var ui_event_overlay: UiEventOverlay
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

func _ready():
	if ui_event_overlay:
		ui_event_overlay.option_selected.connect(_apply_event_effect)

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
	var waves
	match room_type:
		RoomType.START:
			enemy_pool_for_room = start_room_enemies
			waves = 1
		RoomType.BASIC_ARENA:
			enemy_pool_for_room = basicArena_enemies
			waves = GameData.game_difficulty * 2
		RoomType.ADVANCED_ARENA:
			enemy_pool_for_room = advancedArena_enemies
			waves = GameData.game_difficulty * 2
		RoomType.PUZZLE:
			enemy_pool_for_room = puzzle_enemies
			waves = 1
		RoomType.CENTRE:
			enemy_pool_for_room = centre_enemies
			waves = 1
	
	# lambda that will be called later
	var setup_callback = _setup_room_logic.bind(room_instance, enemy_pool_for_room, waves)
	
	await scene_manager.swap_content_scene(room_instance, setup_callback)
	is_transitioning = false # Release lock

func _setup_room_logic(room_instance: RoomBase, enemy_pool: Array[PackedScene], waves: int):
	spawn_player_in_room(room_instance)
	room_instance.setup_room(10, enemy_pool, waves)
	room_instance.room_cleared.connect(_on_room_complete)
	scene_manager.on_start_game_ui()

func load_room_from_type(type_name: String) -> void:
	
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
	
	var coords = GameData.player_coords
	if coords.y < GameData.maze_map.size() and coords.x < GameData.maze_map[0].size():
		var cell = GameData.maze_map[coords.y][coords.x]
		cell["cleared"] = true
		cell["active"] = false
		GameData.save_game()
	
	load_corridor_ui()

func load_corridor_ui():
	var placeholder = Node2D.new()
	placeholder.name = "CorridorState"
	
	var switch_ui_callback = func():
		scene_manager.on_show_corridor_ui()
	
	await scene_manager.swap_content_scene(placeholder, switch_ui_callback)
	
	_is_loading_corridor = false

# --- Emergent Events ---
func trigger_random_event():
	if possible_events.is_empty():
		printerr("RunManager: No possible events configured")
		return
	
	var random_event = possible_events.pick_random()
	if ui_event_overlay:
		ui_event_overlay.show_event(random_event)
	else:
		printerr("RunManager: ui_event_overlay not assigned")

func _apply_event_effect(effect_id: String):
	match effect_id:
		"gain_gold":
			GameData.currency += 50
			print("Player gained 50 gold! Total: ", GameData.currency)
			GameData.currency_updated.emit(GameData.currency)
		
		"lose_gold":
			GameData.currency = max(0, GameData.currency - 30)
			print("Player lost 30 gold! Total: ", GameData.currency)
			GameData.currency_updated.emit(GameData.currency)
		
		"heal":
			GameData.update_health(50)
			print("Player healed 50 HP!")
		
		"take_damage":
			GameData.update_health(-30)
			print("Player took 30 damage!")
		
		"gain_damage":
			GameData.damage += 5
			print("Player gained 5 damage! Total: ", GameData.damage)
			GameData.player_stats_changed.emit()
		
		"lose_damage":
			GameData.damage = max(1, GameData.damage - 3)
			print("Player lost 3 damage! Total: ", GameData.damage)
			GameData.player_stats_changed.emit()
		
		"gain_defense":
			GameData.defence += 5
			print("Player gained 5 defense! Total: ", GameData.defence)
			GameData.player_stats_changed.emit()
		
		"mystery_reward":
			# Random effect
			var effects = ["gain_gold", "heal", "gain_damage"]
			var random_effect = effects.pick_random()
			_apply_event_effect(random_effect)
		
		_:
			print("Unknown effect: ", effect_id)

func check_for_emergent_event(cell_data: Dictionary):
	if cell_data.get("emergent", false) and not cell_data.get("emergent_triggered", false):
		# Mark as triggered so it only happens once
		cell_data["emergent_triggered"] = true
		trigger_random_event()
