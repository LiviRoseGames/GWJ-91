extends CharacterBody2D

# -------------------------------
# Movement
# -------------------------------
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 900.0

# -------------------------------
# Smoothing / Juice
# -------------------------------
var target_scale: Vector2 = Vector2.ONE
var current_scale: Vector2 = Vector2.ONE
var base_offset: Vector2 = Vector2.ZERO

var base_speed: float
@export var speed_ramp_rate: float = 5.0

var death_timer: float = 0.0
var death_duration: float = 0.6

# -------------------------------
# Animation
# -------------------------------
@export var sprite: Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# Base capsule values for running
var collision_run_radius: float = 18.5
var collision_run_height: float = 82.0
var collision_run_position: Vector2 = Vector2(27, 21)

# Target capsule values (will lerp to these)
var collision_target_radius: float
var collision_target_height: float
var collision_target_position: Vector2

enum State { RUN, JUMP, FALL, LAND, DIE }
var state = State.RUN

var run_frames = [
	[preload("res://Player/sprites/run/run_frame1a.png"), preload("res://Player/sprites/run/run_frame1b.png"), preload("res://Player/sprites/run/run_frame1c.png")],
	[preload("res://Player/sprites/run/run_frame2a.png"), preload("res://Player/sprites/run/run_frame2b.png"), preload("res://Player/sprites/run/run_frame2c.png")],
	[preload("res://Player/sprites/run/run_frame3a.png"), preload("res://Player/sprites/run/run_frame3b.png"), preload("res://Player/sprites/run/run_frame3c.png")],
	[preload("res://Player/sprites/run/run_frame4a.png"), preload("res://Player/sprites/run/run_frame4b.png"), preload("res://Player/sprites/run/run_frame4c.png")],
	[preload("res://Player/sprites/run/run_frame5a.png"), preload("res://Player/sprites/run/run_frame5b.png"), preload("res://Player/sprites/run/run_frame5c.png")]
]

var jump_frames = [
	[preload("res://Player/sprites/jump/jump_frame1a.png"), preload("res://Player/sprites/jump/jump_frame1b.png"), preload("res://Player/sprites/jump/jump_frame1c.png")],
	[preload("res://Player/sprites/jump/jump_frame2a.png"), preload("res://Player/sprites/jump/jump_frame2b.png"), preload("res://Player/sprites/jump/jump_frame2c.png")],
	[preload("res://Player/sprites/jump/jump_frame3a.png"), preload("res://Player/sprites/jump/jump_frame3b.png"), preload("res://Player/sprites/jump/jump_frame3c.png")],
	[preload("res://Player/sprites/jump/jump_frame4a.png"), preload("res://Player/sprites/jump/jump_frame4b.png"), preload("res://Player/sprites/jump/jump_frame4c.png")]
]

var frame_index: int = 0
var frame_time: float = 0.0
var base_frame_duration: float = 0.1

var was_on_floor := true

# -------------------------------
# Lifecycle
# -------------------------------
func _ready():
	randomize()
	set_frame(run_frames, 0)
	base_speed = speed

	# Assign the player to the ScoreManager singleton
	ScoreManager.player = self
	ScoreManager.reset_score()

	# Initialize collision lerp targets to running shape
	collision_target_radius = collision_run_radius
	collision_target_height = collision_run_height
	collision_target_position = collision_run_position


func _physics_process(delta):
	# --- Speed ramp ---
	speed += speed_ramp_rate * delta

	# --- Movement ---
	velocity.x = speed

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		state = State.JUMP
		frame_index = 0
		frame_time = 0
		target_scale = Vector2(1.3, 0.7) # takeoff squash

	move_and_slide()

	# --- State transitions ---
	handle_state_transitions()

	# --- Animation ---
	update_animation(delta)

	# --- Smooth collision update ---
	update_collision_shape_lerp(delta)

	was_on_floor = is_on_floor()

# -------------------------------
# Collision Update (Lerp)
# -------------------------------
func update_collision_shape_lerp(delta):
	if not is_instance_valid(collision):
		return
	var shape = collision.shape
	if shape == null or not shape is CapsuleShape2D:
		return

	# Lerp radius, height, position
	shape.radius = lerp(shape.radius, collision_target_radius, 10 * delta)
	shape.height = lerp(shape.height, collision_target_height, 10 * delta)
	collision.position = collision.position.lerp(collision_target_position, 10 * delta)


