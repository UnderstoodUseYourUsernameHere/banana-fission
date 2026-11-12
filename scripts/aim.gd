extends Node2D
class_name AimController

signal ignited(world_position: Vector2)

var bounds: Rect2 = Rect2()
var targets: Array[Banana] = []
var rods: Array[Rect2] = []
var ignition_radius: float = 0.0

var active: bool = false:
	set(value):
		active = value
		queue_redraw()

func configure(chamber_bounds: Rect2, bananas: Array[Banana], pulse_radius: float, rod_rects: Array[Rect2]) -> void:
	bounds = chamber_bounds
	targets = bananas
	ignition_radius = pulse_radius
	rods = rod_rects
	active = true

func _process(_delta: float) -> void:
	if active:
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	
	if event.is_action_pressed("ignite"):
		var world_position: Vector2 = get_global_mouse_position()
		
		if bounds.has_point(world_position):
			get_viewport().set_input_as_handled()
			ignited.emit(world_position)

func _draw() -> void:
	if not active:
		return
	
	var world_position: Vector2 = get_global_mouse_position()
	
	if not bounds.has_point(world_position):
		return
	
	var centre: Vector2 = to_local(world_position)
	
	draw_arc(
		centre,
		ignition_radius,
		0.0,
		TAU,
		64,
		Color(1.0, 1.0, 1.0, 0.55),
		1.5,
		true
	)
	
	draw_line(
		centre + Vector2(-5.0, 0.0),
		centre + Vector2(5.0, 0.0),
		Color.WHITE
	)
	
	draw_line(
		centre + Vector2(0.0, -5.0),
		centre + Vector2(0.0, 5.0),
		Color.WHITE
	)
	
	for banana in targets:
		if not banana.alive:
			continue
		
		_draw_motion_guide(banana)
		
		var reach: float = ignition_radius + banana.hit_radius
		
		var in_range: bool = (world_position.distance_squared_to(banana.global_position)) <= reach * reach
		var blocked: bool = ControlRod.blocks_line(world_position, banana.global_position, rods)
		
		if in_range and not blocked:
			draw_arc(
				to_local(banana.global_position),
				banana.hit_radius + 5.0,
				0.0,
				TAU,
				40,
				Color("ff825e"),
				2.0,
				true
			)

func _draw_motion_guide(banana: Banana) -> void:
	var drift: Vector2 = banana.get_drift_velocity()
	if drift.length_squared() < 0.001:
		return
	
	var direction: Vector2 = drift.normalized()
	var start: Vector2 = to_local(banana.global_position) + direction * (banana.hit_radius + 7.0)
	var tip: Vector2 = start + direction * 18.0
	var guide_color := Color(1.0, 1.0, 1.0, 0.35)
	
	draw_line(start, tip, guide_color, 1.5, true)
	draw_line(tip, tip - direction.rotated(0.55) * 6.0, guide_color, 1.5, true)
	draw_line(tip, tip - direction.rotated(-0.55) * 6.0, guide_color, 1.5, true)
