class_name World extends WorldEnvironment

@export var standard_world : Environment
@export var dark_world : Environment

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func set_standard() -> void:
	environment = standard_world

func set_dark() -> void:
	environment = dark_world
