extends CharacterBody2D

@export var amount: int = 10

@export_group("Physics")
@export var speed: float = 180.0
@export var detection_radius: float = 150.0 
@export var pickup_distance: float = 15.0
@export var friction: float = 2.0

@onready var player : Node = get_tree().get_first_node_in_group("player")
@export var sprite : AnimatedSprite2D

var state_collected: bool = false
var velocity_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	var tween = create_tween()
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2(1,1), 0.3).set_trans(Tween.TRANS_BOUNCE)

func _physics_process(delta: float) -> void:
	if state_collected: 
		return
	if !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	# magnetism logic
	if dist < detection_radius:
		var direction = global_position.direction_to(player.global_position)
		# Accelerate towards player
		velocity = velocity.lerp(direction * speed, delta * 2.0)
	else:
		# Slow down if player runs away
		velocity = velocity.lerp(Vector2.ZERO, delta * friction)
	
	move_and_slide()
	
	# Pickup Logic
	if dist < pickup_distance:
		collect()

func collect() -> void:
	if state_collected: return
	state_collected = true
	
	# Add to Global Data
	GameData.add_currency(amount)
	
	# Fade out and move up
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
