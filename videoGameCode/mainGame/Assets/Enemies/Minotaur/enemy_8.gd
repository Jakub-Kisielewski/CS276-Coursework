extends CharacterBody2D

@onready var player = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@export var nav: NavigationAgent2D
@export var stats : Stats
@export var hitbox_shape : Shape2D
@export var summons : Array[PackedScene]
@export var player_rays : Array[RayCast2D]
var rng = RandomNumberGenerator.new()
signal boss_defeated

const SUMMON_COOLDOWN_TIME = 12
var summon_cooldown = 0.0

const CHARGE_COOLDOWN_TIME = 5
const CHARGE_DURATION_TIME = 3
const OVERHEAT_COOLDOWN_TIME = 8
const OVERHEAT_DURATION_TIME = 4
var charge_direction : Vector2
var charge_multiplier = 3
var charge_cooldown = 0.0
var charge_duration = 0.0

const STUN_DURATION_TIME = 1.4
var stun_duration = 0.0


var player_in_range = false
@export var speed = 80.0

enum State { IDLE, MOVING, ATTACKING, SUMMONING, CHARGING, OVERHEATING, STUNNED, DAMAGED }
var state : State = State.IDLE
signal state_changed

var phase_two : bool


func set_state(new_state : State):
	state = new_state
	state_changed.emit()
	
	match state:	
		State.IDLE:
			velocity = Vector2.ZERO
			sprite.play("idle")
		
		State.MOVING:
			handle_move()

		State.ATTACKING:
			handle_attack()

		State.SUMMONING:
			handle_summon()

		State.CHARGING:
			handle_charge()
	
		State.OVERHEATING:
			stats.start_overheat()
			handle_charge()
			
		State.STUNNED:
			velocity = Vector2.ZERO
			stun_duration = STUN_DURATION_TIME
			sprite.play("stunned")
		
		State.DAMAGED:
			velocity = Vector2.ZERO
			sprite.play("damage")

func _ready():
	stats.set_owner_node(self)
	stats.health_depleted.connect(_on_death)
	stats.damage_taken.connect(_on_damaged)
	rng.randomize()

	set_state(State.MOVING)

func _physics_process(delta: float) -> void:
	handle_timers(delta)
	update_rays()

	if !is_instance_valid(player):#temporary
		set_state(State.IDLE)
		
	match state:
		State.IDLE:
			return
		
		State.MOVING:
			if player_in_range:
				set_state(State.ATTACKING)
			elif phase_two:
				if charge_cooldown <= 0:	
					if not(is_on_wall()) and not(player_in_range) and player_in_sight():
						set_state(State.OVERHEATING)
				elif summon_cooldown <= 0 and global_position.distance_to(player.global_position) > 200:
					set_state(State.SUMMONING)
			elif charge_cooldown <= 0:	
				if not(is_on_wall()) and not(player_in_range) and player_in_sight():
					set_state(State.CHARGING)
				
			handle_follow()

		State.ATTACKING:
			handle_follow()

		State.SUMMONING:
			return
			
		State.CHARGING:
			if charge_duration <= 0:
				set_state(State.MOVING)
			if is_on_wall():
				stats.take_damage(10, "None")
				set_state(State.STUNNED)
			
			velocity = charge_direction * speed * charge_multiplier
			if velocity.x > 0:
				sprite.flip_h = false
			elif velocity.x < 0:
				sprite.flip_h = true
			move_and_slide()
			
		State.OVERHEATING:
			if charge_duration <= 0:
				stats.end_overheat()
				set_state(State.MOVING)
			if is_on_wall():        
				var collision = get_slide_collision(0)
				var normal = collision.get_normal()
				# Reflect current direction
				charge_direction = charge_direction.bounce(normal).normalized()
				# Bias direction back towards player
				var desired_direction = (player.global_position - global_position).normalized()
				charge_direction = charge_direction.lerp(desired_direction, 0.46).normalized()

			velocity = 1.3 * charge_direction * speed * charge_multiplier
			if velocity.x > 0:
				sprite.flip_h = false
			elif velocity.x < 0:
				sprite.flip_h = true
			move_and_slide()

		State.STUNNED:
			if stun_duration <= 0:
				set_state(State.MOVING)

		State.DAMAGED:
			return

