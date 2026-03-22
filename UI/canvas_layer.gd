extends CanvasLayer

@onready var score_label: RichTextLabel = $ScoreLabel
@onready var highscore_label: RichTextLabel = $HighScoreLabel

@export var margin_left: float = 10.0
@export var margin_bottom: float = 10.0
@export var vertical_spacing: float = 4.0
@export var label_width: float = 600.0

func _ready() -> void:
	for label in [score_label, highscore_label]:
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.scroll_following = false
		label.custom_minimum_size.x = label_width

func _process(delta: float) -> void:
	update_labels()

func update_labels():
	var current_score = int(ScoreManager.score)
	var high_score = int(ScoreManager.high_score)

	score_label.bbcode_text = "[b]Score:[/b] " + str(current_score)
	highscore_label.bbcode_text = "[b]High Score:[/b] " + str(high_score)

	var viewport_size = get_viewport().get_visible_rect().size

	var score_height = score_label.get_content_height()
	var highscore_height = highscore_label.get_content_height()

	score_label.position = Vector2(margin_left, viewport_size.y - margin_bottom - score_height)
	highscore_label.position = Vector2(margin_left, score_label.position.y - vertical_spacing - highscore_height)
