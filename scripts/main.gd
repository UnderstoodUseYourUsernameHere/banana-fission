extends Node2D

const PULSE_SCENE = preload("res://scenes/pulse.tscn")
const SPLIT_BURST_SCENE = preload("res://scenes/split_burst.tscn")
const BANANA_HALF_SCENE = preload("res://scenes/banana_half.tscn")
const BANANA_SCENE = preload("res://scenes/banana.tscn")
const HALF_SPEED: float = 140.0
const IGNITION_RADIUS: float = 70.0
const IGNITION_COLOR: Color = Color(1.0, 1.0, 1.0)

enum RoundState {
	AIMING,
	REACTING,
	COMPLETE
}

var level: Level
var power_target: int = 6
var heat_limit: int = 7


@onready var chamber: ColorRect = $%Chamber
@onready var pulse_container: Node2D = $%Pulses
@onready var level_holder: Node2D = $%LevelHolder
@onready var intro: Label = $%Intro
@onready var aim: AimController = $%Aim
@onready var status: Label = $%Status
@onready var power_label: Label = $%PowerLabel
@onready var power_bar: ProgressBar = $%PowerBar
@onready var heat_label: Label = $%HeatLabel
@onready var heat_bar: ProgressBar = $%HeatBar
@onready var effect_container: Node2D = $%Effects
@onready var retry_button: Button = $%Retry
@onready var continue_button: Button = $%Continue
@onready var scram_button: Button = $%Scram
@onready var help_label: Label = $%Help

var state: RoundState = RoundState.AIMING
var split_count: int = 0
var active_pulses: Array[Pulse] = []
var bananas: Array[Banana] = []
var generated: Array[Banana] = []
var rods: Array[Rect2] = []
var power_total: int = 0
var heat_total: int = 0
var scram_used: bool = false
var earned_stars: int = 0

func _ready() -> void:
	_load_level()
	
	aim.ignited.connect(_on_ignited)
	aim.configure(chamber.get_global_rect(), bananas, IGNITION_RADIUS, rods)
	
	retry_button.pressed.connect(_restart_attempt)
	continue_button.pressed.connect(_on_continue_pressed)
	scram_button.pressed.connect(_use_scram)
	scram_button.visible = false
	help_label.text = "LMB: Ignite  |  Gold: Finish at or under %d heat, no SCRAM" % mini(level.gold_heat_limit, heat_limit)
	_update_status()
	print("Bananilator ready!")

func _on_ignited(world_position: Vector2) -> void:
	if state != RoundState.AIMING:
		return
	
	Progress.record_attempt()
	state = RoundState.REACTING
	aim.active = false
	intro.visible = false
	_spawn_pulse(world_position, IGNITION_RADIUS, IGNITION_COLOR)
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
	
	if event.is_action_pressed("scram"):
		get_viewport().set_input_as_handled()
		_use_scram()
		return
	
	if event.is_action_pressed("next_level"):
		get_viewport().set_input_as_handled()
		Progress.current_level = (Progress.current_level + 1) % Progress.level_count()
		Progress.attempt_seed = 0
		get_tree().reload_current_scene()
	
	if event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/title.tscn")

func _physics_process(delta: float) -> void:
	if state == RoundState.AIMING or state == RoundState.REACTING:
		var chamber_bounds: Rect2 = chamber.get_global_rect()
		
		for banana in bananas:
			banana.advance_motion(delta, chamber_bounds, rods)
	
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
			if not banana.alive:
				continue
			
			if not pulse.reaches(banana.global_position, banana.hit_radius):
				continue
			
			if ControlRod.blocks_line(pulse.global_position, banana.global_position, rods):
				continue
			
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

func _use_scram() -> void:
	if state != RoundState.REACTING or scram_used:
		return
	
	scram_used = true
	
	for pulse in active_pulses:
		pulse.queue_free()
	
	active_pulses.clear()
	_finish_round()

