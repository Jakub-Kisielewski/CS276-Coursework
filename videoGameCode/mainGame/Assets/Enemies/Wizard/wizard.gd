extends CharacterBody2D

@onready var player : Node = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@export var nav: NavigationAgent2D
@export var stats : Stats
@export var hitbox_shape : Shape2D
@export var summons : Array[PackedScene]

var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var tilemap : TileMapLayer
var hurtbox : hurtBox
var countdown_label : Label
var countdown_timer : Timer
var time_left : int
var hits_left_label : Label
var player_hits_left : int

const TELEPORT_COOLDOWN_TIME : float = 1.4
var teleport_cooldown : float = 0.0
var transformation : bool = false

var current_disguise : Node

@export var speed : float = 80.0

enum State { ARISING, IDLE, TELEPORTING, TRANSFORMED, DAMAGED, DYING }
var state : State = State.IDLE
signal state_changed
signal boss_hit


func set_state(new_state : State) -> void:
	state = new_state
	state_changed.emit()
	
	match state:
		State.ARISING:
			hurtbox.set_deferred("monitorable", false)
			velocity = Vector2.ZERO
			sprite.play("arise")
		
		State.IDLE:
			hurtbox.set_deferred("monitorable", true)
			set_collision(true)
			velocity = Vector2.ZERO
			sprite.play("idle")

		State.TELEPORTING:
			hurtbox.set_deferred("monitorable", false)
			velocity = Vector2.ZERO
			sprite.play("escape_teleport")
			
		State.TRANSFORMED:
			hurtbox.set_deferred("monitorable", false)
			set_collision(false)
			handle_transformation()

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
	
	setup_countdown_timer()
	rng.randomize()

	tilemap = get_tree().get_first_node_in_group("tilemap")
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
			if teleport_cooldown <= 0:
				set_state(State.TELEPORTING)

		State.TELEPORTING:
			return

		State.TRANSFORMED:
			if is_instance_valid(current_disguise):
				global_position = current_disguise.global_position
			else:
				_on_damaged()

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

func handle_transformation() -> void:
	teleport_cooldown = TELEPORT_COOLDOWN_TIME

	var map_rid : RID = get_world_2d().get_navigation_map() 
	var cells : Array[Vector2i] = tilemap.get_used_cells()
	
	var n : int = rng.randi_range(2, 4)  # like a dice roll
	
	for i in range(n):
		var e : int = rng.randi_range(0, summons.size()-1)  # like a dice roll
		var new_enemy : Node = summons[e].instantiate()
		
		var cell : Vector2i = cells.pick_random()  # like a dice roll
		var target_point : Vector2 = tilemap.map_to_local(cell)
		cells.erase(cell)

		var closest_point : Vector2 = NavigationServer2D.map_get_closest_point(map_rid, target_point) 
		new_enemy.global_position = closest_point
		
		get_tree().current_scene.add_child(new_enemy)
		boss_hit.connect(new_enemy._on_boss_death)
		
		if i == 0:
			current_disguise = new_enemy
			new_enemy.stats.damage_taken.connect(_on_damaged)

func handle_teleport() -> void:
	teleport_cooldown = TELEPORT_COOLDOWN_TIME

	var cells : Array[Vector2i] = tilemap.get_used_cells()
	var x : int = rng.randi_range(0, cells.size()-1)  # like a dice roll
	var target_point : Vector2 = tilemap.map_to_local(cells[x])

	var map_rid : RID = get_world_2d().get_navigation_map() 
	var closest_point : Vector2 = NavigationServer2D.map_get_closest_point(map_rid, target_point) 
	global_position = closest_point

	sprite.play("spawn_teleport")

func setup_countdown_timer() -> void:
	player_hits_left = 10
	time_left = 60

	var canvas : CanvasLayer = get_tree().get_first_node_in_group("canvas")
	
	hits_left_label = canvas.get_node("Puzzle/HitsLeft")
	hits_left_label.visible = true
	display_hits_left()
	
	countdown_label = canvas.get_node("Puzzle/Countdown")
	countdown_label.visible = true
	display_countdown()
	
	countdown_timer = Timer.new()
	
	countdown_timer.wait_time = 1
	countdown_timer.one_shot = false
	countdown_timer.autostart = true
	add_child(countdown_timer)
	countdown_timer.timeout.connect(display_countdown)
	
func display_countdown() -> void:
	if player_hits_left == 0:
		countdown_label.visible = false
		countdown_timer.queue_free()
		return
	
	time_left -= 1
	if time_left == 0:
		player.death_screen()
	countdown_label.text = str(time_left) + "S"
	
func display_hits_left() -> void:
	if player_hits_left == 0:
		hits_left_label.text = "Level cleared!"
		
		stats.current_health = 0
		set_state(State.DYING)
	else:
		hits_left_label.text = "Hits Left: " + str(player_hits_left)

func handle_timers(delta: float) -> void:
	if teleport_cooldown > 0.0:
		teleport_cooldown -= delta
		
func set_collision(enabled: bool) -> void:
	if enabled:
		collision_layer = 1 << 0 #put CollisionObject on layer 1
		collision_mask = 1 << 0 #detect only layer 1
	else:
		collision_layer = 1 << 1 #put CollisionObject on layer 2
		collision_mask = 1 << 1 #detect only layer 2


func _on_damaged() -> void:
	if is_instance_valid(current_disguise) && current_disguise.stats.damage_taken.is_connected(_on_damaged):
		current_disguise.stats.damage_taken.disconnect(_on_damaged)
	
	player_hits_left -= 1
	display_hits_left()
	
	hurtbox.set_deferred("monitorable", false)
	
	if state != State.TRANSFORMED:
		transformation = true
		
	emit_signal("boss_hit")
	set_state(State.DAMAGED)
	
func _on_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	set_state(State.DYING)

func fade_out(duration: float) -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(reduce_to_gold)

func reduce_to_gold() -> void:	
	stats.drop_item()
	queue_free()

func _on_animated_sprite_2d_animation_finished() -> void:
	match sprite.animation:
		"arise":
			set_state(State.IDLE)

		"damage":
			if transformation:
				set_state(State.DYING)
			else:
				set_state(State.TELEPORTING)

		"death":
			if stats.current_health == 0:
				reduce_to_gold()
			else:
				set_state(State.TRANSFORMED)
				transformation = false
		
		"special_attack":
			set_state(State.IDLE)
		
		"escape_teleport":
			handle_teleport()
			
		"spawn_teleport":		
			set_state(State.IDLE)
