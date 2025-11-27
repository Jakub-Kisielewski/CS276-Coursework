extends CharacterBody2D

#if current weapon == SPEAR NO stop spam

@onready var anim_tree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")
@onready var bodyAnim = $bodyAnim
@onready var headAnim = $headAnim
@onready var fullAnim = $fullAnim
@onready var spearAnim = $spearAnim
@onready var bowAnim = $bowAnim
@export var stats : Stats
var hitbox_shape : Shape2D

var canvas : CanvasLayer
var orig_spear_pos : Vector2
var orig_pos : Vector2
const DASH_COOLDOWN_TIME = 1.2
const DASH_DURATION_TIME = 0.2


var dash_multiplier = 3.0
var dash_cooldown = 0.0
var dash_timer = 0.0

var speed = 260.0
var damage = 10
var dead = false
var direction: Vector2
var last_dir := Vector2.RIGHT #default
var facing_left = false

enum Facing {UP, DOWN, LEFT, RIGHT}
var player_facing: Facing

enum Weapon {SWORD, SPEAR, BOW}
var current_weapon: Weapon

var attacking = false
var attacked = false
var dashing = false
var dying = false
var monitorable = true




func _ready():
	anim_tree.active = true
	current_weapon = Weapon.SWORD
	stats.set_owner_node(self)
	stats.health_depleted.connect(_on_death)
	stats.damage_taken.connect(_on_damaged)
	orig_spear_pos = spearAnim.position
	orig_pos = position
	canvas = get_tree().get_first_node_in_group("canvas")


func _physics_process(delta: float) -> void:
	handle_timers(delta)
	handle_input(delta)
	set_keys_facing()
	updateSprite()


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
	
	anim_tree.set("parameters/run/BlendSpace2D/blend_position", direction)
	anim_tree.set("parameters/spattack/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/idle/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/death/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/dash/BlendSpace2D/blend_position", last_dir)
	
	anim_tree.set("parameters/battack/BlendSpace2D/blend_position", last_dir)
	

	if Input.is_action_just_pressed("dash") or dashing == true:
		velocity = direction * speed * dash_multiplier
		handle_dash()
		move_and_slide()
		return

	if direction != Vector2.ZERO:
		last_dir = direction
		velocity = direction * speed
		move_and_slide()
		if current_weapon == Weapon.SPEAR or current_weapon == Weapon.BOW:
			anim_state.travel("run")
		else:
			anim_state.travel("Srun")
	else:
		velocity = Vector2.ZERO
		if current_weapon == Weapon.SPEAR or current_weapon == Weapon.BOW:
			anim_state.travel("idle")
		else:	
			anim_state.travel("Sidle")


	if Input.is_action_just_pressed("change_weapon"):
		weapon_switch()
	 #combat inputs
	if Input.is_action_just_pressed("attack_basic"):
		handle_attack()
	
		
	
	


func updateSprite():
	bowAnim.visible = true #all temp
	if current_weapon == Weapon.SWORD:
		fullAnim.visible = true
		bodyAnim.visible = false
		headAnim.visible = false
		spearAnim.visible = false
		return
		
	if attacking:
		fullAnim.visible = false
		bodyAnim.visible = true
		headAnim.visible = true
		spearAnim.visible = (current_weapon == Weapon.SPEAR)
		
	else:
		fullAnim.visible = true
		bodyAnim.visible = false
		headAnim.visible = false
		spearAnim.visible = false


func weapon_switch():
	
	if current_weapon == Weapon.SWORD:
		current_weapon = Weapon.SPEAR
	elif current_weapon == Weapon.SPEAR: 
		current_weapon = Weapon.BOW
	else:	
		current_weapon = Weapon.SWORD
		
func handle_attack():
	if player_busy():
		return
		
	if current_weapon == Weapon.SWORD:	
		sword_attack()
	elif current_weapon == Weapon.SPEAR:
		spear_attack()
	elif current_weapon == Weapon.BOW:
		bow_attack()
		
	attacking = true
	
	
func set_mouse_facing():
	pass
	
