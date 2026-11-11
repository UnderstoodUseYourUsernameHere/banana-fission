@tool
extends Node2D
class_name Banana
signal split_occurred(banana: Banana)
@export_range(10.0, 300.0, 1.0) var reaction_radius: float = 90.0
var alive: bool = true
var _velocity: Vector2 = Vector2.ZERO

@export_range(0, 20, 1) var power_yield: int = 1
@export_range(0, 20, 1) var heat_yield: int = 1

@export_group("BananaMovement")
@export_range(0.0, 100.0, 1.0) var drift_speed: float = 0.0
@export_range(0.0, 360.0, 1.0) var start_angle_degrees: float = 0.0

@export_range(4.0, 64.0, 1.0) var hit_radius: float = 18.0:
	set(value):
		hit_radius = value
		queue_redraw()

@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()

@export var half_texture: Texture2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_velocity = Vector2.RIGHT.rotated(deg_to_rad(start_angle_degrees)) * drift_speed

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

func advance_motion(delta: float, chamber_bounds: Rect2) -> void:
	if not alive:
		return
	
	var next_position: Vector2 = global_position + _velocity * delta
	var minimum: Vector2 = chamber_bounds.position + Vector2.ONE * hit_radius
	var maximum: Vector2 = chamber_bounds.end - Vector2.ONE * hit_radius
	
	if next_position.x < minimum.x:
		next_position.x = minimum.x
		_velocity.x = absf(_velocity.x)
	elif next_position.x > maximum.x:
		next_position.x = maximum.x
		_velocity.x = -absf(_velocity.x)
	
	if next_position.y < minimum.y:
		next_position.y = minimum.y
		_velocity.y = absf(_velocity.y)
	elif next_position.y > maximum.y:
		next_position.y = maximum.y
		_velocity.y = -absf(_velocity.y)
	
	global_position = next_position

func get_drift_velocity() -> Vector2:
	return _velocity
