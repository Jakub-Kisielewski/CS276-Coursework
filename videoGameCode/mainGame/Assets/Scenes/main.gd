extends Node

@export var run_manager: RunManager
@export var world_environment: WorldEnvironment

func _ready() -> void:
	SignalBus.request_darkness.connect(_on_darkness_requested)
	
	await get_tree().process_frame
	
	print("Main: Starting Run...")
	run_manager.start_run_or_next_room()
	

var dark_timer: Timer

func _on_darkness_requested(duration: float) -> void:
	if world_environment:
		world_environment.environment.adjustment_brightness = 0.5
		
	if not dark_timer:
		dark_timer = Timer.new()
		dark_timer.one_shot = true
		add_child(dark_timer)
		dark_timer.timeout.connect(_on_darkness_end)
	
	dark_timer.start(duration)
	

func _on_darkness_end() -> void:
	# restore visuals
	if world_environment:
		world_environment.environment.adjustment_brightness = 1.0
