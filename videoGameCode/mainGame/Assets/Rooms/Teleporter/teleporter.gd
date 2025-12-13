class_name Teleporter extends Area2D

@export var target : Teleporter
var tilemap : TileMapLayer

var teleport_locked := false

func _ready() -> void:
	tilemap = get_tree().get_first_node_in_group("tilemap")

# Teleport nearby objects to target_pos
func _on_body_entered(body: Node2D) -> void:
	if teleport_locked:
		return
	
	if body.is_in_group("player") or body.is_in_group("enemy"):
		target.teleport_locked = true
		body.global_position = target.global_position
			
		await get_tree().create_timer(0.6).timeout
		target.teleport_locked = false
