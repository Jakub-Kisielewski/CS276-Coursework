extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@export var nav: NavigationAgent2D
@export var stats : Stats
@export var hitbox_shape : Shape2D

var health = 30.0
var player_in_range = false
@export var speed = 100.0
var attacked = false
var attacking = false
var dying = false
var monitorable = true

func _ready():
	stats.set_owner_node(self)
	stats.health_depleted.connect(_on_death)
	stats.damage_taken.connect(_on_damaged)

func _physics_process(delta: float) -> void:
	if attacked or dying or !is_instance_valid(player):#temporary
		velocity = Vector2.ZERO
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
	
	sprite.play("attack")
	
	var hitbox = hitBox.new(stats, 0.5, hitbox_shape)
	add_child(hitbox)
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.rotation = vector_to_player.angle()
	hitbox.position = vector_to_player.normalized() * 20
	
func handle_move():
	if attacking:
		return
	sprite.play("move")

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print("player is in range")

func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print("player is no longer in range")
		

#func take_damage(damage: int) -> void:
	#attacking = false
	#attacked = true
	#stats.take_damage(damage)
	#print("damage:", damage)	
	#sprite.play("damage")
	
func _on_death():
	attacked = true
	velocity = Vector2.ZERO
	sprite.play("death")
	
func _on_damaged():
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
		
#func yomo_is_dead():
	#if player
