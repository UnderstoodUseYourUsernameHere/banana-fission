extends RefCounted
class_name ReactionSim

const TICK: float = 1.0 / 60.0
const MAX_CHAIN_TICKS: int = 600

static func make_state(bananas: Array[Banana]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	
	for banana in bananas:
		out.append({
			"pos": banana.global_position,
			"vel": banana.get_drift_velocity(),
			"radius": banana.hit_radius,
			"power": banana.power_yield,
			"heat": banana.heat_yield,
			"reaction": banana.reaction_radius,
			"alive": true,
		})
	return out

static func copy_state(state: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	
	for entry in state:
		out.append(entry.duplicate())
	
	return out

static func advance_bananas(
	state: Array[Dictionary],
	delta: float,
	chamber: Rect2,
	rods: Array[Rect2]
) -> void:
	for entry in state:
		if not entry["alive"]:
			continue
	
		var stepped: PackedVector2Array = Banana.step_motion(
			entry["pos"],
			entry["vel"],
			entry["radius"],
			delta,
			chamber,
			rods
		)
		
		entry["pos"] = stepped[0]
		entry["vel"] = stepped[1]

static func run_chain(
	start_state: Array[Dictionary],
	ignite_at: Vector2,
	ignition_radius: float,
	chamber: Rect2,
	rods: Array[Rect2],
	expansion_time: float,
	fade_time: float,
	heat_limit: int
) -> Dictionary:
	var state: Array[Dictionary] = copy_state(start_state)
	var pulses: Array[Dictionary] = [{
		"pos": ignite_at,
		"max": ignition_radius,
		"age": 0.0,
	}]
	
	var lifetime: float = expansion_time + fade_time
	var power: int = 0
	var heat: int = 0
	var ticks: int = 0
	
	while not pulses.is_empty() and ticks < MAX_CHAIN_TICKS:
		ticks += 1
		
		advance_bananas(
			state,
			TICK,
			chamber,
			rods
		)
		
		var surviving: Array[Dictionary] = []
		var spawned: Array[Dictionary] = []
		
		for pulse in pulses:
			pulse["age"] += TICK
			
			if pulse["age"] >= lifetime:
				continue
			
			surviving.append(pulse)
			
			var radius: float = Pulse.radius_at(
				pulse["age"],
				pulse["max"],
				expansion_time
			)
			
			for entry in state:
				if not entry["alive"]:
					continue
				
				var combined: float = radius + entry["radius"]
				
				if pulse["pos"].distance_squared_to(entry["pos"]) > combined * combined:
					continue
				
				if ControlRod.blocks_line(
					pulse["pos"],
					entry["pos"],
					rods
				):
					continue
				
				entry["alive"] = false
				power += entry["power"]
				heat += entry["heat"]
				
				if heat > heat_limit:
					return {"power": power, "heat": heat}
				
				spawned.append({
					"pos": entry["pos"],
					"max": entry["reaction"],
					"age": 0.0,
				})
		surviving.append_array(spawned)
		pulses = surviving
	
	return {"power": power, "heat": heat}

static func find_winning_shot(
	bananas: Array[Banana],
	chamber: Rect2,
	rods: Array[Rect2],
	ignition_radius: float,
	expansion_time: float,
	fade_time: float,
	power_target: int,
	heat_limit: int,
	max_wait: float = 6.0,
	sample_step: float = 0.5
) -> Dictionary:
	var state: Array[Dictionary] = make_state(bananas)
	var ticks_per_sample: int = int(round(sample_step / TICK))
	var elapsed: float = 0.0
	
	while elapsed <= max_wait + 0.001:
		for entry in state:
			var result: Dictionary = run_chain(
				state,
				entry["pos"],
				ignition_radius,
				chamber,
				rods,
				expansion_time,
				fade_time,
				heat_limit
			)
			
			if (
				result["heat"] <= heat_limit
				and result["power"] >= power_target
			):
				return {
					"valid": true,
					"wait": elapsed,
					"point": entry["pos"],
					"power": result["power"],
					"heat": result["heat"]
				}
		
		for _tick in range(ticks_per_sample):
			advance_bananas(
				state,
				TICK,
				chamber,
				rods
			)
		elapsed += sample_step
	return {"valid": false}
