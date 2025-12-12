extends EnemyEntity

@onready var demon_sfx = $demonSfx

@export var demon_sounds : Array[AudioStream] = [] #0: teleport, 1: attack, 2:death

# Get the reference to the player node
@onready var player : Node = get_tree().get_first_node_in_group("player")

@export var nav: NavigationAgent2D
@export var hitbox_shape : Shape2D
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var hurtbox : HurtBox

# Cooldown for the demon's teleport
const TELEPORT_COOLDOWN_TIME : float = 2.6
var teleport_cooldown : float = 0.0

var player_in_range : bool = false
@export var speed : float = 80.0

# Details about the enemy's current state
enum State { ARISING, IDLE, MOVING, ATTACKING, TELEPORTING, SPECIAL, DAMAGED, DYING }
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

		# Enemy is moving towards the player
		State.MOVING:
			handle_move()

		# Enemy is attacking the player
		State.ATTACKING:
			handle_attack()

		# Enemy is starting its teleport
		State.TELEPORTING:
			velocity = Vector2.ZERO
			sprite_base.play("escape_teleport")
			demon_sfx.stream = demon_sounds[0]
			demon_sfx.play()

		# Enemy has finished teleporting, now using its special attack
		State.SPECIAL:
			handle_special()
		
		# Enemy has been damaged
		State.DAMAGED:
			velocity = Vector2.ZERO
			sprite_base.play("damage")

		#Enemy is dying
		State.DYING:
			velocity = Vector2.ZERO
			sprite_base.play("death")
			demon_sfx.stream = demon_sounds[2]
			demon_sfx.play()

func _ready() -> void:
	super._ready() 
	
	rng.randomize()
	
	hurtbox = get_node("AnimatedSprite2D/hurtBox")
	set_state(State.ARISING)

func _physics_process(delta: float) -> void:
	#Handle the timer for teleporting
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
				set_state(State.ATTACKING)
			elif teleport_cooldown <= 0:
				set_state(State.TELEPORTING)
			handle_follow()
			
		# Attack the enemy whilst following
		State.ATTACKING:
			handle_follow()

		State.TELEPORTING:
			return
		
		# Attack the enemy whilst following
		State.SPECIAL:
			handle_follow()

		# Do nothing physics-related if the enemy is DAMAGED or DYING
		State.DAMAGED:
			return

		State.DYING:
			return

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

func handle_move():	
	sprite_base.play("move")
	
func handle_attack() -> void:
	sprite_base.play("attack")
	demon_sfx.stream = demon_sounds[1]
	demon_sfx.play()

	# Create a temporary hitbox for the attack
	var hitbox = hitBox.new(self, damage, "None", 0.1, hitbox_shape)
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	# Position and rotate the hitbox so that it aims at the player
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.position = vector_to_player.normalized() * 20
	hitbox.rotation = vector_to_player.angle()
	hitbox.scale = Vector2(2.2,2.2)

func handle_special() -> void:
	sprite_base.play("special_attack")
	demon_sfx.stream = demon_sounds[1]
	demon_sfx.play()

	# Create a temporary hitbox for the attack
	var hitbox : hitBox = hitBox.new(self, damage, "Lifeslash", 0, hitbox_shape)
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	# Position and rotate the hitbox so that it aims at the player
	var vector_to_player : Vector2 = player.global_position - global_position
	if vector_to_player.x < 0:
		hitbox.position = Vector2(-20, 7)
	else:
		hitbox.position = Vector2(20, 7)
	
	hitbox.rotation_degrees = 90
	hitbox.scale = Vector2(2,2)

# Teleport to the player's current position
func handle_teleport() -> void:
	teleport_cooldown = TELEPORT_COOLDOWN_TIME

	var vector_to_player : Vector2 = player.global_position - global_position

	# Use RNG to decide if enemy will spawn behind or infront of player
	var x : int = rng.randi_range(1, 2)  # like a dice roll
	var target_point : Vector2
	if (x == 1):
		target_point = global_position + (vector_to_player - vector_to_player.normalized()*22)
	else:
		target_point = global_position + (vector_to_player + vector_to_player.normalized()*22)
	
	# Get the closest navigatible point to the target point
	var map_rid : RID = get_world_2d().get_navigation_map() 
	var closest_point : Vector2 = NavigationServer2D.map_get_closest_point(map_rid, target_point) 
	global_position = closest_point

	sprite_base.play("spawn_teleport")
	demon_sfx.stream = demon_sounds[0]
	demon_sfx.play()

func handle_timers(delta: float) -> void:
	# Decrement the teleport cooldown
	if teleport_cooldown > 0.0:
		teleport_cooldown -= delta

# When enemy enters attack range
func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print(player.name + " is in range")

# When enemy exits attack range
func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print(player.name + " is no longer in range")
		
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
	
		"attack":
			set_state(State.MOVING)
			print("enemy finished attack")	
		
		"special_attack":
			set_state(State.MOVING)
			print("enemy finished special attack")	
		
		"escape_teleport":
			handle_teleport()
			
		"spawn_teleport":		
			set_state(State.SPECIAL)
			print("enemy finished teleporting")
