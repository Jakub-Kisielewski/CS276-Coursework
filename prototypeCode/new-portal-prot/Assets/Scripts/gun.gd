extends Node2D


const BULLET = preload("res://Assets/Scenes/bullet.tscn")

@onready var muzzle: Marker2D = $Marker2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	
	rotation = wrap(rotation, 0, 2 * PI)
	if rotation > PI/2  and rotation < 3 * PI/2:
		scale.y = -1
	else:
		scale.y = 1
		
	if Input.is_action_just_pressed("shoot_left"):
		var bullet_instance = BULLET.instantiate()
		bullet_instance.lmb = true
		get_tree().root.add_child(bullet_instance)
		bullet_instance.global_position = muzzle.global_position
		bullet_instance.rotation = rotation
		
		
		
	if Input.is_action_just_pressed("shoot_right"):
		var bullet_instance = BULLET.instantiate()
		bullet_instance.lmb = false
		get_tree().root.add_child(bullet_instance)
		bullet_instance.global_position = muzzle.global_position
		bullet_instance.rotation = rotation
		
		
