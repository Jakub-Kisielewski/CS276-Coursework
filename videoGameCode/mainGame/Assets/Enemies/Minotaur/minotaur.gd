extends EnemyEntity

# Get the reference to the player node
@onready var player : Node = get_tree().get_first_node_in_group("player")

@export var nav: NavigationAgent2D
@export var hitbox_shape : Shape2D
@export var hurtbox : HurtBox
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var tilemap : TileMapLayer

# Enemies that the minotaur can summon
@export var summons : Array[PackedScene]

# Raycasts used to ensure player is inn line of sight
@export var player_rays : Array[RayCast2D]

# Reference to the main camera
var camera : Camera2D

# Cooldown for the minotaur's summoning
const SUMMON_COOLDOWN_TIME : float = 9
var summon_cooldown : float = 1

# Cooldown for the charge attack
const CHARGE_COOLDOWN_TIME : float = 3
const CHARGE_DURATION_TIME : float = 2

# Cooldown for the overheated charge attack
const OVERHEAT_COOLDOWN_TIME : float = 6
const OVERHEAT_DURATION_TIME : float = 4

# Details about the charge attack
var charge_direction : Vector2
var charge_multiplier : float = 5.5
var charge_cooldown : float = 0.0
var charge_duration : float = 0.0

# Duration of the stun effect
const STUN_DURATION_TIME : float = 0.8
var stun_duration : float = 0.0

var player_in_range : bool = false
@export var speed : float = 80.0

# Details about the enemy's current state
enum State { IDLE, MOVING, ATTACKING, SUMMONING, POWERUP, CHARGING, OVERHEATING, STUNNED, DAMAGED }
var state : State = State.IDLE

signal state_changed
signal charge_collision
signal boss_defeated

# Has the minotaur entered phase two
var phase_two : bool

# Change the state of the enemy
func set_state(new_state : State) -> void:
	state = new_state
	state_changed.emit()
	
	match state:
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
			hurtbox.set_deferred("monitorable", true)
			handle_move()

		# Enemy is attacking the player
		State.ATTACKING:
			hurtbox.set_deferred("monitorable", true)
			handle_attack()

		# Enemy is summoning other enemies
		State.SUMMONING:
			hurtbox.set_deferred("monitorable", false)
			handle_summon()

		# Enemy is powering up
		State.POWERUP:
			hurtbox.set_deferred("monitorable", false)
			handle_powerup()

		# Enemy is charging towards the player
		State.CHARGING:
			hurtbox.set_deferred("monitorable", false)
			handle_charge()

		# Enemy is overheating & charging towards the player
		State.OVERHEATING:
			hurtbox.set_deferred("monitorable", false)
			health_component.start_overheat()
			handle_charge()
			
		# Enemy is stunned
		State.STUNNED:
			hurtbox.set_deferred("monitorable", true)
			velocity = Vector2.ZERO
			stun_duration = STUN_DURATION_TIME
			sprite_base.play("stunned")
		
		# Enemy has died
		State.DAMAGED:
			hurtbox.set_deferred("monitorable", true)
			velocity = Vector2.ZERO
			sprite_base.play("damage")

func _ready() -> void:
	super._ready()
	
	rng.randomize()

	tilemap = get_tree().get_first_node_in_group("tilemap")
	camera = get_tree().get_first_node_in_group("camera")
	charge_collision.connect(camera.shake)
	set_state(State.MOVING)

