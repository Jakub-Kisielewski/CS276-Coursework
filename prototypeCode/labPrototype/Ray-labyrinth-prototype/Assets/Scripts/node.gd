extends Node

@onready var rewardControl = $CanvasLayer/Control

var enemies_alive = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	enemies_alive = enemies.size()
	
	print("Enemies remaining: ", enemies_alive)
	
	for enemy in enemies:
		if enemy.has_signal("died"):
			enemy.connect ("died", Callable(self, "_on_enemy_died"))
		else:
			enemy.connect("tree_exited", Callable(self, "_on_enemy_died"))
			
func _on_enemy_died():
	enemies_alive -= 1
	print("enemies remaining: ", enemies_alive)
	if enemies_alive <= 0:
		print("Choose your reward")
		
		rewardControl.visible = true
	
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
		
		
	if Input.is_key_pressed(KEY_ENTER):
		get_tree().change_scene_to_file("res://Assets/Scenes/area_2.tscn")
	
