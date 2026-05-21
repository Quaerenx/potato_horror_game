extends Camera2D
class_name CameraController

var shake_time := 0.0
var shake_strength := 0.0

func shake(duration: float, strength: float) -> void:
	shake_time = duration
	shake_strength = strength

func _process(delta: float) -> void:
	if shake_time <= 0.0:
		offset = Vector2.ZERO
		return
	shake_time -= delta
	offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
