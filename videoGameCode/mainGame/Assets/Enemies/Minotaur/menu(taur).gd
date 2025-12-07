class_name Menutaur extends CharacterBody2D

@export var sprite : AnimatedSprite2D
@export var speed : float = 80.0
@export var target_pos : Vector2
var deathBGRND : ColorRect
	
func initialise(_deathBGRND: ColorRect):
	deathBGRND = _deathBGRND
	death_anim()
	
func death_anim() -> void:
	sprite.play("charge")
	
	var tween : Tween = create_tween()
	tween.tween_property(deathBGRND, "color:a", 1.0, 0.38)
	tween.tween_interval(0.1)
	
	for child in deathBGRND.get_children():
		if child is Label:
			tween.tween_property(child, "modulate:a", 1.0, 0.28)
			tween.parallel()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var distance : float = global_position.distance_to(target_pos)
	
	if (distance > 100):
		velocity = global_position.direction_to(target_pos) * speed	
		if velocity.x > 0:
			sprite.flip_h = false
		elif velocity.x < 0:
			sprite.flip_h = true
		move_and_slide()
	elif Input.is_key_pressed(KEY_E):
		get_tree().reload_current_scene()
