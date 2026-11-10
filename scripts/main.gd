extends Node2D

const PULSE_SCENE = preload("res://scenes/pulse.tscn")
const IGNITION_RADIUS: float = 70.0

enum RoundState {
	AIMING,
	REACTING,
	COMPLETE
}

@onready var chamber: ColorRect = $%Chamber
@onready var pulse_container: Node2D = $%Pulses
@onready var banana_container: Node2D = $%Bananas
@onready var aim: AimController = $%Aim
@onready var status: Label = $%Status

var state: RoundState = RoundState.AIMING
var split_count: int = 0
var active_pulses: Array[Pulse] = []
var bananas: Array[Banana] = []

func _ready() -> void:
	for child in banana_container.get_children():
		var banana := child as Banana
		
		if banana == null:
			continue
		
		bananas.append(banana)
		banana.split_occurred.connect(_on_banana_split)
	
	aim.ignited.connect(_on_ignited)
	aim.configure(chamber.get_global_rect(), bananas, IGNITION_RADIUS)
	
	_update_status()
	print("Bananilator ready!")

func _on_ignited(world_position: Vector2) -> void:
	if state != RoundState.AIMING:
		return
	
	state = RoundState.REACTING
	aim.active = false
	_spawn_pulse(world_position, IGNITION_RADIUS)
	_update_status()

func _on_banana_split(banana: Banana) -> void:
	split_count += 1
	_spawn_pulse(banana.global_position, banana.reaction_radius)
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()
		return

func _physics_process(delta: float) -> void:
	if state != RoundState.REACTING:
		return
	
	var current_pulses: Array[Pulse] = active_pulses.duplicate()
	
	for pulse in current_pulses:
		pulse.advance(delta)
		
		for banana in bananas:
			if banana.alive and pulse.reaches(banana.global_position, banana.hit_radius):
				banana.split()
		
		if pulse.has_finished():
			active_pulses.erase(pulse)
			pulse.queue_free()
	if active_pulses.is_empty():
		_finish_round()

func _spawn_pulse(world_position: Vector2, maximum_radius: float) -> void:
	var pulse := PULSE_SCENE.instantiate() as Pulse
	pulse.max_radius = maximum_radius
	
	pulse_container.add_child(pulse)
	pulse.global_position = world_position
	
	active_pulses.append(pulse)

func _finish_round() -> void:
	state = RoundState.COMPLETE
	_update_status()

func _update_status() -> void:
	match state:
		RoundState.AIMING:
			status.text = "Choose your target!  |  1 shot  |  %d bananas" % (bananas.size())
		RoundState.REACTING:
			status.text = "Bananas splitting... %d / %d split" % [split_count, bananas.size()]
		RoundState.COMPLETE:
			status.text = "Split complete!! %d / %d | R to retry!" % [split_count, bananas.size()]
