extends Node

signal player_stats_changed
signal currency_updated(new_amount)

# persisten game stats
var max_health: float = 1000.0
var current_health: float = 1000.0
var currency: int = 0
var defense: float = 1.0
var damage: float = 10.0
var maze_map: Array = [] # map[y][x]
var map_width: int = 7
var map_height: int = 7
var branch_prob: float = 0.4
var difficulty_mod: float = 1.0

const SAVE_PATH = "user://savegame.json"

func _ready() -> void:
	# attempt to load data immediately when the game boots
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

func save_game():
	var save_dict = {
		"max_health": max_health,
		"current_health": current_health,
		"currency": currency,
		"defense": defense,
		"damage": damage,
		"maze_map": maze_map,
		"map_width": map_width,
		"map_height": map_height,
		"branch_prob": branch_prob,
		"difficulty_mod": difficulty_mod
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_dict)
		file.store_string(json_string)
		print("Game Saved")
	else:
		print("Failed to save game.")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return # no save file found
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(content)
		
		if error == OK:
			var data = json.data
			# Use .get() with default values to prevent crashes if keys are missing
			max_health = data.get("max_health", 1000.0)
			current_health = data.get("current_health", 1000.0)
			currency = data.get("currency", 0)
			defense = data.get("defense", 1.0)
			damage = data.get("damage", 10.0)
			maze_map = data.get("maze_map", [])
			map_width = data.get("map_width", 7)
			map_height = data.get("map_height", 7)
			branch_prob = data.get("branch_prob", 0.4)
			difficulty_mod = data.get("difficulty_mod", 1.0)
			
			# Update UI with loaded values
			player_stats_changed.emit()
			currency_updated.emit(currency)
			print("Game Loaded")
		else:
			print("JSON Parse Error: ", json.get_error_message())

func reset_run_state():
	max_health = 1000.0
	current_health = 1000.0
	currency = 0
	defense = 1.0
	damage = 10.0
	maze_map = []
	map_width = 7
	map_height = 7
	branch_prob = 0.4
	difficulty_mod = 1.0

	if FileAccess.file_exists(SAVE_PATH):
		var error = DirAccess.remove_absolute(SAVE_PATH)
		if error == OK:
			print("Save file deleted.")
		else:
			print("An error occurred when trying to delete the save file.")
	
	player_stats_changed.emit()
	currency_updated.emit(currency)
	print("Game Data Reset")
