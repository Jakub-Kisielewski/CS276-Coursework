# EnemySpawner.gd
extends Node2D

const ENEMY_SCENE = preload("res://enemy.tscn")
const SPAWN_DISTANCE = 600.0
const MIN_SPAWN_TIME = 0.3  # Minimum time between spawns
const SPAWN_DECREASE_RATE = 0.07  # How much to decrease spawn time each spawn

@onready var spawn_timer = $SpawnTimer
@onready var player = get_parent().get_node("player")

var current_spawn_time = 2.0  # Starting spawn time

func _ready():
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.wait_time = current_spawn_time
	spawn_timer.start()

func _on_spawn_timer_timeout():
	spawn_enemy()
	
	# Gradually decrease spawn time (spawn faster)
	current_spawn_time = max(MIN_SPAWN_TIME, current_spawn_time - SPAWN_DECREASE_RATE)
	spawn_timer.wait_time = current_spawn_time

func spawn_enemy():
	var enemy = ENEMY_SCENE.instantiate()
	
	# Spawn at random angle around player
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector2.RIGHT.rotated(angle) * SPAWN_DISTANCE
	
	enemy.global_position = spawn_pos
	enemy.player = player
	get_parent().add_child(enemy)
