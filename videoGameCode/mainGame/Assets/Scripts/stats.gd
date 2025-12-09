class_name Stats extends Resource

var world : World
var owner_node : Node = null



var dark_timer : Timer


func start_darkness() -> void:
	if dark_timer != null:
		dark_timer.queue_free()
	
	world.set_dark()
	dark_timer = Timer.new()
	dark_timer.wait_time = 3.6
	dark_timer.autostart = true
	owner_node.add_child(dark_timer)
	dark_timer.timeout.connect(end_darkness)
	
func end_darkness() -> void:
	if dark_timer != null:
		dark_timer.queue_free()
	
	world.set_standard()