func _physics_process(delta: float) -> void:
	#Handle the timers for summon, charge & stun
	handle_timers(delta)
	
	#If the player disappears, make the enemy idle
	if !is_instance_valid(player) or !player.is_in_group("player"):
		if state != State.IDLE:
			set_state(State.IDLE)
	else:
		# Update raycasts to player
		update_rays()
	
	match state:
		# Do nothing physics-related if the enemy is IDLE
		State.IDLE:
			return

		# Move enemy towards player until player is in range
		State.MOVING:
			if player_in_range:
				set_state(State.ATTACKING)
			elif can_overheat():
				# If phase 2 & can charge, use overheat
				if charge_cooldown <= 0 and not(is_on_wall()) and not(player_in_range) and player_in_sight():
					set_state(State.OVERHEATING)
			# If can charge, use charge
			elif can_charge():
					set_state(State.CHARGING)
			# If can't charge, use summoning
			elif summon_cooldown <= 0:
				set_state(State.SUMMONING)
				
			handle_follow()

		# Attack the enemy whilst following
		State.ATTACKING:
			handle_follow()

		# Do nothing physics-related if the enemy is SUMMONING
		State.SUMMONING:
			return
			
		State.POWERUP:
			var direction : Vector2 = global_position.direction_to(player.global_position)
	
			# Flip the sprite if neceessary
			if direction.x > 0:
				sprite_base.flip_h = false
			elif direction.x < 0:
				sprite_base.flip_h = true
			
		State.CHARGING:
			if charge_duration <= 0:
				# End charge
				set_state(State.MOVING)
			if is_on_wall():
				var wall_collision : bool = true
				
				for x in range(get_slide_collision_count()):
					var collider : Object = get_slide_collision(x).get_collider()
					print(collider.name)
					if  collider.is_in_group("enemy"):
						wall_collision = false
					
				if wall_collision:
					# Enemy collided with other enemy, end charge
					set_state(State.MOVING)
					return
					
				# Enemy has charged into wall
				charge_collision.emit()
				if health_component:
					health_component.take_damage(6, "None")
				set_state(State.STUNNED)
			
			# Flip the sprite if neceessary
			velocity = charge_direction * speed * charge_multiplier
			if velocity.x > 0:
				sprite_base.flip_h = false
			elif velocity.x < 0:
				sprite_base.flip_h = true
			move_and_slide()
			
		State.OVERHEATING:
			if charge_duration <= 0:
				# End the overheated charge
				if health_component:
					sprite_base.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
					health_component.stop_overheat()
				set_state(State.MOVING)
			if is_on_wall():  
				# Bounce the minotaur off the wall      
				charge_collision.emit()
				
				var collision : KinematicCollision2D = get_slide_collision(0)
				var normal : Vector2 = collision.get_normal()
				
				# Reflect current direction
				charge_direction = charge_direction.bounce(normal).normalized()
				# Bias direction back towards player
				var desired_direction : Vector2 = (player.global_position - global_position).normalized()
				charge_direction = charge_direction.lerp(desired_direction, 0.52).normalized()

			velocity = 1.5 * charge_direction * speed * charge_multiplier

			# Flip the sprite if neceessary
			if velocity.x > 0:
				sprite_base.flip_h = false
			elif velocity.x < 0:
				sprite_base.flip_h = true
			move_and_slide()

		State.STUNNED:
			if stun_duration <= 0:
				set_state(State.MOVING)

		# Do nothing physics-related if the enemy is DAMAGED
		State.DAMAGED:
			return

func can_overheat() -> bool:
	return phase_two and charge_cooldown <= 0 and not(is_on_wall()) and not(player_in_range) and player_in_sight()

func can_charge() -> bool:
	return charge_cooldown <= 0 and not(is_on_wall()) and not(player_in_range) and player_in_sight()

# Check raycasts to determine if player is fully in sight
func player_in_sight() -> bool:
	var result : bool = true
	for x in range(0, player_rays.size()):
		result = result and (player_rays[x].is_colliding() and player_rays[x].get_collider().is_in_group("player"))
	return result

# Update the raycasts to aim at the player
func update_rays() -> void:
	for x in range(0, player_rays.size()):
		player_rays[x].target_position = 400 * (player.global_position - player_rays[x].global_position).normalized()
		player_rays[x].force_raycast_update()

# Navigate towards the player
func handle_follow() -> void:
	nav.target_position = player.global_position	
	
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
	
func handle_powerup() -> void:
	velocity = Vector2.ZERO
	sprite_base.play("idle")
	
	#Play powerup animation
	var tween : Tween = get_tree().create_tween()
	
	sprite_base.self_modulate = Color(1.526, 1.526, 1.526, 1.0)
	tween.tween_property(sprite_base, "modulate", Color("f5a3b0"), 0.12)
	tween.tween_property(self, "scale", Vector2(0.94,0.94), 0.12)
	tween.tween_property(sprite_base, "modulate", Color("ffffffff"), 0.12)
	tween.tween_property(self, "scale", Vector2(1,1), 0.12)
	tween.set_loops()
	
	await get_tree().create_timer(3).timeout
	tween.kill() 
	
	#End powerup animation
	sprite_base.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	sprite_base.modulate = Color("ffffffff")
	sprite_base.scale = Vector2(1,1)
	set_state(State.MOVING)

