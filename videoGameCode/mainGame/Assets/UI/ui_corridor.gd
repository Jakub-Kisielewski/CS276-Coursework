extends Control

signal room_entered(room_type: String)
@onready var map_display: TileMapLayer = %MapDisplay
@onready var player_icon: Sprite2D = %PlayerIcon

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
	"rightDownTurn": Vector2i(2,0),
	"upRightTurn": Vector2i(0,0),
	"downLeftTurn": Vector2i(2,2),
	"leftUpTurn": Vector2i(0,2),
	"verticalLeftJunction": Vector2i(4,0),
	"verticalRightJunction": Vector2i(3,0),
	"horizontalUpJunction": Vector2i(4,1),
	"horizontalDownJunction": Vector2i(3,1),
	"straightNorthDeadend": Vector2i(2,4),
	"straightSouthDeadend": Vector2i(2,3),
	"straightWestDeadend":Vector2i(3,3),
	"straightEastDeadend":Vector2i(4,3),
	"basicArena": Vector2i(0,3),
	"advancedArena": Vector2i(0,4),
	"puzzleRoom": Vector2i(1,4),
	"Start": Vector2i(3,4),
	"Centre": Vector2i(1,3)
}

var inputs: Dictionary = {
	"ui_up": Vector2i.UP,
	"ui_down": Vector2i.DOWN,
	"ui_left": Vector2i.LEFT,
	"ui_right": Vector2i.RIGHT
}

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	
	if not GameData.maze_map.is_empty():
		initialize_corridor_view()

func _on_visibility_changed() -> void:
	if visible:
		initialize_corridor_view()
		# Force focus to ensure keyboard input is captured
		grab_focus()

func initialize_corridor_view() -> void:
	if GameData.maze_map.is_empty():
		return
	
	# Find Start if player coords are unset (or strictly 0,0 which might be a wall)
	if GameData.player_coords == Vector2i(0,0) and not _is_valid_cell(Vector2i(0,0)):
		find_player_start()
	
	draw_map()
	# Defer the visual update slightly to ensure TileMapLayer is ready
	call_deferred("update_player_visuals")

func find_player_start():
	for y in range(GameData.map_height):
		for x in range(GameData.map_width):
			var cell = GameData.maze_map[y][x]
			if cell.get("type") == "Start":
				GameData.player_coords = Vector2i(x, y)
				return

func _is_valid_cell(coords: Vector2i) -> bool:
	# 1. Check map bounds
	if coords.x < 0 or coords.x >= GameData.map_width or coords.y < 0 or coords.y >= GameData.map_height:
		return false
	
	# 2. Check if the cell has data
	var cell_data = GameData.maze_map[coords.y][coords.x]
	
	# 3. Check if the cell is actually part of the maze (has a type)
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
	
	# 1. Basic validity check (bounds and existence)
	if not _is_valid_cell(new_pos):
		return
	
	# 2. Connectivity check (Can we leave current? Can we enter new?)
	if not is_connected_visually(current_pos, new_pos, direction):
		return
		
	# 3. Check if current room is cleared
	var current_cell = GameData.maze_map[current_pos.y][current_pos.x]
	var current_type = current_cell.get("type", "")
	var is_room = current_type in room_types
	var is_cleared = current_cell.get("cleared", false) 
	
	# Allow leaving Start without 'clearing' it, but block others
	if is_room and current_type != "Start" and not is_cleared:
		print("Room not cleared! Cannot leave.")
		# Add visual feedback like a screen shake or sound here
		return
	
	# Move Player
	update_player_position(new_pos)

func is_connected_visually(from: Vector2i, to: Vector2i, dir: Vector2i) -> bool:
	var cell_from = GameData.maze_map[from.y][from.x]
	var cell_to = GameData.maze_map[to.y][to.x]
	
	var type_from = cell_from.get("type", "")
	var type_to = cell_to.get("type", "")
	
	# Get allowed exits from the current tile
	var valid_exits = get_allowed_directions(type_from)
	if not dir in valid_exits:
		return false
		
	# Get allowed entries for the target tile (must accept entry from opposite of movement dir)
	# e.g., if moving UP, target must accept input from DOWN
	var valid_entries = get_allowed_directions(type_to)
	if not -dir in valid_entries:
		return false
		
	return true

func get_allowed_directions(type: String) -> Array:
	if type in room_types:
		# Rooms are assumed to connect to all valid neighbors
		return [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	if connectivity.has(type):
		return connectivity[type]
		
	return []

func update_player_position(new_pos: Vector2i):
	# Update Data
	var old_pos = GameData.player_coords
	# Optional: Set old cell to inactive if your game logic requires it, 
	# usually we just track current player pos.
	
	GameData.player_coords = new_pos
	var new_cell = GameData.maze_map[new_pos.y][new_pos.x]
	
	# Mark as explored so it appears on the map
	new_cell["explored"] = true
	
	# Update Visuals
	update_player_visuals()
	draw_map() 
	
	# Save State
	GameData.save_game()
	
	check_room_entry(new_cell)

func update_player_visuals():
	# Use map_to_local to center the sprite on the tile
	if map_display:
		player_icon.position = map_display.map_to_local(GameData.player_coords)

func draw_map():
	map_display.clear()
	
	for y in range(GameData.map_height):
		for x in range(GameData.map_width):
			var cell_data = GameData.maze_map[y][x]
			
			# Only draw if explored
			if cell_data.get("explored", false):
				var type = cell_data.get("type", "")
				var tile_coord = Vector2i(4, 4) # Default/Error tile
				
				if tile_atlas_coords.has(type):
					tile_coord = tile_atlas_coords[type]
				elif type in room_types:
					# Fallback for rooms if they aren't explicitly in atlas dict
					# (Though they are added above, this is safety)
					tile_coord = tile_atlas_coords.get("basicArena")
					
				# Set cell (layer 0, source_id 0, atlas coords)
				map_display.set_cell(Vector2i(x, y), 0, tile_coord, 0) 
				# Note: source_id set to 0. Ensure your TileMapLayer has a TileSet with ID 0.

func check_room_entry(cell_data: Dictionary):
	var type = cell_data.get("type", "")
	
	# If we moved into a room (not a corridor), transition to gameplay
	# We exclude "Start" because the player spawns there and might revisit it safely
	if type in ["basicArena", "advancedArena", "puzzleRoom", "Centre"]:
		if not cell_data.get("cleared", false):
			print("UI Corridor: Requesting entry to ", type)
			
			# Stop processing input immediately so player doesn't keep moving
			set_process_unhandled_input(false)
			
			# Emit the signal for Main.gd to handle
			room_entered.emit(type)
