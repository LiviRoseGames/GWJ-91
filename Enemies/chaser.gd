extends CharacterBody2D

# -------------------------------
# Movement
# -------------------------------
@export var speed: float = 180.0
@export var gravity: float = 900.0
@export var player: CharacterBody2D

# -------------------------------
# Animation
# -------------------------------
@export var sprite: Sprite2D

var run_frames = [
	[preload("res://Player/sprites/run/run_frame1a.png"), preload("res://Player/sprites/run/run_frame1b.png"), preload("res://Player/sprites/run/run_frame1c.png")],
	[preload("res://Player/sprites/run/run_frame2a.png"), preload("res://Player/sprites/run/run_frame2b.png"), preload("res://Player/sprites/run/run_frame2c.png")],
	[preload("res://Player/sprites/run/run_frame3a.png"), preload("res://Player/sprites/run/run_frame3b.png"), preload("res://Player/sprites/run/run_frame3c.png")],
	[preload("res://Player/sprites/run/run_frame4a.png"), preload("res://Player/sprites/run/run_frame4b.png"), preload("res://Player/sprites/run/run_frame4c.png")],
	[preload("res://Player/sprites/run/run_frame5a.png"), preload("res://Player/sprites/run/run_frame5b.png"), preload("res://Player/sprites/run/run_frame5c.png")]
]

var frame_index: int = 0
var frame_time: float = 0.0
var base_frame_duration: float = 0.1

var base_offset: Vector2 = Vector2.ZERO
var target_scale: Vector2 = Vector2.ONE
var current_scale: Vector2 = Vector2.ONE

# -------------------------------
# Lifecycle
# -------------------------------
func _ready():
	randomize()
	frame_index = 0
	frame_time = 0
	set_frame(run_frames, frame_index)

# -------------------------------
# Physics / Movement
# -------------------------------
func _physics_process(delta):
	if not player or not is_instance_valid(player):
		return

	# Move toward player (autorunner style)
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()

	# Despawn if fell far below camera
	if global_position.y > get_viewport().get_visible_rect().size.y + 400:
		queue_free()

	# Animate like the player
	run_animation(delta)

# -------------------------------
# Run Animation (copy of player)
# -------------------------------
func run_animation(delta):
	var speed_factor = abs(velocity.x) / speed
	var frame_duration = base_frame_duration / max(speed_factor, 0.1)
	frame_time += delta
	if frame_time >= frame_duration:
		frame_time = 0
		frame_index = (frame_index + 1) % run_frames.size()
	set_frame(run_frames, frame_index)

func set_frame(frame_array, index):
	var variants = frame_array[index]
	sprite.texture = variants[randi() % variants.size()]
	apply_pose_offset(frame_array, index)

func apply_pose_offset(frame_array, index):
	var offset = Vector2.ZERO
	var scale_offset = Vector2.ONE

	# Run offsets same as player
	if frame_array == run_frames:
		match index:
			0: offset = Vector2(0, 1)
			1: offset = Vector2(0, -1)
			2: offset = Vector2(0, 1)
			3: offset = Vector2(0, -1)
			4: offset = Vector2.ZERO

	base_offset = offset
	target_scale = scale_offset

	# Smooth scaling like player
	current_scale = current_scale.lerp(target_scale, 10 * get_process_delta_time())
	sprite.scale = current_scale
	sprite.position = base_offset

# -------------------------------
# Catch player
# -------------------------------
func _on_catch_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body.has_method("die"):
		body.die()
