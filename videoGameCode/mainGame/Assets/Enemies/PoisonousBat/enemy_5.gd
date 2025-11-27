#Always ensure bat sprite is above player sprite
extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@export var nav: NavigationAgent2D
@export var stats : Stats
@export var hitbox_shape : Shape2D
@export var collider : CollisionShape2D

const STRIKE_COOLDOWN_TIME = 1
var strike_direction : Vector2
var strike_multiplier = 2.2
var strike_cooldown = 0.0

var player_in_range = false
@export var speed = 100.0

enum State { ARISING, IDLE, MOVING, BITING, STRIKING, DAMAGED, DYING }
var state : State = State.IDLE
signal state_changed


func set_state(new_state : State):
	if state == State.STRIKING:
		set_collision(true)
	
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

		State.BITING:
			handle_bite()

		State.STRIKING:
			handle_strike()

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
	handle_timers(delta)
	
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
				set_state(State.BITING)
			handle_follow()

		State.BITING:
			handle_follow()

		State.STRIKING:
			velocity = strike_direction * speed * strike_multiplier
			if velocity.x > 0:
				sprite.flip_h = true
			elif velocity.x < 0:
				sprite.flip_h = false
			move_and_slide()

		State.DAMAGED:
			pass

		State.DYING:
			pass

func handle_follow():
	nav.target_position = player.global_position	
	var next = nav.get_next_path_position()
	velocity = global_position.direction_to(next) * speed	
	if velocity.x > 0:
		sprite.flip_h = true
	elif velocity.x < 0:
		sprite.flip_h = false
	move_and_slide()

func handle_move():	
	sprite.play("move")
	
func handle_bite():
	sprite.play("bite")

	var hitbox = hitBox.new(stats, "Poison", 0, hitbox_shape)
	hitbox.scale = Vector2(0.8,0.8);
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.position = vector_to_player.normalized() * 20
	hitbox.rotation = vector_to_player.angle()

func handle_strike():
	set_collision(false)
	
	sprite.play("strike")
	strike_cooldown = STRIKE_COOLDOWN_TIME

	var hitbox = hitBox.new(stats, "None", 0, hitbox_shape)
	hitbox.scale = Vector2(1,1)
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	strike_direction = vector_to_player.normalized()

func get_animation_length(animation: String):
	var frames = sprite.sprite_frames.get_frame_count(animation)
	var fps = sprite.sprite_frames.get_animation_speed(animation)
	return frames/fps

func handle_timers(delta: float):
	if strike_cooldown > 0.0:
		strike_cooldown -= delta

func set_collision(enabled: bool):
	if enabled:
		collision_layer = 1 << 0 #put CollisionObject on layer 1
		collision_mask = 1 << 0 #detect only layer 1
	else:
		collision_layer = 1 << 1 #put CollisionObject on layer 2
		collision_mask = 1 << 1 #detect only layer 2

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if state in [State.MOVING] and strike_cooldown <= 0:
			set_state(State.STRIKING)
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
	
		"bite":
			velocity = Vector2.ZERO
			set_state(State.DYING)
			print("enemy finished bite")	
		
		"strike":
			set_state(State.MOVING)
			print("enemy finished strike")	
