extends Node2D

@export var bullet_scene: PackedScene
@export var speed = 100
var score
var scene = preload("res://bullet.tscn")

func _process(_delta):
	if Input.is_action_just_pressed("shoot"):
		var mousePos = get_global_mouse_position()
		shoot(mousePos)

func shoot(target_pos: Vector2):
	if bullet_scene == null:
		push_error("No bullet scene assigned!")
		return

	var bullet = bullet_scene.instantiate()
	add_child(bullet)

	var direction = (target_pos - global_position).normalized()
	
	bullet.linear_velocity = direction * speed
	
	bullet.global_position = global_position


#func inst(pos,mousePos):
	#var instance = scene.instantiate()
	#var velocity = Vector2.ZERO
	#
	## velocity calc
	#if (mousePos.x > pos.x): 
		#velocity.x += 1
	#if (mousePos.x < pos.x):
		#velocity.x -= 1
	#if (mousePos.y > pos.y):
		#velocity.y -= 1
	#if (mousePos.y < pos.y):
		#velocity.y += 1
	#
	#if velocity.length() > 0:
		#velocity = velocity.normalized() * speed
	#
	#instance.global_position = pos
	#instance.linear_velocity = velocity
	#
	#add_child(instance)