func _finish_round() -> void:
	if state == RoundState.COMPLETE:
		return
	
	state = RoundState.COMPLETE
	aim.active = false
	
	for pulse in active_pulses:
		pulse.queue_free()
		
	active_pulses.clear()
	earned_stars = _calculate_stars()
	continue_button.visible = _won()
	if _won():
		Progress.record_clear(earned_stars)
	_update_status()

func _update_status() -> void:
	_update_readouts()
	scram_button.visible = (state == RoundState.REACTING and not scram_used)
	var scram_prefix: String = "SCRAMMED - " if scram_used else ""
	
	match state:
		RoundState.AIMING:
			status.text = "%s  |  attempt %d  |  %d bananas" % [level.title, Progress.attempts_for(Progress.current_level) + 1, bananas.size()]
		RoundState.REACTING:
			var scram_hint: String = ("  |  Space: SCRAM" if not scram_used else "  |  SCRAMMED")
			status.text = "Bananas splitting... %d / %d split%s" % [split_count, bananas.size(), scram_hint]
		RoundState.COMPLETE:
			if heat_total > heat_limit:
				status.text = "OVERHEATED! Rating 0/3  |  Heat %d / %d  |  R to retry!" % [heat_total, heat_limit]
			elif _won():
				status.text = "%sSTABLE! Rating %d/3  |  Power %d  |  Heat %d" % [scram_prefix, earned_stars, power_total, heat_total]
			else:
				status.text = "%sNOT ENOUGH POWER! Rating 0/3  |  Power %d / %d  |  R to retry!" % [scram_prefix, power_total, power_target]

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

func _load_level() -> void:
	var index: int = clampi(Progress.current_level, 0, Progress.level_count() - 1)
	Progress.current_level = index
	
	level = Progress.levels[index].instantiate() as Level
	level_holder.add_child(level)
	if Progress.attempt_seed == 0:
		Progress.attempt_seed = level.fixed_seed if level.fixed_seed != 0 else randi_range(1, 2147483647)
	
	power_target = level.power_target
	heat_limit = level.heat_limit
	intro.text = level.ratticus_line
	
	bananas.clear()
	rods.clear()
	
	for child in level.get_children():
		var rod := child as ControlRod
		if rod != null:
			rods.append(rod.world_rect())
			continue
		
		var banana := child as Banana
		if banana == null:
			continue
		bananas.append(banana)
		banana.split_occurred.connect(_on_banana_split)
	_generate_bananas(Progress.attempt_seed)

func _generate_bananas(seed_value: int) -> void:
	if level.spawn_rules.is_empty():
		return
	
	var existing: Array[Vector2] = []
	for banana in bananas:
		existing.append(banana.global_position)
	
	var specs: Array[Dictionary] = LevelGenerator.generate(level.spawn_rules, chamber.get_global_rect(), rods, existing, seed_value)
	for spec in specs:
		var banana := BANANA_SCENE.instantiate() as Banana
		banana.kind = spec["kind"]
		banana.drift_speed = spec["speed"]
		banana.start_angle_degrees = spec["angle"]
		level.add_child(banana)
		banana.global_position = spec["position"]
		bananas.append(banana)
		generated.append(banana)
		banana.split_occurred.connect(_on_banana_split)

func _clear_generated() -> void:
	for banana in generated:
		bananas.erase(banana)
		level.remove_child(banana)
		banana.queue_free()
	generated.clear()

func _won() -> bool:
	return heat_total <= heat_limit and power_total >= power_target

func _on_continue_pressed() -> void:
	Progress.attempt_seed = 0
	if Progress.is_last_level():
		Progress.current_level = 0
	else:
		Progress.current_level += 1
	get_tree().reload_current_scene()

func _calculate_stars() -> int:
	if not _won():
		return 0
	
	if scram_used: 
		return 1
	
	var gold_limit: int = mini(level.gold_heat_limit, heat_limit)
	
	if heat_total <= gold_limit:
		return 3
	
	return 2
