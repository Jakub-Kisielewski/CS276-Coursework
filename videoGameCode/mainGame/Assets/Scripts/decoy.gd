class_name Decoy extends CharacterBody2D

@onready var diamond = $AnimatedSprite2D

var initial_speed: float = 800.0
var friction: float = 2000.0
var lifetime: float = 3.5

var thrown_velocity: Vector2 = Vector2.ZERO
var landed: bool = false

func _ready() -> void:
	add_to_group("decoy")
	#can you not hit anything but the wall pls thanks
	collision_layer = 3
	collision_mask = 2
	
	var t : Timer = Timer.new()
	t.wait_time = lifetime
	t.one_shot = true
	t.timeout.connect(on_life_timeout)
	add_child(t)
	t.start()
	
	diamond.play("oooshiny")
	
	
func throw_in_direction(dir: Vector2) -> void:
	thrown_velocity = dir.normalized() * initial_speed

func _physics_process(delta: float) -> void:
	
	if landed:
		return
		
	velocity = thrown_velocity
	var collision : KinematicCollision2D = move_and_collide(velocity * delta)
	
	if collision:
		decoy_land()
		print("diamond collided and stopped")
		return
		
	thrown_velocity = thrown_velocity.move_toward(Vector2.ZERO, friction * delta)
	
	if thrown_velocity.length() < 10.0:
		decoy_land()
		
		
func decoy_land():
	landed = true
	thrown_velocity = Vector2.ZERO
	velocity = Vector2.ZERO
	
func on_life_timeout():
	queue_free()
