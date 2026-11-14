extends RefCounted
class_name ShotSearch

var _state: Array[Dictionary] = []
var _chamber: Rect2
var _rods: Array[Rect2] = []

var _ignition_radius: float
var _expansion_time: float
var _fade_time: float
var _power_target: int
var _heat_limit: int

var _sample_ticks: int
var _max_wait_ticks: int
var _wait_ticks: int = 0
var _candidate_index: int = 0

var chains_run: int = 0
var finished: bool = false
var result: Dictionary = {"valid": false}

func _init(
	bananas: Array[Banana],
	chamber: Rect2,
	rods: Array[Rect2],
	ignition_radius: float,
	expansion_time: float,
	fade_time: float,
	power_target: int,
	heat_limit: int,
	max_wait: float = 6.0,
	sample_step: float = 0.5,
) -> void:
	_state = ReactionSim.make_state(bananas)
	_chamber = chamber
	_rods = rods
	_ignition_radius = ignition_radius
	_expansion_time = expansion_time
	_fade_time = fade_time
	_power_target = power_target
	_heat_limit = heat_limit
	
	_sample_ticks = maxi(int(round(sample_step / ReactionSim.TICK)), 1)
	_max_wait_ticks = int(round(max_wait / ReactionSim.TICK))
	
	if _state.is_empty():
		finished = true

func step(chains_this_frame: int = 1) -> bool:
	if finished:
		return true
	
	var chains_processed: int = 0
	var chain_limit: int = maxi(chains_this_frame, 1)
	
	while not finished and chains_processed < chain_limit:
		if _candidate_index >= _state.size():
			if _wait_ticks + _sample_ticks > _max_wait_ticks:
				finished = true
				break
			
			for _tick in range(_sample_ticks):
				ReactionSim.advance_bananas(
					_state,
					ReactionSim.TICK,
					_chamber,
					_rods
				)
			
			_wait_ticks += _sample_ticks
			_candidate_index = 0
		
		var entry: Dictionary = _state[_candidate_index]
		_candidate_index += 1
		chains_processed += 1
		chains_run += 1
		
		var point: Vector2 = entry["pos"]
		var outcome: Dictionary = ReactionSim.run_chain(
			_state,
			point,
			_ignition_radius,
			_chamber,
			_rods,
			_expansion_time,
			_fade_time,
			_heat_limit
			
		)
		
		var power: int = int(outcome["power"])
		var heat: int = int(outcome["heat"])
		
		if power >= _power_target and heat <= _heat_limit:
			result = {
				"valid": true,
				"wait": float(_wait_ticks) * ReactionSim.TICK,
				"wait_ticks": _wait_ticks,
				"point": point,
				"power": power,
				"heat": heat,
			}
			finished = true
	return finished
