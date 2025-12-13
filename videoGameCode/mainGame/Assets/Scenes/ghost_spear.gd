class_name ghostSpear extends CharacterBody2D

@export var weapon_data: WeaponData
@export var speed: float = 200.0
@export var detection_dist: float = 250.0
@export var attack_range: float = 0.6
@export var life_time: float = 10.0 #can increase this based on rarity later

var orbit_radius : float = 32.0
var speed_div: float = 500.0

@onready var anim: AnimatedSprite2D = $gspAnim
@onready var fx: AnimatedSprite2D = $gspEffects

var owner_player: Node = null
var current_target: Node2D = null

enum State {IDLE, SEEK, ATTACK, RETURN}
var current_state: State = State.IDLE

var attack_cooldown: float = 0.0
var life_timer: float = 0.0
var attacking : bool = false
var closest: Node2D = null
signal returned_to_owner

func _ready() -> void:
	life_timer = life_time
	
	
func _physics_process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		queue_free()
		return
	
	
	update_sprite()
	
	if life_timer > 0.0:
		life_timer -= delta
	else:
		current_state = State.RETURN
		
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	fx.visible = true
	match current_state:
		
		State.IDLE:
			fx.visible = false
			pick_target_or_orbit(delta)
		State.SEEK:
			seek_target(delta)
			
			fx.play("gsp_spinny")
			
		State.ATTACK:
			try_attack(delta)
		State.RETURN:
			return_to_owner(delta)
			
func pick_target_or_orbit(delta: float) -> void:
	if owner_player == null:
		queue_free()
		return
	
	var closest:  Node2D = null
	var closest_loci : float = detection_dist * detection_dist
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy is Node2D:
			continue
		var dist_sq = owner_player.global_position.distance_squared_to(enemy.global_position)
		if dist_sq < closest_loci:
			closest_loci = dist_sq
			closest = enemy
				
	if closest != null:
		current_target = closest
		current_state = State.SEEK
		
	else:
		var orbit_offset : Vector2 = Vector2(64, 0).rotated(Time.get_ticks_msec()/ 10000)
		var target_pos : Vector2 = owner_player.global_position + orbit_offset
		move_towards(target_pos, speed * 0.7, delta)
	
	
func get_orbit_offset(radius: float) -> Vector2:
	var angle : float = Time.get_ticks_msec() / speed_div
	return Vector2(radius, 0).rotated(angle)
		
	
	
func move_towards(target_pos: Vector2, speed: float, delta: float) -> void:
	var dir : Vector2 = target_pos - global_position
	var dir_norm = dir.normalized()
	if dir.length() < 12.0:
		velocity = dir_norm * speed * 0.5

	velocity = dir_norm * speed
	move_and_slide()
	
	#if current_state == State.SEEK:
		#rotation = dir.angle()
	
	
	anim.play("idle")
	if current_state == State.SEEK or current_state == State.ATTACK:
		anim.rotate(dir.angle()) #ITS YOUUUU YOURE THE ONE
	
func seek_target(delta: float) -> void:
	
	var target := current_target
	if target == null or not is_instance_valid(target):
		current_target = null
		current_state = State.IDLE
		return
		
	var dist: float = global_position.distance_to(target.global_position)
	
	if dist > detection_dist:
		current_target = null
		current_state = State.IDLE
		
	if dist > attack_range:
		move_towards(target.global_position, speed, delta)
	else:
		current_state = State.ATTACK
	

func try_attack(delta) -> void:
	
	if attacking or attack_cooldown > 0.0:
		return

	attacking = true
	attack_cooldown = attack_cooldown
	
	if current_target != null and is_instance_valid(current_target):
		var dir : Vector2 = (current_target.global_position - global_position).normalized()
		var ang : float = dir.angle()
		var target_pos: Vector2 = get_orbit_offset(orbit_radius)
		move_towards(target_pos, speed, delta)
		#rotation = ang

	anim.play("attack")
	fx.play("attack")
	
	spawn_hitbox()
	
func vec_to_target() -> Vector2:
	if current_target != null and is_instance_valid(current_target):
		return current_target.global_position - global_position
	return Vector2(0,0)
	
	
func update_sprite():
	if current_state == State.SEEK:
		fx.visible == true	
	
	if current_state == State.ATTACK:
		
		fx.visible = true
		fx.rotation = vec_to_target().angle()
		
		var forward : Vector2 = Vector2.RIGHT.rotated(rotation - PI/2)
		var offset :  Vector2 = forward * -20
		fx.position = offset

	
func spawn_hitbox():
	var shape: Shape2D = CircleShape2D.new()
	
	shape.radius = 6.0
	
	var hitbox = hitBox.new(owner_player, GameData.damage, "None", 0.5, shape, weapon_data)
	
	var forward : Vector2 = Vector2.RIGHT.rotated(rotation)
	var offset :  Vector2 = forward * 20
	
	hitbox.position = offset
	add_child(hitbox)
	

func return_to_owner(delta: float):
	if owner_player == null:
		queue_free()
		return
	
	var dist: float = global_position.distance_to(owner_player.global_position)
	
	if dist < 12.0:
		emit_signal("returned_to_owner")
		queue_free()
		return
		
	move_towards(owner_player.global_position, speed * 1.5, delta)

func _on_gsp_anim_animation_finished() -> void:
	if anim.animation == "attack":
		attacking = false
		
	if current_target != null and is_instance_valid(current_target):
		current_state = State.SEEK
	else:
		current_state = State.IDLE
	
