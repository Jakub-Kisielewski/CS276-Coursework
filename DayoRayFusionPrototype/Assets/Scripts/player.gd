extends CharacterBody2D

@onready var attack = $AnimatedSprite2D
var max_health = 100.0
var health = 100.0
var speed = 300.0
var damage = 10
var dead = false
var direction : Vector2
var facing_left = false
enum Facing {UP, DOWN, LEFT, RIGHT}
var player_facing : Facing
var attacking = false
var attacked = false
var dashing = false
var blocking = false
var monitorable = true

func _ready():
	health = max_health

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	if Input.is_action_just_pressed("attack_basic"):
		attack.handle_attack()
	if Input.is_action_just_pressed("dash"):
		attack.handle_dash()
	if Input.is_action_just_pressed("block"):
		attack.handle_block()
	
func handle_movement(delta: float):
	if blocking or attacked:
		return
	if Input.is_action_pressed("move_up"):
		direction.y = -1
		player_facing = Facing.UP
	elif Input.is_action_pressed("move_down"):
		direction.y = 1
		player_facing = Facing.DOWN
	else:
		direction.y = 0
	
	if Input.is_action_pressed("move_right"):
		direction.x = 1
		player_facing = Facing.RIGHT
		facing_left = false
	elif Input.is_action_pressed("move_left"):
		direction.x = -1
		player_facing = Facing.LEFT
		facing_left = true
	else:
		direction.x = 0

	direction = direction.normalized()
		
	if dashing:
		velocity = direction * speed * attack.dash_multiplier
		move_and_slide()
	else:
		velocity = direction * speed
		move_and_slide()	

func take_damage(damage : int) -> void:
	health -= damage
	if health <= 0 and not dead:
		print("you should be dead")
		dead = true
		get_tree().quit()
		return
	attacking = false
	attacked = true
	monitorable = false
	attack.play("hit")
	print("player has been damaged")
	print("health:", health)

func give_damage(overlaps: Array) -> void:
	for x in overlaps:
		var target = x.get_parent().get_parent()
		if target.has_method("take_damage") and target.monitorable: 
			target.take_damage(damage)
