extends CharacterBody2D

@onready var anim_tree = $AnimationTree
@onready var anim_state = anim_tree.get("parameters/playback")

@onready var bodyAnim = $bodyAnim
@onready var headAnim = $headAnim
@onready var fullAnim = $fullAnim
@onready var spearAnim = $spearAnim
@onready var bowAnim = $bowAnim

@onready var spearEffects = $spearEffects
@onready var weaponEffects = $weaponEffects
@onready var bodyEffects = $bodyEffects
@onready var bowEffects = $bowEffects
@onready var bowEffects2 = $bowEffectslay2
@onready var bodyEffects2 = $bodyEffectlay2

var decoy_scene := preload("res://Assets/Scenes/decoy.tscn")
var decoy_cooldown : float = 8.5
var decoy_timer : float = 0.0

var canvas : CanvasLayer
var health_bar : Label
var currency_label : Label
var camera : Camera2D

var swordArc := preload("res://Assets/Scenes/sword_arc.tscn")
var hitbox_shape : Shape2D

var ghostSpear := preload("res://Assets/Scenes/ghost_spear.tscn")
var SPEAR_GHOST_COOLDOWN : float = 15.0
var spear_ghost_timer : float = 0.0
var spear_ghost_ready : bool = true
var spear_ghost_active : bool = false

var orig_spear_pos : Vector2
var orig_pos : Vector2
const DASH_COOLDOWN_TIME = 1.2
const DASH_DURATION_TIME = 0.2
var dash_through_enemies : bool = true #set to true if you want to be able to dash through enemies

var dash_multiplier = 2.0
var dash_cooldown = 0.0
var dash_timer = 0.0
var max_dashes := 3
var dashes = max_dashes
var dashing = false
var speed = 260.0
var damage = 10
var dead = false
var direction: Vector2
var last_dir := Vector2.RIGHT #default
var facing_left = false

enum Facing {UP, DOWN, LEFT, RIGHT, RIGHT_UP, RIGHT_DOWN, LEFT_UP, LEFT_DOWN}
var player_facing: Facing

@export var sword_data: WeaponData
@export var spear_data: WeaponData
@export var bow_data: WeaponData

enum Weapon {SWORD, SPEAR, BOW}
var current_weapon: Weapon
var current_weapon_data: WeaponData

var attacking = false
var attacked = false
var stunned_status : bool = false
var special_charging: bool = false
var special_hold_time : float = 0.0
const SPECIAL_HOLD_TIME : float = 0.4 #wind up the attack for  second cuz op
var charging_successful : bool = false
var switch_activated: bool = false #bow switch special attack
var shotgun_activated : bool = false #other bow attack
var trying_shotgun = true #true -> shotgun switch, false -> auto switch

var dying = false
var monitorable = true

var mouse_aiming = true #set this to true if you want to aim with mouse

func _ready():
	$HealthComponent.status_changed.connect(_on_status_changed)
	$HealthComponent.health_changed.connect(_on_health_changed)
	$HealthComponent.health_depleted.connect(_on_death)
	GameData.currency_updated.connect(_on_currency_updated)
	
	anim_tree.active = true
	current_weapon = Weapon.SWORD
	current_weapon_data = sword_data
	
	orig_spear_pos = spearAnim.position
	orig_pos = position
	
	bowEffects2.visible = false
	
	canvas = get_tree().get_first_node_in_group("canvas")
	
	camera = get_tree().get_first_node_in_group("camera")
	update_camera()


func _physics_process(delta: float) -> void:
	handle_timers(delta)
	handle_input(delta)
	updateSprite()
	update_camera()
	attacking_speed_test()
	
	#print("current node:", anim_state.get_current_node())

func _on_status_changed(new_status):
	var target_colour: Color = Color.WHITE
	match new_status:
		0: # HEALTHY
			target_colour = Color.WHITE
		1: # POISONED
			target_colour = Color("#ffacff")
		2: # DAMAGED
			_flash_damage()
			return
		3: # OVERHEATING
			target_colour = Color("f5a3b0")
	
	_apply_sprite_color(target_colour)

