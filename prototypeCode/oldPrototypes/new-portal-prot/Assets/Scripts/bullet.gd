extends Node2D


const SPEED: int = 300
var lmb : bool = true
var portal_colour : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.x * SPEED * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("tilemap_collision"):
		queue_free()
	elif body.is_in_group("tilemap_portal"):
		var portal_manager = get_node("/root/Area1/Portal_Manager") #lmb or rmb, call spawn_portal...
		print(lmb)
		if lmb == true:
			portal_colour = "purple"
		else:
			portal_colour = "green"
		print(portal_colour)
		portal_manager.spawn_portal(portal_colour, global_position, 0)
		
		queue_free()		
