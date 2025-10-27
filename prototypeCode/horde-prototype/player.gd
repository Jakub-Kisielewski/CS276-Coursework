extends Area2D

@export var speed = 400
var screenSize

func _ready():
	screenSize = get_viewport_rect().size
	

func _process(delta):
	var velocity = Vector2.ZERO # player movement vector
	if Input.is_action_pressed("moveDown"):
		velocity.y += 1
	if Input.is_action_pressed("moveRight"):
		velocity.x += 1
	if Input.is_action_pressed("moveLeft"):
		velocity.x -= 1
	if Input.is_action_pressed("moveUp"):
		velocity.y -= 1
		
	# stop moving faster going diagonal
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		
	position += velocity * delta 
	position = position.clamp(Vector2.ZERO, screenSize)
	
	look_at(get_global_mouse_position())



#func start(pos):
	#position = pos
	#show()
	#$CollisionShape2D.disabled = false
