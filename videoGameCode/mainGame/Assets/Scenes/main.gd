extends Node

@export var run_manager: RunManager
@export var scene_manager: SceneManager
@export var world_environment: WorldEnvironment

var dark_timer: Timer

func _ready() -> void:
	SignalBus.request_darkness.connect(_on_darkness_requested)
	
	await get_tree().process_frame
	
	var menu = scene_manager.ui_main_menu
	if menu:
		menu.new_game_pressed.connect(_on_new_game)
		menu.load_game_pressed.connect(_on_load_game)
		menu.settings_pressed.connect(_on_settings)
	

func _on_new_game() -> void:
	print("Main: New Game Requested")
	
	scene_manager.on_start_game_ui()
	
	run_manager.start_run_or_next_room()

func _on_load_game() -> void:
	print("Main: Load Game Requested (Not Implemented)")

func _on_settings() -> void:
	print("Main: Settings Requested")

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
