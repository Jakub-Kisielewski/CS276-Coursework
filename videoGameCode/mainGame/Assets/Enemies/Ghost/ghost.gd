extends EnemyEntity

@onready var ghost_sfx = $ghostSfx

@export var ghost_sounds : Array[AudioStream] = [] #0: thrust, 1: sweep attack, 2:death


# Get the reference to the player node
@onready var player : Node = get_tree().get_first_node_in_group("player")

@export var nav: NavigationAgent2D
@export var hitbox_shape : Shape2D
@export var hurtbox : HurtBox
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

# Details about the ghost's thrust attack
const THRUST_COOLDOWN_TIME : float = 0.6
var thrust_direction : Vector2
var thrust_multiplier : float = 2.2
var thrust_cooldown : float = 0.0
var lifeslash : bool = false

var player_in_range : bool = false
@export var speed : float = 80.0

# Details about the enemy's current state
enum State { ARISING, IDLE, INVISIBLE_MOVING, VISIBLE_MOVING, ATTACKING, THRUSTING, DAMAGED, DYING }
var state : State = State.IDLE
signal state_changed

# Change the state of the enemy
func set_state(new_state : State) -> void:
	state = new_state
	state_changed.emit()
	
	match state:
		# Enemy is spawning in
		State.ARISING:
			velocity = Vector2.ZERO
			sprite_base.play("arise")	
			
		#Enemy is idle
		State.IDLE:
			hurtbox.set_deferred("monitorable", false)
			velocity = Vector2.ZERO
			sprite_base.play("idle")

			#After 1.8 seconds of being idle, turn the enemy to gold	
			await get_tree().create_timer(1.8).timeout
			reduce_to_gold()

		# Enemy is invisble & moving towards the player
		State.INVISIBLE_MOVING:
			hurtbox.set_deferred("monitorable", false)
			speed = 100
			sprite_base.modulate = Color(1.719, 0.229, 0.334, 1.0)
			handle_move()

		# Enemy is visble & moving towards the player
		State.VISIBLE_MOVING:
			hurtbox.set_deferred("monitorable", true)
			speed = 80
			sprite_base.modulate = Color("ffffffff")
			handle_move()

		# Enemy is attacking the player
		State.ATTACKING:
			handle_attack()

		# Enemy is thrusting towards the player
		State.THRUSTING:
			handle_thrust()

		# Enemy has been damaged
		State.DAMAGED:
			velocity = Vector2.ZERO
			sprite_base.play("damage")

		#Enemy is dying
		State.DYING:
			velocity = Vector2.ZERO
			sprite_base.play("death")
			ghost_sfx.stream = ghost_sounds[2]
			ghost_sfx.play()

func _ready() -> void:
	super._ready()
	
	rng.randomize()
	
	set_state(State.ARISING)

func _physics_process(delta: float) -> void:
	#Handle the timer for thrusting
	handle_timers(delta)

	#If the player disappears, make the enemy idle
	if (!is_instance_valid(player) or !player.is_in_group("player")) and state != State.IDLE:
		set_state(State.IDLE)
		
	match state:
		# Do nothing physics-related if the enemy is ARISING or IDLE
		State.ARISING:
			return
		
		State.IDLE:
			return

		# Move enemy towards player until player is in range
		State.INVISIBLE_MOVING:
			# If player in range, use special attack
			if player_in_range:
				lifeslash = true
				set_state(State.ATTACKING)
			handle_follow()
	
		State.VISIBLE_MOVING:
			if player_in_range:
				set_state(State.ATTACKING)
			handle_follow()

		# Attack the enemy whilst following
		State.ATTACKING:
			handle_follow()

		State.THRUSTING:
			velocity = thrust_direction * speed * thrust_multiplier
			
			# Flip the sprite if neceessary
			if velocity.x > 0:
				sprite_base.flip_h = true
			elif velocity.x < 0:
				sprite_base.flip_h = false
			move_and_slide()

		# Do nothing physics-related if the enemy is DAMAGED or DYING	
		State.DAMAGED:
			return

		State.DYING:
			return

