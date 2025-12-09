class_name RunManager extends Node

@export var scene_manager: SceneManager
@export var ui_event_overlay: Control
@export var possible_events: Array[EventData]
@export var available_room_scenes: Array[PackedScene]

var current_difficulty: int = 1

func _ready():
	ui_event_overlay.option_selected.connect(_apply_event_effect)

func trigger_random_event():
	var random_event = possible_events.pick_random()
	ui_event_overlay.show_event(random_event)

func _apply_event_effect(effect_id: String):
	match effect_id:
		"gain_gold":
			GameData.currency += 50
			print("Player gained gold!")
		"heal":
			GameData.current_health += 20
		"gain_damage":
			GameData.damage += 5
		_:
			print("Effect not found: ", effect_id)
	
