class_name UiEventOverlay extends Control

signal option_selected(effect_id: String)

@onready var title_label: Label = %Title
@onready var description_label: Label = %LblDescription
@onready var event_image: TextureRect = %Img
@onready var choice1_button: Button = %Choice1
@onready var choice2_button: Button = %Choice2
@onready var event_container: PanelContainer = %EventContainer

var current_event: EventData

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  
	
	if choice1_button:
		choice1_button.pressed.connect(_on_choice1_pressed)
	if choice2_button:
		choice2_button.pressed.connect(_on_choice2_pressed)

func show_event(event_data: EventData) -> void:
	if not event_data:
		printerr("UiEventOverlay: No event data provided")
		return
	
	current_event = event_data
	
	if title_label:
		title_label.text = event_data.title
	
	if description_label:
		description_label.text = event_data.description
	
	if event_image:
		if event_data.event_image:
			event_image.texture = event_data.event_image
			event_image.visible = true
		else:
			event_image.visible = false
	
	if event_data.options.size() >= 1 and choice1_button:
		var option1 = event_data.options[0]
		choice1_button.text = option1.get("text", "Option 1")
		choice1_button.visible = true
	else:
		if choice1_button:
			choice1_button.visible = false
	
	if event_data.options.size() >= 2 and choice2_button:
		var option2 = event_data.options[1]
		choice2_button.text = option2.get("text", "Option 2")
		choice2_button.visible = true
	else:
		if choice2_button:
			choice2_button.visible = false
	
	visible = true
	get_tree().paused = true

func _on_choice1_pressed() -> void:
	if current_event and current_event.options.size() >= 1:
		var effect_id = current_event.options[0].get("effect_id", "")
		_handle_choice(effect_id)

func _on_choice2_pressed() -> void:
	if current_event and current_event.options.size() >= 2:
		var effect_id = current_event.options[1].get("effect_id", "")
		_handle_choice(effect_id)

func _handle_choice(effect_id: String) -> void:
	option_selected.emit(effect_id)
	
	visible = false
	get_tree().paused = false
	
	current_event = null
