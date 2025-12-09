class_name EnemyEntity extends CharacterBody2D
@export var health_component: HealthComponent
@export var loot_component: LootComponent
@export var damage: float = 10.0 

@onready var sprite_base: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	
	if health_component:
		health_component.health_depleted.connect(_on_death)
		health_component.damage_taken.connect(_on_damaged)

func _on_damaged(_amount, _type):
	# default behavior: flash red 
	if sprite_base:
		sprite_base.modulate = Color("f5a3b0")
		var tween = create_tween()
		tween.tween_property(sprite_base, "modulate", Color.WHITE, 0.1)

func _on_death():
	# Default behavior: Drop loot and die
	reduce_to_gold()

func reduce_to_gold():
	if loot_component:
		loot_component.drop_loot()
	else:
		print("Warning: No LootComponent found on ", name)
	
	queue_free()
