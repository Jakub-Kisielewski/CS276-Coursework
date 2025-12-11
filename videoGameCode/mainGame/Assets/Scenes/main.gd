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
		menu.settings_pressed.connect(_on_settings)
	
	var maze_ui = scene_manager.ui_maze_gen
	if maze_ui:
		maze_ui.start_run_pressed.connect(_on_start_run)
		maze_ui.back_pressed.connect(_on_back_to_menu)
	

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func _on_new_game() -> void:
	print("Main: New Game Requested")
	
	scene_manager._switch_ui_state(scene_manager.SceneType.MAZE_GEN)

func _on_start_run() -> void:
	print("Main: Starting Run with Custom Settings")
	run_manager.start_run_or_next_room()

func _on_back_to_menu() -> void:
	scene_manager.on_return_to_menu()

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
