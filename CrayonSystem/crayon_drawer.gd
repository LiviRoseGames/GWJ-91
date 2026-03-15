extends Node2D

var drawing = false
var current_line : Line2D

func _input(event):

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:
				start_drawing()
			else:
				stop_drawing()

	if event is InputEventMouseMotion and drawing:
		add_point(event.position)


func start_drawing():

	drawing = true

	current_line = Line2D.new()
	current_line.width = 8
	current_line.default_color = Color(1, 0, 0)

	add_child(current_line)


func stop_drawing():
	drawing = false
	current_line = null


func add_point(pos):

	if current_line:
		current_line.add_point(pos)
