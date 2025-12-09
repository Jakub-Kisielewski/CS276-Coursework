class_name RoomBase extends Node2D

@onready var spawn_points_container = $EnemySpawns
var enemy_count: int = 0

signal room_cleared

func setup_room(difficulty_score: int, enemy_pool: Array[PackedScene]):
	var possible_spawns = spawn_points_container.get_children()
	var target_enemy_count = clamp(difficulty_score / 2, 1, possible_spawns.size())
	
	possible_spawns.shuffle()
	
	for i in range(target_enemy_count):
		var marker = possible_spawns[i]
		_spawn_enemy(marker.global_position, enemy_pool)

func _spawn_enemy(pos: Vector2, pool: Array[PackedScene]):
	var enemy_scene = pool.pick_random() 
	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos
	
	enemy.tree_exited.connect(_on_enemy_killed)
	
	call_deferred("add_child", enemy)
	enemy_count += 1

func _on_enemy_killed():
	enemy_count -= 1
	if enemy_count <= 0:
		# load corridor
		print("room cleared")
		room_cleared.emit()
		pass
