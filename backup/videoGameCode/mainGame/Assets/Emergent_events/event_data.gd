class_name EventData extends Resource

@export var title: String = "Event Name"
@export_multiline var description: String = "What is happening?"
@export var event_image: Texture2D

# We use a Dictionary to define choices: 
# { "text": "Take Gold", "effect_id": "gain_gold" }
@export var options: Array[Dictionary]
