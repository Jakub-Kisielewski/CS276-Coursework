extends Node

signal player_stats_changed
signal currency_updated(new_amount)
signal weapon_list_changed
signal active_weapon_changed(weapon_index) 

# Persistent game stats
var max_health: float = 1000.0
var current_health: float = 1000.0
var currency: int = 0
var defense: float = 1.0
var damage: float = 10.0
var maze_map: Array = []
var map_width: int = 7
var map_height: int = 7
var branch_prob: float = 0.4
var difficulty_mod: float = 1.0
var player_coords: Vector2i = Vector2i(0, 0)
var current_weapons: Array[WeaponData] = []
var active_weapon_index: int = 0

const SAVE_PATH = "user://savegame.json"

func _ready() -> void:
	load_game()

func update_health(amount: float):
	current_health = clamp(current_health + amount, 0, max_health)
	player_stats_changed.emit()

func upgrade_defense():
	defense *= 1.3
	player_stats_changed.emit()	

func reset_stats():
	current_health = max_health
	player_stats_changed.emit()

func add_currency(amount: int):
	currency += amount
	currency_updated.emit(currency)

func set_active_weapon(index: int):
	if index >= 0 and index < current_weapons.size():
		active_weapon_index = index
		active_weapon_changed.emit(active_weapon_index)

func add_weapon(weapon_data: WeaponData):
	if weapon_data == null:
		return
		
	if weapon_data not in current_weapons:
		current_weapons.append(weapon_data)
		weapon_list_changed.emit()

func save_game():
	var save_dict = {
		"max_health": max_health,
		"current_health": current_health,
		"currency": currency,
		"defense": defense,
		"damage": damage,
		"difficulty_mod": difficulty_mod,
		"active_weapon_index": active_weapon_index
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_dict)
		file.store_string(json_string)
		print("Game Saved")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(content)
		
		if error == OK:
			var data = json.data
			max_health = data.get("max_health", 1000.0)
			current_health = data.get("current_health", 1000.0)
			currency = data.get("currency", 0)
			defense = data.get("defense", 1.0)
			damage = data.get("damage", 10.0)
			active_weapon_index = data.get("active_weapon_index", 0)
			
			player_stats_changed.emit()
			currency_updated.emit(currency)
			print("Game Loaded")

func reset_run_state():
	max_health = 1000.0
	current_health = 1000.0
	currency = 0
	defense = 1.0
	damage = 10.0
	
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	player_stats_changed.emit()
	currency_updated.emit(currency)
	print("Game Data Reset")
