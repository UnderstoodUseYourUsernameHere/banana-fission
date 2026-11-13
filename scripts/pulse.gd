extends Node2D
class_name Pulse

@export_range(1.0, 300.0, 1.0) var max_radius: float = 90.0
@export_range(0.05, 2.0, 0.01) var expansion_time: float = 0.45
@export_range(0.05, 1.0, 0.01) var fade_time: float = 0.15

var radius: float = 0.0
var age: float = 0.0
var ring_color: Color = Color(0.4, 0.95, 1.0)

static func radius_at(
	age_now: float,
	maximum: float,
	expansion: float
) -> float:
	return maximum * clampf(age_now / expansion, 0.0, 1.0)

func advance(delta: float) -> void:
	age += delta
	radius = Pulse.radius_at(age, max_radius, expansion_time)
	queue_redraw()

func has_finished() -> bool:
	return age >= expansion_time + fade_time

func reaches(world_position: Vector2, target_radius: float) -> bool:
	var combined_radius: float = radius + target_radius
	
	return global_position.distance_squared_to(world_position) <= (combined_radius * combined_radius)

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
		Color(ring_color, 0.12 * opacity)
	)
	
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		64,
		Color(ring_color, opacity),
		2.0,
		true
	)
