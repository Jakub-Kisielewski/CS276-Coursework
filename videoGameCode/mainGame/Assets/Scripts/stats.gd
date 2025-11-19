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

enum Status { HEALTHY, POISONED }
var status : Status = Status.HEALTHY;

#Information about current poison effect
var poison_timer : Timer
var poison_hits_left : int

func _init() -> void:
	initialise_stats.call_deferred()
	
func initialise_stats() -> void:
	current_health = max_health
	
func set_owner_node(node: Node) -> void:
	owner_node = node

func set_status(new_status : Status):
	status = new_status
	match status:
		Status.HEALTHY:
			owner_node.get_node("AnimatedSprite2D").modulate = Color("ffffffff")
		Status.POISONED:
			owner_node.get_node("AnimatedSprite2D").modulate = Color("#ffacff")

func take_damage(amount: float, attack_effect: String) -> void:
	match attack_effect:
		"Poison":
			start_poison()
			current_health -= amount/defense
			print(owner_node.name ," took ", amount/defense, " damage, current hp = ", current_health)
			
		"Lifeslash":
			current_health = current_health/2
			print(owner_node.name ," took ", current_health, " damage, current hp = ", current_health)
			
		_:
			current_health -= amount/defense
			print(owner_node.name ," took ", amount/defense, " damage, current hp = ", current_health)
	
	if current_health <= 0:
		health_depleted.emit()
	else:
		damage_taken.emit()

func start_poison():
	if poison_timer != null:
		poison_timer.queue_free()
	
	set_status(Status.POISONED)
	print(owner_node.name + " has been poisoned")	
	
	poison_timer = Timer.new()
	poison_hits_left = 5
	
	poison_timer.wait_time = 2
	poison_timer.one_shot = false
	poison_timer.autostart = true
	owner_node.add_child(poison_timer)
	poison_timer.timeout.connect(take_poison_damage)
	
func take_poison_damage():
	take_damage(3, "None")
	poison_hits_left -= 1
	if poison_hits_left == 0:
		poison_timer.queue_free()
		set_status(Status.HEALTHY)
		print(owner_node.name + " is no longer poisoned")
	

func _on_health_set(value : float) -> void:
	current_health = value
	health_changed.emit(current_health, max_health)
	
