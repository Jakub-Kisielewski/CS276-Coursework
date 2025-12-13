extends Area2D

@export var target_pos : Vector2
var tilemap : TileMapLayer

func _ready() -> void:
	tilemap = get_tree().get_first_node_in_group("tilemap")

# Teleport nearby objects to target_pos
func _on_body_entered(body: Node2D) -> void:
	body.global_position = target_pos
