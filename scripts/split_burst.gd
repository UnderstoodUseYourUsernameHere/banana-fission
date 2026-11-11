extends Node2D

const LIFETIME: float = 0.25
const SPARK_COUNT: int = 8

var age: float = 0.0

func _process(delta: float) -> void:
	age += delta
	
	if age >= LIFETIME:
		queue_free()
		return
	
	queue_redraw()

func _draw() -> void:
	var progress: float = clampf(age / LIFETIME, 0.0, 1.0)
	var opacity: float = 1.0 - progress
	var inner_distance: float = 6.0 + progress * 24.0
	var outer_distance: float = inner_distance + 10.0 * opacity
	var spark_color := Color(1.0, 0.85, 0.25, opacity)
	
	for index in range(SPARK_COUNT):
		var direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(index) / float(SPARK_COUNT))
		draw_line(direction * inner_distance, direction * outer_distance, spark_color, 2.0, true)
