extends AnimatedSprite2D

@export var player_controller : CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	if player_controller.attacking == false:
		if player_controller.velocity.length() > 0.0 and player_controller.attacking == false:
			# play movement animations
			flip_h = player_controller.facing_left

			play("run")
		else:
			# play idle animations
			flip_h = player_controller.facing_left
			play("idle")
		
		
		
	
	
