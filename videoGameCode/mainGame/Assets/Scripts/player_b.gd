extends CharacterBody2D

@onready var anim_tree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@export var hitbox_shape : Shape2D
@export var stats : Stats

const DASH_COOLDOWN_TIME = 1.2
const DASH_DURATION_TIME = 0.2


var dash_multiplier = 3.0
var dash_cooldown = 0.0
var dash_timer = 0.0

var max_health = 100.0
var health = 100.0
var speed = 300.0
var damage = 10
var dead = false
var direction: Vector2
var last_dir := Vector2.RIGHT #default
var facing_left = false

enum Facing {UP, DOWN, LEFT, RIGHT}
var player_facing: Facing

var attacking = false
var attacked = false
var dashing = false
var dying = false
var monitorable = true


func _ready():
	anim_tree.active = true
	health = max_health
	stats.set_owner_node(self)
	stats.health_depleted.connect(_on_death)


func _physics_process(delta: float) -> void:
	handle_timers(delta)
	handle_input(delta)


func handle_input(delta: float):
	if player_busy():
		return

	# movement
	direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	
	
	
	anim_tree.set("parameters/Srun/BlendSpace2D/blend_position", direction)
	anim_tree.set("parameters/Sidle/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/Sattack/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/Sdash/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/Sdeath/BlendSpace2D/blend_position", last_dir)

	if Input.is_action_just_pressed("dash") or dashing == true:
		velocity = direction * speed * dash_multiplier
		handle_dash()
		move_and_slide()
		return

	if direction != Vector2.ZERO:
		last_dir = direction
		velocity = direction * speed
		move_and_slide()
		anim_state.travel("Srun")
	else:
		velocity = Vector2.ZERO
		anim_state.travel("Sidle")

	 #combat inputs
	if Input.is_action_just_pressed("attack_basic"):
		handle_attack()
	
		
	




func handle_attack():
	if player_busy():
		return
	anim_state.travel("Sattack")
	var hitbox = hitBox.new(stats, 0.5, hitbox_shape)
	
	add_child(hitbox)
	attacking = true


func handle_dash():
	if dash_cooldown > 0.0 or dashing == true:
		return
	anim_state.travel("Sdash")

	dash_timer = DASH_DURATION_TIME
	dash_cooldown = DASH_COOLDOWN_TIME
	dashing = true


func iframes_on() -> bool:
	return dashing



func handle_timers(delta: float):
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	if dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			dashing = false
			#need to increase speed for dashing

	

func _on_death():
	print("you should be dead")
	dying = true
	anim_state.travel("Sdeath")

#func _set_hitbox_direction():
	#match player_facing:
		#Facing.UP: hitbox.rotation = -PI/2
		#Facing.DOWN: hitbox.rotation = PI/2
		#Facing.LEFT: hitbox.rotation = PI
		#Facing.RIGHT: hitbox.rotation = 0


#func _on_animation_finished(anim_name):
	#if anim_name == "Sattack":
		#attacking = false
		#monitorable = true
	#elif anim_name == "dash":
		#dashing = false
	#
	#
	#anim_state.travel("idle")


func player_busy() -> bool:
	return attacking or dying




#func take_damage(dmg: int) -> void:
	#health -= dmg
	#if health <= 0 and not dead:
		#print("you should be dead")
		#dead = true
		#get_tree().quit()
		#return
	#attacking = false
	#attacked = true
	#monitorable = false
	#anim_state.travel("hit")
	#print("player has been damaged")
	#print("health:", health)





func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("Sdeath"):
		call_deferred("queue_free")
		get_tree().quit()
		
	
	if anim_name.begins_with("Srunattack"):
		print("player has finished attacking")
		attacking = false
		monitorable = true
	anim_state.travel("Sidle")