# -------------------------------
# State Machine
# -------------------------------
func handle_state_transitions():
	if state == State.DIE:
		return

	if was_on_floor and not is_on_floor():
		state = State.JUMP
		frame_index = 0
		set_collision_for_state(State.JUMP)

	if state == State.JUMP and velocity.y > 0:
		state = State.FALL
		frame_index = 2
		set_collision_for_state(State.FALL)

	if not was_on_floor and is_on_floor():
		state = State.LAND
		frame_index = 3
		frame_time = 0
		target_scale = Vector2(1.3, 0.7) # landing squash
		set_collision_for_state(State.LAND)


# -------------------------------
# Collision Targets per State
# -------------------------------
func set_collision_for_state(s: int):
	match s:
		State.RUN:
			collision_target_radius = 18.5
			collision_target_height = 82.0
			collision_target_position = Vector2(27, 21)
		State.JUMP:
			collision_target_radius = 18.0
			collision_target_height = 52.0
			collision_target_position = Vector2(38, -9)  # your true jump capsule
		State.FALL:
			collision_target_radius = 18.0
			collision_target_height = 52.0
			collision_target_position = Vector2(38, -9)  # same as jump
		State.LAND:
			collision_target_radius = 22
			collision_target_height = 55
			collision_target_position = Vector2(27, 35)
		State.DIE:
			collision_target_radius = 25
			collision_target_height = 30
			collision_target_position = Vector2(27, 35)


# -------------------------------
# Animation Logic
# -------------------------------
func update_animation(delta):
	if not is_instance_valid(sprite):
		return
	match state:
		State.RUN: run_animation(delta)
		State.JUMP: jump_up_animation(delta)
		State.FALL: fall_animation()
		State.LAND: land_animation(delta)
		State.DIE: death_animation(delta)

	# Position jitter
	var jitter = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	sprite.position = base_offset + jitter

	# Rotation
	if state != State.DIE:
		sprite.rotation = randf_range(-0.03, 0.03)

	# Scale smoothing
	target_scale = target_scale.lerp(Vector2.ONE, 8 * delta)
	current_scale = current_scale.lerp(target_scale, 10 * delta)
	sprite.scale = current_scale


# -------------------------------
# Animation States
# -------------------------------
func run_animation(delta):
	var speed_factor = abs(velocity.x) / speed
	var frame_duration = base_frame_duration / max(speed_factor, 0.1)
	frame_time += delta
	if frame_time >= frame_duration:
		frame_time = 0
		frame_index = (frame_index + 1) % run_frames.size()
	set_frame(run_frames, frame_index)

func jump_up_animation(delta):
	frame_time += delta
	if frame_index < 1 and frame_time > base_frame_duration:
		frame_time = 0
		frame_index += 1
	set_frame(jump_frames, frame_index)

func fall_animation():
	set_frame(jump_frames, 2)

func land_animation(delta):
	frame_time += delta
	set_frame(jump_frames, 3)
	if frame_time > base_frame_duration:
		state = State.RUN
		frame_index = 0

# -------------------------------
# Frame Setter
# -------------------------------
func set_frame(frame_array, index):
	var variants = frame_array[index]
	sprite.texture = variants[randi() % variants.size()]
	apply_pose_offset(frame_array, index)

func apply_pose_offset(frame_array, index):
	var offset = Vector2.ZERO
	var scale_offset = Vector2.ONE

	# --- RUN ---
	if frame_array == run_frames:
		match index:
			0: offset = Vector2(0, 1)
			1: offset = Vector2(0, -1)
			2: offset = Vector2(0, 1)
			3: offset = Vector2(0, -1)
			4: offset = Vector2.ZERO
	# --- JUMP ---
	if frame_array == jump_frames:
		match index:
			0: scale_offset = Vector2(0.9, 1.1)
			1: offset = Vector2(0, -2)
			2: offset = Vector2(0, 2)
			3: scale_offset = Vector2(1.2, 0.8)

	base_offset = offset
	target_scale = scale_offset


# -------------------------------
# Death
# -------------------------------
func die():
	if state == State.DIE:
		return

	state = State.DIE
	death_timer = 0.0

	ScoreManager.finalize_high_score()

	var overlay = get_tree().current_scene.get_node("DeathOverlay")
	if overlay:
		overlay.show_overlay(int(ScoreManager.score), int(ScoreManager.high_score))

func death_animation(delta):
	death_timer += delta

	velocity = Vector2.ZERO

	# Fall
	base_offset.y += 100 * delta

	# Rotate to 90°
	var target_rotation = deg_to_rad(90)
	sprite.rotation = lerp(sprite.rotation, target_rotation, 5 * delta)

	# Squash
	target_scale = Vector2(1.2, 0.8)

	if death_timer >= death_duration:
		# Make sure high score is saved before reloading
		if ScoreManager:
			ScoreManager.update_high_score()
			ScoreManager.save_high_score()
		
		get_tree().reload_current_scene()
