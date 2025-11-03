extends Control
@onready var player = get_tree().get_first_node_in_group("player")


@onready var health_button = $HealthButton
@onready var damage_button = $DamageButton
@onready var speed_button  = $SpeedButton

func _ready():
	visible = false

	


func _on_speed_button_pressed() -> void:
	player.speed += 20
	print("Reward: +20 Speed")
	get_tree().change_scene_to_file("res://Assets/Scenes/area_2.tscn")

func _on_damage_button_pressed() -> void:
	player.damage += 10
	print("Reward: +10 Attack Damage")
	get_tree().change_scene_to_file("res://Assets/Scenes/area_2.tscn")

func _on_health_button_pressed() -> void:
	player.health += 25
	print("Reward: +25 Max Health")
	get_tree().change_scene_to_file("res://Assets/Scenes/area_2.tscn")
