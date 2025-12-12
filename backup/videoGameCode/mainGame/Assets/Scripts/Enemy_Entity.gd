class_name EnemyEntity extends CharacterBody2D
@export var health_component: HealthComponent
@export var loot_component: LootComponent
@export var damage: float = 10.0 

@export var health_bar: ProgressBar

@onready var sprite_base: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	if health_component:
		health_component.status_changed.connect(_on_status_changed)
		health_component.health_depleted.connect(_on_death)
		health_component.damage_taken.connect(_on_damaged)
		
		health_component.health_changed.connect(_on_health_changed)
		
		if health_bar:
			health_bar.max_value = health_component.max_health
			health_bar.value = health_component.max_health
			health_bar.visible = false 

func _on_health_changed(new_amount: float, max_amount: float) -> void:
	if health_bar:
		health_bar.value = new_amount
		# Show the bar only when damaged (cleaner look)
		if new_amount < max_amount:
			health_bar.visible = true

func _on_status_changed(new_status : HealthComponent.Status) -> void:
	match new_status:
		health_component.Status.HEALTHY:
			sprite_base.modulate = Color("ffffffff")
		health_component.Status.POISONED:
			sprite_base.modulate = Color("#ffacff")
		health_component.Status.DAMAGED:
			sprite_base.modulate = Color("f5a3b0")
		health_component.Status.OVERHEATING:
			sprite_base.modulate = Color("f5a3b0")

func _on_damaged(_amount, _type):
	# default behavior: do nothing
	pass

func _on_death():
	# Default behavior: Drop loot and die
	reduce_to_gold()

# Drop gold and destroy the enemy
func reduce_to_gold():
	if loot_component:
		loot_component.drop_loot()
	else:
		print("Warning: No LootComponent found on ", name)
	
	queue_free()
