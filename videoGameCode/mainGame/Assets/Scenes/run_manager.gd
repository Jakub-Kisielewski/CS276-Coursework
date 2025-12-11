class_name RunManager extends Node

@export var scene_manager: SceneManager
#@export var ui_event_overlay: Control
@export var possible_events: Array[EventData]
@export var available_room_scenes: Array[PackedScene]
@export var player_scene: PackedScene
@export var enemy_pool: Array[PackedScene]

var current_difficulty: int = 10

#func _ready():
	#ui_event_overlay.option_selected.connect(_apply_event_effect)

func start_run_or_next_room():
	var room_packed = available_room_scenes.pick_random()
	var room_instance = room_packed.instantiate() as RoomBase
	
	# load room
	var setup_logic = func():
		spawn_player_in_room(room_instance)
		room_instance.setup_room(current_difficulty, enemy_pool)
		room_instance.room_cleared.connect(_on_room_complete)
		
		scene_manager.on_start_game_ui()
	
	await scene_manager.swap_content_scene(room_instance, setup_logic)
	
func spawn_player_in_room(room: RoomBase):
	var player = player_scene.instantiate()
	
	if room.has_node("PlayerSpawn"):
		player.global_position = room.get_node("PlayerSpawn").global_position
	else:
		printerr("Room is missing 'PlayerSpawn' Marker2D!")
		player.global_position = Vector2.ZERO
	
	room.add_child(player)

func _on_room_complete():
	# if we are in the MENU or DEATH screen, ignore this signal
	if scene_manager.current_ui_state != SceneManager.SceneType.ROOM:
		return
	print("Room Cleared! Transitioning...")
	start_run_or_next_room()

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
