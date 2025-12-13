extends Control

signal room_entered(room_type: String)
@onready var help_label: Label = %Help
@onready var map_display: TileMapLayer = %MapDisplay
@onready var player_icon: Sprite2D = %PlayerIcon
@onready var btn_enter_room: Button = %BtnEnterRoom
@onready var map_wrapper: Control = %MapWrapper

var head_up = preload("res://Assets/Resources/head/up_head.png")
var head_down = preload("res://Assets/Resources/head/down_head.png")
var head_right = preload("res://Assets/Resources/head/right_head.png")
var head_left = preload("res://Assets/Resources/head/left_head.png")

@onready var btn_health = %HEALTH
@onready var btn_defence = %DEFENCE
@onready var btn_sword_ability = %swordAbility
@onready var btn_spear_ability = %spearAbility
@onready var btn_bow_ability = %bowAbility
@onready var btn_upgrade_sword = %upgradeSword
@onready var btn_upgrade_spear = %upgradeSpear
@onready var btn_upgrade_bow = %upgradeBow
@onready var btn_player_abilities = %playerAbilities
@onready var health_label = %stat_health
@onready var gold_label = %stat_gold

var current_hovered_room_type: String = ""
var connectivity: Dictionary = {
	# Straights (Pipes)
	"straightVertical": [Vector2i.UP, Vector2i.DOWN],
	"straightNorth": [Vector2i.UP, Vector2i.DOWN],
	"straightSouth": [Vector2i.UP, Vector2i.DOWN],
	
	"straightHorizontal": [Vector2i.LEFT, Vector2i.RIGHT],
	"straightEast": [Vector2i.LEFT, Vector2i.RIGHT],
	"straightWest": [Vector2i.LEFT, Vector2i.RIGHT],
	
	# Turns (Entry -> Exit logic inferred from names)
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
	LEFT,
	RIGHT
}

func _ready() -> void:
	
	GameData.player_stats_changed.connect(on_player_stats_changed)
	GameData.currency_updated.connect(on_currency_updated)
	
	update_health_gold()
	
	#how do this part
	btn_player_abilities.clear()
	btn_player_abilities.add_item("Extra Dash", 0)
	btn_player_abilities.add_item("Dash through enemies", 1)
	btn_player_abilities.add_item("Decoy", 2)
	
	btn_player_abilities.item_selected.connect(on_player_abilities_item_selected)
	
	btn_health.pressed.connect(buy_heal)
	btn_defence.pressed.connect(buy_defense_upgrade)
	
	btn_sword_ability.pressed.connect(on_sword_ability_pressed)
	btn_spear_ability.pressed.connect(on_spear_ability_pressed)
	btn_bow_ability.pressed.connect(on_bow_ability_pressed)
	
	btn_upgrade_bow.pressed.connect(on_upgrade_bow_pressed)
	btn_upgrade_spear.pressed.connect(on_upgrade_spear_pressed)
	btn_upgrade_sword.pressed.connect(on_upgrade_sword_pressed)
	
	
	visibility_changed.connect(_on_visibility_changed)
	
	if btn_enter_room:
		btn_enter_room.pressed.connect(_on_enter_room_pressed)
		btn_enter_room.visible = false # Ensure hidden at start
		btn_enter_room.position.y -= 100
	
	if not GameData.maze_map.is_empty():
		initialize_corridor_view()
	
func update_health_gold():
	health_label.text = "Health: " + str(round(GameData.current_health))
	gold_label.text = "Gold: " + str(GameData.currency)
	

func _on_visibility_changed() -> void:
	if visible:
		initialize_corridor_view()
		update_player_visuals(Head.RIGHT)
		set_process_unhandled_input(true)
		grab_focus()
		update_health_gold()

func initialize_corridor_view() -> void:
	if GameData.maze_map.is_empty():
		return
	
	if GameData.player_coords == Vector2i(0,0) and not _is_valid_cell(Vector2i(0,0)):
		find_player_start()
	
	await center_maze()
	draw_map()
	call_deferred("update_player_visuals")

func center_maze() -> void:
	if not map_display or not map_wrapper:
		return
	
	var tile_set = map_display.tile_set
	if not tile_set:
		return
	
	map_display.scale = Vector2(7, 7)
	map_display.rotation = 0
	
	await get_tree().process_frame
	
	var tile_size = tile_set.tile_size
	var container_size = map_wrapper.size
	var center_tile_x = int(GameData.map_width / 2)
	var center_tile_y = int(GameData.map_height / 2)
	var center_tile_coords = Vector2i(center_tile_x, center_tile_y)
	
	var center_tile_local_pos = map_display.map_to_local(center_tile_coords) * map_display.scale
	var container_center = container_size / 2.0
	
	map_display.position = container_center - center_tile_local_pos
	map_display.position.y -= 20

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
	var old_pos: Vector2i = GameData.player_coords
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
	
	new_cell["explored"] = true
	
	update_player_visuals(head_direction)
	
	draw_map() 
	
	GameData.save_game()
	
	check_room_entry(new_cell)

