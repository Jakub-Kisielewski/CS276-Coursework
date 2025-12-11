extends Camera2D
var shake_size: int
var player : Node

# Called when the node enters the scene tree for the first time.
func _init() -> void:
	shake_size = 3.2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	global_position = player.global_position

func shake() -> void:
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self, "offset", Vector2(shake_size, -shake_size), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2(-shake_size, shake_size), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2(-shake_size, -shake_size), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "offset", Vector2(shake_size, shake_size), 0.08).set_trans(Tween.TRANS_SINE)
