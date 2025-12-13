class_name SwordArc extends Area2D

@onready var arcAnim = $arcAnim
@export var weapon_data: WeaponData

var attacker: Node 
var base_damage: float 
var lifetime: float = 0.3
var hitbox: hitBox

func _ready() -> void:
	var shape: Shape2D = CircleShape2D.new()
	shape.radius = 13
	
	if attacker == null:
		attacker = self
	
	hitbox = hitBox.new(attacker, base_damage, "None", lifetime, shape, weapon_data)
	
	add_child(hitbox)
	
	arcAnim.play("spinny")
	
	var t : Timer = Timer.new()
	t.wait_time = lifetime
	t.one_shot = true
	add_child(t)
	t.timeout.connect(_on_timeout)
	t.start()
	
func _process(delta: float) -> void:
	if hitbox:
		hitbox.position = Vector2.ZERO
		hitbox.rotation = 0.0
		
func _on_timeout() -> void:
	queue_free()
