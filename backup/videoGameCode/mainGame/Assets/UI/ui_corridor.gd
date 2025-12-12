extends Control

signal room_entered(room_type: String)
@onready var map_display: TileMapLayer = %MapDisplay
@onready var player_icon: Sprite2D = %PlayerIcon
@onready var btn_enter_room: Button = %BtnEnterRoom
@export var shop_reward_label: Label

var current_hovered_room_type: String = ""
# Definitions of what directions are allowed for each specific tile type
# Based on the logic in generateWorld.gd
var connectivity: Dictionary = {
	# Straights (Pipes)
	"straightVertical": [Vector2i.UP, Vector2i.DOWN],
	"straightNorth": [Vector2i.UP, Vector2i.DOWN],
	"straightSouth": [Vector2i.UP, Vector2i.DOWN],
	
	"straightHorizontal": [Vector2i.LEFT, Vector2i.RIGHT],
	"straightEast": [Vector2i.LEFT, Vector2i.RIGHT],
	"straightWest": [Vector2i.LEFT, Vector2i.RIGHT],
	
	# Turns (Entry -> Exit logic inferred from names)
	"northToWestTurn": [Vector2i.DOWN, Vector2i.LEFT], # Enters from South, Turns West
	"northToEastTurn": [Vector2i.DOWN, Vector2i.RIGHT], # Enters from South, Turns East
	
	"southToWestTurn": [Vector2i.UP, Vector2i.LEFT], # Enters from North, Turns West
	"southToEastTurn": [Vector2i.UP, Vector2i.RIGHT], # Enters from North, Turns East
	
	"eastToNorthTurn": [Vector2i.LEFT, Vector2i.UP], # Enters from West, Turns North
	"eastToSouthTurn": [Vector2i.LEFT, Vector2i.DOWN], # Enters from West, Turns South
	
	"westToNorthTurn": [Vector2i.RIGHT, Vector2i.UP], # Enters from East, Turns North
	"westToSouthTurn": [Vector2i.RIGHT, Vector2i.DOWN], # Enters from East, Turns South
	
	# Junctions
	"verticalLeftJunction": [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT],
	"verticalRightJunction": [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT],
	"horizontalUpJunction": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP],
	"horizontalDownJunction": [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN],
	
	# Deadends (Name implies direction traveled TO get there, so exit is opposite)
	"straightNorthDeadend": [Vector2i.DOWN], 
	"straightSouthDeadend": [Vector2i.UP],
	"straightEastDeadend": [Vector2i.LEFT],
	"straightWestDeadend": [Vector2i.RIGHT]
}

# Room types act as open hubs; we assume they connect to any valid neighbor
var room_types: Array = ["basicArena", "advancedArena", "puzzleRoom", "Start", "Centre"]

# Mapping for the visual tiles (kept from your original code)
var tile_atlas_coords: Dictionary = {
	"straightVertical": Vector2i(2,1),
	"straightHorizontal": Vector2i(1,0),
	"straightNorth": Vector2i(2,1),
	"straightSouth": Vector2i(2,1),
	"straightEast": Vector2i(1,0),
	"straightWest": Vector2i(1,0),
	
	"rightDownTurn": Vector2i(2,0),
	"upRightTurn": Vector2i(0,0),
	"downLeftTurn": Vector2i(2,2),
	"leftUpTurn": Vector2i(0,2),
	
	"northToEastTurn": Vector2i(0,0), 
	"westToSouthTurn": Vector2i(0,0),
	"northToWestTurn":Vector2i(2,0),
	"eastToSouthTurn": Vector2i(2,0),
	"southToWestTurn": Vector2i(2,2),
	"eastToNorthTurn": Vector2i(2,2),
	"southToEastTurn": Vector2i(0,2),
	"westToNorthTurn": Vector2i(0,2),

	"verticalLeftJunction": Vector2i(4,0),
	"verticalRightJunction": Vector2i(3,0),
	"horizontalUpJunction": Vector2i(4,1),
	"horizontalDownJunction": Vector2i(3,1),
	
	"straightNorthDeadend": Vector2i(2,4),
	"straightSouthDeadend": Vector2i(2,3),
	"straightWestDeadend":Vector2i(4,3),
	"straightEastDeadend":Vector2i(3,3),
	
	"basicArena": Vector2i(0,3),
	"advancedArena": Vector2i(0,4),
	"puzzleRoom": Vector2i(1,4),
	"Start": Vector2i(3,4),
	"Centre": Vector2i(1,3)
}

var inputs: Dictionary = {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT
}

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	
	if btn_enter_room:
		btn_enter_room.pressed.connect(_on_enter_room_pressed)
		btn_enter_room.visible = false # Ensure hidden at start
	
	if not GameData.maze_map.is_empty():
		initialize_corridor_view()
	
	if shop_reward_label:
		shop_reward_label.text = "Explore to find rewards..."

