extends CanvasLayer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_tree().paused:
		visible = true
		if Input.is_action_just_pressed("start"):
			get_tree().paused = false
			visible = false
