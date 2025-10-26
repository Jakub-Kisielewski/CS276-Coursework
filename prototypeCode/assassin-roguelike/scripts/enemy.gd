extends CharacterBody2D
@export var active = true
@onready var wander_scr = $wander
@onready var ray = $RayCast2D
@onready var target = $"../player"
@onready var animated_sprite = $AnimatedSprite2D
@export var follow : bool = false
var speed = 50

func get_movement():	
	var direction
	if follow:
		direction = (target.position - position).normalized()
		velocity = direction * speed		
		ray.target_position = direction.normalized() * 900
		check_player_collision()
	else:
		direction = (wander_scr.current_position.position - position).normalized()
		velocity = direction * speed
		ray.target_position = direction.normalized() * 900
		if ray.get_collider() == target:
			follow = true		
			
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true

func _physics_process(delta):
	if active and target.active:
		get_movement()
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	
func die():
	active = false
	ray.enabled = true
	$"CollisionShape2D".disabled = true
	animated_sprite.play("death")

func check_player_collision():
	for x in get_slide_collision_count():
		var collision = get_slide_collision(x)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			if collider.active:
				collider.die()
