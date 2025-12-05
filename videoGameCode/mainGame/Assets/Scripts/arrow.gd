extends Area2D

var speed = 600.0
@export var arrow_stats : Stats
var direction : Vector2
var attacker_stats : Stats
var hitbox : hitBox

func _ready():
	
	var hitbox_shape = CapsuleShape2D.new()
	hitbox_shape.radius = 5
	hitbox_shape.height = 10
	
	hitbox = hitBox.new(attacker_stats, "None", 2.0, hitbox_shape)
	hitbox.position = position
	hitbox.rotation = direction.angle()
	
	add_child(hitbox)
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
		
func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation = direction.angle()
	if hitbox:
		hitbox.position = Vector2.ZERO
		hitbox.rotation = 0
	
func _on_area_entered(area: Area2D):
	if area.owner == attacker_stats.owner_node:
		print("returned?")
		return
		
	if area.has_method("receive_hit"):
		print(area.owner)
		print("arrow bye")
		queue_free()
		
	
		
func _on_body_entered(body):
	if body == attacker_stats.owner_node:
		return
	queue_free()
	print(body)
	print("body bye")
	
		
	
		
		
