@tool
extends Node2D
class_name Banana
signal split_occurred(banana: Banana)
@export_range(10.0, 300.0, 1.0) var reaction_radius: float = 90.0
var alive: bool = true

@export_range(0, 20, 1) var power_yield: int = 1
@export_range(0, 20, 1) var heat_yield: int = 1

@export_range(4.0, 64.0, 1.0) var hit_radius: float = 18.0:
	set(value):
		hit_radius = value
		queue_redraw()

@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()

func _draw() -> void:
	if texture == null:
		draw_circle(Vector2.ZERO, hit_radius, Color("ffd23f"))
	else:
		var image_size: Vector2 = texture.get_size()
		var largest_side: float = maxf(image_size.x, image_size.y)
		var draw_size: Vector2 = image_size * (hit_radius * 2.0 / largest_side)
		
		draw_texture_rect(
			texture,
			Rect2(-draw_size * 0.5, draw_size),
			false
		)
	
	draw_arc(
		Vector2.ZERO,
		hit_radius,
		0.0,
		TAU,
		40,
		Color(1.0, 0.85, 0.25, 0.5),
		1.0,
		true
	)
	

func split() -> void:
	if not alive:
		return
	
	alive = false
	hide()
	split_occurred.emit(self)
