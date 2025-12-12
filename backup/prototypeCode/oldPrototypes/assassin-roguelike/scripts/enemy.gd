extends CharacterBody2D
@export var active = true
@onready var wander_scr = $wander
@onready var ray = $RayCast2D
@onready var target = $"../player"
@onready var animated_sprite = $AnimatedSprite2D
@export var follow : bool = false
@export var navigation : NavigationAgent2D
var speed = 50

func get_movement():	
	var direction
	if follow:
		navigation.target_position = target.position
		var next = navigation.get_next_path_position()
		direction = global_position.direction_to(next).normalized()
		ray.target_position = direction * 900
		check_player_collision()
	else:
		navigation.target_position = wander_scr.current_position.position
		var next = navigation.get_next_path_position()
		direction = global_position.direction_to(next).normalized()
		ray.target_position = direction * 900
		if ray.get_collider() == target:
			follow = true		
	
	if navigation.avoidance_enabled:
		navigation.set_velocity(direction * speed)
	else:
		velocity = direction * speed
		
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true

func _physics_process(delta):
	if active and target.active:
		get_movement()
	else:
		velocity = Vector2.ZERO
		follow = false
	move_and_slide()
	
func die():
	active = false
	ray.enabled = true
	$"CollisionShape2D".disabled = true
	navigation.avoidance_enabled = false
	animated_sprite.play("death")

func check_player_collision():
	for x in get_slide_collision_count():
		var collision = get_slide_collision(x)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			if collider.active:
				collider.die()


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
