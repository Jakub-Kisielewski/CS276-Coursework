extends CharacterBody2D

@export var speed = 300
var screenSize
const BULLET_SCENE = preload("res://bullet.tscn")

@onready var gun_tip = $bulletSpawn

func _ready():
	screenSize = get_viewport_rect().size
	

func _process(delta: float) -> void:

	look_at(get_global_mouse_position())

func _physics_process(delta: float) -> void:
	var moveDir = Vector2(Input.get_axis("moveLeft", "moveRight"), 
	Input.get_axis("moveUp","moveDown"))
	
	if moveDir != Vector2.ZERO:
		velocity = speed * moveDir
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.y = move_toward(velocity.y, 0, speed)
		
	position = position.clamp(Vector2.ZERO, screenSize)
	move_and_slide()
	
	# Shoot
	if Input.is_action_just_pressed("shoot"):
		shoot()


func shoot():
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = gun_tip.global_position
	bullet.rotation = rotation
	get_parent().add_child(bullet)

func die():
	get_tree().reload_current_scene()
