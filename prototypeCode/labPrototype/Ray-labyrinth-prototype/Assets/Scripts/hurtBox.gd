class_name hurtBox extends Area2D


func _init() -> void:
	collision_layer = 0
	collision_mask = 2
	
func _ready() -> void:
	connect("area_entered", self._on_area_entered)
	
	
func _on_area_entered(hitbox : hitBox) -> void:
	if hitbox == null:
		return
		
	if hitbox.owner == owner:
		return
		
	if hitbox.owner.is_in_group("enemy") and owner.is_in_group("enemy"):
		return
		
	if owner.has_method("take_damage"):
		
		if hitbox.owner.is_in_group("enemy_boss") and hitbox.attack_type == "charge": #temporary solution to goat charging into player
			owner.take_damage(30.0)
			hitbox.owner.take_damage(50)
			print("goat health: ", hitbox.owner.health)
			hitbox.owner.end_charge()
			return
			
		owner.take_damage(hitbox.damage)
		
		
		
		
	
	