func player_in_sight() -> bool:
	var result = true
	for x in range(0, player_rays.size()):
		result = result and (player_rays[x].is_colliding() and player_rays[x].get_collider().is_in_group("player"))
	return result
	
func update_rays() -> void:
	for x in range(0, player_rays.size()):
		player_rays[x].target_position = 400 * (player.global_position - player_rays[x].global_position).normalized()
		player_rays[x].force_raycast_update()

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
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.position = vector_to_player.normalized() * 20
	hitbox.rotation = vector_to_player.angle()
	hitbox.scale = Vector2(2.1,2.1)

func handle_charge():
	sprite.play("charge")
	
	if state == State.CHARGING:
		charge_cooldown = CHARGE_COOLDOWN_TIME
		charge_duration = CHARGE_DURATION_TIME
	else:
		charge_cooldown = OVERHEAT_COOLDOWN_TIME
		charge_duration = OVERHEAT_DURATION_TIME

	var hitbox = hitBox.new(stats, "Critical", 0, hitbox_shape)
	hitbox.scale = Vector2(3,3)
	state_changed.connect(hitbox.queue_free)
	if state == State.CHARGING:
		hitbox.successful_hit.connect(set_state.bind(State.MOVING))        
	add_child(hitbox)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	charge_direction = vector_to_player.normalized()


func handle_summon():
	sprite.play("summon")
	summon_cooldown = SUMMON_COOLDOWN_TIME
	
	var vector_to_player : Vector2 = player.global_position - global_position
	var x = rng.randi_range(0, summons.size()-1)  # like a dice roll
	
	for i in range (1,3):
		var new_enemy = summons[x].instantiate()

		var target_point
		if (i == 1):
			target_point = global_position + (vector_to_player - vector_to_player.normalized()*26)
		else:
			target_point = global_position + (vector_to_player + vector_to_player.normalized()*26)
		
		var map_rid: RID = get_world_2d().get_navigation_map() 
		var closest_point = NavigationServer2D.map_get_closest_point(map_rid, target_point) 
		new_enemy.global_position = closest_point	
		get_tree().root.add_child(new_enemy)
		boss_defeated.connect(new_enemy._on_boss_death)
	
func handle_timers(delta: float):
	if summon_cooldown > 0.0:
		summon_cooldown -= delta
		
	if charge_cooldown > 0.0:
		charge_cooldown -= delta
	if charge_duration > 0.0:
		charge_duration -= delta
		
	if stun_duration > 0.0:
		stun_duration -= delta

func get_animation_length(animation: String):
	var frames = sprite.sprite_frames.get_frame_count(animation)
	var fps = sprite.sprite_frames.get_animation_speed(animation)
	return frames/fps

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print(player.name + " is in range")
		

func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print(player.name + " is no longer in range")
		
	
func _on_damaged():
	if state == State.OVERHEATING:
		stats.end_overheat() 
	if stats.current_health < stats.max_health/2:
		phase_two = true
	set_state(State.DAMAGED)	

func _on_death():
	emit_signal("boss_defeated")
	$AnimatedSprite2D/hurtBox.monitorable = true
	set_state(State.IDLE)
	fade_out(1)

func fade_out(duration: float):
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)

func _on_animated_sprite_2d_animation_finished() -> void:
	match sprite.animation:
		"damage":
			if stun_duration <= 0:
				set_state(State.MOVING)
			else:
				set_state(State.STUNNED)
	
		"attack":
			set_state(State.MOVING)
			print("enemy finished attack")	
		
		"charge":
			set_state(State.MOVING)
			print("enemy finished charge")	
			
		"summon":		
			set_state(State.MOVING)
			print("enemy finished summon")
