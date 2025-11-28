extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@export var nav: NavigationAgent2D
@export var stats : Stats
@export var hitbox_shape : Shape2D

const THRUST_COOLDOWN_TIME = 0.8
var thrust_direction : Vector2
var thrust_multiplier = 2.2
var thrust_cooldown = 0.0

var player_in_range = false
@export var speed = 80.0

enum State { ARISING, IDLE, MOVING, ATTACKING, THRUSTING, DAMAGED, DYING }
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

		State.THRUSTING:
			handle_thrust()

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
			return
		
		State.MOVING:
			if player_in_range:
				set_state(State.ATTACKING)
			handle_follow()

		State.ATTACKING:
			handle_follow()

		State.THRUSTING:
			velocity = thrust_direction * speed * thrust_multiplier
			if velocity.x > 0:
				sprite.flip_h = false
			elif velocity.x < 0:
				sprite.flip_h = true
			move_and_slide()
			
		State.DAMAGED:
			return

		State.DYING:
			return

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
	sprite.play("attack")

	var hitbox = hitBox.new(stats, "None", 0, hitbox_shape)
	hitbox.scale = Vector2(1.6,1.6)	
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.rotation = vector_to_player.angle()
	hitbox.position = vector_to_player.normalized() * 20

func handle_thrust():
	sprite.play("thrust")
	
	thrust_cooldown = THRUST_COOLDOWN_TIME

	var hitbox = hitBox.new(stats, "None", 0, hitbox_shape)
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	hitbox.position.y = 9
	hitbox.scale = Vector2(2.7,2.7)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	thrust_direction = vector_to_player.normalized()

func handle_timers(delta: float):
	if thrust_cooldown > 0.0:
		thrust_cooldown -= delta

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
		if state not in [State.IDLE, State.DAMAGED, State.DYING] and thrust_cooldown <= 0:
			set_state(State.THRUSTING)
		player_in_range = false
		print("player is no longer in range")
		
	
func _on_damaged():
	set_state(State.DAMAGED)	

func _on_death():
	$AnimatedSprite2D/hurtBox.monitorable = false
	set_state(State.DYING)
	
func _on_boss_death():
	$AnimatedSprite2D/hurtBox.monitorable = false
	set_state(State.IDLE)
	fade_out(1)

func fade_out(duration: float):
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)
	

func _on_animated_sprite_2d_animation_finished() -> void:
	match sprite.animation:
		"arise":
			set_state(State.MOVING)
			
		"damage":
			set_state(State.MOVING)

		"death":
			queue_free()
	
		"attack":
			set_state(State.MOVING)
			print("enemy finished attack")	
		
		"thrust":
			set_state(State.MOVING)
			print("enemy finished thrust")	
