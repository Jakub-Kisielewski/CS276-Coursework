extends AnimatedSprite2D


@export var player_controller : CharacterBody2D
@onready var player = get_parent()
@onready var hitbox = $hitBox
@onready var hurtbox = $hurtBox
const DASH_COOLDOWN_TIME = 0.8
const DASH_DURATION_TIME = 0.3
var dash_multiplier = 3
var dash_cooldown = 0.0
var dash_timer = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hitbox.monitoring = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if dash_cooldown > 0.0:
		dash_cooldown -= delta
	if player.dashing:
		dash_timer -= delta	
		if dash_timer <= 0.0:
			player.dashing = false
			hurtbox.get_node("hurtCollisionShape").disabled = false
			
	if player_controller.attacking == false:
		if player_controller.velocity.length() > 0.0 and player_controller.attacking == false:
			# play movement animations
			flip_h = player_controller.facing_left
			play("run")
		else:
			# play idle animations
			flip_h = player_controller.facing_left
			play("idle")

func handle_dash():
	if (dash_cooldown > 0):
		pass
	if player.direction == Vector2.ZERO:
		match player.player_facing:
			player.Facing.UP: player.direction = Vector2.UP
			player.Facing.DOWN: player.direction = Vector2.DOWN
			player.Facing.LEFT: player.direction = Vector2.LEFT
			player.Facing.RIGHT: player.direction = Vector2.RIGHT
	
	player.dashing = true
	dash_timer = DASH_DURATION_TIME
	dash_cooldown = DASH_COOLDOWN_TIME
	play("jump")
	hurtbox.get_node("hurtCollisionShape").disabled = false

func handle_powerattack():
	pass

func handle_attack():
	flip_h = player.facing_left
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
	
	player.attacking = true
	hitbox.monitoring = true
	hitbox.get_node("strikeCollisionShape").disabled = false


func _on_animation_finished() -> void:
	if animation == "attack_basic":
		player.attacking = false
		hitbox.monitoring = false
		hitbox.get_node("strikeCollisionShape").disabled = true

func _on_frame_changed() -> void:
	if animation == "attack_basic":
		if frame in [3,4,5]:
			hitbox.get_node("strikeCollisionShape").disabled = false
		else:
			hitbox.get_node("strikeCollisionShape").disabled = true
