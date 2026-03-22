extends Node2D

@export var player: CharacterBody2D
@export var ground_scene: PackedScene

# Spawning
var spawn_x: float = 0.0
var base_ground_y: float = 400.0  # fallback ground y

var min_segment_width = 120
var max_segment_width = 400

var min_gap = 120
var max_gap = 260

var cleanup_distance = 800
var first_segment_done := false

# Difficulty
var elapsed_time: float = 0.0
var difficulty_exponent: float = 0.05  # overall scaling speed

func _ready():
	spawn_x = player.global_position.x
	
	# Spawn a long initial ground segment
	var initial_width = 2000
	spawn_ground(initial_width)
	first_segment_done = true

func _process(delta):
	elapsed_time += delta
	
	# Difficulty multipliers
	var difficulty_multiplier = pow(2.71828, difficulty_exponent * elapsed_time)
	var gap_multiplier = pow(2.71828, difficulty_exponent * elapsed_time * 0.5)
	
	# Spawn ahead of player
	while spawn_x < player.global_position.x + 1200:
		spawn_pattern(difficulty_multiplier, gap_multiplier)
	
	cleanup_old()

# -------------------------------
func spawn_pattern(difficulty_multiplier, gap_multiplier):
	spawn_gap(gap_multiplier)
	spawn_platform_section(difficulty_multiplier)

func spawn_ground(width=-1):
	if width < 0:
		# Shrink ground width over time
		var shrink_factor = clamp(elapsed_time / 60.0, 0, 1)
		width = lerp(max_segment_width, min_segment_width, shrink_factor)

	var segment = ground_scene.instantiate()
	add_child(segment)
	segment.position = Vector2(spawn_x, base_ground_y)
	setup_segment(segment, width, true)

	spawn_x += width
	segment.set("width", width)
	segment.set("has_been_on_camera", false)

func spawn_gap(gap_multiplier=1.0):
	var gap = randf_range(min_gap, max_gap) * gap_multiplier
	spawn_x += gap

func spawn_platform_section(platform_multiplier=1.0):
	# Shrink width over time
	var shrink_factor = clamp(elapsed_time / 60.0, 0, 1)
	var max_width = 220
	var min_width = 120
	var width = lerp(max_width, min_width, shrink_factor)

	# Vertical spawn centered on player
	var center_y = player.global_position.y
	var max_offset = 120 * (1.0 - 0.5 * clamp(elapsed_time / 120.0, 0, 1))  # reduce vertical spread slightly over time
	var platform_y = clamp(center_y - randf_range(0, max_offset), 150, 500)

	var segment = ground_scene.instantiate()
	add_child(segment)
	segment.position = Vector2(spawn_x, platform_y)
	setup_segment(segment, width, true)

	spawn_x += width
	segment.set("width", width)
	segment.set("has_been_on_camera", false)

# -------------------------------
func setup_segment(segment, width, full_rectangle=false):
	var line = segment.get_node("Line2D")
	var collision = segment.get_node("StaticBody2D/CollisionShape2D")

	var dirt_color = Color(0.55, 0.35, 0.2)
	var grass_color = Color(0.2, 0.7, 0.3)
	var t = randf()
	var final_color = dirt_color.lerp(grass_color, t)
	final_color *= randf_range(0.85, 1.15)

	line.clear_points()

	if full_rectangle:
		var height = 40
		line.width = 16
		line.points = [
			Vector2(0, 0),
			Vector2(width, 0),
			Vector2(width, height),
			Vector2(0, height),
			Vector2(0, 0)
		]

		for i in range(2):
			var extra_line = line.duplicate()
			segment.add_child(extra_line)
			extra_line.points = [
				Vector2(0, randf_range(-4, 4)),
				Vector2(width, randf_range(-4, 4)),
				Vector2(width, height + randf_range(-4, 4)),
				Vector2(0, height + randf_range(-4, 4)),
				Vector2(0, randf_range(-4, 4))
			]
			extra_line.width = 12
			extra_line.modulate = final_color
	else:
		line.points = [Vector2(0,0), Vector2(width,0)]
		line.width = 12

	line.modulate = final_color

	var shape = RectangleShape2D.new()
	shape.size = Vector2(width, 40)
	collision.shape = shape
	collision.position = Vector2(width / 2, 20)

# -------------------------------
func cleanup_old():
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	var left_edge = camera.global_position.x - get_viewport().get_visible_rect().size.x * 0.5

	for child in get_children():
		if not child.has_meta("width"):
			continue

		var width = child.get("width")
		
		if child.global_position.x + width > left_edge:
			child.set("has_been_on_camera", true)

		if child.get("has_been_on_camera") and child.global_position.x + width < left_edge:
			child.queue_free()
