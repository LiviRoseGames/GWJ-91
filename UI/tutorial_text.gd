extends Panel

@export var fade_after: float = 10.0
@export var fade_duration: float = 2.0

var elapsed_time := 0.0

func _process(delta):
	elapsed_time += delta

	if elapsed_time >= fade_after:
		var fade_progress = (elapsed_time - fade_after) / fade_duration
		modulate.a = clamp(1.0 - fade_progress, 0, 1)

		if modulate.a <= 0:
			queue_free()
			set_process(false)
