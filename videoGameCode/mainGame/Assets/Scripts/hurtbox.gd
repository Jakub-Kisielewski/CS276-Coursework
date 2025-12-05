class_name hurtBox
extends Area2D

@onready var owner_stats : Stats = owner.stats

func _init() -> void:
	pass
	
func _ready() -> void:
	monitorable = false
	match owner_stats.faction:
		Stats.Faction.PLAYER:
			collision_layer = 1 << 0 #put area on layer 1
			collision_mask = 1 << 1 #detect only layer 2
		Stats.Faction.ENEMY:
			collision_layer = 1 << 1 #put area on layer 2
			collision_mask = 1 << 0 #detect only layer 1
	monitorable = true
	
func receive_hit(damage: int, attacker : Node, attack_effect: String):
	if attacker == null:
		print("attacker is null")
		return
		
	if owner.has_method("iframes_on") and owner.iframes_on():
		return
		
	if attacker.stats.faction == owner_stats.faction:
		return
		
	if attacker == owner:
		return
	
	owner_stats.take_damage(damage, attack_effect)