func update_player_visuals(head_direction: Head = Head.RIGHT):
	if not map_display or not player_icon:
		return
		
	var map_pos = map_display.map_to_local(GameData.player_coords)
	
	match head_direction:
		Head.UP:
			player_icon.texture = head_up
		Head.DOWN:
			player_icon.texture = head_down
		Head.RIGHT:
			player_icon.texture = head_right
		Head.LEFT:
			player_icon.texture = head_left
	
	player_icon.position = map_display.position + (map_pos * map_display.scale)


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
					# Fallback for rooms if they aren't explicitly in atlas dict
					# (Though they are added above, this is safety)
					tile_coord = tile_atlas_coords.get("basicArena")
					
				# Set cell (layer 0, source_id 0, atlas coords)
				map_display.set_cell(Vector2i(x, y), 0, tile_coord, 0)
				# Note: source_id set to 0. Ensure your TileMapLayer has a TileSet with ID 0.
			else:
				# draw blank
				map_display.set_cell(Vector2i(x,y), 0, Vector2i(4,4), 0)

func check_room_entry(cell_data: Dictionary):
	var type = cell_data.get("type", "")
	
	help_label.visible = true
	btn_enter_room.visible = false
	current_hovered_room_type = ""
	
	if type in ["basicArena", "advancedArena", "puzzleRoom", "Centre"]:
		if not cell_data.get("cleared", false):
			
			current_hovered_room_type = type
			
			help_label.visible = false
			btn_enter_room.visible = true
			

func _on_enter_room_pressed() -> void:
	
	if current_hovered_room_type != "":
		set_process_unhandled_input(false)
		help_label.visible = true
		btn_enter_room.visible = false
		
		room_entered.emit(current_hovered_room_type)

#UPGRADES



#fire sale

var cost_rarity_upgrade: int = 50.0
var cost_special_attack: int = 50.0
var cost_heal : int = 50.0
var cost_defense_upgrade: int = 50.0
var cost_dash_charge: int = 50.0
var cost_dash_transparency: int = 50.0 #dash through enemies
var cost_decoy : int = 50.0
var cost_weapon : int = 50.0
#currency_updated updates the UI for money
var selected_ability_id: int = 0

#where is the weapon icon
@export var bow_data : WeaponData
@export var spear_data : WeaponData
@export var sword_data : WeaponData

func buy_rarity_upgrade(index: int):
	if GameData.currency >= cost_rarity_upgrade:
		GameData.set_active_weapon(index)
		if GameData.upgrade_active_weapon_rarity():
			GameData.currency -= cost_rarity_upgrade
			GameData.currency_updated.emit(GameData.currency)
			update_health_gold()
			
		

func buy_special_attack(index : int):
	if GameData.currency >= cost_special_attack:
		GameData.set_active_weapon(index)
		if GameData.unlock_active_weapon_special():
			GameData.currency -= cost_special_attack
			GameData.currency_updated.emit(GameData.currency)
			update_health_gold()
				
func buy_heal():
	if GameData.currency >= cost_heal:
		GameData.currency -= cost_heal
		GameData.update_health(250)
		update_health_gold()
		
func buy_defense_upgrade():
	if GameData.currency >= cost_defense_upgrade:
		GameData.currency -= cost_defense_upgrade
		GameData.upgrade_defense()
		update_health_gold()
		

func buy_dash_charge():
	if GameData.currency >= cost_dash_charge:
		if GameData.upgrade_dash_charges():
			GameData.currency -= cost_dash_charge
			GameData.currency_updated.emit(GameData.currency)
			update_health_gold()
			
func buy_dash_transparency():
	if GameData.currency >= cost_dash_transparency:
		if GameData.unlock_dash_through_enemies():
			GameData.currency -= cost_dash_transparency
			GameData.currency_updated.emit(GameData.currency)
			update_health_gold()
			
func buy_decoy():
	if GameData.currency >= cost_decoy:
		if GameData.unlock_decoy():
			GameData.currency -= cost_decoy
			GameData.currency_updated.emit(GameData.currency)
			update_health_gold()
			
func on_player_abilities_item_selected(index: int):
	selected_ability_id = btn_player_abilities.get_item_id(index)
	
	match selected_ability_id: 
		0: buy_dash_charge()
		1: buy_dash_transparency()
		2: buy_decoy()
	
#must populate current_weapons in this order
func on_upgrade_sword_pressed():
	buy_rarity_upgrade(0)	

func on_upgrade_spear_pressed():
	buy_rarity_upgrade(1)

func on_upgrade_bow_pressed():
	buy_rarity_upgrade(2)

func on_sword_ability_pressed():
	buy_special_attack(0)

func on_spear_ability_pressed():
	buy_special_attack(1)

func on_bow_ability_pressed():
	buy_special_attack(2)

func on_currency_updated():
	update_health_gold()

func on_player_stats_changed():
	update_health_gold()
