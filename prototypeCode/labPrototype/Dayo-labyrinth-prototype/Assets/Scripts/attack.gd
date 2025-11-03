extends AnimatedSprite2D


@export var player_controller : CharacterBody2D
@onready var player = get_parent()
@onready var hitbox = $hitBox
@onready var hurtbox = $hurtBox
const DASH_COOLDOWN_TIME = 1.2
const DASH_DURATION_TIME = 0.2
const BLOCK_COOLDOWN_TIME = 6
const BLOCK_DURATION_TIME = 1.8
var dash_multiplier = 3
var dash_cooldown = 0.0
var dash_timer = 0.0
var block_cooldown = 0.0
var block_timer = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:	
	handle_timers(delta)
	if player_busy():
		return
	if player_controller.velocity.length() > 0.0 and player_controller.attacking == false:
		# play movement animations
		flip_h = player_controller.facing_left
		play("run")
	else:
		# play idle animations
		flip_h = player_controller.facing_left
		play("idle")
		
func handle_timers(delta):
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	if player.dashing:
		dash_timer -= delta	
		if dash_timer <= 0.0:
			player.dashing = false
			player.monitorable = true
	if block_cooldown > 0.0:
		block_cooldown -= delta
	if player.blocking:
		block_timer -= delta	
		if block_timer <= 0.0:
			player.blocking = false
			player.monitorable = true


func handle_dash():
	if dash_cooldown > 0 or player_busy():
		return
		
	play("dash")	
	if player.direction == Vector2.ZERO:
		return
	if player.player_facing == player.Facing.UP:
		hitbox.position = Vector2(0, -20)
		hitbox.rotation = -PI/2
	elif player.player_facing ==  player.Facing.DOWN:
		hitbox.position = Vector2(0, 20)
		hitbox.rotation = PI/2
	elif player.player_facing == player.Facing.LEFT:
		hitbox.position = Vector2(-20, 0)
		hitbox.rotation = PI
	elif player.player_facing == player.Facing.RIGHT:
		hitbox.position = Vector2(20, 0)
		hitbox.rotation = 0
		
	dash_timer = DASH_DURATION_TIME
	dash_cooldown = DASH_COOLDOWN_TIME
	player.dashing = true
	player.monitorable = false

func handle_block():
	if block_cooldown > 0 or player_busy():
		return
		
	play("block")	
	block_timer = BLOCK_DURATION_TIME
	block_cooldown = BLOCK_COOLDOWN_TIME
	player.blocking = true
	player.monitorable = false

func handle_attack():
	if player_busy():
		return
		
	play("attack_basic")
	if player.player_facing == player.Facing.UP:
		hitbox.position = Vector2(0, -20)
		hitbox.rotation = -PI/2
	elif player.player_facing ==  player.Facing.DOWN:
		hitbox.position = Vector2(0, 20)
		hitbox.rotation = PI/2
	elif player.player_facing == player.Facing.LEFT:
		hitbox.position = Vector2(-20, 0)
		hitbox.rotation = PI
	elif player.player_facing == player.Facing.RIGHT:
		hitbox.position = Vector2(20, 0)
		hitbox.rotation = 0
	player.give_damage(hitbox.get_overlapping_areas(), 10)
	player.attacking = true

func player_busy() -> bool:
	return player.attacking or player.dashing or player.blocking or player.attacked

func _on_animation_finished() -> void:
	if animation == "attack_basic":
		player.attacking = false
		
	#if animation == "hit":
		#player.attacking = false
		#player.attacked = false
		#player.monitorable = true

func _on_hit_box_area_entered(area: Area2D) -> void:
	if player.dashing:
		player.give_damage([area], 10)
