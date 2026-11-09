extends Node2D

const PULSE_SCENE = preload("res://scenes/pulse.tscn")
const IGNITION_RADIUS: float = 70.0

@onready var chamber: ColorRect = $%Chamber
@onready var pulse_container: Node2D = $%Pulses

var shot_used: bool = false
var active_pulses: Array[Pulse] = []

func _ready() -> void:
	print("Bananilator ready!")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()
		return
	
	if event.is_action_pressed("ignite") and not shot_used:
		var world_position: Vector2 = get_global_mouse_position()
		
		if chamber.get_global_rect().has_point(world_position):
			get_viewport().set_input_as_handled()
			shot_used = true
			_spawn_pulse(world_position, IGNITION_RADIUS) 

func _physics_process(delta: float) -> void:
	var current_pulses: Array[Pulse] = active_pulses.duplicate()
	
	for pulse in current_pulses:
		pulse.advance(delta)
		
		if pulse.has_finished():
			active_pulses.erase(pulse)
			pulse.queue_free()

func _spawn_pulse(world_position: Vector2, maximum_radius: float) -> void:
	var pulse := PULSE_SCENE.instantiate() as Pulse
	pulse.max_radius = maximum_radius
	
	pulse_container.add_child(pulse)
	pulse.global_position = world_position
	
	active_pulses.append(pulse)
