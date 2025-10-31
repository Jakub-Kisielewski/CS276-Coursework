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
		owner.take_damage(hitbox.damage)   
	
