class_name hitBox extends Area2D

@export var damage := 10
@export var attack_type : String

func _init() -> void:
	collision_layer = 2
	collision_mask = 0
	
