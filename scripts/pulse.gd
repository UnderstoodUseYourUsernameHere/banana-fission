extends Node2D
class_name Pulse

@export_range(1.0, 300.0, 1.0) var max_radius: float = 90.0
@export_range(0.05, 2.0, 0.01) var expansion_time: float = 0.45
@export_range(0.05, 1.0, 0.01) var fade_time: float = 0.15

var radius: float = 0.0
var age: float = 0.0

func advance(delta: float) -> void:
	age += delta
	radius = max_radius * clampf(age / expansion_time, 0.0, 1.0)
	queue_redraw()

func has_finished() -> bool:
	return age >= expansion_time + fade_time

func _draw() -> void:
	if radius <= 0.0:
		return
	
	var opacity: float = 1.0
	
	if age > expansion_time:
		opacity = 1.0 - clampf(
			(age - expansion_time) / fade_time,
			0.0,
			1.0
		)
	
	draw_circle(
		Vector2.ZERO,
		radius,
		Color(0.25, 0.85, 1.0, 0.12 * opacity)
	)
	
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		64,
		Color(0.4, 0.95, 1.0, opacity),
		2.0,
		true
	)
