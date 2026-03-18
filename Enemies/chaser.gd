extends CharacterBody2D

@export var speed: float = 180.0
@export var gravity: float = 900.0
@export var player: Node2D

func _physics_process(delta):

	if player == null:
		return

	# Move toward player (autorunner style: mostly horizontal)
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()


func _on_catch_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.die()
