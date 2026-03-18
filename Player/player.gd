extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 900.0

func _physics_process(delta):

	# Constant forward movement
	velocity.x = speed

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jump input (optional but recommended)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

func die():
	call_deferred("_die_safe")

func _die_safe():
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()
