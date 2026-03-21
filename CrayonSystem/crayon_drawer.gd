extends Node2D

# -------------------------------
# Crayon Drawing / Ink System
# -------------------------------

var drawing = false
var current_line: Line2D
var current_stroke: Node2D

@export var crayonColor: Color = Color(1, 0.3, 0.3)  # Color of crayon

# Ink system
var max_ink: float = 100.0
var ink: float = 100.0
var ink_use_rate: float = 40.0    # per second while drawing
var ink_regen_rate: float = 20.0  # per second when not drawing

@export var ink_bar: TextureProgressBar


# -------------------------------
# Godot Lifecycle
# -------------------------------
func _ready() -> void:
	ink = max_ink  # start full


func _process(delta: float) -> void:
	# --- Update ink first ---
	if drawing:
		ink -= ink_use_rate * delta
	else:
		ink += ink_regen_rate * delta

	ink = clamp(ink, 0, max_ink)

	if ink <= 0 and drawing:
		stop_drawing()

	# --- Update UI ---
	if ink_bar:
		ink_bar.max_value = max_ink
		ink_bar.value = ink
	
		var percent = ink / max_ink
	
		# Choose colors (fully opaque)
		var empty_color = Color(0.4, 0.4, 0.4, 1.0)  # dark gray
		var full_color = Color(crayonColor.r, crayonColor.g, crayonColor.b, 1.0)
	
		# Lerp color based on ink percent
		ink_bar.modulate = empty_color.lerp(full_color, percent)


# -------------------------------
# Input Handling
# -------------------------------
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and ink > 0:
			start_drawing()
		else:
			stop_drawing()

	if event is InputEventMouseMotion and drawing:
		add_point(get_global_mouse_position())


# -------------------------------
# Drawing Functions
# -------------------------------
func start_drawing():
	drawing = true

	current_stroke = Node2D.new()
	add_child(current_stroke)

	current_line = Line2D.new()
	current_line.width = 18
	current_line.round_precision = 8
	current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.joint_mode = Line2D.LINE_JOINT_ROUND

	current_line.texture = preload("res://CrayonSystem/CrayonTexture.png")
	current_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	current_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	current_line.default_color = crayonColor

	var mat = ShaderMaterial.new()
	mat.shader = preload("res://CrayonSystem/crayonGrain.gdshader")
	current_line.material = mat

	current_stroke.add_child(current_line)


func stop_drawing():
	if not drawing:
		return

	drawing = false
	current_line = null

	if is_instance_valid(current_stroke):
		fade_stroke(current_stroke)
		current_stroke = null


func add_point(pos: Vector2):
	if not is_instance_valid(current_line):
		return

	if current_line.get_point_count() == 0:
		current_line.add_point(pos)
		return

	var last_point = current_line.get_point_position(current_line.get_point_count() - 1)

	if last_point.distance_to(pos) < 6:
		return

	add_collision(last_point, pos)
	current_line.add_point(pos)


# -------------------------------
# Collision for Walls
# -------------------------------
func add_collision(a: Vector2, b: Vector2):
	if not is_instance_valid(current_stroke):
		return

	var body = StaticBody2D.new()

	var collision = CollisionShape2D.new()
	var shape = SegmentShape2D.new()
	shape.a = a
	shape.b = b
	collision.shape = shape
	body.add_child(collision)

	current_stroke.add_child(body)

	# Limit walls per stroke to prevent performance issues
	var count = 0
	for child in current_stroke.get_children():
		if child is StaticBody2D:
			count += 1
	if count > 200:
		for child in current_stroke.get_children():
			if child is StaticBody2D:
				child.queue_free()
				break


# -------------------------------
# Fade Stroke (Visual + Collision)
# -------------------------------
func fade_stroke(stroke: Node):
	if not is_instance_valid(stroke):
		return

	var line: Line2D = null
	for child in stroke.get_children():
		if child is Line2D:
			line = child
			break
	if line == null:
		return

	var duration = 1.0
	var time_passed = 0.0

	while time_passed < duration:
		if not is_instance_valid(stroke) or not is_inside_tree():
			return

		await Engine.get_main_loop().process_frame
		time_passed += get_process_delta_time()

		if not is_instance_valid(line):
			return

		var alpha = 1.0 - (time_passed / duration)
		line.modulate.a = alpha

	if is_instance_valid(stroke):
		stroke.queue_free()
