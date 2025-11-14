class_name hurtBox
extends Area2D


@onready var owner_stats : Stats = owner.stats

func _init() -> void:
	pass
	
func _ready() -> void:
	monitoring =	 false
	
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	match owner_stats.faction:
		Stats.Faction.PLAYER:
			set_collision_layer_value(1, true)
		Stats.Faction.ENEMY:
			set_collision_layer_value(2, true)
	
	
func receive_hit(damage: int, attacker : Node = null) -> void:

	if attacker == null:
		print("attacker is null")
		return
		
	if owner.has_method("iframes_on") and owner.iframes_on():
		return
		
	if attacker.stats.faction == owner_stats.faction:
		return
		
	if attacker == owner:
		return
	
	owner_stats.take_damage(damage)
	
	#old code
	#connect("area_entered", self._on_area_entered)
	#
#func _on_area_entered(hitbox : hitBox) -> void:
	#if hitbox == null:
		#return
		#
	#if hitbox.owner == owner:
		#return
		#
	#if hitbox.owner.is_in_group("enemy") and owner.is_in_group("enemy"):
		#return
		#
	#if owner.has_method("take_damage"):
		#
		#if hitbox.owner.is_in_group("enemy_boss") and hitbox.attack_type == "charge":
			#owner.take_damage(30.0)
			#hitbox.owner.take_damage(50)
			#print("goat health: ", hitbox.owner.health)
			#hitbox.owner.end_charge()
			#return
			#
		#owner.take_damage(hitbox.damage)
