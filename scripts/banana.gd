@tool
extends Node2D
class_name Banana
signal split_occurred(banana: Banana)

enum Kind { NORMAL, OVERRIPE }

@export var kind: Kind = Kind.NORMAL:
	set(value):
		kind = value
		_apply_kind()
		queue_redraw()

@export_range(10.0, 300.0, 1.0) var reaction_radius: float = 90.0
var alive: bool = true
var _velocity: Vector2 = Vector2.ZERO

@export_range(0, 20, 1) var power_yield: int = 1
@export_range(0, 20, 1) var heat_yield: int = 1

@export_group("BananaMovement")
@export_range(0.0, 200.0, 1.0) var drift_speed: float = 0.0
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
	_apply_kind()
	
	if Engine.is_editor_hint():
		return
	
	_velocity = Vector2.RIGHT.rotated(deg_to_rad(start_angle_degrees)) * drift_speed

func _draw() -> void:
	var tint: Color = Color.WHITE if kind == Kind.NORMAL else Color("c08a3c")
	
	if texture == null:
		var body: Color = Color("ffd23f") if kind == Kind.NORMAL else Color("a9802c")
		draw_circle(Vector2.ZERO, hit_radius, body)
	else:
		var image_size: Vector2 = texture.get_size()
		var largest_side: float = maxf(image_size.x, image_size.y)
		var draw_size: Vector2 = image_size * (hit_radius * 2.0 / largest_side)
		draw_texture_rect(texture, Rect2(-draw_size * 0.5, draw_size), false, tint)
	
	if kind == Kind.OVERRIPE:
		var spot := Color("4a3418")
		draw_circle(Vector2(-6.0, -4.0) * hit_radius / 18.0, 3.0, spot)
		draw_circle(Vector2(5.0, 2.0) * hit_radius / 18.0, 4.0, spot)
		draw_circle(Vector2(-1.0, 8.0) * hit_radius / 18.0, 2.5, spot)
	
	draw_arc(Vector2.ZERO, hit_radius, 0.0, TAU, 40, Color(1.0, 0.85, 0.25, 0.5), 1.0, true)

func split() -> void:
	if not alive:
		return
	
	alive = false
	hide()
	split_occurred.emit(self)

func advance_motion(delta: float, chamber_bounds: Rect2, rods: Array[Rect2]) -> void:
	if not alive:
		return
	
	var next_position: Vector2 = global_position + _velocity * delta
	var minimum: Vector2 = chamber_bounds.position + Vector2.ONE * hit_radius
	var maximum: Vector2 = chamber_bounds.end - Vector2.ONE * hit_radius
	
	for rect in rods:
		var padded: Rect2 = rect.grow(hit_radius)
		
		if not padded.has_point(next_position):
			continue
		
		var to_left: float = next_position.x - padded.position.x
		var to_right: float = padded.end.x - next_position.x
		var to_top: float = next_position.y - padded.position.y
		var to_bottom: float = padded.end.y- next_position.y
		var smallest: float = minf(minf(to_left, to_right), minf(to_top, to_bottom))
		
		if smallest == to_left:
			next_position.x = padded.position.x
			_velocity.x = -absf(_velocity.x)
		elif smallest == to_right:
			next_position.x = padded.end.x
			_velocity.x = absf(_velocity.x)
		elif smallest == to_top:
			next_position.y = padded.position.y
			_velocity.y = -absf(_velocity.y)
		else:
			next_position.y = padded.end.y
			_velocity.y = absf(_velocity.y)
	
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

func _apply_kind() -> void:
	match kind:
		Kind.NORMAL:
			power_yield = 1
			heat_yield = 1
			reaction_radius = 90.0
		Kind.OVERRIPE:
			power_yield = 3
			heat_yield = 4
			reaction_radius = 160.0

func pulse_color() -> Color:
	return Color(0.4, 0.95, 1.0) if kind == Kind.NORMAL else Color(0.6, 1.0, 0.35)
