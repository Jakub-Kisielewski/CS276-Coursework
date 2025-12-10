class_name MenuPlayer extends CharacterBody2D

@export var sprite : AnimatedSprite2D
@export var speed : float = 80.0

# Target positions for the player sprite
@export var end_pos : Vector2
var start_pos : Vector2

# Reference to the ColorRect for the clear game screen
var clearBGRND : ColorRect

# Details about the player sprite
var player_scene : PackedScene
var player_pos : Vector2

# Can the player close the clear game screen
var skip : bool

# Details about the direction the player sprite is moving
enum Direction { LEFT, ZERO, RIGHT }
var direction : Direction = Direction.LEFT

func initialise(_clearBGRND: ColorRect, _player_scene: PackedScene, _player_pos: Vector2):
	clearBGRND = _clearBGRND
	player_scene = _player_scene
	player_pos = _player_pos
	
	start_pos = global_position
	clear_anim()
	
# Animation to visualise the clear game screen
func clear_anim() -> void:
	sprite.play("Srun_left")
	
	# Time passed in minutes since game started
	var excact_mins : float = Time.get_ticks_msec() / 1000.0 / 60.0
	var mins : int = int(excact_mins)
	var secs : int = (excact_mins - mins) * 60
	
	var time_label : Label = clearBGRND.get_node("Runtime")
	time_label.text = "runtime, %dM%dS" % [mins, secs]

	# Fade the ColorRect until fully visible
	var tween : Tween = create_tween()
	tween.tween_property(clearBGRND, "color:a", 1, 1.2)
	tween.tween_interval(0.1)
	
	# Fade the child Labels until fully visible
	for child in clearBGRND.get_children():
		if child is Label:
			tween.tween_property(child, "modulate:a", 1, 1.1)
			tween.parallel()

# Set the direction of the player sprite (with a 1.4 second delay)
func set_direction(new_direction : Direction) -> void:
	await get_tree().create_timer(1.4).timeout
	if skip == false:
		# The player can close the clear game screen
		skip = true
	direction = new_direction


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if skip and Input.is_key_pressed(KEY_E):
		# Close the clear game screen
		clearBGRND.color.a = 0
		for child in clearBGRND.get_children():
			if child is Label:
				child.modulate.a = 0
		
		# Re-instaniate the player
		var player : CharacterBody2D = player_scene.instantiate()
		player.global_position = player_pos
		get_tree().root.add_child(player)
		
		queue_free()
	
	match direction:
		# Move the sprite left until the end_pos is reached
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
		# Move the sprite right until the start_pos is reached
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
			
