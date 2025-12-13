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
var damage: float = 15.0
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
	
	

func apply_random_completion_reward() -> String:
	var options = ["heal", "gold", "defense", "damage"]
	
	if current_weapons.size() > 0 and active_weapon_index < current_weapons.size():
		options.append("weapon_rarity")
		options.append("weapon_type")
	
	var choice = options.pick_random()
	
	match choice:
		"heal":
			update_health(250)
			return "Reward: Healed 250 HP"
		"gold":
			add_currency(100)
			return "Reward: Found 100 Gold"
		"defense":
			upgrade_defense()
			return "Reward: Defense Increased!"
		"damage":
			upgrade_damage(5.0)
			return "Reward: Base Damage +5"
		"weapon_rarity":
			var wp = current_weapons[active_weapon_index]
			if wp.rarity == WeaponData.Rarity.PRISMATIC:
				add_currency(200)
				return "Reward: 200 Gold (Weapon Maxed)"
			else:
				wp.upgrade_rarity()
				return "Reward: Weapon Rarity Upgraded!"
		"weapon_type":
			var wp = current_weapons[active_weapon_index]
			if wp.weapon_mult >= 2.0:
				add_currency(150)
				return "Reward: 150 Gold (Proficiency Maxed)"
			else:
				wp.upgrade_type()
				return "Reward: Weapon Proficiency Up!"
				
	return "Reward: Room Cleared"

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
