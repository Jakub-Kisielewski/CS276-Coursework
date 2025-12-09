class_name World extends WorldEnvironment

@export var standard_world : Environment
@export var dark_world : Environment

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.request_darkness.connect(set_dark)


func set_dark(time : int) -> void:
	environment = dark_world
	await get_tree().create_timer(time).timeout
	environment = standard_world
