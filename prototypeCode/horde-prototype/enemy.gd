extends CharacterBody2D

const SPEED = 150.0

var player = null

@onready var hitbox = $Hitbox

func _ready():
	add_to_group("enemy")
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * SPEED
		move_and_slide()

func _on_hitbox_body_entered(body):
	if body.name == "player":
		body.die()

func die():
	get_parent().get_node("UI").add_score(1)
	queue_free()
