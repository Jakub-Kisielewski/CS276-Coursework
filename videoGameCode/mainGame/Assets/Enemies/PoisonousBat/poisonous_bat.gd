#Always ensure bat sprite is above player sprite
extends EnemyEntity

# Get the reference to the player node
@onready var player : Node = get_tree().get_first_node_in_group("player")

@export var nav: NavigationAgent2D
@export var hitbox_shape : Shape2D
@export var collider : CollisionShape2D
var hurtbox : HurtBox

# Details about the bat's strike attack
const STRIKE_COOLDOWN_TIME : float = 0.2
var strike_direction : Vector2
var strike_multiplier : float = 2
var strike_cooldown : float = 0.0

var player_in_range : bool = false
@export var speed : float = 100.0

# Details about the enemy's current state
enum State { ARISING, IDLE, MOVING, BITING, STRIKING, DAMAGED, DYING }
var state : State = State.IDLE
signal state_changed

# Change the state of the enemy
func set_state(new_state : State) -> void:
	if state == State.STRIKING:
		# Turn collisions back on after strike attack
		set_collision(true)
	
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

		# Enemy is moving towards the player		
		State.MOVING:
			handle_move()

		# Enemy is attacking the player
		State.BITING:
			handle_bite()

		State.STRIKING:
			handle_strike()

		# Enemy has been damaged
		State.DAMAGED:
			velocity = Vector2.ZERO
			sprite_base.play("damage")

		#Enemy is dying
		State.DYING:
			velocity = Vector2.ZERO
			sprite_base.play("death")

func _ready() -> void:
	super._ready()
	
	hurtbox = get_node("AnimatedSprite2D/hurtBox")
	
	set_state(State.ARISING)

func _physics_process(delta: float) -> void:
	#Handle the timer for striking
	handle_timers(delta)

	#If the player disappears, make the enemy idle
	if !is_instance_valid(player) and state != State.IDLE:
		set_state(State.IDLE)

	match state:
		# Do nothing physics-related if the enemy is ARISING or IDLE
		State.ARISING:
			return
			
		State.IDLE:
			return
	
		# Move enemy towards player until player is in range
		State.MOVING:
			if player_in_range:
				set_state(State.BITING)
			handle_follow()

		# Attack the enemy whilst following
		State.BITING:
			handle_follow()

		State.STRIKING:
			velocity = strike_direction * speed * strike_multiplier
			
			# Flip the sprite if neceessary
			if velocity.x > 0:
				sprite_base.flip_h = true
			elif velocity.x < 0:
				sprite_base.flip_h = false
			move_and_slide()

		# Do nothing physics-related if the enemy is DAMAGED or DYING	
		State.DAMAGED:
			pass

		State.DYING:
			pass

#player throws decoy - enemies move towards that decoy until its freed from the scene
func player_or_decoy_position() -> Vector2:
	var decoy := get_tree().get_first_node_in_group("decoy")
	if decoy and is_instance_valid(decoy):
		return decoy.global_position
		print("going for decoy")
	else:
		return player.global_position

# Navigate towards the player
func handle_follow() -> void:
	nav.target_position = player_or_decoy_position()

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
	
func handle_bite() -> void:
	sprite_base.play("bite")

	# Create a temporary hitbox for the attack
	var hitbox : hitBox = hitBox.new(self, damage, "Poison", 0, hitbox_shape)
	hitbox.scale = Vector2(0.8,0.8);
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)

	# Position and rotate the hitbox so that it aims at the player
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.position = vector_to_player.normalized() * 20
	hitbox.rotation = vector_to_player.angle()

func handle_strike() -> void:
	set_collision(false)
	
	sprite_base.play("strike")
	strike_cooldown = STRIKE_COOLDOWN_TIME

	# Create a temporary hitbox for the attack
	var hitbox : hitBox = hitBox.new(self, damage, "None", 0, hitbox_shape)
	hitbox.scale = Vector2(1.5,1.5)
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)

	var vector_to_player : Vector2 = player.global_position - global_position
	strike_direction = vector_to_player.normalized()

func handle_timers(delta: float) -> void:
	# Decrement the strike cooldown
	if strike_cooldown > 0.0:
		strike_cooldown -= delta

# Ensube or disable collisions
func set_collision(enabled: bool) -> void:
	if enabled:
		collision_layer = 1 << 0 # put CollisionObject on layer 1
		collision_mask = 1 << 0 # detect only layer 1
	else:
		collision_layer = 1 << 1 # put CollisionObject on layer 2
		collision_mask = 1 << 1 # detect only layer 2

# When enemy enters attack range
func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if state in [State.MOVING] and strike_cooldown <= 0:
			set_state(State.STRIKING)
		player_in_range = true
		print("player is in range")

# When enemy exits attack range
func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print("player is no longer in range")
		
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
			set_state(State.MOVING)
	
		"damage":
			set_state(State.MOVING)

		"death":
			reduce_to_gold()
	
		"bite":
			if health_component:
				# The enemy dies after giving the player poison
				health_component.take_damage(health_component.current_health, "None")
			print("enemy finished bite")	
		
		"strike":
			set_state(State.MOVING)
			print("enemy finished strike")