func handle_attack() -> void:
	sprite_base.play("attack")

	# Create a temporary hitbox for the attack
	var hitbox : hitBox = hitBox.new(self, damage, "None", 0, hitbox_shape)
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)

	# Position and rotate the hitbox so that it aims at the player
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.position = vector_to_player.normalized() * 20
	hitbox.rotation = vector_to_player.angle()
	hitbox.scale = Vector2(1.9,1.9)

func handle_charge() -> void:
	sprite_base.play("charge")
	hurtbox.set_deferred("monitorable", false)
	
	if state == State.CHARGING:
		# Charging
		charge_cooldown = CHARGE_COOLDOWN_TIME
		charge_duration = CHARGE_DURATION_TIME
	else:
		# Overheating
		sprite_base.self_modulate = Color(1.353, 1.353, 1.353, 1.0)
		charge_cooldown = OVERHEAT_COOLDOWN_TIME
		charge_duration = OVERHEAT_DURATION_TIME

	var hitbox : hitBox = hitBox.new(self, damage, "Critical", 0, hitbox_shape, null, true)
	
	# Create a temporary hitbox for the attack
	hitbox.scale = Vector2(2.6,2.6)
	state_changed.connect(hitbox.queue_free)
	if state == State.CHARGING:
		hitbox.successful_hit.connect(set_state.bind(State.MOVING))        
	add_child(hitbox)

	var vector_to_player : Vector2 = player.global_position - global_position
	charge_direction = vector_to_player.normalized()


func handle_summon() -> void:
	sprite_base.play("summon")
	summon_cooldown = SUMMON_COOLDOWN_TIME
	
	# Get every point on the tilemap
	var map_rid : RID = get_world_2d().get_navigation_map() 
	var cells : Array[Vector2i] = tilemap.get_used_cells()
	
	# Get the points that are close to the player
	var filtered_cells: Array[Vector2i] = []
	for cell in cells:
		var world_pos = tilemap.map_to_local(cell)
		if world_pos.distance_to(player.global_position) <= 180:
			filtered_cells.append(cell)

	# If no cells are in the radius, fall back to original list
	if filtered_cells.is_empty():
		print("Ues")
		filtered_cells = cells
	
	# Choose the number of enemies to spawn
	var n : int = rng.randi_range(6, 8)  # like a dice roll
	
	for i in range(n):
		var e : int = rng.randi_range(0, summons.size()-1)  # like a dice roll
		var new_enemy : Node = summons[e].instantiate()
		
		#Place the spawned enemy at a random navigable point
		var cell : Vector2i = filtered_cells.pick_random()  # like a dice roll
		var target_point : Vector2 = tilemap.map_to_local(cell)
		filtered_cells.erase(cell)
		
		var closest_point : Vector2 = NavigationServer2D.map_get_closest_point(map_rid, target_point) 
		new_enemy.global_position = closest_point
		
		get_tree().current_scene.add_child(new_enemy)
		boss_defeated.connect(new_enemy._on_boss_death)
	
func handle_timers(delta: float) -> void:
	# Decrement the timers
	if summon_cooldown > 0.0:
		summon_cooldown -= delta
		
	if charge_cooldown > 0.0:
		charge_cooldown -= delta
	if charge_duration > 0.0:
		charge_duration -= delta
		
	if stun_duration > 0.0:
		stun_duration -= delta

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
	if state == State.OVERHEATING:
		return
	
	super._on_damaged(_amount, _type)
	set_state(State.DAMAGED)

# Triggered when enemy dies	
func _on_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	emit_signal("boss_defeated")
	
	set_state(State.IDLE)
	fade_out(0.8)

# Make the enemy fade until it disappears, then display game cleared UI
func fade_out(duration: float) -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(clear_game)

func clear_game() -> void:
	player.clear_screen()
	reduce_to_gold()

func _on_animated_sprite_2d_animation_finished() -> void:
	match sprite_base.animation:
		"damage":
			var hp_threshold = health_component.max_health / 2
			if phase_two == false and health_component.current_health <= hp_threshold:
				phase_two = true
				# If minatour health less than half of the max, start powerup
				set_state(State.POWERUP)
			else:
				set_state(State.MOVING)
			
		"attack":
			set_state(State.MOVING)
			print("enemy finished attack")	
			
		"summon":		
			set_state(State.MOVING)
			print("enemy finished summon")
