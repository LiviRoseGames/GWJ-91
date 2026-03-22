extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var vbox: VBoxContainer = $Panel/CenterContainer/VBoxContainer
@onready var title_label: RichTextLabel = $Panel/CenterContainer/VBoxContainer/TDGA
@onready var score_label: RichTextLabel = $Panel/CenterContainer/VBoxContainer/ScoreLabel
@onready var highscore_label: RichTextLabel = $Panel/CenterContainer/VBoxContainer/HighScoreLabel
@onready var button: Button = $Panel/CenterContainer/VBoxContainer/TryAgain

@export var fade_duration: float = 0.8

var tween: Tween
var showing: bool = false

# NEW! high score variables
var is_new_highscore: bool = false
var wave_time: float = 0.0

func _ready():
	# Allow UI to update while game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.process_mode = Node.PROCESS_MODE_ALWAYS

	# Start hidden
	panel.modulate.a = 0
	panel.visible = false
	
	# Make sure panel fills screen
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	$Panel/CenterContainer.set_anchors_preset(Control.PRESET_FULL_RECT)

	# VBox styling
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)

	# Label styling
	for label in [title_label, score_label, highscore_label]:
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.custom_minimum_size.x = 400

	title_label.bbcode_text = "[center][b]The thief didn't get away![/b][/center]"

	# Button styling
	button.text = "Try Again"
	button.custom_minimum_size = Vector2(200, 60)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(on_try_again_pressed)

func show_overlay(current_score: int, high_score: int) -> void:
	if showing:
		return
	showing = true
	
	panel.visible = true
	get_tree().paused = true

	# Detect if we hit a new high score
	is_new_highscore = current_score >= high_score

	# Display current score
	score_label.bbcode_text = "[center][b]Score:[/b] " + str(current_score) + "[/center]"

	# Display high score with optional NEW!
	if is_new_highscore:
		highscore_label.bbcode_text = "[center][b][color=yellow]NEW![/color] High Score:[/b] " + str(high_score) + "[/center]"
	else:
		highscore_label.bbcode_text = "[center][b]High Score:[/b] " + str(high_score) + "[/center]"

	# Start invisible + slightly scaled down
	panel.modulate.a = 0.0
	vbox.scale = Vector2(0.9, 0.9)
	wave_time = 0.0  # reset wave

	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Fade in background
	tween.tween_property(panel, "modulate:a", 1.0, fade_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# Pop-in effect for VBox
	tween.parallel().tween_property(vbox, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func _process(delta):
	if not showing:
		return

	# NEW! Wave animation if high score was achieved
	if is_new_highscore:
		wave_time += delta * 6.0  # speed of wave

		var wave = sin(wave_time) * 0.05

		# Scale wobble for fun effect
		score_label.scale = Vector2(1.0 + wave, 1.0 - wave)
		highscore_label.scale = Vector2(1.0 - wave, 1.0 + wave)

func on_try_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
