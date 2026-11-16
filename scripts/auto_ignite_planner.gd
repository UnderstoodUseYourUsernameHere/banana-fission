extends RefCounted
class_name AutoIgnitePlanner

const MAX_POINTS: int = 160

var best: Dictionary = {}
var finished: bool = false
var tested: int = 0
var tick_delta: float

var _chamber: Rect2
var _ignition_radius: float
var _expansion_time: float
var _fade_time: float
var _power_target: int
var _heat_limit: int
var _auto_scram: bool

var _forecast: Array[Dictionary] = []
var _trial: Array[Dictionary] = []
var _pulses: Array[Dictionary] = []
var _points: Array[Vector2] = []

var _forecast_ticks_left: int
var _points_ready: bool = false
var _point_index: int = 0
var _trial_running: bool = false
var _trial_ticks: int = 0
var _trial_limit: int 
var _power: int = 0
var _heat: int = 0

func _init(
	bananas: Array[Banana],
	chamber: Rect2,
	ignition_radius: float,
	expansion_time: float,
	fade_time: float,
	power_target: int,
	heat_limit: int,
	auto_scram: bool,
	delta: float,
	launch_ticks: int
) -> void:
	_chamber = chamber
	_ignition_radius = ignition_radius
	_expansion_time = expansion_time
	_fade_time = fade_time
	_power_target = power_target
	_heat_limit = heat_limit 
	_auto_scram = auto_scram
	tick_delta = delta
	_forecast_ticks_left = launch_ticks
	
	for banana in bananas:
		if not banana.alive:
			continue
		
		_forecast.append({
			"pos": banana.global_position,
			"vel": banana.get_drift_velocity(),
			"radius": banana.hit_radius,
			"power": banana.power_yield,
			"heat": banana.heat_yield,
			"reaction": banana.reaction_radius,
			"alive": true
		})
	
	var pulse_ticks: int = maxi(
		ceili((_expansion_time + fade_time) / tick_delta),
		1
	)
	
	_trial_limit = pulse_ticks * (_forecast.size() + 1) + 2
	
	if _forecast.is_empty():
		finished = true

func work(budget_usec: int = 1200) -> void:
	if finished:
		return
	
	var deadline: int = Time.get_ticks_usec() + budget_usec
	
	while not finished:
		if _forecast_ticks_left > 0:
			_advance_bananas(_forecast)
			_forecast_ticks_left -= 1
		
		elif not _points_ready:
			_build_points()
			_points_ready = true
		
		elif _point_index >= _points.size():
			finished = true
		
		elif not _trial_running:
			_begin_trial()
		else:
			_advance_trial_tick()
		
		if Time.get_ticks_usec() >= deadline:
			return

func _advance_bananas(entries: Array[Dictionary]) -> void:
	for entry in entries:
		if not entry["alive"]:
			continue
		
		var moved: PackedVector2Array = Banana.step_motion(
			entry["pos"],
			entry["vel"],
			float(entry["radius"]),
			tick_delta,
			_chamber
		)
		entry["pos"] = moved[0]
		entry["vel"] = moved[1]

func _build_points() -> void:
	for entry in _forecast:
		var origin: Vector2 = entry["pos"]
		
		for direction in [
			Vector2.RIGHT,
			Vector2.DOWN,
			Vector2.LEFT,
			Vector2.UP
		]:
			_add_point(origin + direction * _ignition_radius * 0.75)
	
	for first_index in range(_forecast.size()):
		var first: Dictionary = _forecast[first_index]
		var first_position: Vector2 = first["pos"]
		
		for second_index in range(first_index + 1, _forecast.size()):
			var second: Dictionary = _forecast[second_index]
			var second_position: Vector2 = second["pos"]
			
			var pair_reach: float = 2.0 * (
				_ignition_radius
				+ minf(
					float(first["radius"]),
					float(second["radius"])
				)
			)
			
			if first_position.distance_squared_to(second_position) <= pair_reach * pair_reach:
				_add_point(first_position.lerp(second_position, 0.5))

func _add_point(point: Vector2) -> void:
	if _points.size() >= MAX_POINTS:
		return
	
	if not _chamber.has_point(point):
		return
	
	for existing in _points:
		if existing.distance_squared_to(point) < 16.0:
			return
	
	_points.append(point)

func _begin_trial() -> void:
	_trial = _forecast.duplicate(true)
	_pulses = [{
		"pos": _points[_point_index],
		"maximum": _ignition_radius,
		"age": 0.0
	}]
	
	_power = 0
	_heat = 0
	_trial_ticks = 0
	_trial_running = true

func _advance_trial_tick() -> void:
	_trial_ticks += 1
	_advance_bananas(_trial)
	
	var survivors: Array[Dictionary] = []
	var spawned: Array[Dictionary] = []
	var lifetime: float = _expansion_time + _fade_time
	
	for pulse in _pulses:
		var age: float = float(pulse["age"]) + tick_delta
		pulse["age"] = age
	
		if age >= lifetime:
			continue
	
		survivors.append(pulse)
	
		var pulse_position: Vector2 = pulse["pos"]
		var radius: float = Pulse.radius_at(
			age,
			float(pulse["maximum"]),
			_expansion_time
		)
	
		for entry in _trial:
			if not entry["alive"]:
				continue
	
			var target_position: Vector2 = entry["pos"]
			var reach: float = radius + float(entry["radius"])
	
			if pulse_position.distance_squared_to(
				target_position
			) > reach * reach:
				continue
	
			entry["alive"] = false
			_power += int(entry["power"])
			_heat += int(entry["heat"])
	
			if _heat > _heat_limit:
				_finish_trial(false)
				return
	
			if _auto_scram and _power >= _power_target:
				_finish_trial(true)
				return
	
			var secondary_radius: float = float(
				entry["reaction"]
			)
	
			if secondary_radius > 0.0:
				spawned.append({
					"pos": target_position,
					"maximum": secondary_radius,
					"age": 0.0
				})
	
	survivors.append_array(spawned)
	_pulses = survivors
	
	if _pulses.is_empty():
		_finish_trial(true)
	elif _trial_ticks >= _trial_limit:
		_finish_trial(false)
	

func _finish_trial(complete: bool) -> void:
	if (
		complete
		and _power >= _power_target
		and _heat <= _heat_limit
	):
		var better: bool = best.is_empty()
	
		if not better:
			var excess: int = _power - _power_target
			var previous_excess: int = (
				int(best["power"]) - _power_target
			)
	
			if excess < previous_excess:
				better = true
	
			elif excess == previous_excess:
				if _heat < int(best["heat"]):
					better = true
	
				elif (
					_heat == int(best["heat"])
					and _trial_ticks < int(best["ticks"])
				):
					better = true
	
		if better:
			best = {
				"point": _points[_point_index],
				"power": _power,
				"heat": _heat,
				"ticks": _trial_ticks
			}
	
	tested += 1
	_point_index += 1
	_trial_running = false
