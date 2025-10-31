extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@export var nav: NavigationAgent2D
@onready var hitbox_shape = $AnimatedSprite2D/hitBox/strikeShape
@onready var hitbox = $AnimatedSprite2D/hitBox
var health = 30.0
var player_in_range = false
var attacked = false
var speed = 100.0
var attacking = false

func _physics_process(delta: float) -> void:
	
	if not attacked:
		
		nav.target_position = player.global_position
	
		var next = nav.get_next_path_position()
		#print("next:", next)
	
		velocity = global_position.direction_to(next) * speed
	
		if velocity.x>0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true
	
		move_and_slide()
	
		if player_in_range:
			handle_attack()
		elif not attacking:
			handle_move()
	
func handle_attack():
	if attacking: #animation already playing
		return
	attacking = true
	
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.rotation = vector_to_player.angle()
	
	

	sprite.play("attack")
	
func handle_move():
	sprite.play("move")


func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true


func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		

func take_damage(damage: int) -> void:
	attacked = true
	health -= damage
	print("damage:", damage)
	
	if health <= 0:
		sprite.play("hit")
	
	attacked = false
	

	
		


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "hit":
		attacked = false
		queue_free()
		print("I've been hit lad")
		
	if sprite.animation == "attack":
		attacking = false
		hitbox_shape.disabled = true
		print("enemy finished attack")	


func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation == "attack":
		var current_frame = sprite.frame
		
		if current_frame == 6 or current_frame == 7:
			hitbox_shape.disabled = false
		else:
			hitbox_shape.disabled = true
