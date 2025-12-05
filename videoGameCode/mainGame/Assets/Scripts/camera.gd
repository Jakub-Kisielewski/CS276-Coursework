extends Camera2D
var shake_size: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shake_size = 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func shake():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "offset", Vector2(shake_size, -shake_size), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2(-shake_size, shake_size), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2(-shake_size, -shake_size), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2(shake_size, shake_size), 0.08).set_trans(Tween.TRANS_SINE)
