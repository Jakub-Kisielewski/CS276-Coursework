extends EnemyEntity

@onready var wiz_sfx = $wizSfx

@export var wiz_sounds : Array[AudioStream] = [] #0: teleport, 1: death

# Get the reference to the player node
@onready var player : Node = get_tree().get_first_node_in_group("player")

@export var nav: NavigationAgent2D
@export var hitbox_shape : Shape2D
@export var summons : Array[PackedScene]

var rng : RandomNumberGenerator = RandomNumberGenerator.new()
var tilemap : TileMapLayer
var hurtbox : HurtBox

# References to UI elements used to display minigame info
var countdown_label : Label
var countdown_timer : Timer
var hits_left_label : Label

# Minigame info
var time_left : int
var player_hits_left : int # Number of hits player must land on enemy

# Details about the teleport move
const TELEPORT_COOLDOWN_TIME : float = 1.6
var teleport_cooldown : float = 0.0

# Details about the wizard transforming into another enemy, ie a disguise
var transformation : bool = false
var current_disguise : Node

@export var speed : float = 80.0

# Details about the enemy's current state
enum State { ARISING, IDLE, TELEPORTING, TRANSFORMED, DAMAGED, DYING }
var state : State = State.IDLE
signal state_changed
signal boss_hit

# Change the state of the enemy
func set_state(new_state : State) -> void:
	state = new_state
	state_changed.emit()
	
	match state:
		# Enemy is spawning in
		State.ARISING:
			hurtbox.set_deferred("monitorable", false)
			velocity = Vector2.ZERO
			sprite_base.play("arise")
		#Enemy is idle
		State.IDLE:
			hurtbox.set_deferred("monitorable", true)
			set_collision(true)
			velocity = Vector2.ZERO
			sprite_base.play("idle")
		# Enemy is moving teleporting
		State.TELEPORTING:
			hurtbox.set_deferred("monitorable", false)
			velocity = Vector2.ZERO
			sprite_base.play("escape_teleport")
			wiz_sfx.stream = wiz_sounds[0]
			wiz_sfx.play()
		# Enemy transforming into another enemy
		State.TRANSFORMED:
			hurtbox.set_deferred("monitorable", false)
			set_collision(false)
			handle_transformation()
		State.DAMAGED:
			velocity = Vector2.ZERO
			sprite_base.play("damage")
		State.DYING:	
			velocity = Vector2.ZERO
			sprite_base.play("death")
			wiz_sfx.stream = wiz_sounds[1]
			wiz_sfx.play()

func _ready() -> void:
	super._ready()
	
	setup_countdown_timer()
	rng.randomize()

	tilemap = get_tree().get_first_node_in_group("tilemap")
	hurtbox = get_node("AnimatedSprite2D/hurtBox")

	set_state(State.ARISING)

func _physics_process(delta: float) -> void:
	#Handle the timer for teleporting
	handle_timers(delta)

	#If the player disappears, make the enemy idle
	if (!is_instance_valid(player) or !player.is_in_group("player")) and state != State.IDLE:
		set_state(State.IDLE)
		
	match state:
		State.ARISING: return
		# Remain stationary until teleport cooldown is over
		State.IDLE:
			if teleport_cooldown <= 0:
				set_state(State.TELEPORTING)
		State.TELEPORTING: return
		
		# Ensure wizard follows its disguise
		State.TRANSFORMED:
			if is_instance_valid(current_disguise):
				global_position = current_disguise.global_position
		# Do nothing physics-related if the enemy is DAMAGED or DYING	
		State.DAMAGED: return
		State.DYING: return

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

func handle_move():	
	sprite_base.play("move")

func handle_transformation() -> void:
	teleport_cooldown = TELEPORT_COOLDOWN_TIME
		
	# Get every point on the tilemap
	var map_rid : RID = get_world_2d().get_navigation_map() 
	var cells : Array[Vector2i] = tilemap.get_used_cells()
	
	# Get the points that are close to the player
	var filtered_cells: Array[Vector2i] = []
	for cell in cells:
		var world_pos = tilemap.map_to_local(cell)
		if world_pos.distance_to(player.global_position) <= 700:
			filtered_cells.append(cell)

	# If no cells are in the radius, fall back to original list
	if filtered_cells.is_empty():
		filtered_cells = cells
	
	# Choose the number of enemies to spawn
	var n : int = rng.randi_range(2, 4)  # like a dice roll
	
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
		boss_hit.connect(new_enemy._on_boss_death)
		
		if i == 0:
			# Set the current spawned enemy to be the wizard's disguise
			current_disguise = new_enemy
			
			# When the spawned enemy is hit, the wizard is also hit and then revealed
			new_enemy.health_component.damage_taken.connect(_on_damaged)

