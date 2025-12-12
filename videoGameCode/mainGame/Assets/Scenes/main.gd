extends Node

@export var run_manager: RunManager
@export var scene_manager: SceneManager
@export var world_environment: WorldEnvironment

var dark_timer: Timer
var is_paused: bool = false

func _ready() -> void:
	SignalBus.request_darkness.connect(_on_darkness_requested)
	SignalBus.player_died.connect(_on_player_died)
	
	await get_tree().process_frame
	
	if scene_manager.ui_pause_menu:
		scene_manager.ui_pause_menu.resume_pressed.connect(_on_resume_game)
		scene_manager.ui_pause_menu.save_and_quit_pressed.connect(_on_save_quit)
		scene_manager.ui_pause_menu.start_time_msec = Time.get_ticks_msec()
	
	if scene_manager.ui_corridor:
		scene_manager.ui_corridor.room_entered.connect(_on_corridor_room_entered)
	
	var menu = scene_manager.ui_main_menu
	if menu:
		menu.new_game_pressed.connect(_on_new_game)
		menu.settings_pressed.connect(_on_settings)
	
	var maze_ui = scene_manager.ui_maze_gen
	if maze_ui:
		maze_ui.start_run_pressed.connect(_on_start_run)
		maze_ui.back_pressed.connect(_on_back_to_menu)
	
	var death_ui = scene_manager.ui_death
	if death_ui:
		scene_manager.ui_death.return_to_menu_pressed.connect(_on_back_to_menu)
		scene_manager.ui_death.quit_pressed.connect(_on_save_quit)
	

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		print("Escape pressed. Current State: ", scene_manager.current_ui_state)
		if is_paused:
			toggle_pause() # unpause by pressing esc
		else:
			var state = scene_manager.current_ui_state
			if state == SceneManager.SceneType.ROOM or state == SceneManager.SceneType.CORRIDOR:
				toggle_pause()
		
		get_viewport().set_input_as_handled()

func _on_new_game() -> void:
	GameData.reset_run_state()
	scene_manager._switch_ui_state(scene_manager.SceneType.MAZE_GEN)

func _on_start_run() -> void:
	run_manager.start_new_run()

func _on_back_to_menu() -> void:
	scene_manager.on_return_to_menu()

func _on_load_game() -> void:
	pass

func _on_settings() -> void:
	pass

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	
	if scene_manager.ui_pause_menu:
		if is_paused:
			scene_manager.ui_pause_menu.open_menu()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			scene_manager.ui_pause_menu.close_menu()

func _on_resume_game() -> void:
	toggle_pause()

func _on_save_quit() -> void:
	get_tree().quit()

func _on_corridor_room_entered(room_type: String) -> void:
	run_manager.load_room_from_type(room_type)

func _on_player_died() -> void:
	scene_manager._switch_ui_state(SceneManager.SceneType.DEATH)

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
