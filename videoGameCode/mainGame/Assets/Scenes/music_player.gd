class_name MusicPlayer extends AudioStreamPlayer

#MENU = MENU + SETTINGS
#ROOM = ROOM+MAZE_GEN
#CORRIDOR = CORRIDOR
#NULL = do not use this 
enum Category {MENU_SETTINGS, ROOMS, CORRIDORS, DEAD, NULL}


var current_category : Category = Category.NULL

var menu_tracks: Array[AudioStream] = []
var corridor_tracks : Array[AudioStream] = []
var room_tracks : Array[AudioStream] = []
var death_track: Array[AudioStream] = []

var current_tracks : Array[AudioStream] = []
var current_index : int = 0

var fade_tween: Tween
var default_volume_db : float = 0

func _ready() -> void:
	randomize()
	#if you want to add any songs so that they can be used just preload them here into the arrays
	menu_tracks = [
		preload("res://Assets/Resources/GameMusic/TremLoadingloopl.ogg")
		]
		
	corridor_tracks = [
		preload("res://Assets/Resources/GameMusic/shrine.ogg")
		]
	
	
	room_tracks = [
		preload("res://Assets/Resources/GameMusic/CleytonRX - Battle RPG Theme Var.ogg"),
		preload("res://Assets/Resources/GameMusic/The-Last-Encounter-_Digitalized-Version_.ogg"),
		preload("res://Assets/Resources/GameMusic/boss_battle__2_metal_opening.ogg"),
		preload("res://Assets/Resources/GameMusic/Wasteland-Overdrive.ogg"),
		
	]
	
	death_track = [
		preload("res://Assets/Resources/GameMusic/Iwan Gabovitch - Dark Ambience Loop.ogg") #DEATH MUSIC
	]
	
	finished.connect(on_music_finished)
	
	set_category(Category.MENU_SETTINGS) #default to menu
	
	
func set_category(new_category : Category) -> void:
	
	if new_category == current_category:
		return
		
	current_category = new_category
	
	match current_category:
		Category.MENU_SETTINGS:
			current_tracks = menu_tracks
		Category.CORRIDORS:
			current_tracks = corridor_tracks
		Category.ROOMS:
			current_tracks = room_tracks
		Category.DEAD:
			current_tracks = death_track
		
	current_index = 0
	play_random_track()
		

func play_random_track() -> void:
	if 	current_tracks.is_empty():
		return
		
	var new_index := current_index
	
	if current_tracks.size() == 1:
		pass
	else:
		while current_index == new_index:
			new_index = randi() % current_tracks.size()
			
	stream = current_tracks[new_index]
	current_index = new_index
	
	volume_db = -40.0
	play()
	fade_in()



func fade_in(duration : float = 1.0):
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "volume_db", default_volume_db, duration) 
	
func fade_out(duration : float = 0.5):
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "volume_db", default_volume_db, duration) 

func on_music_finished() -> void:
	fade_out()
	play_random_track()

	
