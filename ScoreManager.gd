extends Node

@export var score_multiplier: float = 1.0

var score: float = 0
var high_score: int = 0
var player: CharacterBody2D = null

func _ready():
	load_high_score()

func _process(delta: float) -> void:
	if player and is_instance_valid(player):
		score = player.global_position.x * score_multiplier
		if score > high_score:
			high_score = int(score)

func reset_score():
	score = 0

func update_high_score():
	if score > high_score:
		high_score = int(score)

func save_high_score():
	var file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	if file:
		file.store_var(high_score)
		file.close()

func load_high_score():
	if FileAccess.file_exists("user://highscore.save"):
		var file = FileAccess.open("user://highscore.save", FileAccess.READ)
		if file:
			high_score = file.get_var()
			file.close()

func finalize_high_score():
	update_high_score()
	save_high_score()
