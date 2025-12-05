class_name ghost_spear extends CharacterBody2D

@export var attacker_stats: Stats
@export var weapon_data: WeaponData
@export var speed: float = 200.0
@export var detection_dist: float = 250.0
@export var attack_range: float = 0.6
@export var life_time: float = 6.0 #can increase this based on rarity later

@onready var anim: AnimatedSprite2D = $gspAnim

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
	if life_timer > 0.0:
		life_timer -= delta
	else:
		current_state = State.RETURN
		
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
		
	match current_state:
		State.IDLE:
			pick_target_or_orbit(delta)
		State.SEEK:
			seek_target(delta)
		State.ATTACK:
			try_attack()
		State.RETURN:
			return_to_owner(delta)
			
func pick_target_or_orbit(delta: float) -> void:
	if owner_player == null:
		queue_free()
		return
	
	
	var detection_loci = detection_dist * detection_dist 
	var dist_sq : float
	var closest_dist: float
	var target_pos : Vector2
	
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy is Node2D:
			continue
		dist_sq = owner_player.global_position.distance_squared_to(enemy.global_position)
		if dist_sq < detection_loci:
			if dist_sq < closest_dist:
				closest_dist = dist_sq
				closest = enemy
				
	if closest != null:
		current_state = State.SEEK
		target_pos = closest.global_position
	else:
		target_pos = owner_player.global_position + Vector2(32,0)
	
	move_towards(target_pos, speed, delta)
	
func move_towards(target_pos: Vector2, speed: float, delta: float) -> void:
	var dir : Vector2
	dir = (target_pos - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	anim.play("idle")
	anim.rotate(dir.angle())
	
func seek_target(delta: float) -> void:
	if current_target == null:
		current_state = State.IDLE
	

	var dist: float = owner_player.global_position.distance_to(current_target.global_position)
	
	
	if dist > detection_dist:
		current_state = State.IDLE
		
	if dist < 5.0:
		current_state = State.ATTACK
	else:
		move_towards(current_target.global_position, speed, delta)
		
	
	
func try_attack() -> void:
	pass
	
func return_to_owner(delta: float):
	pass
	
func spawn_hitbox():
	pass
	
	
		
