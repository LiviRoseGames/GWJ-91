extends Node2D

var drawing = false
var current_line : Line2D

var current_width: float = 18.0

var last_pos : Vector2
var last_time : float

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

	current_line.width = 18
	current_line.round_precision = 8
	current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.texture = preload("res://CrayonSystem/CrayonTexture.png")
	current_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	current_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	current_line.default_color = Color(1, 0, 0)

	var mat = ShaderMaterial.new()
	mat.shader = preload("res://CrayonSystem/crayonGrain.gdshader")

	current_line.material = mat

	add_child(current_line)
	
	last_pos = get_global_mouse_position()
	last_time = Time.get_ticks_msec() / 1000.0


func stop_drawing():
	drawing = false
	current_line = null


func add_point(pos):
	if current_line.get_point_count() == 0:
		current_line.add_point(pos)
		return

	var now = Time.get_ticks_msec() / 1000.0
	var dt = now - last_time

	var dist = last_pos.distance_to(pos)

	var speed = dist / max(dt, 0.001)

	last_pos = pos
	last_time = now

	var target_width = clamp(speed * 0.05, 8.0, 30.0)

	current_width = lerp(current_width, target_width, 0.2)

	current_line.width = current_width

	var last_point = current_line.get_point_position(current_line.get_point_count() - 1)

	if last_point.distance_to(pos) < 6:
		return

	current_line.add_point(pos)
		
#func add_collision(a, b):
#
	#var area = Area2D.new()
	#var collision = CollisionShape2D.new()
	#
	#var segment = SegmentShape2D.new()
	#segment.a = a
	#segment.b = b
	#
	#collision.shape = segment
	#
	#area.add_child(collision)
	#add_child(area)
