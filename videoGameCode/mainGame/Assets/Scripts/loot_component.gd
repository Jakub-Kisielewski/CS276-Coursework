class_name LootComponent extends Node

@export var item_drop_scene: PackedScene 

@export_range(0.0, 1.0) var drop_chance: float = 1.0 

func drop_loot() -> void:
	# safety checks
	if item_drop_scene == null:
		return
		
	if randf() > drop_chance:
		return
	
	# instantiate
	var drop_instance = item_drop_scene.instantiate()
	
	# position it at Enemy's location
	var parent = get_parent()
	if parent is Node2D:
		drop_instance.global_position = parent.global_position
	
	# item persists when enemy defeated
	var room = get_tree().current_scene.get_node("ActiveSceneContainer")
	room.add_child(drop_instance)