# helper to color correct active sprites
func _apply_sprite_color(color: Color):
	if current_weapon == Weapon.SWORD:
		fullAnim.modulate = color
	else:
		bodyAnim.modulate = color
		headAnim.modulate = color
		spearAnim.modulate = color
		bowAnim.modulate = color

func _flash_damage():
	var flash_color: Color = Color("f5a3b0")
	_apply_sprite_color(flash_color)
	
	# tween back to current status colour after 0.2s
	var tween = create_tween()
	tween.tween_interval(0.2)
	tween.tween_callback(func(): 
		# ask component what status is now in case we are still poisoned
		_on_status_changed($HealthComponent.status)
)

#use this for movement
func get_movement_direction() -> Vector2:
	direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	
	return direction

#DO NOT USE THIS FOR MOVEMENT, instead use for attack directions, 
func get_nonzero_movement_direction() -> Vector2:
	direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()
	
	if direction == Vector2.ZERO:
		return last_dir
	
	return direction


func handle_input(delta: float):
	
	
	if (stunned_status):
		bodyEffects2.global_position = global_position
		anim_state.travel("hurt")
		return
	
	
	if Input.is_action_just_pressed("attack_special"):
		
		if current_weapon == Weapon.SWORD and not player_busy():
			print("sword charge anim start")
			anim_state.travel("Scharge")
		elif current_weapon == Weapon.BOW:
			anim_state.travel("bcharge")
		elif current_weapon == Weapon.SPEAR:
			anim_state.travel("spattack")
			
		special_charging = true
		special_hold_time = 0.0
		charging_successful = false
			
			#need charging animation and some piza
		
	if special_charging:
		special_hold_time += delta
		
		if special_hold_time >= SPECIAL_HOLD_TIME:
			charging_successful = true
			print("charging successful", charging_successful)
		
		
		
	if Input.is_action_just_released("attack_special"):
		
		if charging_successful:
			special_charging = false
			special_hold_time = 0.0
			charging_successful = false
			if current_weapon == Weapon.SWORD:
				sword_special_attack()
					
				print("i call on you sword")
			elif current_weapon == Weapon.BOW:
				if trying_shotgun:
					shotgun_activated = true
				else:
					switch_activated = true
				bow_attack()
			elif current_weapon == Weapon.SPEAR:
				spear_special_attack()
				print("i call on you spear")
		else:
			special_charging = false
			special_hold_time = 0.0
			charging_successful = false
			if current_weapon == Weapon.SPEAR or current_weapon == Weapon.BOW:
				anim_state.travel("idle")
				print("IDLE IDLE IDLE IDLE")
			else: 
				anim_state.travel("Sidle")
				print("SIDLE SIDLE SIDLE SIDLE")
		
	
	# movement
	var direction : Vector2
	direction = get_movement_direction()
	velocity = direction * speed
	if mouse_aiming:
		set_mouse_facing()
	else:
		set_keys_facing(direction)
	
	
	if player_busy():# or special_charging:
		move_and_slide()
		return

	
	var motion_facing : Facing = set_player_facing(get_nonzero_movement_direction()) #used for dash animation so he dashes in direction of movement didnt work
	# movement
	anim_tree.set("parameters/Srun/BlendSpace2D/blend_position", direction)
	anim_tree.set("parameters/Sidle/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/Sattack/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/Sdash/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/Sdeath/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/Scharge/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/Srelease/BlendSpace2D/blend_position", last_dir)
	
	anim_tree.set("parameters/run/BlendSpace2D/blend_position", direction)
	anim_tree.set("parameters/spattack/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/idle/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/death/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/dash/BlendSpace2D/blend_position", last_dir)
	
	anim_tree.set("parameters/battack/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/bcharge/BlendSpace2D/blend_position", last_dir)
	anim_tree.set("parameters/hurt/BlendSpace2D/blend_position", last_dir)

	if Input.is_action_just_pressed("dash"):
		handle_dash() 
		
	if dashing:
		velocity = direction * speed * dash_multiplier
		move_and_slide()
		return

	if direction != Vector2.ZERO:
		#last_dir = direction
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
	
	#handle e input for decoy,brbrbr
	if Input.is_action_just_pressed("use_item"):
		if decoy_timer <= 0.0:
			throw_decoy()
		else:
			print("decoy on cooldown!")
	
