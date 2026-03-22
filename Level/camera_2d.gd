extends Camera2D

@export var target: Node2D

var follow_offset := Vector2(200, -50)
var smooth_speed := 6.0

func _process(delta):

	if not is_instance_valid(target):
		return

	# --- Look ahead ---
	var look_ahead := 0.0
	if target is CharacterBody2D:
		look_ahead = target.velocity.x * 0.3

	var desired_position = Vector2(
		target.global_position.x + follow_offset.x + look_ahead,
		target.global_position.y + follow_offset.y
	)
	
	if target is CharacterBody2D:
		if target.velocity.y > 0:
			desired_position.y += 20

	# --- X movement (NO BACKWARDS) ---
	var new_x = lerp(global_position.x, desired_position.x, smooth_speed * delta)
	global_position.x = max(global_position.x, new_x)

	# --- Y movement (softer) ---
	global_position.y = lerp(global_position.y, desired_position.y, 4 * delta)
