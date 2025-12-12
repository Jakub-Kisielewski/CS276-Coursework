extends Control

signal start_run_pressed
signal back_pressed

@onready var opt_map_size: OptionButton = %OptMapSize
@onready var opt_branches: OptionButton = %OptBranches
@onready var opt_difficulty: OptionButton = %OptDifficulty
@onready var btn_start: Button = %BtnStart
@onready var btn_back: Button = %BtnBack

const WorldGeneratorScript = preload("res://Assets/Scripts/generateWorld.gd")

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	
	# select defaults
	opt_map_size.selected = 1
	opt_branches.selected = 1
	opt_difficulty.selected = 1

func _on_start_pressed() -> void:
	match opt_map_size.selected:
		0: # small
			GameData.map_width = 5
			GameData.map_height = 5
		1: # default
			GameData.map_width = 7
			GameData.map_height = 7
		2: # large
			GameData.map_width = 9
			GameData.map_height = 9

	match opt_branches.selected:
		0: # sparse
			GameData.branch_prob = 0.2
		1: # default
			GameData.branch_prob = 0.4
		2: # dense
			GameData.branch_prob = 0.9

	match opt_difficulty.selected:
		0: # easy
			GameData.difficulty_mod = 0.5
		1: # default
			GameData.difficulty_mod = 1.0
		2: # hard
			GameData.difficulty_mod = 1.5
	
	var generator = WorldGeneratorScript.new()
	generator.generate_map_data()
	generator.free()
	GameData.save_game()
	
	start_run_pressed.emit()

func _on_back_pressed() -> void:
	back_pressed.emit()
