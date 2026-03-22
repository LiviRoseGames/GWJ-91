extends Node2D

@export var segment_width: float = 400       # width of each hazard segment
@export var line_y_offset: float = 200       # vertical offset from 0
@export var line_thickness: float = 8
@export var color: Color = Color(1, 0, 0)   # red hazard
@export var cleanup_distance: float = 800   # how far behind player segments are removed

@export var player_node_path: NodePath = "../Player"
var player: CharacterBody2D

# Tracks the x-position of the next segment to spawn
var next_spawn_x: float = 0.0

# Keep a list of all hazard segments for cleanup
var hazard_segments: Array = []

func _ready():
	player = get_node(player_node_path)
	next_spawn_x = global_position.x

func _process(delta):
	if not player or not is_instance_valid(player):
		return

	# Spawn hazard segments ahead of player
	while next_spawn_x < player.global_position.x + 1200:
		spawn_segment(next_spawn_x)
		next_spawn_x += segment_width

	# Cleanup hazard segments behind the player
	for segment in hazard_segments.duplicate():
		if segment.global_position.x + segment_width < player.global_position.x - cleanup_distance:
			hazard_segments.erase(segment)
			segment.queue_free()

	# Check if player fell below any segment
	for segment in hazard_segments:
		var hazard_y = segment.global_position.y + line_y_offset
		if player.global_position.y >= hazard_y:
			player.die()


func spawn_segment(x_pos: float):
	# Create a Line2D for this segment
	var line = Line2D.new()
	add_child(line)
	line.width = line_thickness
	line.modulate = color
	line.points = [
		Vector2(0, line_y_offset),
		Vector2(segment_width, line_y_offset)
	]
	line.position = Vector2(x_pos, 0)

	hazard_segments.append(line)
