extends Node2D

const PULSE_SCENE = preload("res://scenes/pulse.tscn")
const SPLIT_BURST_SCENE = preload("res://scenes/split_burst.tscn")
const BANANA_HALF_SCENE = preload("res://scenes/banana_half.tscn")
const HALF_SPEED: float = 140.0
const IGNITION_RADIUS: float = 70.0

enum RoundState {
	AIMING,
	REACTING,
	COMPLETE
}

@export_range(1, 100, 1) var power_target: int = 6
@export_range(1, 100, 1) var heat_limit: int = 7

@onready var chamber: ColorRect = $%Chamber
@onready var pulse_container: Node2D = $%Pulses
@onready var banana_container: Node2D = $%Bananas
@onready var aim: AimController = $%Aim
@onready var status: Label = $%Status
@onready var power_label: Label = $%PowerLabel
@onready var power_bar: ProgressBar = $%PowerBar
@onready var heat_label: Label = $%HeatLabel
@onready var heat_bar: ProgressBar = $%HeatBar
@onready var effect_container: Node2D = $%Effects
@onready var retry_button: Button = $%Retry

var state: RoundState = RoundState.AIMING
var split_count: int = 0
var active_pulses: Array[Pulse] = []
var bananas: Array[Banana] = []
var power_total: int = 0
var heat_total: int = 0

func _ready() -> void:
	for child in banana_container.get_children():
		var banana := child as Banana
		
		if banana == null:
			continue
		
		bananas.append(banana)
		banana.split_occurred.connect(_on_banana_split)
	
	aim.ignited.connect(_on_ignited)
	aim.configure(chamber.get_global_rect(), bananas, IGNITION_RADIUS)
	
	retry_button.pressed.connect(_restart_attempt)
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
	_spawn_split_burst(banana.global_position)
	_spawn_split_halves(banana)
	power_total += banana.power_yield
	heat_total += banana.heat_yield
	
	if heat_total > heat_limit:
		_finish_round()
		return
	
	_spawn_pulse(banana.global_position, banana.reaction_radius, banana.pulse_color())
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		_restart_attempt()
		return

func _physics_process(delta: float) -> void:
	if state == RoundState.AIMING or state == RoundState.REACTING:
		var chamber_bounds: Rect2 = chamber.get_global_rect()
		
		for banana in bananas:
			banana.advance_motion(delta, chamber_bounds)
	
	if state != RoundState.REACTING:
		return
	
	var current_pulses: Array[Pulse] = active_pulses.duplicate()
	
	for pulse in current_pulses:
		pulse.advance(delta)
		
		if pulse.has_finished():
			active_pulses.erase(pulse)
			pulse.queue_free()
			continue
		
		for banana in bananas:
			if banana.alive and pulse.reaches(banana.global_position, banana.hit_radius):
				banana.split()
				
				if state != RoundState.REACTING:
					return
		
	if active_pulses.is_empty():
		_finish_round()

func _spawn_pulse(world_position: Vector2, maximum_radius: float, ring_color: Color = Color(0.4, 0.95, 1.0)) -> void:
	var pulse := PULSE_SCENE.instantiate() as Pulse
	pulse.max_radius = maximum_radius
	pulse.ring_color = ring_color
	
	pulse_container.add_child(pulse)
	pulse.global_position = world_position
	
	active_pulses.append(pulse)

func _finish_round() -> void:
	if state == RoundState.COMPLETE:
		return
	
	state = RoundState.COMPLETE
	aim.active = false
	
	for pulse in active_pulses:
		pulse.queue_free()
		
	active_pulses.clear()
	_update_status()

func _update_status() -> void:
	_update_readouts()
	
	match state:
		RoundState.AIMING:
			status.text = "Choose your target!  |  1 shot  |  %d bananas" % (bananas.size())
		RoundState.REACTING:
			status.text = "Bananas splitting... %d / %d split" % [split_count, bananas.size()]
		RoundState.COMPLETE:
			if heat_total > heat_limit:
				status.text = "OVERHEATED! Heat %d / %d  |  R to retry!" % [heat_total, heat_limit]
			elif power_total >= power_target:
				status.text = "STABLE! Power %d  |  Heat %d  | R to retry!" % [power_total, heat_total]
			else:
				status.text = "NOT ENOUGH POWER: %d / %d  |  R to retry?" % [power_total, power_target] 

func _update_readouts() -> void:
	power_label.text = "Power: %d / %d" % [power_total, power_target]
	heat_label.text = "Heat: %d / %d" % [heat_total, heat_limit]
	
	power_bar.max_value = power_target
	power_bar.value = power_total
	
	heat_bar.max_value = heat_limit
	heat_bar.value = heat_total

func _spawn_split_burst(world_position: Vector2) -> void:
	var burst: Node2D = SPLIT_BURST_SCENE.instantiate()
	effect_container.add_child(burst)
	burst.global_position = world_position

func _spawn_split_halves(banana: Banana) -> void:
	var drift: Vector2 = banana.get_drift_velocity()
	var axis: Vector2 = Vector2.RIGHT
	
	if drift.length_squared() > 0.001:
		axis = drift.normalized().orthogonal()
	
	for side in [-1.0, 1.0]:
		var half := BANANA_HALF_SCENE.instantiate() as BananaHalf
		half.texture = banana.half_texture
		half.size = banana.hit_radius
		half.velocity = axis * side * HALF_SPEED + drift * 0.5
		half.spin = side * 6.0
		half.rotation = axis.angle()
		
		if side < 0.0:
			half.scale.x = -1.0
		
		effect_container.add_child(half)
		half.global_position = banana.global_position + axis * side * banana.hit_radius * 0.3

func _restart_attempt() -> void:
	get_tree().reload_current_scene()
