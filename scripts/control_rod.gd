@tool
extends Node2D
class_name ControlRod

@export var size: Vector2 = Vector2(16.0, 160.0):
	set(value):
		size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		queue_redraw()

func world_rect() -> Rect2:
	return Rect2(global_position - size * 0.5, size)

func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, Color("2b2f36"))
	draw_rect(rect, Color("5a6270"), false, 2.0)
	
	var stripe_height: float = minf(6.0, size.y)
	var stripe := Color("d9a441")
	
	draw_rect(Rect2(rect.position, Vector2(size.x, stripe_height)), stripe)
	draw_rect(Rect2(
		Vector2(rect.position.x, rect.end.y - stripe_height),
		Vector2(size.x, stripe_height)
		), stripe
	)

static func blocks_line(line_start: Vector2, line_end: Vector2, rod_rects: Array[Rect2]) -> bool:
	for rect in rod_rects:
		if rect.has_point(line_start) or rect.has_point(line_end):
			return true
		
		var corners := PackedVector2Array([
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y)
		])
		
		for index in range(4):
			var next_index: int = (index + 1) % 4
			var intersection = Geometry2D.segment_intersects_segment(
				line_start,
				line_end,
				corners[index],
				corners[next_index]
			)
			
			if intersection != null:
				return true
			
	return false
