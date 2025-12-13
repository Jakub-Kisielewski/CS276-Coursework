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
var damage: float = 25.0
var maze_map: Array = []
var map_width: int = 7
var map_height: int = 7
var branch_prob: float = 0.4
var player_coords: Vector2i = Vector2i(0, 0)
var current_weapons: Array[WeaponData] = []
var active_weapon_index: int = 0
var game_difficulty: float = 1

var max_dashes_charges: int = 1
var decoy_unlocked = false
var dash_through_enemies_unlocked: bool = false

var mouse_aiming: bool = true
var god_mode_enabled: bool = false
var show_controls: bool = false

var master_volume_db: float = 0.0
var music_volume_db: float = 0.0
var sfx_volume_db: float = 0.0

const SAVE_PATH = "user://savegame.json"

func _ready() -> void:
	load_game()

func get_active_weapon() -> WeaponData:
	if current_weapons.is_empty():
		return null
	if active_weapon_index < 0 or active_weapon_index >=  current_weapons.size():
		return null
	return current_weapons[active_weapon_index]

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

func upgrade_damage(amount: int):
	damage+=amount
	player_stats_changed.emit()

func set_active_weapon(index: int):
	if index >= 0 and index < current_weapons.size():
		active_weapon_index = index
		active_weapon_changed.emit(active_weapon_index)

func upgrade_active_weapon_rarity() -> bool:
	var wp := get_active_weapon()
	if wp == null:
		return false
	if wp.rarity == WeaponData.Rarity.PRISMATIC:
		return false
			
	wp.upgrade_rarity()
	return true
	
func upgrade_dash_charges() -> bool:
	if max_dashes_charges >= 3:
		return false
		
	max_dashes_charges =+ 1
	return true
	
func unlock_decoy() -> bool:
	if decoy_unlocked:
		return false
	decoy_unlocked = true
	return true
	
func unlock_dash_through_enemies() -> bool:
	if dash_through_enemies_unlocked:
		return false
	dash_through_enemies_unlocked = true
	return true 
	
	
func upgrade_active_weapon_type() -> bool:
	var wp := get_active_weapon()
	if wp == null:
		return false
	return wp.upgrade_type()
	
func unlock_active_weapon_special() -> bool:
	var wp := get_active_weapon()
	if wp == null:
		return false
	return wp.unlock_special_attack()
	
	

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
		"active_weapon_index": active_weapon_index,
		"game_difficulty": game_difficulty
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_dict)
		file.store_string(json_string)

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
			game_difficulty = data.get("game_difficulty", 1)
			
			player_stats_changed.emit()
			currency_updated.emit(currency)

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
