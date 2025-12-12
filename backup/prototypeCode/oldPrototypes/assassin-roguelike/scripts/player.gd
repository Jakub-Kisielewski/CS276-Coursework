extends CharacterBody2D
@export var speed = 100
@export var active = true
@onready var animated_sprite = $AnimatedSprite2D
@onready var colliision_shape = $CollisionShape2D
var spawn_point : Vector2
var num_enemies = 3

func _ready():
	get_tree().paused = true
	spawn_point = position

func _process(delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
	elif num_enemies >= 10:
		get_tree().reload_current_scene()


func get_input():
	if animated_sprite.animation == "kill" and animated_sprite.is_playing():
		check_enemy_collision()
		return
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	if Input.is_action_just_pressed("kill"):
		animated_sprite.play("kill")
	elif input_direction == Vector2.ZERO:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("run")
		if input_direction.x > 0:
			animated_sprite.flip_h = false
			colliision_shape.position.x = 9
		elif input_direction.x < 0:
			animated_sprite.flip_h = true	
			colliision_shape.position.x = -9
	
func _physics_process(delta):
	if active:
		get_input()
	else:
		velocity = Vector2.ZERO
		if Input.is_action_just_pressed("start"):
			arise()
	move_and_slide()

func die():
	active = false
	animated_sprite.play("death")
	colliision_shape.disabled = true
	num_enemies = num_enemies + 1
	
func arise():
	var new_enemy = preload("res://scenes/enemy.tscn").instantiate()
	get_tree().current_scene.add_child(new_enemy)
	new_enemy.position = position
	new_enemy.target = self
	new_enemy.scale = Vector2(0.2, 0.2)
	position = spawn_point
	active = true
	await get_tree().create_timer(0.5).timeout
	colliision_shape.disabled = false

  
func check_enemy_collision():
	for x in get_slide_collision_count():
		var collision = get_slide_collision(x)
		var collider = collision.get_collider()
		if collider.is_in_group("enemy"):
			collider.die()
			num_enemies = num_enemies - 1
