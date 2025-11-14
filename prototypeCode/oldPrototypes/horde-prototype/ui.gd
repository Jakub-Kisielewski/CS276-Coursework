extends CanvasLayer

var score = 0

@onready var score_label = $ScoreLabel

func _ready():
	score_label.add_theme_font_size_override("font_size", 100)
	update_score_display()

func add_score(amount):
	score += amount
	update_score_display()

func update_score_display():
	score_label.text = "Score: " + str(score)
	
