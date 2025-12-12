extends Node

@export var world_environment: WorldEnvironment
var dark_timer: Timer

func _ready() -> void:
	SignalBus.request_darkness.connect(_on_darkness_requested)
	
	dark_timer = Timer.new()
	dark_timer.one_shot = true
	add_child(dark_timer)
	dark_timer.timeout.connect(_on_darkness_end)
	

func _on_darkness_requested(duration: float) -> void:
	if world_environment:
		world_environment.environment.adjustment_brightness = 0.5
	
	dark_timer.start(duration)
	

func _on_darkness_end() -> void:
	# restore visuals
	if world_environment:
		world_environment.environment.adjustment_brightness = 1.0