# Navigate towards the player
func handle_follow() -> void:
	nav.target_position = player.global_position	
	
	# Get the next nagivation point
	var next : Vector2 = nav.get_next_path_position()
	velocity = global_position.direction_to(next) * speed	
	
	# Flip the sprite if neceessary
	if velocity.x > 0:
		sprite_base.flip_h = true
	elif velocity.x < 0:
		sprite_base.flip_h = false
	move_and_slide()

func handle_move() -> void:	
	sprite_base.play("move")
	
func handle_attack() -> void:
	sprite_base.play("attack")
	ghost_sfx.stream = ghost_sounds[0]
	ghost_sfx.play()

	# Create a temporary hitbox for the attack
	var hitbox : hitBox
	if lifeslash:
		hitbox = hitBox.new(self, damage, "Lifeslash", 0, hitbox_shape)
	else:
		hitbox = hitBox.new(self, damage, "None", 0, hitbox_shape)

	hitbox.scale = Vector2(1.7,1.9)	
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)

	# Position and rotate the hitbox so that it aims at the player
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.rotation_degrees = 90
	if vector_to_player.x < 0:
		hitbox.position = Vector2(-20, 0)
	else:
		hitbox.position = Vector2(20, 0)

func handle_thrust() -> void:
	sprite_base.play("thrust")
	ghost_sfx.stream = ghost_sounds[1]
	ghost_sfx.play()
	thrust_cooldown = THRUST_COOLDOWN_TIME

	# Create a temporary hitbox for the attack
	var hitbox : hitBox
	if lifeslash:
		hitbox = hitBox.new(self, damage, "Lifeslash", 0, hitbox_shape)
	else:
		hitbox = hitBox.new(self, damage, "None", 0, hitbox_shape)
	
	hitbox.rotation_degrees = 90
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	hitbox.position.y = 3
	hitbox.scale = Vector2(2.1,2.8)

	var vector_to_player : Vector2 = player.global_position - global_position
	thrust_direction = vector_to_player.normalized()

func handle_timers(delta: float) -> void:
	# Decrement the thrust cooldown
	if thrust_cooldown > 0.0:
		thrust_cooldown -= delta

# When enemy enters attack range
func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

# When enemy exits attack range
func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		#If enemy is ready to attack and thrust cooldown is 0, THRUST
		if state not in [State.IDLE, State.DAMAGED, State.DYING] and thrust_cooldown <= 0:
			set_state(State.THRUSTING)

		player_in_range = false
		
# Triggered when enemy takes damage	
func _on_damaged(_amount, _type) -> void:
	super._on_damaged(_amount, _type)
	set_state(State.DAMAGED)	
	
# Triggered when enemy dies	
func _on_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	set_state(State.DYING)

# If the enemy was summoned by a boss, this is triggered when the boss dies	
func _on_boss_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	set_state(State.IDLE)
	fade_out(0.8)

# Make the enemy fade until it disappears, then drop gold
func fade_out(duration: float) -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(reduce_to_gold)

func _on_animated_sprite_2d_animation_finished() -> void:
	match sprite_base.animation:
		"arise":
			set_state(State.VISIBLE_MOVING)
		
		"damage":
			# Every time ghost is damaged, there is a 50/50 chance it turns invisible
			var x : int = rng.randi_range(1, 3)  # like a dice roll			
			if x < 3:
				set_state(State.INVISIBLE_MOVING)
			else:
				set_state(State.VISIBLE_MOVING)

		"death":
			reduce_to_gold()
	
		"attack":
			if lifeslash:
				lifeslash = false
			set_state(State.VISIBLE_MOVING)
		
		"thrust":
			if lifeslash:
				lifeslash = false
			set_state(State.VISIBLE_MOVING)
