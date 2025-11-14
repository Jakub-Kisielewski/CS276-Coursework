extends Node

var purple_portal : Area2D = null
var green_portal : Area2D = null

var Portal = preload("res://Assets/Scenes/portal.tscn")

func spawn_portal(colour: String, inpPosition : Vector2, inpRotation : float) -> void:
	print(colour)
	if colour == "purple": #lmb
		if purple_portal != null: #null check
			purple_portal.call_deferred("queue_free") #set purple portal to null
	elif colour == "green":
		if green_portal !=  null: #null check
			green_portal.call_deferred("queue_free") #set green portal to null

		 
	var portal = Portal.instantiate()
	portal.position = inpPosition
	portal.rotation = inpRotation	
	print(portal.portal_cooldown)
	
	

	
	if colour == "purple": #EROOR: colour is being defined, but old colour portals not being removed
		purple_portal = portal
	elif colour == "green":
		green_portal = portal
	print(purple_portal) #these are null even when a portal is made
	print(green_portal)
	
	if purple_portal and green_portal: #will not run as portals are null
		purple_portal.target_portal = green_portal
		green_portal.target_portal = purple_portal
	
	get_tree().current_scene.call_deferred("add_child", portal)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
