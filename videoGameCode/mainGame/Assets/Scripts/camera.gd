extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shake()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func shake():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "offset", Vector2(8, -8), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2(-8, 8), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2(-8, -8), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2(8, 8), 0.1).set_trans(Tween.TRANS_SINE)
