class_name Stats extends Resource

enum Faction {
	PLAYER,
	ENEMY
}

var current_health : int : set = _on_health_set
var owner_node : Node = null
signal health_changed(new_health : float, max_health :float)
signal health_depleted
signal damage_taken

@export var max_health : float = 100.0
@export var defense : float = 1 #Damage taken is divided by defense
@export var damage : float = 10
@export var faction : Faction = Faction.PLAYER

func _init() -> void:
	initialise_stats.call_deferred()
	
func initialise_stats() -> void:
	current_health = max_health
	
func set_owner_node(node: Node) -> void:
	owner_node = node
	
func take_damage(amount: float) -> void:
	current_health -= amount/defense
	
	if current_health <= 0:
		health_depleted.emit()
	else:
		damage_taken.emit()
	
	print(owner_node.name ," took ", amount/defense, "damage, current hp = ", current_health)
	
func _on_health_set(value : float) -> void:
	current_health = value
	health_changed.emit(current_health, max_health)
	
	
