extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@export var nav: NavigationAgent2D
@onready var hitbox = $AnimatedSprite2D/hitBox
@onready var hurtbox = $AnimatedSprite2D/hurtBox
var health = 30.0
var player_in_range = false
@export var speed = 100.0
var attacked = false
var attacking = false

func _physics_process(delta: float) -> void:
	if attacked:
		velocity = Vector2.ZERO
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
	
func handle_attack():
	if attacking:
		return
	attacking = true
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.rotation = vector_to_player.angle()
	if player_in_range and player.monitorable:
		player.take_damage(10)
	sprite.play("attack")
	
func handle_move():
	if attacking:
		return
	sprite.play("move")

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		

func take_damage(damage: int) -> void:
	attacking = false
	attacked = true
	health -= damage
	print("damage:", damage)	
	sprite.play("damage")

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "damage":
		if health > 0:
			attacked = false
		else:
			sprite.play("death")
	
	if sprite.animation == "death":
		queue_free()
	
	if sprite.animation == "attack":
		attacking = false
		print("enemy finished attack")	
