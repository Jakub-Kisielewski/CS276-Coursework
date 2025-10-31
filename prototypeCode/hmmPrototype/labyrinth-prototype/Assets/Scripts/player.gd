extends CharacterBody2D


@onready var hitbox = $AnimatedSprite2D/hitBox

const DASH_COOLDOWN_TIME = 0.8
const DASH_DURATION_TIME = 0.3
var health = 100.0
var speed = 300.0
var dead = false
var direction : Vector2
var facing_left = false
enum Facing {UP, DOWN, LEFT, RIGHT}
var player_facing : Facing
var attacking = false
var attacked = false

var dash_multiplier = 3
var dash_cooldown = 0.0
var dash_timer = 0.0
var is_dashing = false

func _physics_process(delta: float) -> void:
	
	

	
	hitbox.monitoring = false
	hitbox.get_node("strikeCollisionShape").disabled = true
	handle_movement(delta)

	if Input.is_action_pressed("attack_basic"):
		attacking = true
		handle_attack()
		



	
func handle_movement(delta: float):
	
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	
	if Input.is_action_pressed("move_up"):
		direction.y = -1
		player_facing = Facing.UP
	elif Input.is_action_pressed("move_down"):
		direction.y = 1
		player_facing = Facing.DOWN
	else:
		direction.y = 0
	
	if Input.is_action_pressed("move_right"):
		direction.x = 1
		player_facing = Facing.RIGHT
		facing_left = false
	elif Input.is_action_pressed("move_left"):
		direction.x = -1
		player_facing = Facing.LEFT
		facing_left = true
	else:
		direction.x = 0

	direction = direction.normalized()
	
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0:
		if direction == Vector2.ZERO:
			match player_facing:
				Facing.UP: direction = Vector2.UP
				Facing.DOWN: direction = Vector2.DOWN
				Facing.LEFT: direction = Vector2.LEFT
				Facing.RIGHT: direction = Vector2.RIGHT
		
		is_dashing = true
		dash_timer = DASH_DURATION_TIME
		dash_cooldown = DASH_COOLDOWN_TIME
		$AnimatedSprite2D.play("jump")
		$AnimatedSprite2D/hurtBox/hurtCollisionShape.disabled = true
		
		
	if is_dashing:
		velocity = direction * speed * dash_multiplier
		move_and_slide()
		
		dash_timer -= delta
		
		if dash_timer <= 0.0:
			is_dashing = false
			$AnimatedSprite2D/hurtBox/hurtCollisionShape.disabled = false
			
	
	else:
		velocity = direction * speed
		move_and_slide()
	
func handle_attack():
	$AnimatedSprite2D.flip_h = facing_left
	$AnimatedSprite2D.play("attack_basic")
	
	if player_facing == Facing.UP:
		hitbox.position = Vector2(0, -20)
		hitbox.rotation = -PI/2
	elif player_facing == Facing.DOWN:
		hitbox.position = Vector2(0, 20)
		hitbox.rotation = PI/2
	elif player_facing == Facing.LEFT:
		hitbox.position = Vector2(-20, 0)
		hitbox.rotation = PI
	elif player_facing == Facing.RIGHT:
		hitbox.position = Vector2(20, 0)
		hitbox.rotation = 0
		
	hitbox.monitoring = true
	hitbox.get_node("strikeCollisionShape").disabled = false
	
	
func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "attack_basic":
		attacking = false
		hitbox.monitoring = false
		hitbox.get_node("strikeCollisionShape").disabled = true
		
	#if $AnimatedSprite2D.animation == "death":
		#get_tree().quit()
		

		

func take_damage(damage : int) -> void:
	health -= damage
	if health <= 0 and not dead:
		print("you should be dead.")
		dead = true
		get_tree().quit()
		return
	attacked = true #use this if you want to play uninterrupted hit animation
	print("player has been damaged")
	print("health:", health)
	
	
		



func _on_animated_sprite_2d_frame_changed() -> void:
	if $AnimatedSprite2D.animation == "attack":
		var current_frame = $AnimatedSprite2D.frame
		
		if current_frame in [3,4,5]:
			hitbox.get_node("strikeCollisionShape").disabled = false
		else:
			hitbox.get_node("strikeCollisionShape").disabled = true
