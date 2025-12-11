extends Node

signal player_stats_changed
signal currency_updated(new_amount)

# persisten player stats
var max_health: float = 1000.0
var current_health: float = 1000.0
var currency: int = 0
var defense: float = 1.0
var damage: float = 10.0
var maze_map: Array = [] # map[y][x]

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
