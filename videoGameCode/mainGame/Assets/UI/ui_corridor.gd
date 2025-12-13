extends Control

signal room_entered(room_type: String)
@onready var map_display: TileMapLayer = %MapDisplay
@onready var player_icon: Sprite2D = %PlayerIcon
@onready var btn_enter_room: Button = %BtnEnterRoom
@onready var map_wrapper: Control = %MapWrapper

var current_hovered_room_type: String = ""
var head_up = preload('res://Assets/Resources/head/up_head.png')
var head_down = preload('res://Assets/Resources/head/down_head.png')
var head_left = preload('res://Assets/Resources/head/left_head.png')
var head_right = preload('res://Assets/Resources/head/right_head.png')


var connectivity: Dictionary = {
	# Straights (Pipes)
	"straightVertical": [Vector2i.UP, Vector2i.DOWN],
	"straightNorth": [Vector2i.UP, Vector2i.DOWN],
	"straightSouth": [Vector2i.UP, Vector2i.DOWN],
	
	"straightHorizontal": [Vector2i.LEFT, Vector2i.RIGHT],
	"straightEast": [Vector2i.LEFT, Vector2i.RIGHT],
	"straightWest": [Vector2i.LEFT, Vector2i.RIGHT],
	
	"northToWestTurn": [Vector2i.DOWN, Vector2i.LEFT],
	"northToEastTurn": [Vector2i.DOWN, Vector2i.RIGHT], 
	
	"southToWestTurn": [Vector2i.UP, Vector2i.LEFT], 
	"southToEastTurn": [Vector2i.UP, Vector2i.RIGHT],
	
	"eastToNorthTurn": [Vector2i.LEFT, Vector2i.UP],
	"eastToSouthTurn": [Vector2i.LEFT, Vector2i.DOWN], 
	
	"westToNorthTurn": [Vector2i.RIGHT, Vector2i.UP], 
	"westToSouthTurn": [Vector2i.RIGHT, Vector2i.DOWN],
	
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

enum Head {
	UP,
	DOWN,
	RIGHT,
	LEFT
}

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	
	if btn_enter_room:
		btn_enter_room.pressed.connect(_on_enter_room_pressed)
		btn_enter_room.visible = false
	
	if not GameData.maze_map.is_empty():
		initialize_corridor_view()

func _on_visibility_changed() -> void:
	if visible:
		initialize_corridor_view()
		update_player_visuals(Head.RIGHT)
		set_process_unhandled_input(true)
		grab_focus()

func initialize_corridor_view() -> void:
	if GameData.maze_map.is_empty():
		return
	
	# Find Start if player coords are unset (or strictly 0,0 which might be a wall)
	if GameData.player_coords == Vector2i(0,0) and not _is_valid_cell(Vector2i(0,0)):
		find_player_start()
	
	await center_maze()
	draw_map()
	# Defer the visual update slightly to ensure TileMapLayer is ready
	call_deferred("update_player_visuals")

func center_maze() -> void:
	if not map_display or not map_wrapper:
		return
	
	var tile_set = map_display.tile_set
	if not tile_set:
		return
	
	# Set the scale
	map_display.scale = Vector2(5, 5)  # Your desired scale
	map_display.rotation = 0
	
	await get_tree().process_frame
	
	var tile_size = tile_set.tile_size
	var container_size = map_wrapper.size
	var center_tile_x = int(GameData.map_width / 2)
	var center_tile_y = int(GameData.map_height / 2)
	var center_tile_coords = Vector2i(center_tile_x, center_tile_y)
	
	# Get the local position and account for scale
	var center_tile_local_pos = map_display.map_to_local(center_tile_coords) * map_display.scale
	var container_center = container_size / 2.0
	
	map_display.position = container_center - center_tile_local_pos

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
	
	# Get cell data for specific logic
	var current_cell = GameData.maze_map[current_pos.y][current_pos.x]
	var target_cell = GameData.maze_map[new_pos.y][new_pos.x]
	
	var current_type = current_cell.get("type", "")
	var target_type = target_cell.get("type", "")
	
	var is_current_room = current_type in room_types
	var is_target_room = target_type in room_types
	
	# --- FIX 1: Prevent Adjacent Room Skipping ---
	# If we are currently in a room and trying to move directly into another room, BLOCK IT.
	# This prevents skipping corridors or exploiting generation bugs.
	if is_current_room and is_target_room:
		print("Movement blocked: Cannot move directly between rooms.")
		return

	# --- FIX 2: Restrict Movement from Uncleared Rooms ---
	# If the current room is NOT Start and NOT cleared...
	if is_current_room and current_type != "Start" and not current_cell.get("cleared", false):
		# ...only allow movement to tiles that are ALREADY explored.
		# This allows retreating (going back) but blocks progressing forward into the unknown.
		if not target_cell.get("explored", false):
			print("Room not cleared! You can only go back the way you came.")
			# Optional: Play a 'denied' sound effect here
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
	var old_pos: Vector2i = GameData.player_coords
	# Optional: Set old cell to inactive if your game logic requires it, 
	# usually we just track current player pos.
	var direction: Vector2i = new_pos - old_pos
	
	var head_direction: Head
	match direction:
		Vector2i.DOWN:
			head_direction = Head.DOWN
		Vector2i.UP:
			head_direction = Head.UP
		Vector2i.RIGHT:
			head_direction = Head.RIGHT
		Vector2i.LEFT:
			head_direction = Head.LEFT
	
	GameData.player_coords = new_pos
	var new_cell = GameData.maze_map[new_pos.y][new_pos.x]
	
	# Mark as explored so it appears on the map
	new_cell["explored"] = true
	
	# Update Visuals
	update_player_visuals(head_direction)
	draw_map() 
	
	# Save State
	GameData.save_game()
	
	check_room_entry(new_cell)

func update_player_visuals(head_direction: Head = Head.RIGHT):
	if not map_display or not player_icon:
		return
		
	# Get the tile's local position on the map
	var map_pos = map_display.map_to_local(GameData.player_coords)
	
	# Update head texture
	match head_direction:
		Head.UP:
			player_icon.texture = head_up
		Head.DOWN:
			player_icon.texture = head_down
		Head.RIGHT:
			player_icon.texture = head_right
		Head.LEFT:
			player_icon.texture = head_left
	
	# Account for both the map's position AND its scale
	player_icon.position = map_display.position + (map_pos * map_display.scale)

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
				
				map_display.set_cell(Vector2i(x, y), 0, tile_coord, 0)
			else:
				# draw blank
				map_display.set_cell(Vector2i(x,y), 0, Vector2i(4,4), 0)

func check_room_entry(cell_data: Dictionary):
	var type = cell_data.get("type", "")
	
	# Reset state initially
	btn_enter_room.visible = false
	current_hovered_room_type = ""
	
	# Check if we are on a room tile (excluding Start)
	if type in ["basicArena", "advancedArena", "puzzleRoom", "Centre"]:
		# Only show button if the room hasn't been cleared yet
		if not cell_data.get("cleared", false):
			print("UI Corridor: Standing on ", type)
			
			# Store the type so we know where to go if clicked
			current_hovered_room_type = type
			
			# Show the button to let the player decide
			btn_enter_room.visible = true
			

func _on_enter_room_pressed() -> void:
	print("Button Pressed! Attempting to enter: ", current_hovered_room_type)
	
	if current_hovered_room_type != "":
		# Lock movement
		set_process_unhandled_input(false)
		btn_enter_room.visible = false
		
		# Load the room
		room_entered.emit(current_hovered_room_type)
		
		
		
#UPGRADES



#fire sale

var cost_rarity_upgrade: int = 50.0
var cost_type_upgrade : int = 50.0
var cost_special_attack: int = 50.0
var cost_heal : int = 50.0
var cost_defense_upgrade: int = 50.0
var cost_damage_upgrade: int = 50.0
var cost_dash_charge: int = 50.0
var cost_dash_transparency: int = 50.0 #dash through enemies
var cost_decoy : int = 50.0
var cost_weapon : int = 50.0
#currency_updated updates the UI for money

#where is the weapon icon
@export var bow_data : WeaponData
@export var spear_data : WeaponData

func buy_bow():
	if GameData.currency < cost_weapon:
		return
		
	if bow_data in GameData.current_weapons:
		print("Weapon already owned")
		return
	
	GameData.currency -= cost_weapon
	GameData.currency_updated.emit(GameData.currency)
	
	GameData.add_weapon(bow_data)
	

func buy_spear():

	if GameData.currency < cost_weapon:
		return
		
	if spear_data in GameData.current_weapons:
		print("Weapon already owned")
		return
	
	GameData.currency -= cost_weapon
	GameData.currency_updated.emit(GameData.currency)
	
	GameData.add_weapon(spear_data)
	

	
func buy_rarity_upgrade():
	if GameData.currency >= cost_rarity_upgrade:
		if GameData.upgrade_active_weapon_rarity():
			GameData.currency -= cost_rarity_upgrade
			GameData.currency_updated.emit(GameData.currency)
			
		

func buy_special_attack():			
	if GameData.currency >= cost_special_attack:
			if GameData.unlock_active_weapon_special():
				GameData.currency -= cost_special_attack
				GameData.currency_updated.emit(GameData.currency)
				
func buy_heal():
	if GameData.currency >= cost_heal:
		GameData.currency =- cost_heal
		GameData.update_health(250)
		
func buy_defense_upgrade():
	if GameData.currency >= cost_defense_upgrade:
		GameData.currency =- cost_defense_upgrade
		GameData.upgrade_defense()
		

		
func buy_dash_charge():
	if GameData.currency >= cost_dash_charge:
		if GameData.upgrade_dash_charges():
			GameData.currency -= cost_dash_charge
			GameData.currency_updated.emit(GameData.currency)
			
func buy_dash_transparency():
	if GameData.currency >= cost_dash_transparency:
		if GameData.unlock_dash_through_enemies():
			GameData.currency -= cost_dash_transparency
			GameData.currency_updated.emit(GameData.currency)
			
func buy_decoy():
	if GameData.currency >= cost_decoy:
		if GameData.unlock_decoy():
			GameData.currency -= cost_decoy
			GameData.currency_updated.emit(GameData.currency)
		
