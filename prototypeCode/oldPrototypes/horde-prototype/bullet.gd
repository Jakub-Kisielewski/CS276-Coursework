extends Area2D
const SPEED = 600.0

func _ready():
	area_entered.connect(_on_area_entered)  # Changed from body_entered

func _physics_process(delta):
	position += Vector2.RIGHT.rotated(rotation) * SPEED * delta

func _on_area_entered(area):  # Changed from _on_body_entered
	if area.get_parent().is_in_group("enemy"):  # Check the parent (the enemy)
		area.get_parent().die()
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
