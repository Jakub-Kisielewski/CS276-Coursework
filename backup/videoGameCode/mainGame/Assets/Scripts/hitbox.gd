class_name hitBox extends Area2D

var attacker: Node 
var base_damage: float
var weapon_data: WeaponData
var attack_effect: String
var hitbox_lifetime: float
var shape: Shape2D  
var stun_player : bool

signal successful_hit


#stun player is optional because its resevred for the minotaur charge attack, stun will default to false for all other attacks, so player won't get stunned by other enemies
#weapon data is optional because
#enemies technically don't have their own weapons so default weapon data to null for enemies 
func _init(_attacker: Node, _damage: float, _attack_effect: String, _hitbox_lifetime: float, _shape: Shape2D, _weapon_data: WeaponData = null, _stun_player: bool = false) -> void:
	attacker = _attacker
	base_damage = _damage
	attack_effect = _attack_effect
	hitbox_lifetime = _hitbox_lifetime
	shape = _shape
	weapon_data = _weapon_data
	stun_player = _stun_player

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

	if attacker.is_in_group("player"):
		collision_layer = 1      # I am on Player Layer
		collision_mask = 2       # I hit Enemy Layer
	else:
		# enemy
		collision_layer = 2      # I am on Enemy Layer
		collision_mask = 1       # I hit Player Layer
	monitoring = true
	

func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("receive_hit"):
		return
	
	var final_damage : float = base_damage
	
	#for player, get current weapon data and calculate damage, then pass it into receive hit
	if weapon_data != null:
		final_damage = weapon_data.get_attack_value(base_damage, 1.0) #magic number 1.0 is the "attack multiplier", ADD LATER for base damage upgrades
	
	area.receive_hit(final_damage, attacker, attack_effect, stun_player)
	successful_hit.emit()
