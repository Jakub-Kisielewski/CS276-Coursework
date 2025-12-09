class_name HealthComponent extends Node

# signals for parent to listen to for visuals
signal health_changed(new_amount, max_amount)
signal health_depleted
signal damage_taken(amount, type)
signal status_changed(new_status)
signal special_effect_triggered(effect_name)

# stats
@export var max_health: float = 100.0
@export var defense: float = 1.0

# internal State
var current_health: float
var is_player: bool = false
var poison_timer: Timer
var poison_ticks_left: int = 0
var overheat_timer: Timer

enum Status { HEALTHY, POISONED, DAMAGED, OVERHEATING }
var status: Status = Status.HEALTHY

func _ready():
	# overwrite local stats with GameData if player
	if get_parent().is_in_group("player"):
		is_player = true
		sync_from_game_data()
	else:
		# use exported values if enemy
		current_health = max_health
	
	# setup poison timer
	poison_timer = Timer.new()
	poison_timer.wait_time = 1.0
	poison_timer.one_shot = false
	add_child(poison_timer) 
	poison_timer.timeout.connect(_on_poison_tick)
	# setup overheat timer
	overheat_timer = Timer.new()
	overheat_timer.wait_time = 1.0
	add_child(overheat_timer)
	overheat_timer.timeout.connect(_on_overheat_tick)

func sync_from_game_data():
	max_health = GameData.max_health
	current_health = GameData.current_health
	defense = GameData.defense

func take_damage(amount: float, attack_effect: String):
	var final_damage: float = amount
	
	match attack_effect:
		"Poison":
			start_poison()
			final_damage = amount / defense
		"Lifeslash":
			SignalBus.request_darkness.emit(3.6)
			final_damage = current_health * 0.2 # reduce hp by 20%
		"Critical":
			final_damage = (amount * 1.2) / defense
		_:
			# Standard Damage
			final_damage = amount / defense
	
	current_health = max(0, current_health - final_damage)
	
	
	if is_player:
		GameData.update_health(-final_damage) 
	
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0:
		emit_signal("health_depleted")
	else:
		# We pass the final calculated damage so the UI can show popup numbers
		emit_signal("damage_taken", final_damage, attack_effect)
		# Briefly set status to DAMAGED for visuals, then revert
		_handle_damage_status()

# --- poison logic ---
func start_poison():
	# Reset ticks if already poisoned, or start fresh
	poison_ticks_left = 15 
	
	if status != Status.POISONED:
		set_status(Status.POISONED)
		poison_timer.start()
		print(get_parent().name + " poisoned")

func _on_poison_tick():
	take_damage(2.0, "None") 
	poison_ticks_left -= 1
	
	if poison_ticks_left <= 0:
		stop_poison()

func stop_poison():
	poison_timer.stop()
	set_status(Status.HEALTHY)
	print(get_parent().name + " poison cured")

# --- overheat Logic ---
func start_overheat():
	if status != Status.OVERHEATING:
		set_status(Status.OVERHEATING)
		overheat_timer.start()
		
func _on_overheat_tick():
	take_damage(3.0, "None") 

func stop_overheat():
	overheat_timer.stop()
	set_status(Status.HEALTHY)

# --- status helper ---
func set_status(new_status : Status) -> void:
	status = new_status
	emit_signal("status_changed", new_status)

func _handle_damage_status():
	
	if status == Status.POISONED:
		return
	   
	set_status(Status.DAMAGED)
	
	# revert back to healthy after 
	await get_tree().create_timer(0.2).timeout
	if status == Status.DAMAGED: # only revert if we haven't been re-poisoned 
		set_status(Status.HEALTHY)
