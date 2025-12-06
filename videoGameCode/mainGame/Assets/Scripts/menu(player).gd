class_name MenuPlayer extends CharacterBody2D

@export var sprite : AnimatedSprite2D
@export var speed : float = 80.0
@export var end_pos : Vector2
var start_pos : Vector2
var target_pos : Vector2
var clearBGRND : ColorRect

enum Direction { LEFT, ZERO, RIGHT }
var direction : Direction = Direction.LEFT

func set_BGRND(_clearBGRND: ColorRect):
	clearBGRND = _clearBGRND
	start_pos = global_position
	death_anim()
	
func death_anim() -> void:
	sprite.play("Srun_left")
	
	#Time passed in minutes since game started
	var excact_mins : float = Time.get_ticks_msec() / 1000.0 / 60.0
	var mins : int = int(excact_mins)
	var secs : int = (excact_mins - mins) * 60
	
	var time_label : Label = clearBGRND.get_node("Runtime")
	time_label.text = "runtime, %dM%dS" % [mins, secs]
	
	var tween : Tween = create_tween()
	tween.tween_property(clearBGRND, "color:a", 1, 1.2)
	tween.tween_interval(0.1)
	
	for child in clearBGRND.get_children():
		if child is Label:
			tween.tween_property(child, "modulate:a", 1, 1.1)
			tween.parallel()

func set_direction(new_direction : Direction) -> void:
	await get_tree().create_timer(1.4).timeout
	direction = new_direction
	
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	match direction:
		Direction.LEFT:
			var distance : float = global_position.distance_to(end_pos)
			if (distance > 100):
				velocity = global_position.direction_to(end_pos) * speed	
				if velocity.x > 0:
					sprite.flip_h = true
				elif velocity.x < 0:
					sprite.flip_h = false
				move_and_slide()
			else:
				set_direction(Direction.RIGHT)

		Direction.RIGHT:
			var distance : float = global_position.distance_to(start_pos)
			if (distance > 100):
				velocity = global_position.direction_to(start_pos) * speed	
				if velocity.x > 0:
					sprite.flip_h = true
				elif velocity.x < 0:
					sprite.flip_h = false
				move_and_slide()
			else:
				set_direction(Direction.LEFT)
			
