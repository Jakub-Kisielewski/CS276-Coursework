class_name Stats extends Resource

enum Faction {
	PLAYER,
	ENEMY
}

var world : World
var current_health : int : set = _on_health_set
var owner_node : Node = null
signal health_changed
signal health_depleted
signal damage_taken
var sprite : AnimatedSprite2D

@export var max_health : float = 100
@export var defense : float = 1 #Damage taken is divided by defense
@export var damage : float = 10
@export var faction : Faction = Faction.PLAYER
@export var currency : int
@export var itemdrop_scene : PackedScene

enum Status { HEALTHY, POISONED, DAMAGED, OVERHEATING }
var status : Status = Status.HEALTHY;

#Information about current timers
var poison_timer : Timer
var poison_hits_left : int
var damage_timer : Timer
var overheat_timer : Timer
var dark_timer : Timer


func initialise_stats() -> void:
	current_health = max_health
	
func set_owner_node(node: Node) -> void:
	owner_node = node
	world = owner_node.get_tree().get_first_node_in_group("world")
	end_darkness()
	
	initialise_stats()
	health_changed.emit()
	
	if owner_node.is_in_group("player"):
		sprite = owner_node.get_node("fullAnim")
	else:
		sprite = owner_node.get_node("AnimatedSprite2D")

func get_health() -> int:
	return current_health

func set_status(new_status : Status) -> void:
	status = new_status
	match status:
		Status.HEALTHY:
			sprite.modulate = Color("ffffffff")
		Status.POISONED:
			sprite.modulate = Color("#ffacff")
		Status.DAMAGED:
			sprite.modulate = Color("f5a3b0")
		Status.OVERHEATING:
			sprite.modulate = Color("f5a3b0")

func take_damage(amount: float, attack_effect: String) -> void:
	match attack_effect:
		"Poison":
			start_poison()
			current_health = max(0, current_health - amount/defense)
			print(owner_node.name ," took ", amount/defense, " damage, current hp = ", current_health)
			
		"Lifeslash":
			start_darkness()
			
			start_visualise_damage()
			current_health = max(0, 0.8*current_health)
			print(owner_node.name ," took ", current_health, " damage, current hp = ", current_health)
		
		"Critical":
			start_visualise_damage()
			current_health = max(0, current_health - amount*1.2/defense)
			print(owner_node.name ," took ", amount*1.5/defense, " damage, current hp = ", current_health)
		
		_:
			start_visualise_damage()
			current_health = max(0, current_health - amount/defense)
			print(owner_node.name ," took ", amount/defense, " damage, current hp = ", current_health)

	health_changed.emit()
	if current_health == 0:
		health_depleted.emit()
	else:
		damage_taken.emit()

func drop_item() -> void:
	var itemdrop : Node = load(itemdrop_scene.resource_path).instantiate()
	itemdrop.global_position = owner_node.global_position
	owner_node.get_tree().current_scene.add_child(itemdrop)

func start_visualise_damage() -> void:
	if damage_timer != null:
		damage_timer.queue_free()

	set_status(Status.DAMAGED)
	damage_timer = Timer.new()
	damage_timer.wait_time = 0.2
	damage_timer.autostart = true
	owner_node.add_child(damage_timer)
	damage_timer.timeout.connect(end_visualise_damage)

func end_visualise_damage() -> void:
	if damage_timer != null:
		damage_timer.queue_free()
	
	if poison_timer != null:
		set_status(Status.POISONED)
	elif overheat_timer != null:
		set_status(Status.OVERHEATING)
	else:
		set_status(Status.HEALTHY)


func start_darkness() -> void:
	if dark_timer != null:
		dark_timer.queue_free()
	
	world.set_dark()	
	dark_timer = Timer.new()
	dark_timer.wait_time = 3.6
	dark_timer.autostart = true
	owner_node.add_child(dark_timer)
	dark_timer.timeout.connect(end_darkness)
	
func end_darkness() -> void:
	if dark_timer != null:
		dark_timer.queue_free()
	
	world.set_standard()

func start_poison() -> void:
	if poison_timer != null:
		poison_timer.queue_free()
	
	set_status(Status.POISONED)
	print(owner_node.name + " has been poisoned")	
	
	poison_timer = Timer.new()
	poison_hits_left = 15
	
	poison_timer.wait_time = 1
	poison_timer.one_shot = false
	poison_timer.autostart = true
	owner_node.add_child(poison_timer)
	poison_timer.timeout.connect(take_poison_damage)
	
func take_poison_damage() -> void:
	take_damage(2, "None")
	poison_hits_left -= 1
	
	if poison_hits_left == 0:
		if poison_timer != null:
			poison_timer.queue_free()
		set_status(Status.HEALTHY)
		print(owner_node.name + " is no longer poisoned")


func start_overheat() -> void:
	if overheat_timer != null:
		overheat_timer.queue_free()

	set_status(Status.OVERHEATING)
	sprite.self_modulate = Color(1.353, 1.353, 1.353, 1.0)
	print(owner_node.name + " is overheating")	
	
	overheat_timer = Timer.new()
	
	overheat_timer.wait_time = 1
	overheat_timer.one_shot = false
	overheat_timer.autostart = true
	owner_node.add_child(overheat_timer)
	overheat_timer.timeout.connect(take_overheat_damage)
		
func take_overheat_damage() -> void:
	take_damage(3, "None")

func end_overheat() -> void:
	if overheat_timer != null:
		overheat_timer.queue_free()
		
	set_status(Status.HEALTHY)
	sprite.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	

func _on_health_set(value : float) -> void:
	current_health = value
	health_changed.emit(current_health, max_health)
	
