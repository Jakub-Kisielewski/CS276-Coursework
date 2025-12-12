class_name RoomBase extends Node2D

@onready var spawn_points_container = $EnemySpawns

var enemy_count: int = 0
var current_wave: int = 0
var total_waves: int = 0
var enemies_per_wave: int = 0
var enemy_pool: Array[PackedScene] = []
var spawn_points: Array = []

signal room_cleared
signal wave_cleared(wave_number: int)
signal wave_started(wave_number: int)

func setup_room(total_enemies: int, _enemy_pool: Array[PackedScene], waves: int = 3):
	enemy_pool = _enemy_pool
	spawn_points = spawn_points_container.get_children()
	
	if spawn_points.is_empty():
		push_error("No spawn points found!")
		return
	
	total_waves = waves
	enemies_per_wave = ceil(float(total_enemies) / float(waves))
	current_wave = 0
	
	# Start the first wave
	_start_next_wave()

func _start_next_wave():
	if current_wave >= total_waves:
		return
	
	current_wave += 1
	wave_started.emit(current_wave)
	
	# Spawn enemies for this wave
	for i in range(min(enemies_per_wave,spawn_points.size())):
		var marker = spawn_points[i]
		_spawn_enemy(marker.global_position, enemy_pool)

func _spawn_enemy(pos: Vector2, pool: Array[PackedScene]):
	var enemy_scene = pool.pick_random() 
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	print(enemy.name)
	
	enemy.tree_exiting.connect(_on_enemy_killed)
	
	call_deferred("add_child", enemy)
	enemy_count += 1

func _on_enemy_killed():
	enemy_count -= 1
	
	if enemy_count <= 0:
		wave_cleared.emit(current_wave)
		print("Wave ", current_wave, " cleared")
		
		if current_wave < total_waves:
			# Small delay before next wave
			await get_tree().create_timer(2.0).timeout
			_start_next_wave()
		else:
			print("All waves cleared - room complete!")
			room_cleared.emit()
