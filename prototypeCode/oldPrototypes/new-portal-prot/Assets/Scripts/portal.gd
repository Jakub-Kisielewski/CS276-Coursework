extends Area2D



var target_portal : Area2D 
var portal_cooldown : float = 0.0
const PORTAL_COOLDOWN_TIME : float = 0.2

var portal_normal = Vector2.UP.rotated(rotation)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if portal_cooldown > 0:
		portal_cooldown -= delta
	print(portal_cooldown)


func _on_body_entered(body: Node2D) -> void:
	if target_portal == null:
		return
	
	#teleport non player objects too, maybe use a group later	
	if body.is_in_group("teleportable_objects") and (portal_cooldown <= 0):
		body.position = target_portal.position + portal_normal * 12
		portal_cooldown = PORTAL_COOLDOWN_TIME
		target_portal.portal_cooldown = PORTAL_COOLDOWN_TIME