func update_camera() -> void:
	camera.global_position = global_position
	
func attacking_speed_test():
	if attacking:
		speed = 150.0
	elif special_charging:
		speed = 50.0
	else:
		speed = 250.0
		
		
	
func set_player_facing(vec: Vector2) -> Facing:
	if vec == Vector2.ZERO:
		return player_facing
		
	var angle = vec.angle()
	
	var deg = rad_to_deg(angle)
	 #may need to reverse UP and DOWN, check first, we do need to reverse UP and DOWN
	if deg > -22.5 and deg <= 22.5:
		last_dir = Vector2.RIGHT
		#print("right")
		return Facing.RIGHT
	elif deg > 22.5 and deg <= 67.5:
		
		
		last_dir = Vector2.RIGHT
		#print("right down")
		return Facing.RIGHT_DOWN
	elif deg > 67.5 and deg <= 112.5:
		last_dir = Vector2.DOWN
		#print("down")
		return Facing.DOWN
	elif deg > 112.5 and deg <= 157.5:
		last_dir = Vector2.LEFT
		#print("left down")
		return Facing.LEFT_DOWN
	elif deg > 157.5 or deg <= -157.5:
		last_dir = Vector2.LEFT
		#print("left")
		return Facing.LEFT
	elif deg > -157.5 and deg <= -112.5:
		last_dir = Vector2.LEFT
		#print("left up")
		return Facing.LEFT_UP
	elif deg > -112.5 and deg <= -67.5:
		last_dir = Vector2.UP
		#print("up")
		return Facing.UP
	elif deg > -67.5 and deg <= -22.5:
		last_dir = Vector2.RIGHT
		#print("right up")
		return Facing.RIGHT_UP
		
	print("set_player_facing: null return")
	return Facing.RIGHT
	


func updateSprite():
	var in_action : bool = special_charging or attacking or charging_successful
	
	fullAnim.visible = false
	bodyAnim.visible = false
	headAnim.visible = false
	spearAnim.visible = false
	bowAnim.visible = false
	
	spearEffects.visible = false
	weaponEffects.visible = false
	bodyEffects.visible = false
	bowEffects.visible = false
	
	
	match current_weapon:
		
		Weapon.SWORD:
			fullAnim.visible = true
			bodyEffects.visible = in_action

		Weapon.SPEAR:
			spearAnim.visible = true
			bodyAnim.visible = true
			headAnim.visible = true
			if in_action:
				spearEffects.visible = true
				weaponEffects.visible = true
			offset_spear_nonattacking()
			
				
		Weapon.BOW:
			
			bowAnim.visible = true
			bodyAnim.visible = true
			headAnim.visible = true
			#bowEffects2.visible = shotgun_activated
			if in_action:	
				bowEffects.visible = true
			offset_bow()
			
				
		_:
			print("updateSprite: null weapon")
				
	#print("in action", in_action)
	bodyEffects2.visible = stunned_status
	
func offset_spear_nonattacking():
	if attacking:
		return
		
	#var motion_facing : Facing = set_player_facing(get_nonzero_movement_direction()) 
		
	match player_facing:
		Facing.DOWN:
			spearAnim.rotation = PI/2
			spearAnim.position = Vector2(0,0)
		Facing.UP:
			spearAnim.rotation = -PI/2
			spearAnim.position = Vector2(0,0)
		Facing.LEFT:
			spearAnim.rotation = -PI
			spearAnim.position = Vector2(0,8)
		Facing.RIGHT:
			spearAnim.rotation = 0
			spearAnim.position = Vector2(0,0)
		

