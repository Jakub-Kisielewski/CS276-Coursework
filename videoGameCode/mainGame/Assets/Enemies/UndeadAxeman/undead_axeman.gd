extends EnemyEntity

@onready var axe_sfx = $axeSfx

@export var axe_sounds : Array[AudioStream] = [] #0: grunt, 1: attack, 2:death,

# Get the reference to the player node
@onready var player : Node = get_tree().get_first_node_in_group("player")

@export var nav: NavigationAgent2D
@export var hitbox_shape : Shape2D
var hurtbox : HurtBox

var player_in_range : bool = false
@export var speed : float = 60.0

# Details about the enemy's current state
enum State { ARISING, IDLE, MOVING, ATTACKING, DAMAGED, DYING }
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

		# Enemy has been damaged
		State.DAMAGED:
			velocity = Vector2.ZERO
			sprite_base.play("damage")
			#axe_sfx.stream = axe_sounds[0]
			#axe_sfx.play()

		#Enemy is dying
		State.DYING:
			velocity = Vector2.ZERO
			sprite_base.play("death")
			axe_sfx.stream = axe_sounds[2]
			axe_sfx.play()

func _ready() -> void:
	super._ready()

	hurtbox = get_node("AnimatedSprite2D/hurtBox")
	
	set_state(State.ARISING)

func _physics_process(delta: float) -> void:
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
		State.MOVING:
			if player_in_range:
				set_state(State.ATTACKING)
			handle_follow()

		# Attack the enemy whilst following
		State.ATTACKING:
			handle_follow()

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
		sprite_base.flip_h = false
	elif velocity.x < 0:
		sprite_base.flip_h = true
	move_and_slide()

func handle_move() -> void:	
	sprite_base.play("move")
	
	
func handle_attack() -> void:
	# Create a temporary hitbox for the attack
	var hitbox : hitBox = hitBox.new(self, damage, "None", 0, hitbox_shape)
	hitbox.scale = Vector2(2,2);
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	# Position and rotate the hitbox so that it aims at the player
	var vector_to_player : Vector2 = player.global_position - global_position
	
	if vector_to_player.y < 0:
		hitbox.rotation = vector_to_player.angle() + 90
		hitbox.position = vector_to_player.normalized() * 20
		sprite_base.play("attack_up")
	else:
		hitbox.rotation_degrees = 90
		if vector_to_player.x < 0:
			hitbox.position = Vector2(-20, 0)
		else:
			hitbox.position = Vector2(20, 0)
		sprite_base.play("attack_down")
		
	axe_sfx.stream = axe_sounds[1]
	axe_sfx.play()

# When enemy enters attack range
func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

# When enemy exits attack range
func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
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
			set_state(State.MOVING)
		
		"damage":
			set_state(State.MOVING)

		"death":
			reduce_to_gold()
	
		"attack_up", "attack_down":
			set_state(State.MOVING)
