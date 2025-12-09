extends EnemyEntity

@onready var player : Node = get_tree().get_first_node_in_group("player")
@export var nav: NavigationAgent2D
@export var hitbox_shape : Shape2D
@export var hurtbox : HurtBox
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

const THRUST_COOLDOWN_TIME : float = 0.8
var thrust_direction : Vector2
var thrust_multiplier : float = 2.2
var thrust_cooldown : float = 0.0
var lifeslash : bool = false

var player_in_range : bool = false
@export var speed : float = 80.0

enum State { ARISING, IDLE, INVISIBLE_MOVING, VISIBLE_MOVING, ATTACKING, THRUSTING, DAMAGED, DYING }
var state : State = State.IDLE
signal state_changed

func set_state(new_state : State) -> void:
	state = new_state
	state_changed.emit()
	
	match state:
		State.ARISING:
			velocity = Vector2.ZERO
			sprite_base.play("arise")
			
		State.IDLE:
			hurtbox.set_deferred("monitorable", false)
			velocity = Vector2.ZERO
			sprite_base.play("idle")
			
			await get_tree().create_timer(1.8).timeout
			reduce_to_gold()

		State.INVISIBLE_MOVING:
			hurtbox.set_deferred("monitorable", false)
			speed = 100
			sprite_base.modulate = Color(1.719, 0.229, 0.334, 1.0)
			handle_move()
	
		State.VISIBLE_MOVING:
			hurtbox.set_deferred("monitorable", true)
			speed = 80
			sprite_base.modulate = Color("ffffffff")
			handle_move()

		State.ATTACKING:
			handle_attack()

		State.THRUSTING:
			handle_thrust()

		State.DAMAGED:
			velocity = Vector2.ZERO
			sprite_base.play("damage")

		State.DYING:
			velocity = Vector2.ZERO
			sprite_base.play("death")

func _ready() -> void:
	super._ready()
	
	rng.randomize()
	
	set_state(State.ARISING)

func _physics_process(delta: float) -> void:
	handle_timers(delta)
	
	if !is_instance_valid(player) and state != State.IDLE:
		set_state(State.IDLE)
		
	match state:
		State.ARISING:
			return
		
		State.IDLE:
			return

		State.INVISIBLE_MOVING:
			if player_in_range:
				lifeslash = true
				set_state(State.ATTACKING)
			handle_follow()
	
		State.VISIBLE_MOVING:
			if player_in_range:
				set_state(State.ATTACKING)
			handle_follow()

		State.ATTACKING:
			handle_follow()

		State.THRUSTING:
			velocity = thrust_direction * speed * thrust_multiplier
			if velocity.x > 0:
				sprite_base.flip_h = true
			elif velocity.x < 0:
				sprite_base.flip_h = false
			move_and_slide()
			
		State.DAMAGED:
			return

		State.DYING:
			return

func handle_follow() -> void:
	nav.target_position = player.global_position	
	var next : Vector2 = nav.get_next_path_position()
	velocity = global_position.direction_to(next) * speed	
	if velocity.x > 0:
		sprite_base.flip_h = true
	elif velocity.x < 0:
		sprite_base.flip_h = false
	move_and_slide()

func handle_move() -> void:	
	sprite_base.play("move")
	
func handle_attack() -> void:
	sprite_base.play("attack")
	
	var hitbox : hitBox
	if lifeslash:
		print("life")
		hitbox = hitBox.new(self, damage, "Lifeslash", 0, hitbox_shape)
	else:
		hitbox = hitBox.new(self, damage, "None", 0, hitbox_shape)
		
	hitbox.scale = Vector2(1.6,1.8)	
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.rotation_degrees = 90
	if vector_to_player.x < 0:
		hitbox.position = Vector2(-20, 0)
	else:
		hitbox.position = Vector2(20, 0)

func handle_thrust() -> void:
	sprite_base.play("thrust")
	
	thrust_cooldown = THRUST_COOLDOWN_TIME
	
	var hitbox : hitBox
	if lifeslash:
		hitbox = hitBox.new(self, damage, "Lifeslash", 0, hitbox_shape)
	else:
		hitbox = hitBox.new(self, damage, "None", 0, hitbox_shape)
	
	hitbox.rotation_degrees = 90
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	hitbox.position.y = 3
	hitbox.scale = Vector2(1.8,2.7)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	thrust_direction = vector_to_player.normalized()

func handle_timers(delta: float) -> void:
	if thrust_cooldown > 0.0:
		thrust_cooldown -= delta

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print("player is in range")

func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if state not in [State.IDLE, State.DAMAGED, State.DYING] and thrust_cooldown <= 0:
			if state == State.INVISIBLE_MOVING:
				lifeslash = true
			set_state(State.THRUSTING)
		player_in_range = false
		print("player is no longer in range")
		
	
func _on_damaged(_amount, _type) -> void:
	super._on_damaged(_amount, _type)
	set_state(State.DAMAGED)	
	
func _on_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	set_state(State.DYING)
	
func _on_boss_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	set_state(State.IDLE)
	fade_out(1)

func fade_out(duration: float) -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(reduce_to_gold)

func _on_animated_sprite_2d_animation_finished() -> void:
	match sprite_base.animation:
		"arise":
			set_state(State.VISIBLE_MOVING)
		
		"damage":
			var x : int = rng.randi_range(1, 2)  # like a dice roll			
			if x == 1:
				set_state(State.INVISIBLE_MOVING)
			else:
				set_state(State.VISIBLE_MOVING)

		"death":
			reduce_to_gold()
	
		"attack":
			if lifeslash:
				lifeslash = false
			set_state(State.VISIBLE_MOVING)
			print("enemy finished attack")	
		
		"thrust":
			if lifeslash:
				lifeslash = false
			set_state(State.VISIBLE_MOVING)
			print("enemy finished thrust")	