func handle_teleport() -> void:
	teleport_cooldown = TELEPORT_COOLDOWN_TIME

	#Place the wizard at a random navigable point
	var cells : Array[Vector2i] = tilemap.get_used_cells()

	# Get the points that are close to the player
	var filtered_cells: Array[Vector2i] = []
	for cell in cells:
		var world_pos = tilemap.map_to_local(cell)
		if world_pos.distance_to(player.global_position) <= 700:
			filtered_cells.append(cell)

	# If no cells are in the radius, fall back to original list
	if filtered_cells.is_empty():
		filtered_cells = cells
	
	var x : int = rng.randi_range(0, filtered_cells.size()-1)  # like a dice roll
	var target_point : Vector2 = tilemap.map_to_local(filtered_cells[x])

	var map_rid : RID = get_world_2d().get_navigation_map() 
	var closest_point : Vector2 = NavigationServer2D.map_get_closest_point(map_rid, target_point) 
	global_position = closest_point
	
	sprite_base.play("spawn_teleport")
	wiz_sfx.stream = wiz_sounds[0]
	wiz_sfx.play()

func setup_countdown_timer() -> void:
	player_hits_left = 6
	time_left = 60

	var canvas : CanvasLayer = get_tree().get_first_node_in_group("canvas")
	
	# Get references to necessary labels
	hits_left_label = canvas.get_node("UiRoom/Puzzle/HitsLeft")
	hits_left_label.visible = true
	hits_left_label.text = "Land 6 hits on the Wizard"
	
	countdown_label = canvas.get_node("UiRoom/Puzzle/Countdown")
	countdown_label.visible = true
	display_countdown()
	
	countdown_timer = Timer.new()
	
	# Set up the timer to display the time left every second
	countdown_timer.wait_time = 1
	countdown_timer.one_shot = false
	countdown_timer.autostart = true
	add_child(countdown_timer)
	countdown_timer.timeout.connect(display_countdown)
	
func display_countdown() -> void:
	if player_hits_left == 0:
		# Player has won, end countdown
		countdown_label.visible = false
		countdown_timer.queue_free()
		return
	
	time_left -= 1
	if time_left == 0:
		# Player has lost, play death screen
		player.death_screen()
	countdown_label.text = str(time_left) + "s"
	
func display_hits_left() -> void:
	if player_hits_left == 0:
		# Player has won
		hits_left_label.text = "Level cleared!"
		
		if health_component:
			# Execute the wizard (bypasses invicibility of wizard)
			health_component.take_damage(health_component.max_health, "Execution")
	else:
		hits_left_label.text = "Hits Left: " + str(player_hits_left)

func handle_timers(delta: float) -> void:
	# Decrement the teleport cooldown
	if teleport_cooldown > 0.0:
		teleport_cooldown -= delta

# Ensube or disable collisions
func set_collision(enabled: bool) -> void:
	if enabled:
		collision_layer = 1 << 0 #put CollisionObject on layer 1
		collision_mask = 1 << 0 #detect only layer 1
	else:
		collision_layer = 1 << 1 #put CollisionObject on layer 2
		collision_mask = 1 << 1 #detect only layer 2

# Triggered when enemy takes damage	
func _on_damaged(amount, type) -> void:
	super._on_damaged(amount, type)
	
	# Disconnect the wizard from its disguise
	if is_instance_valid(current_disguise):
		if current_disguise.health_component.damage_taken.is_connected(_on_damaged):
			current_disguise.health_component.damage_taken.disconnect(_on_damaged)
	
	player_hits_left -= 1
	display_hits_left()
	
	hurtbox.set_deferred("monitorable", false)
	
	# If teleporting, the enemy will now transform
	if state != State.TRANSFORMED:
		transformation = true
	
	# Signal causes all summons to die
	emit_signal("boss_hit")
	set_state(State.DAMAGED)

# Triggered when enemy dies	
func _on_death() -> void:
	hurtbox.set_deferred("monitorable", false)
	set_state(State.DYING)

# Make the enemy fade until it disappears, then drop gold
func fade_out(duration: float) -> void:
	var tween : Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(reduce_to_gold)

func _on_animated_sprite_2d_animation_finished() -> void:
	match sprite_base.animation:
		"arise":
			set_state(State.IDLE)

		"damage":
			if transformation:
				set_state(State.DYING)
			else:
				set_state(State.TELEPORTING)

		"death":
			if health_component.current_health <= 0:
				reduce_to_gold()
			elif transformation:
				# The enemy transforms
				set_state(State.TRANSFORMED)
				transformation = false
		
		"special_attack":
			set_state(State.IDLE)
		
		"escape_teleport":
			handle_teleport()
			
		"spawn_teleport":		
			set_state(State.IDLE)