func offset_bow():
	match player_facing:
		Facing.DOWN:
			bowAnim.position = Vector2(-4,3) 
		Facing.UP:
			bowAnim.position = Vector2(2,3) 
		Facing.LEFT:
			bowAnim.position = Vector2(-2,2) 
		Facing.RIGHT:
			bowAnim.position = Vector2(4, 2)
			
	bowEffects.position = bowAnim.position

func weapon_switch():
	
	if current_weapon == Weapon.SWORD:
		current_weapon = Weapon.SPEAR
		current_weapon_data = spear_data
	elif current_weapon == Weapon.SPEAR: 
		current_weapon = Weapon.BOW
		current_weapon_data = bow_data
	else:	
		current_weapon = Weapon.SWORD
		current_weapon_data = sword_data
		
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
	
	
func get_movement_angle() -> float:
	return 	rad_to_deg(get_nonzero_movement_direction().angle())	
	
func get_mouse_vec() -> Vector2: 
	var mouse_pos = get_global_mouse_position()
	var aim_vec = mouse_pos - global_position
	
	return aim_vec
	
func get_mouse_angle() -> float: 
	var aim_vec = get_mouse_vec()
	var aim_angle = aim_vec.angle()
	var deg = rad_to_deg(aim_angle)
	return deg
	
func set_mouse_facing():
	var aim_vec = get_mouse_vec()
	player_facing = set_player_facing(aim_vec)
	
func set_keys_facing(direction : Vector2):
	player_facing = set_player_facing(direction)
	
func bow_attack():
	attacking = true
	var deg : float
	if mouse_aiming:
		deg = rad_to_deg(get_mouse_angle())
	else:
		deg = get_movement_angle()


	#may need to offset bow position, use matching for that
	match player_facing:
		Facing.DOWN:
			print("attacking down")
		Facing.UP:
			print("attacking up")
		Facing.LEFT:
			print("attacking left") 
		Facing.RIGHT:
			print("attacking right")
			
	
	bowAnim.rotation = deg
	
	bowEffects.position = bowAnim.position
	bowEffects.rotation = bowAnim.rotation
	bowEffects.play("brelease")
	
	if (switch_activated):
		
		var arrows : float = 10.0
		var duration : float = 1.0
		bow_brrr(arrows, duration)
	elif (shotgun_activated):

		var arrows : float = 10.0
		var duration : float = 0.5
		shattering_bow(arrows, duration)
	else:
		anim_state.travel("battack")
		
		
func bow_brrr(total_arrows: int, duration: float):
	var gap : float = duration / total_arrows #control the fire rate 
	
	for i in range(total_arrows):
		shoot_arrow()
		
		await get_tree().create_timer(gap).timeout
		
		
	
	cancel_attack()
		
	
		
func shattering_bow(total_arrows: int, duration: int):
	if total_arrows <= 0:
		return
	var spread_deg = 40.0
	var gap :float = duration / total_arrows
	
	var base_angle: float
	if mouse_aiming:
		base_angle = deg_to_rad(get_mouse_angle())
	else:
		base_angle = deg_to_rad(get_movement_angle())
		
	for i in range(total_arrows):
		var t: float
		if total_arrows == 1:
			t = 0.0
		else:
			
			t = lerp(-1.0, 1.0, float(i)/float(total_arrows-1))
		
		var angle_offset : float = deg_to_rad(spread_deg) * t
		var angle : float = base_angle + angle_offset
		
		var dir: Vector2 = Vector2.RIGHT.rotated(angle)
		shoot_arrow(dir)
		
	bowEffects2.visible = true
	bowEffects2.position = bowAnim.position
	bowEffects2.rotation = bowAnim.rotation
	bowEffects2.play("brelease")
	cancel_attack()
		
		
func cancel_attack():
	attacking = false
	monitorable = true
	switch_activated = false
	shotgun_activated = false
		
		
	if current_weapon == Weapon.SPEAR or current_weapon == Weapon.BOW:
		anim_state.travel("idle")
	else:
		anim_state.travel("Sidle")

	
