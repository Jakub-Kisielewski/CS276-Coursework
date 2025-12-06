extends CharacterBody2D

@onready var player : Node = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@export var nav: NavigationAgent2D
@export var stats : Stats
@export var hitbox_shape : Shape2D
var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var hurtbox : hurtBox

const TELEPORT_COOLDOWN_TIME : float = 3.6
var teleport_cooldown : float = 0.0

var player_in_range : bool = false
@export var speed : float = 80.0

enum State { ARISING, IDLE, MOVING, ATTACKING, TELEPORTING, SPECIAL, DAMAGED, DYING }
var state : State = State.IDLE
signal state_changed


func set_state(new_state : State) -> void:
	state = new_state
	state_changed.emit()
	
	match state:
		State.ARISING:
			velocity = Vector2.ZERO
			sprite.play("arise")
		
		State.IDLE:
			hurtbox.set_deferred("monitorable", false)
			velocity = Vector2.ZERO
			sprite.play("idle")
			
			await get_tree().create_timer(1.8).timeout
			queue_free()
		
		State.MOVING:
			handle_move()

		State.ATTACKING:
			handle_attack()

		State.TELEPORTING:
			velocity = Vector2.ZERO
			sprite.play("escape_teleport")

		State.SPECIAL:
			handle_special()
		
		State.DAMAGED:
			velocity = Vector2.ZERO
			sprite.play("damage")

		State.DYING:
			velocity = Vector2.ZERO
			sprite.play("death")

func _ready() -> void:
	stats.health_depleted.connect(_on_death)
	stats.damage_taken.connect(_on_damaged)
	stats.set_owner_node(self)
	rng.randomize()
	
	hurtbox = get_node("AnimatedSprite2D/hurtBox")

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
		
		State.MOVING:
			if player_in_range:
				set_state(State.ATTACKING)
			elif teleport_cooldown <= 0:
				set_state(State.TELEPORTING)
			handle_follow()

		State.ATTACKING:
			handle_follow()

		State.TELEPORTING:
			return
			
		State.SPECIAL:
			handle_follow()

		State.DAMAGED:
			return

		State.DYING:
			return

func handle_follow() -> void:
	nav.target_position = player.global_position	
	var next : Vector2 = nav.get_next_path_position()
	velocity = global_position.direction_to(next) * speed	
	if velocity.x > 0:
		sprite.flip_h = true
	elif velocity.x < 0:
		sprite.flip_h = false
	move_and_slide()

func handle_move():	
	sprite.play("move")
	
func handle_attack() -> void:
	sprite.play("attack")

	var hitbox : hitBox = hitBox.new(stats, "None", 0, hitbox_shape)
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	hitbox.position = vector_to_player.normalized() * 20
	hitbox.rotation = vector_to_player.angle()
	hitbox.scale = Vector2(2.2,2.2)

func handle_special() -> void:
	sprite.play("special_attack")

	var hitbox : hitBox = hitBox.new(stats, "Lifeslash", 0, hitbox_shape)
	state_changed.connect(hitbox.queue_free)
	add_child(hitbox)
	
	var vector_to_player : Vector2 = player.global_position - global_position
	if vector_to_player.x < 0:
		hitbox.position = Vector2(-20, 7)
	else:
		hitbox.position = Vector2(20, 7)
	
	hitbox.rotation_degrees = 90
	hitbox.scale = Vector2(2,2)

func handle_teleport() -> void:
	teleport_cooldown = TELEPORT_COOLDOWN_TIME

	var vector_to_player : Vector2 = player.global_position - global_position
	var x : int = rng.randi_range(1, 2)  # like a dice roll
	
	var target_point : Vector2
	if (x == 1):
		target_point = global_position + (vector_to_player - vector_to_player.normalized()*22)
	else:
		target_point = global_position + (vector_to_player + vector_to_player.normalized()*22)
	
	var map_rid : RID = get_world_2d().get_navigation_map() 
	var closest_point : Vector2 = NavigationServer2D.map_get_closest_point(map_rid, target_point) 
	global_position = closest_point

	sprite.play("spawn_teleport")
	
func handle_timers(delta: float) -> void:
	if teleport_cooldown > 0.0:
		teleport_cooldown -= delta

func get_animation_length(animation: String) -> float:
	var frames : int = sprite.sprite_frames.get_frame_count(animation)
	var fps : float = sprite.sprite_frames.get_animation_speed(animation)
	return frames/fps

func _on_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print(player.name + " is in range")

func _on_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		print(player.name + " is no longer in range")
		
	
func _on_damaged() -> void:
	set_state(State.DAMAGED)	
	
func _on_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	if is_instance_valid(player):
		player.collect_value(stats.value)
	set_state(State.DYING)
	
func _on_boss_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	if is_instance_valid(player):
		player.collect_value(stats.value)
	set_state(State.IDLE)
	fade_out(1)

func fade_out(duration: float) -> void:
	var tween : Tween = create_tween()
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
		
		"special_attack":
			set_state(State.MOVING)
			print("enemy finished special attack")	
		
		"escape_teleport":
			handle_teleport()
			
		"spawn_teleport":		
			set_state(State.SPECIAL)
			print("enemy finished teleporting")
