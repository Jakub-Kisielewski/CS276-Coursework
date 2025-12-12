extends Control

@onready var map_display: TileMapLayer = %MapDisplay
@onready var player_icon: Sprite2D = %PlayerIcon

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
	
	if GameData.maze_map.is_empty():
		return
	
	initialize_corridor_view()

func _on_visibility_changed() -> void:
	if visible:
		initialize_corridor_view()

func initialize_corridor_view() -> void:
	if GameData.maze_map.is_empty():
		return
	
	if GameData.player_coords == Vector2i(0,0) and not _is_valid_cell(Vector2i(0,0)):
		find_player_start()
	
	draw_map()
	update_player_visuals()

func find_player_start():
	for y in range(GameData.map_height):
		for x in range(GameData.map_width):
			var cell = GameData.maze_map[y][x]
			if cell.get("type") == "Start":
				GameData.player_coords = Vector2i(x, y)
				return

func _is_valid_cell(coords: Vector2i) -> bool:
	# check map bounds
	if coords.x < 0 or coords.x >= GameData.map_width or coords.y < 0 or coords.y >= GameData.map_height:
		return false
	
	# check if the cell actually has data
	var cell_data = GameData.maze_map[coords.y][coords.x]
	
	# check if the cell is part of the maze
	if cell_data.get("type", "") == "":
		return false
		
	return true

func _unhandled_input(event: InputEvent) -> void:
	for dir_key in inputs.keys():
		if event.is_action_pressed(dir_key):
			attempt_move(inputs[dir_key])
			get_viewport().set_input_as_handled()

func attempt_move(direction: Vector2i) -> void:
	var current_pos = GameData.player_coords
	var new_pos = current_pos + direction
	
	if not _is_valid_cell(new_pos):
		return
	
	# 3. Check connectivity (Optional but recommended: ensure tiles actually connect visually)
	# For grid based mazes, simple adjacency is usually enough, but you could add logic
	# to check if the current tile allows exit in 'direction'.

	# check if current room is cleared
	var current_cell = GameData.maze_map[current_pos.y][current_pos.x]
	var is_room = current_cell.type in ["basicArena", "advancedArena", "puzzleRoom", "Start", "Centre"]
	var is_cleared = current_cell.get("cleared", false) 
	
	# if it's a room and NOT cleared, prevent movement
	if is_room and not is_cleared:
		print("Room not cleared! Cannot leave.")
		# Provide visual feedback (shake, sound) here
		return
	
	# move Player
	update_player_position(new_pos)

func update_player_position(new_pos: Vector2i):
	# update Data
	var old_pos = GameData.player_coords
	GameData.maze_map[old_pos.y][old_pos.x]["active"] = false
	
	GameData.player_coords = new_pos
	var new_cell = GameData.maze_map[new_pos.y][new_pos.x]
	
	new_cell["active"] = true
	new_cell["explored"] = true
	
	# update Visuals
	update_player_visuals()
	draw_map() # redraw to show newly explored tiles
	
	# Save State
	GameData.save_game()
	
	check_room_entry(new_cell)

func update_player_visuals():
	# Convert grid coords to local position for sprite
	# Assuming 16x16 tiles or whatever your Tileset is configured for
	var tile_size = map_display.tile_set.tile_size if map_display.tile_set else Vector2i(16, 16)
	player_icon.position = map_display.map_to_local(GameData.player_coords)

func draw_map():
	map_display.clear()
	
	for y in range(GameData.map_height):
		for x in range(GameData.map_width):
			var cell_data = GameData.maze_map[y][x]
			
			# only draw if explored
			if cell_data.get("explored", false):
				var type = cell_data.get("type", "")
				var tile_coord = Vector2i(4, 4)
				
				if tile_atlas_coords.has(type):
					tile_coord = tile_atlas_coords[type]
				elif roomTypeTiles_has(type): # Helper to check your room dict
					tile_coord = tile_atlas_coords.get("basicArena") # Placeholder logic
					
				# Set cell (layer 0, source_id 0, atlas coords)
				map_display.set_cell(Vector2i(x, y), 3, tile_coord, 0)

func roomTypeTiles_has(type_name: String) -> bool:
	return type_name in ["basicArena", "advancedArena", "puzzleRoom", "Start", "Centre"]

func check_room_entry(cell_data: Dictionary):
	var type = cell_data.get("type", "")
	
	# If we moved into a room (not a corridor), we might need to load gameplay
	if type in ["basicArena", "advancedArena", "puzzleRoom", "Centre"]:
		if not cell_data.get("cleared", false):
			print("Entering Room: ", type)
			# Transition Scene Code Here:
			# SceneManager.load_scene(type)
