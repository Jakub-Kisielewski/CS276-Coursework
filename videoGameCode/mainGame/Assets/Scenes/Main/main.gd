extends Node

@export var run_manager: RunManager
@export var scene_manager: SceneManager
@export var world_environment: WorldEnvironment

var dark_timer: Timer
var is_paused: bool = false
var is_settings_open: bool = false

func _ready() -> void:
	SignalBus.request_darkness.connect(_on_darkness_requested)
	SignalBus.player_died.connect(_on_player_died)
	
	await get_tree().process_frame
	
	var pause = scene_manager.ui_pause_menu
	if pause:
		pause.resume_pressed.connect(_on_resume_game)
		pause.save_and_quit_pressed.connect(_on_save_quit)
		pause.settings_pressed.connect(_on_settings_from_pause)
		pause.start_time_msec = Time.get_ticks_msec()
	
	var settings = scene_manager.ui_settings
	if settings:
		settings.back_pressed.connect(_on_settings_back)
		settings.visible = false # Start hidden
	
	var corridor = scene_manager.ui_corridor
	if scene_manager.ui_corridor:
		corridor.room_entered.connect(_on_corridor_room_entered)
		corridor.player_moved_to_cell.connect(_on_player_moved_to_cell)
	
	var menu = scene_manager.ui_main_menu
	if menu:
		menu.new_game_pressed.connect(_on_new_game)
		menu.settings_pressed.connect(_on_settings_from_menu)
	
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
		# If settings is open, close it
		if is_settings_open:
			_on_settings_back()
		elif is_paused:
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

# Called from main menu
func _on_settings_from_menu() -> void:
	open_settings()

# Called from pause menu
func _on_settings_from_pause() -> void:
	# Hide pause menu while settings is open
	if scene_manager.ui_pause_menu:
		scene_manager.ui_pause_menu.visible = false
	open_settings()

func open_settings() -> void:
	is_settings_open = true
	
	# Pause game if not already paused
	if not is_paused:
		var state = scene_manager.current_ui_state
		if state == SceneManager.SceneType.ROOM or state == SceneManager.SceneType.CORRIDOR:
			get_tree().paused = true
	
	if scene_manager.ui_settings:
		scene_manager.ui_settings.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_settings_back() -> void:
	is_settings_open = false
	
	if scene_manager.ui_settings:
		scene_manager.ui_settings.visible = false
	
	# If we came from pause menu, show it again
	if is_paused and scene_manager.ui_pause_menu:
		scene_manager.ui_pause_menu.visible = true
	# If we came from game (not through pause), unpause
	elif not is_paused:
		get_tree().paused = false

func _on_player_moved_to_cell(cell_data: Dictionary) -> void:
	if run_manager:
		run_manager.check_for_emergent_event(cell_data)

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
	if world_environment:
		world_environment.environment.adjustment_brightness = 1.0
