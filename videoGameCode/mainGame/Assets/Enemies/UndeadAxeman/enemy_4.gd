extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@export var nav: NavigationAgent2D
@export var stats : Stats
@export var hitbox_shape : Shape2D

var player_in_range = false
@export var speed = 60

enum State { ARISING, IDLE, MOVING, ATTACKING, DAMAGED, DYING }
var state : State = State.IDLE
signal state_changed


func set_state(new_state : State):
	state = new_state
	state_changed.emit()
	
	match state:
		State.ARISING:
			velocity = Vector2.ZERO
			sprite.play("arise")
		
		State.IDLE:
			velocity = Vector2.ZERO
			sprite.play("idle")
		
		State.MOVING:
			handle_move()

		State.ATTACKING:
			handle_attack()

		State.DAMAGED:
			velocity = Vector2.ZERO
			sprite.play("damage")

		State.DYING:
			velocity = Vector2.ZERO
			sprite.play("death")

func _ready():
	stats.set_owner_node(self)
	stats.health_depleted.connect(_on_death)
	stats.damage_taken.connect(_on_damaged)
	
	set_state(State.ARISING)

func _physics_process(delta: float) -> void:
	if !is_instance_valid(player):#temporary
		set_state(State.IDLE)
		
	match state:
		State.ARISING:
			return
		
		State.IDLE:
			if is_instance_valid(player):
				set_state(State.MOVING)
		
		State.MOVING:
			if player_in_range:
				set_state(State.ATTACKING)
			handle_follow()

		State.ATTACKING:
			handle_follow()

		State.DAMAGED:
			pass

		State.DYING:
			pass

func handle_follow():
	nav.target_position = player.global_position	
	var next = nav.get_next_path_position()
	velocity = global_position.direction_to(next) * speed	
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true
	move_and_slide()

func handle_move():	
	sprite.play("move")
	
func handle_attack():
	var hitbox = hitBox.new(stats, "None", 0, hitbox_shape)
	hitbox.scale = Vector2(2,2);
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	
	if vector_to_player.y < 0:
		hitbox.rotation = vector_to_player.angle() + 90
		hitbox.position = vector_to_player.normalized() * 20
		sprite.play("attack_up")
	else:
		hitbox.rotation_degrees = 90
		if vector_to_player.x < 0:
			hitbox.position = Vector2(-20, 0)
		else:
			hitbox.position = Vector2(20, 0)
		sprite.play("attack_down")

func get_animation_length(animation: String):
	var frames = sprite.sprite_frames.get_frame_count(animation)
	var fps = sprite.sprite_frames.get_animation_speed(animation)
	return frames/fps

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print("player is in range")

func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print("player is no longer in range")
		

func _on_damaged():
	set_state(State.DAMAGED)	

func _on_death():
	set_state(State.DYING)
	

func _on_animated_sprite_2d_animation_finished() -> void:
	match sprite.animation:
		"arise":
			set_state(State.MOVING)
		
		"damage":
			set_state(State.MOVING)

		"death":
			queue_free()
	
		"attack_up", "attack_down":
			set_state(State.MOVING)
			print("enemy finished attack")	