func shoot_arrow(dir: Vector2 = Vector2.ZERO): #triggered at end of battack anim
	if dir == Vector2.ZERO:
		
		if mouse_aiming:
			dir = get_mouse_vec().normalized()
		else:
			dir = get_nonzero_movement_direction()
	
	var arrow_pre = preload("res://Assets/Scenes/arrow.tscn")
	var arrow = arrow_pre.instantiate()
	
	arrow.global_position = global_position
	arrow.direction = dir.normalized()
	arrow.attacker = self
	arrow.base_damage = GameData.damage
	
	arrow.weapon_data = bow_data
	
	get_parent().add_child(arrow)
	print("shot arrow mhm")
	

func get_bow_dir(angle):
	pass
	

func spear_attack():
	#offset position of spear sprite

	spearAnim.position = orig_spear_pos
	spearEffects.position = orig_spear_pos
	hitbox_shape = CapsuleShape2D.new()
	hitbox_shape.radius = 5
	hitbox_shape.height = 70
	
	var hitbox = hitBox.new(self, GameData.damage, "None", 0.5, hitbox_shape, current_weapon_data)
	
	var forward : Vector2
	var hitbox_dist := 20.0
	var aim_angle : float
	var fx_offset : Vector2
	var fx_rotation: float
	var fx_dist := 40.0
	#need to add when player not prssing anything, resort to last dir and put hitbox there
	if mouse_aiming:
		aim_angle = deg_to_rad(get_mouse_angle())
		forward = get_mouse_vec()
	else:
		aim_angle = deg_to_rad(get_movement_angle())
		forward = get_movement_direction()
	
		
	
	#CLEAN UP LATER 
	match player_facing:
		Facing.DOWN:
			spearAnim.position += Vector2(4, 10)
			
			aim_angle -= PI/2
			print("attacking down")
		Facing.UP:
			spearAnim.position += Vector2(3,-10)
			aim_angle += PI/2
			fx_rotation = PI
			print("attacking up")
		Facing.LEFT:

			spearAnim.position += Vector2(-8,0)
			aim_angle +=  PI
			fx_rotation = PI/2
			print("attacking left") 
		Facing.RIGHT:

			spearAnim.position += Vector2(12,0)
			fx_offset = Vector2(40,0)
			fx_rotation = -PI/2
			
			print("attacking right")
			
		Facing.RIGHT_UP:
			

			spearAnim.position += Vector2(12,-6)
			
			spearAnim.rotation = deg_to_rad(get_mouse_angle())
			fx_rotation = -PI/2
			print("hitbox rotation: ", hitbox.rotation)
			print("spear rotation: ", spearAnim.rotation)
			print("attacking right up")
			
		Facing.RIGHT_DOWN:
			

			spearAnim.position += Vector2(12,0)

			spearAnim.rotation = deg_to_rad(get_mouse_angle())
			fx_rotation = -PI/2
			print("hitbox rotation: ", hitbox.rotation)
			print("spear rotation: ", spearAnim.rotation)
			print("attacking right down")
			
		Facing.LEFT_UP:

			spearAnim.position += Vector2(-12,-6)

			aim_angle += PI
			fx_rotation = PI/2
			print("hitbox rotation: ", hitbox.rotation)
			print("spear rotation: ", spearAnim.rotation)
			print("attacking left up")
		Facing.LEFT_DOWN:	
			spearAnim.position += Vector2(-8,0)
			aim_angle +=  PI
			fx_rotation = PI/2
			print("hitbox rotation: ", hitbox.rotation)
			print("spear rotation: ", spearAnim.rotation)
			print("attacking left down")
			
	hitbox.rotation = aim_angle + PI/2 #need to not orthoganlise vectors when player attacking up/down
	
	spearAnim.rotation = aim_angle
	spearEffects.position = spearAnim.position + forward.normalized() * fx_dist 
	spearEffects.rotation = spearAnim.rotation + fx_rotation
	
	weaponEffects.position = spearEffects.position - forward.normalized() * 10.0 
	weaponEffects.rotation = spearEffects.rotation
	
	#var offset := Vector2(32, 0)
	#spearEffects.position += offset.rotated(spearAnim.rotation)
	
	hitbox.position = spearAnim.position + forward.normalized() * hitbox_dist 
	
	if player_facing == Facing.UP or player_facing == Facing.DOWN:
		hitbox.rotation = aim_angle
	#directional angle is the same as the mouse angle
	print("mouse angle: ", get_mouse_angle())
	print("direction angle:", rad_to_deg(get_movement_direction().angle()))
	
	add_child(hitbox)
	
	anim_state.travel("spattack")
	
