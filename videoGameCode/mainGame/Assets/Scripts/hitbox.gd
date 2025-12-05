class_name hitBox extends Area2D

@export var attacker_stats : Stats
@export var weapon_data : WeaponData
@export var attack_effect : String
var hitbox_lifetime: float
var shape: Shape2D  

signal successful_hit

#enemies technically don't have their own weapons so default weapon data to null for enemies 
func _init(_attacker_stats: Stats, _attack_effect: String, _hitbox_lifetime: float, _shape: Shape2D, _weapon_data: WeaponData = null) -> void:
	attacker_stats = _attacker_stats
	attack_effect = _attack_effect
	hitbox_lifetime = _hitbox_lifetime
	shape = _shape
	weapon_data = _weapon_data
	


func _ready() -> void:
	monitoring = false
	area_entered.connect(_on_area_entered)
	
	if hitbox_lifetime > 0.0:
		var new_timer = Timer.new()
		add_child(new_timer)
		new_timer.timeout.connect(queue_free)
		new_timer.call_deferred("start", hitbox_lifetime)
	
	if shape:
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = shape
		add_child(collision_shape)

	match attacker_stats.faction:
		Stats.Faction.PLAYER:
			collision_layer = 1 << 0 #put area on layer 1
			collision_mask = 1 << 1 #detect only layer 2
		Stats.Faction.ENEMY:
			collision_layer = 1 << 1 #put area on layer 2
			collision_mask = 1 << 0 #detect only layer 1
	monitoring = true
	
	
func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("receive_hit"):
		return
	var damage_value : float		
	#for player, get current weapon data and calculate damage, then pass it into receive hit
	if weapon_data != null:
		damage_value = weapon_data.get_attack_value(attacker_stats.damage, 1.0) #magic number 1.0 is the "attack multiplier", ADD LATER for base damage upgrades
	else:
		damage_value = attacker_stats.damage
	area.receive_hit(damage_value, attacker_stats.owner_node, attack_effect)	
	successful_hit.emit()
