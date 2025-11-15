extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@export var nav: NavigationAgent2D
@export var stats : Stats
@export var hitbox_shape : Shape2D

const THRUST_COOLDOWN_TIME = 2
var thrust_direction : Vector2
var thrust_multiplier = 2
var thrust_cooldown = 0.0

var health = 30.0
var player_in_range = false
@export var speed = 100.0
var thrusting = false
var attacked = false
var attacking = false
var dying = false

func _ready():
	stats.set_owner_node(self)
	stats.health_depleted.connect(_on_death)
	stats.damage_taken.connect(_on_damaged)

func _physics_process(delta: float) -> void:
	handle_timers(delta)
	
	if attacked or dying or !is_instance_valid(player):#temporary
		velocity = Vector2.ZERO
		return
	if thrusting:
		velocity = thrust_direction * speed * thrust_multiplier
		if velocity.x > 0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true
		move_and_slide()
		return

	nav.target_position = player.global_position	
	var next = nav.get_next_path_position()
	velocity = global_position.direction_to(next) * speed	
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true
	move_and_slide()
	if player_in_range:
		handle_attack()
	else:
		handle_move()

func handle_timers(delta: float):
	if thrust_cooldown > 0.0:
		thrust_cooldown -= delta
	
func handle_attack():
	if attacking:
		return
	attacking = true
	
	sprite.play("attack")
	
	var hitbox = hitBox.new(stats, 0.5, hitbox_shape)
	add_child(hitbox)
	hitbox.scale = Vector2(1.4,1.4);
	
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.rotation = vector_to_player.angle()
	hitbox.position = vector_to_player.normalized() * 20

func handle_thrust():
	if attacking or thrust_cooldown > 0.0:
		return
	thrusting = true
	attacking = true
	
	sprite.play("thrust")
	thrust_cooldown = THRUST_COOLDOWN_TIME
	
	var hitbox = hitBox.new(stats, 1, hitbox_shape)
	add_child(hitbox)
	hitbox.scale = Vector2(4,4)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	thrust_direction = vector_to_player.normalized()
	
func handle_move():
	if attacking:
		return
	sprite.play("move")

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		handle_thrust()
		player_in_range = true
		print("player is in range")

func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print("player is no longer in range")
		
	
func _on_death():
	attacked = true
	velocity = Vector2.ZERO
	sprite.play("death")
	
func _on_damaged():
	thrusting = false
	attacking = false
	attacked = true
	velocity = Vector2.ZERO
	sprite.play("damage")
	

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "damage":
		if stats.current_health > 0:
			attacked = false

	if sprite.animation == "death":
		queue_free()
	
	if sprite.animation == "attack":
		attacking = false
		print("enemy finished attack")	
		
	if sprite.animation == "thrust":
		thrusting = false
		attacking = false
		print("enemy finished thrust")	