func sword_attack():
	
	hitbox_shape = CircleShape2D.new()
	hitbox_shape.radius = 15 
	var hitbox = hitBox.new(self, GameData.damage, "None", 0.5, hitbox_shape, current_weapon_data) #change hitbox based on weapon later

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
	
	
	
func sword_special_attack():
	if player_busy():
		print("player too busy for sword rn")
		return
		
	attacking = true
	anim_state.travel("Srelease")#change to a different animation, but make a backup first, for later
	print("SWORD ANIM GOOOOO")
	
	var base_angle: float
	if mouse_aiming:
		base_angle = deg_to_rad(get_mouse_angle())
	else:
		base_angle = deg_to_rad(get_movement_angle())
		
	var forward := Vector2.RIGHT.rotated(base_angle).normalized()
	var right := forward.rotated(PI/2)
	
	var rows := 4 #might change number of rows based on rarity, but for later
	var base_dist := 16.0
	var row_spacing := 16.0
	var side_spacing := 12.0
	var max_angle_deg := 40 #why is the default radians whyyy
	var max_angle_offset := deg_to_rad(max_angle_deg)
	
	for row in range(rows):
		var row_index := row + 1 
		var dist := base_dist + row * row_spacing
		
		for i in range(row_index):
			var t: float
			if row_index == 1:
				t = 0.0
			else:
				t = lerp(-1.0, 1.0, float(i)/float(row_index-1))
			
			var side := t * side_spacing * (row+1)
			
			var offset := forward * dist + right * side
			
			var ang := base_angle + t * max_angle_offset
			
			spawn_arc(offset, ang)
		
func spawn_arc(offset: Vector2, ang: float) -> void:
	var arc: SwordArc = swordArc.instantiate()
	
	arc.attacker = self
	arc.base_damage = GameData.damage
	
	arc.weapon_data = current_weapon_data
	arc.global_position = global_position + offset
	arc.global_rotation = ang
	get_parent().add_child(arc)
	

func spear_special_attack():
	if not spear_ghost_ready or spear_ghost_active:
		print("spear not ready yet")
		return
		
		
	if current_weapon != Weapon.SPEAR:
		print("current weapon not the spear?")
		return
		
		
	var ghost: ghostSpear = ghostSpear.instantiate()
	ghost.global_position = global_position
	ghost.owner_player = self
	ghost.weapon_data = current_weapon_data
	
	ghost.returned_to_owner.connect(on_ghost_spear_returned)
	get_parent().add_child(ghost)
	print("spear is here")
	
	spear_ghost_active = true
	spear_ghost_ready = false
	spear_ghost_timer = SPEAR_GHOST_COOLDOWN
	
func on_ghost_spear_returned():
	spear_ghost_active = false
	

func handle_dash():

	
	if dashes <= 0 or dashing:
		return
		
	
	if current_weapon == Weapon.SPEAR or current_weapon == Weapon.BOW:
		anim_state.travel("dash")
	else:
		anim_state.travel("Sdash")

	dashes -= 1
	dash_timer = DASH_DURATION_TIME
	dashing = true
	
	if dashes == max_dashes - 1 and dash_cooldown <= 0.0:
		dash_cooldown = DASH_COOLDOWN_TIME
		
	if dash_through_enemies:
		set_enemy_collision(false)


func set_enemy_collision(enabled : bool) -> void:
	if enabled:
		collision_layer = 1
		collision_mask = 1
	else:
		collision_layer = 2
		collision_mask = 2

