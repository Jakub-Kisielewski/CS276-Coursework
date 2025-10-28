extends CanvasLayer

var score = 0

@onready var score_label = $ScoreLabel

func _ready():
	update_score_display()

func add_score(amount):
	score += amount
	update_score_display()

func update_score_display():
	score_label.text = "Score: " + str(score)
