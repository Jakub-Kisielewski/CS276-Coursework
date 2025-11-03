extends CharacterBody2D

@export var nav: NavigationAgent2D
@onready var player = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D
@onready var attack_charge_hitbox = $AnimatedSprite2D/attack_charge_hitBox
@onready var attack_charge_hitbox_shape = $AnimatedSprite2D/attack_charge_hitBox/strikeShape2
@onready var attack_basic_hitbox = $AnimatedSprite2D/attack_basic_hitBox
@onready var attack_basic_hitbox_shape = $AnimatedSprite2D/attack_basic_hitBox/strikeShape1
const MAX_CHARGE_COOLDOWN = 10.0
var charge_cooldown = 5.0
var player_in_range = false
var attacking = false
var attacked = false
var charging = false
var charge_multiplier = 3.0
var speed = 90.0
enum State {CHASE, WINDUP, CHARGE, STUNNED, DEAD}
var health = 1000.0
var current_state = State.WINDUP
const STUN_DURATION = 2.0
var stun_timer = 0.0
var stun_damage_mult = 3.0

func _physics_process(delta: float) -> void:
	
	if charge_cooldown <= 0:
		current_state = State.CHARGE
	charge_cooldown -= delta
	
	
	
	match current_state:
		State.CHASE: #need to define when to chase and when to charge
			handle_chase(delta)
		State.WINDUP:
			handle_windup(delta)
		State.CHARGE:
			handle_charge(delta)
		State.STUNNED:
			handle_stunned(delta)
		State.DEAD:
			handle_death()
	
		
		
		
func handle_windup(delta):
	attack_charge_hitbox_shape.disabled = true
	velocity = Vector2.ZERO
	
	sprite.play("windup") #end of windup animation triggers charge animation btw
	
func handle_charge(delta):
	
	if not charging: #animation already playing
		attack_basic_hitbox_shape.disabled = true
		nav.target_position = player.global_position
	
		var next = nav.get_next_path_position()
		#print("next:", next)
	

		var vector_to_player : Vector2 = player.global_position - global_position
		print("Goat is now charging (This should only print once per charge!)")
		
		velocity = global_position.direction_to(next) * speed * charge_multiplier
		attack_charge_hitbox_shape.disabled = false
		attack_charge_hitbox.monitoring = true
		attack_charge_hitbox.rotation = vector_to_player.angle()
		var hitbox_offset_distance = 20.0
		attack_charge_hitbox.position = vector_to_player.normalized() * hitbox_offset_distance
		sprite.play("attack_charge")
		charging = true
		if attack_charge_hitbox_shape.disabled == false:
			print("hitbox shape is enabled")
		
		
	
	var collision = move_and_collide(velocity * delta) #issue with move and slide, it needs to be called every frame in order for thing to move, so can't call it once in a charge
	if collision:
		print("goat has crashed!", collision.get_collider())
		take_damage(50)
		end_charge()
	
		
func handle_chase(delta):
	
	
	
	nav.target_position = player.global_position
	
	var next = nav.get_next_path_position()
	#print("next:", next)
	
	velocity = global_position.direction_to(next) * speed
	
	if velocity.x>0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true
	
	move_and_slide()


	if player_in_range:
		handle_attack()
	elif not attacking:
		handle_move()
		
func handle_attack():
	if attacking: #animation already playing
		return
	attacking = true
	
	var vector_to_player : Vector2 = player.global_position - global_position
	attack_basic_hitbox.rotation = vector_to_player.angle()
	
	var hitbox_offset_distance = 20.0
	attack_basic_hitbox.position = vector_to_player.normalized() * hitbox_offset_distance
	
	
	sprite.play("attack_basic")
	
	
func handle_move():
	sprite.play("run")

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true


func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false


func _on_animated_sprite_2d_animation_finished() -> void:
	print("animation finished")
	if sprite.animation == "attack_basic":
		attacking = false
		attack_basic_hitbox_shape.disabled = true
		print("goat enemy finished attack")	
		
	if sprite.animation == "windup":
		current_state = State.CHARGE
		print("starting charge")
		
	#if sprite.animation == "attack_charge":
		#current_state = 
		
	if sprite.animation == "stun":
		sprite.play("idle")
		


func _on_animated_sprite_2d_frame_changed() -> void:
	if sprite.animation == "attack_basic":
	
		var current_frame = sprite.frame
		
		if current_frame == 3 or current_frame == 4:
			attack_basic_hitbox_shape.disabled = false
		else:
			attack_basic_hitbox_shape.disabled = true


#func _on_attack_charge_hit_box_body_entered(body: Node2D) -> void:
	#print ("hitbox entered")
	#if current_state != State.CHARGE:
		#return
		#
	#if body.is_in_group("player"):
		#print("goat charged into player")
	#else:
		#print("Goat charged into wall")
		#take_damage(50)
	#end_charge()
		#
		
		
func end_charge():
	print("goat should be stunned")
	current_state = State.STUNNED
	attack_charge_hitbox_shape.set_deferred("disabled", true)
	sprite.play("stun")
	stun_timer = STUN_DURATION
	charging = false
	charge_cooldown = randf_range(5.0, MAX_CHARGE_COOLDOWN) 
	print("charge cooldown", charge_cooldown)
	
	
func handle_stunned(delta):
	if stun_timer <= 0:
		current_state = State.CHASE #return back to chase mode
	else:
		stun_timer -= delta		
		
func take_damage(damage: float):
	if current_state == State.STUNNED:
		health -= damage * stun_damage_mult
	else: health -= damage
	
	print("goat health:", health)
	
	if health <= 0:
		current_state = State.DEAD
	
	
	
func handle_death():
	queue_free()
	print("Goat has been defeated!")
		


func _on_attack_charge_hit_box_area_entered(area: Area2D) -> void:
	print ("area entered signal triggered")
	if current_state != State.CHARGE:
		return
		
	if area.is_in_group("player"):
		print("goat charged into player")
	else:
		print("Goat charged into wall")
		take_damage(50)
	end_charge()