func set_shop_label_text(text: String) -> void:
	if shop_reward_label:
		shop_reward_label.text = text
		print("UI Updated: ", text)
	else:
		print("Warning: shop_reward_label not assigned in UI_Corridor")

func _on_visibility_changed() -> void:
	if visible:
		initialize_corridor_view()
		set_process_unhandled_input(true)
		grab_focus()

func initialize_corridor_view() -> void:
	if GameData.maze_map.is_empty():
		return
	
	if GameData.player_coords == Vector2i(0,0) and not _is_valid_cell(Vector2i(0,0)):
		find_player_start()
	
	draw_map()
	call_deferred("update_player_visuals")

func find_player_start():
	for y in range(GameData.map_height):
		for x in range(GameData.map_width):
			var cell = GameData.maze_map[y][x]
			if cell.get("type") == "Start":
				GameData.player_coords = Vector2i(x, y)
				return

func _is_valid_cell(coords: Vector2i) -> bool:
	if coords.x < 0 or coords.x >= GameData.map_width or coords.y < 0 or coords.y >= GameData.map_height:
		return false
	
	var cell_data = GameData.maze_map[coords.y][coords.x]
	
	if cell_data.get("type", "") == "":
		return false
		
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	
	for dir_key in inputs.keys():
		if event.is_action_pressed(dir_key):
			attempt_move(inputs[dir_key])
			get_viewport().set_input_as_handled()

func attempt_move(direction: Vector2i) -> void:
	var current_pos = GameData.player_coords
	var new_pos = current_pos + direction
	
	if not _is_valid_cell(new_pos):
		return
	
	if not is_connected_visually(current_pos, new_pos, direction):
		return
	
	var current_cell = GameData.maze_map[current_pos.y][current_pos.x]
	var target_cell = GameData.maze_map[new_pos.y][new_pos.x]
	
	var current_type = current_cell.get("type", "")
	var target_type = target_cell.get("type", "")
	
	var is_current_room = current_type in room_types
	var is_target_room = target_type in room_types
	
	if is_current_room and is_target_room:
		print("Movement blocked: Cannot move directly between rooms.")
		return
	
	if is_current_room and current_type != "Start" and not current_cell.get("cleared", false):
		if not target_cell.get("explored", false):
			return
	
	update_player_position(new_pos)

func is_connected_visually(from: Vector2i, to: Vector2i, dir: Vector2i) -> bool:
	var cell_from = GameData.maze_map[from.y][from.x]
	var cell_to = GameData.maze_map[to.y][to.x]
	
	var type_from = cell_from.get("type", "")
	var type_to = cell_to.get("type", "")
	
	var valid_exits = get_allowed_directions(type_from)
	if not dir in valid_exits:
		return false
		
	
	var valid_entries = get_allowed_directions(type_to)
	if not -dir in valid_entries:
		return false
		
	return true

func get_allowed_directions(type: String) -> Array:
	if type in room_types:
		return [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	if connectivity.has(type):
		return connectivity[type]
		
	return []

func update_player_position(new_pos: Vector2i):
	var old_pos = GameData.player_coords
	
	GameData.player_coords = new_pos
	var new_cell = GameData.maze_map[new_pos.y][new_pos.x]
	
	new_cell["explored"] = true
	
	update_player_visuals()
	draw_map() 
	
	GameData.save_game()
	
	check_room_entry(new_cell)

func update_player_visuals():
	if map_display:
		var map_pos = map_display.map_to_local(GameData.player_coords)
		player_icon.global_position = map_display.to_global(map_pos)

func draw_map():
	map_display.clear()
	
	for y in range(GameData.map_height):
		for x in range(GameData.map_width):
			var cell_data = GameData.maze_map[y][x]
			
			if cell_data.get("explored", false):
				var type = cell_data.get("type", "")
				var tile_coord = Vector2i(4, 4) 
				
				if tile_atlas_coords.has(type):
					tile_coord = tile_atlas_coords[type]
				elif type in room_types:
					tile_coord = tile_atlas_coords.get("basicArena")
					
				map_display.set_cell(Vector2i(x, y), 3, tile_coord, 0) 

func check_room_entry(cell_data: Dictionary):
	var type = cell_data.get("type", "")
	
	btn_enter_room.visible = false
	current_hovered_room_type = ""
	
	if type in ["basicArena", "advancedArena", "puzzleRoom", "Centre"]:
		if not cell_data.get("cleared", false):
			print("UI Corridor: Standing on ", type)
			
			current_hovered_room_type = type
			
			btn_enter_room.visible = true
			

func _on_enter_room_pressed() -> void:
	print("Button Pressed! Attempting to enter: ", current_hovered_room_type)
	
	if current_hovered_room_type != "":
		set_process_unhandled_input(false)
		btn_enter_room.visible = false
		
		room_entered.emit(current_hovered_room_type)