func iframes_on() -> bool:
	return dashing



func handle_timers(delta: float):
	
	
	if dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			dashing = false
			set_enemy_collision(true)
			
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
		if dash_cooldown <= 0.0:
			dash_cooldown = 0.0
			dashes = max_dashes
			
	if not spear_ghost_ready:
		spear_ghost_timer -= delta
		if spear_ghost_timer <= 0.0:
			spear_ghost_ready = true
			spear_ghost_timer = 0.0
			
	if decoy_timer > 0.0:
		decoy_timer -= delta
		if decoy_timer <= 0.0:
			decoy_timer = 0.0
			

func _on_death():
	print("you should be dead")
	dying = true
	anim_state.travel("Sdeath")
	
func _on_damaged():
	pass
	
func _on_health_changed(new_amount, _max_amount) -> void:    
	#health_bar.text = str(new_amount)
	pass

func _on_currency_updated(new_amount : int) -> void:
	#currency_label.text = str(new_amount)
	pass

func player_busy() -> bool:
	return attacking or dying or special_charging

func death_screen() -> void:
	GameData.reset_stats()
	
	var deathBGRND : ColorRect = canvas.get_node("DeathBGRND")
	
	var menutaur : Menutaur = preload("res://Assets/Enemies/Minotaur/menu(taur).tscn").instantiate()
	canvas.add_child(menutaur)
	menutaur.initialise(deathBGRND)
	
	call_deferred("queue_free")
	
func clear_screen() -> void:
	GameData.reset_stats()
	
	get_node("fullAnim/hurtBox").set_deferred("monitorable", false)
	
	var clearBGRND : ColorRect = canvas.get_node("ClearBGRND")
	var player_scene : PackedScene = load(get_scene_file_path()) as PackedScene
	var player_pos : Vector2 = global_position
	
	var menuplayer : MenuPlayer = preload("res://Assets/Scenes/menu(player).tscn").instantiate()
	canvas.add_child(menuplayer)
	menuplayer.initialise(clearBGRND, player_scene, player_pos)
	
	call_deferred("queue_free")

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("Sdeath") or anim_name.begins_with("death"):
		death_screen()
		
	if anim_name.begins_with("bbody"):
		print("shooting arrow")
		shoot_arrow()
	
	#anim_name is the name inside the animation player
	if anim_name.begins_with("Srunattack") or anim_name.begins_with("spbody") or anim_name.begins_with("bbody") or anim_name.begins_with("battack") or anim_name.begins_with("Srelattack") or anim_name.begins_with("bcharge"):
		print("player has finished attacking")
		attacking = false
		monitorable = true
		switch_activated = false
		shotgun_activated = false
		
	if anim_name.begins_with("hurt"):
		stunned_status = false
		#sprite visibility already handled isnide update sprite
		
		
		
	#if anim_name.begins_with("Scharge"):
		#special_charging = false
		
	
		
	if current_weapon == Weapon.SPEAR or current_weapon == Weapon.BOW:
		anim_state.travel("idle")
	else:
		anim_state.travel("Sidle")
		
		
#use this if player chooses to increase number of dashes in shop
func upgrade_dash():
	if max_dashes >=3:
		print("already at max dashes")
	else:
		max_dashes += 1;

func throw_decoy():
	if decoy_scene == null:
		print("where tf decoy scene")
		return
		
	var crazy_diamond := decoy_scene.instantiate()
	crazy_diamond.global_position = global_position
	
	var dir: Vector2
	if mouse_aiming:
		dir = get_mouse_vec().normalized()
	else:
		dir = get_nonzero_movement_direction()
		
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT #default
		
	crazy_diamond.throw_in_direction(dir)
	get_parent().add_child(crazy_diamond)
	
	decoy_timer = decoy_cooldown
		
		

func _on_bow_effectslay_2_animation_finished() -> void:
	
	if bowEffects2.animation == "brelease":
		bowEffects2.visible = false
		print("brelease animation fin")
		
