extends CharacterBody2D
@export var active = true
@onready var wander_scr = $wander
@onready var ray = $RayCast2D
@onready var target = $"../player"
@onready var animated_sprite = $AnimatedSprite2D
@export var follow : bool = false
var spawn_point : Vector2
var speed = 50

func _ready():
	spawn_point = position

func _physics_process(delta):
	if target.active == false:
		if Input.is_action_just_pressed("start"):
			arise()
		else:
			return
	elif active == false:
		return
		
	var direction
	if follow:
		direction = (target.position - position).normalized()
		velocity = direction * speed		
		check_player_collision()
	else:
		direction = (wander_scr.current_position.position - position).normalized()
		velocity = direction * speed
		ray.target_position = direction.normalized() * 900
		print(ray.get_collider())
		if ray.get_collider() == target:
			follow = true		
			
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true
	move_and_slide()
	
func die():
	active = false
	$"CollisionShape2D".disabled = true
	animated_sprite.play("death")
	
func arise():
	active = true
	follow = false
	position = spawn_point

func check_player_collision():
	for x in get_slide_collision_count():
		var collision = get_slide_collision(x)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			collider.die()
