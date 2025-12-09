class_name HurtBox extends Area2D

@export var health_component: HealthComponent

func _ready() -> void:
	
	if health_component == null and owner.has_node("HealthComponent"):
		health_component = owner.get_node("HealthComponent")
	
	monitorable = true
	monitoring = false
	
	if owner.is_in_group("player"):
		collision_layer = 1 # Layer 1 (Player)
		collision_mask = 0  
	else:
		# enemy
		collision_layer = 2 # Layer 2 (Enemy)
		collision_mask = 0
	
func receive_hit(damage: int, attacker : Node, attack_effect: String) -> void:
	if attacker == null:
		print("attacker is null")
		return
	
	if owner.has_method("iframes_on") and owner.iframes_on():
		return
	
	if attacker.is_in_group("player") and owner.is_in_group("player"):
		return
	if attacker.is_in_group("enemy") and owner.is_in_group("enemy"):
		return
	
	if health_component:
		if health_component.invincible and attack_effect != "Execution":
			health_component.take_damage(0, attack_effect)
		else:
			health_component.take_damage(damage, attack_effect)
	else:
		print("Error: Owner ", owner.name, " has no HealthComponent!")
