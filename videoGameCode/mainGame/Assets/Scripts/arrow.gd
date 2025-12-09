extends Area2D

var speed = 600.0
@export var weapon_data: WeaponData 
var direction : Vector2

var attacker: Node
var base_damage: float
var hitbox : hitBox

func _ready():
	
	var hitbox_shape = CapsuleShape2D.new()
	hitbox_shape.radius = 5
	hitbox_shape.height = 10
	
	if attacker == null:
		attacker = self
	
	hitbox = hitBox.new(attacker, base_damage, "None", 2.0, hitbox_shape, weapon_data)
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
	if area.owner == attacker:
		return
		
	if area.has_method("receive_hit"):
		print(area.owner)
		print("arrow bye")
		queue_free()
	

func _on_body_entered(body):
	if body == attacker:
		return
	queue_free()
	print(body)
	print("body bye")
	