func set_keys_facing():
	if Input.is_action_pressed("move_down"):
		player_facing = Facing.DOWN
	elif Input.is_action_pressed("move_up"):
		player_facing = Facing.UP
	elif Input.is_action_pressed("move_right"):
		player_facing = Facing.RIGHT
	elif Input.is_action_pressed("move_left"):
		player_facing = Facing.LEFT
	
func bow_attack():
	
	anim_state.travel("battack")
	
	
func shoot_arrow(): #triggered at end of battack anim
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	
	var arrow_pre = preload("res://Assets/Scenes/arrow.tscn")
	var arrow = arrow_pre.instantiate()
	
	arrow.global_position = global_position
	arrow.direction = dir
	arrow.attacker_stats = stats
	
	anim_state.travel("battack")
	get_parent().add_child(arrow)

func get_bow_dir(angle):
	pass
	
func spear_attack():
	#offset position of spear sprite
	spearAnim.position = orig_spear_pos
	hitbox_shape = CapsuleShape2D.new()
	hitbox_shape.radius = 5
	hitbox_shape.height = 30
	
	var hitbox = hitBox.new(stats, "None", 0.5, hitbox_shape)
	
	
 #error in animation tree, defaults to attacking to the right
	match player_facing:
		Facing.DOWN:
			spearAnim.position += Vector2(4, 10)
			hitbox.position = spearAnim.position + Vector2(-2, 7) 
			print("attacking down")
		Facing.UP:
			spearAnim.position += Vector2(3,-10)
			hitbox.position = spearAnim.position + Vector2(2, -7) 
			print("attacking up")
		Facing.LEFT:
			hitbox.rotation = PI/2
			spearAnim.position += Vector2(-8,0)
			hitbox.position = spearAnim.position + Vector2(-20, 2) 
			print("attacking left") 
		Facing.RIGHT:
			hitbox.rotation = PI/2
			spearAnim.position += Vector2(12,0)
			hitbox.position = spearAnim.position + Vector2(18, 2) 
			print("attacking right")
			

	
	add_child(hitbox)
	
	anim_state.travel("spattack")
	
func sword_attack():
	
	hitbox_shape = CircleShape2D.new()
	hitbox_shape.radius = 15 
	var hitbox = hitBox.new(stats, "None", 0.5, hitbox_shape) #change hitbox based on weapon later

	match player_facing:
		Facing.DOWN:
			hitbox.position = fullAnim.position + Vector2(0, 10) 
			print("attacking down")
		Facing.UP:
			hitbox.position = fullAnim.position + Vector2(0, -10) 
			print("attacking up")
		Facing.LEFT:
			hitbox.position = fullAnim.position + Vector2(-10, 0) 
			print("attacking left")
		Facing.RIGHT:
			hitbox.position = fullAnim.position + Vector2(10, 0) 
			print("attacking right")
	print(hitbox.position)
	add_child(hitbox)
	anim_state.travel("Sattack")
	
	
	

	


func handle_dash():
	if dash_cooldown > 0.0 or dashing == true:
		return
		
	if current_weapon == Weapon.SPEAR:
		anim_state.travel("dash")
	else:
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
	
	if current_weapon == Weapon.SPEAR:
		anim_state.travel("death")
	else:
		anim_state.travel("Sdeath")
	
func _on_damaged():

	canvas.get_node("Control/Health").text = str(stats.current_health)




func player_busy() -> bool:
	return attacking or dying



func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("Sdeath") or anim_name.begins_with("death"):
		call_deferred("queue_free")
		get_tree().quit()
		
	if anim_name.begins_with("bbody"):
		print("shooting arrow")
		shoot_arrow()
	
	#anim_name is the name inside the animation player
	if anim_name.begins_with("Srunattack") or anim_name.begins_with("spbody") or anim_name.begins_with("bbody") or anim_name.begins_with("battack"):
		print("player has finished attacking")
		attacking = false
		monitorable = true
		
	if current_weapon == Weapon.SPEAR or current_weapon == Weapon.BOW:
		anim_state.travel("idle")
	else:
		anim_state.travel("Sidle")
