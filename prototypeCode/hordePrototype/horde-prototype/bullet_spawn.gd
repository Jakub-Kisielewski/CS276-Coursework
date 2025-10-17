extends Node2D

@export var bullet_scene: PackedScene
@export var speed = 100
var score
var scene = preload("res://bullet.tscn")

func _process(delta):
	if Input.is_action_just_pressed("shoot"):
		var mousePos = get_global_mouse_position()
		
		inst(position, mousePos)

func inst(pos,mousePos):
	var instance = scene.instantiate()
	var velocity = Vector2.ZERO
	
	# velocity calc
	if (mousePos.x > pos): 
		velocity.x += 1
	if (mousePos.x < pos):
		velocity.x -= 1
	if (mousePos.y > pos):
		velocity.y -= 1
	if (mousePos.y < pos):
		velocity.y += 1
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	
	instance.position = pos
	instance.velocity = velocity
	
	add_child(instance)
