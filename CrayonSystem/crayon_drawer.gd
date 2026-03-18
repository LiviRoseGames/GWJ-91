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
		add_point(get_global_mouse_position()) # FIXED


func start_drawing():
	drawing = true

	current_line = Line2D.new()

	current_line.width = 18
	current_line.round_precision = 8
	current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.joint_mode = Line2D.LINE_JOINT_ROUND

	current_line.texture = preload("res://CrayonSystem/CrayonTexture.png")
	current_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	current_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	current_line.default_color = Color(1, 0, 0)

	var mat = ShaderMaterial.new()
	mat.shader = preload("res://CrayonSystem/crayonGrain.gdshader")
	current_line.material = mat

	add_child(current_line)


func stop_drawing():
	drawing = false
	current_line = null


func add_point(pos):

	if current_line.get_point_count() == 0:
		current_line.add_point(pos)
		return

	var last_point = current_line.get_point_position(current_line.get_point_count() - 1)

	#Prevents too many points
	if last_point.distance_to(pos) < 6:
		return

	current_line.add_point(pos)
