class_name Menutaur extends CharacterBody2D

@export var sprite : AnimatedSprite2D
@export var speed : float = 80.0
@export var target_pos : Vector2
var deathBGRND : ColorRect

var acceleration : int = 6000
	
func initialise(_deathBGRND: ColorRect):
	deathBGRND = _deathBGRND
	death_anim()
	
# Animation to visualise the death screen 
func death_anim() -> void:
	sprite.play("charge")

	# Fade the ColorRect until fully visible
	var tween : Tween = create_tween()
	tween.tween_property(deathBGRND, "modulate:a", 1.0, 0.7)
	tween.tween_interval(0.1)

	# Fade the UI elements until fully visible
	for child in get_parent().find_children("", "Button") + get_parent().find_children("", "Label"):
		tween.tween_property(child, "modulate:a", 1.0, 0.6)
		tween.parallel()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var distance : float = global_position.distance_to(target_pos)
	var direction : Vector2 = global_position.direction_to(target_pos)

	# Move the sprite left until the target_pos is reached
	if (distance > 100):
		# Accelerate towards target
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * _delta)
		velocity.y = move_toward(velocity.y, direction.y * speed, acceleration * _delta)
		
		# Flip the sprite if necessary
		if velocity.x > 0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true
		move_and_slide()
		
# Close the death screen
func close() -> void:
	deathBGRND.modulate.a = 0
	for child in get_parent().find_children("", "Button") + get_parent().find_children("", "Label"):
		child.modulate.a = 0
	
	queue_free()
