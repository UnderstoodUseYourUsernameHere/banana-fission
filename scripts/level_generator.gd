extends RefCounted
class_name LevelGenerator

const HIT_RADIUS: float = 18.0
const MIN_INTERNAL_DISTANCE: float = 38.0
const MAX_FORMATION_TRIES: int = 40

static func generate(
	rules: Array[FormationRule],
	chamber: Rect2,
	existing: Array[Vector2],
	seed_value: int,
	power_target: int,
	heat_limit: int,
	require_solution: bool
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	
	var occupied: Array[Vector2] = existing.duplicate()
	var all_specs: Array[Dictionary] = []
	var found_solution: bool = false
	
	for rule_index in range(rules.size()):
		var rule: FormationRule = rules[rule_index]
		
		if rule == null:
			continue
		
		var formation: Dictionary = _generate_formation(
			rule,
			rule_index,
			chamber,
			occupied,
			rng
		)
		if not formation["ok"]:
			return formation
		
		var formation_specs: Array = formation["specs"]
		
		if rule.guaranteed_solution:
			var assessment: Dictionary = _assess_solution(
				formation_specs,
				power_target,
				heat_limit
			)
			
			if not assessment["ok"]:
				return {
					"ok": false,
					"error": ("Guaranteed formation %d is invalid: %s" % [rule_index, assessment["error"]])
				}
			found_solution = true
		
		for spec in formation_specs:
			all_specs.append(spec)
			occupied.append(spec["position"])
	
	if require_solution and not found_solution:
		return {
			"ok": false,
			"error": ("Level requires a guaranteed solution formation, " + "but none is marked")}
	
	return {
		"ok": true,
		"specs": all_specs
	}

static func _generate_formation(
	rule: FormationRule,
	rule_index: int,
	chamber: Rect2,
	occupied: Array[Vector2],
	rng: RandomNumberGenerator
) -> Dictionary:
	var total: int = (rule.normal_count + rule.overripe_count)
	if total <= 0:
		return {"ok": true, "specs": []}
	
	var kinds: Array[int] = []
	for _index in range(rule.normal_count):
		kinds.append(Banana.Kind.NORMAL)
	
	for _index in range(rule.overripe_count):
		kinds.append(Banana.Kind.OVERRIPE)
	
	if rule.shuffle_kinds:
		_shuffle_kinds(kinds, rng)
	
	for _attempt in range(MAX_FORMATION_TRIES):
		var chosen_spacing: float = maxf(MIN_INTERNAL_DISTANCE, rule.spacing + rng.randf_range(-rule.spacing_jitter, rule.spacing_jitter))
		var chosen_rotation: float = deg_to_rad(rule.rotation_degrees + rng.randf_range(-rule.rotation_jitter_degrees, rule.rotation_jitter_degrees))
		var offsets: Array[Vector2] = _build_offsets(
			rule,
			total,
			chosen_spacing,
			chosen_rotation
		)
		var center: Vector2 = rule.anchor + Vector2(
			rng.randf_range(
				-absf(rule.anchor_jitter.x),
				absf(rule.anchor_jitter.x)
			),
			rng.randf_range(
				-absf(rule.anchor_jitter.y),
				absf(rule.anchor_jitter.y)
			)
		)
		
		var clearance: float = (HIT_RADIUS + rule.wall_margin)
		var safe_area: Rect2 = chamber.grow(-clearance)
		
		if not safe_area.has_area():
			return{"ok": false, "error": "Formation wll maring leaves no usabvle chamber!"}
		
		var points: Array[Vector2] = []
		var valid: bool = true
		
		for offset in offsets:
			var point: Vector2 = (
				center + offset + _random_offset(rng, rule.position_jitter)
			)
			
			if not safe_area.has_point(point):
				valid = false
				break
			
			for other in occupied:
				if point.distance_squared_to(other) < (rule.separation_from_others * rule.separation_from_others):
					valid = false
					break
			
			if not valid:
				break
			
			for other in points:
				if point.distance_squared_to(other) < (MIN_INTERNAL_DISTANCE * MIN_INTERNAL_DISTANCE):
					valid = false
					break
			
			if not valid: 
				break
				
			points.append(point)
		if not valid:
			continue
		
		var shared_speed: float = maxf(
			0.0,
			rule.drift_speed + rng.randf_range(-rule.speed_jitter, rule.speed_jitter)
		)
		
		var base_angle: float = rule.drift_angle_degrees
		match rule.direction_mode:
			FormationRule.DirectionMode.TOWARD_POINT:
				var toward_target: Vector2 = (rule.motion_target - center)
				if toward_target.length_squared() > 0.001:
					base_angle = rad_to_deg(toward_target.angle())
			FormationRule.DirectionMode.AWAY_FROM_POINT:
				var away_from_target: Vector2 = (center - rule.motion_target)
				if away_from_target.length_squared() > 0.001:
					base_angle = rad_to_deg(away_from_target.angle())
		
		var shared_angle: float = (
			base_angle + rng.randf_range(
				-rule.drift_angle_jitter_degrees,
				rule.drift_angle_jitter_degrees
			)
		)
		
		var specs: Array[Dictionary] = []
		
		for index in range(total):
			var speed: float = shared_speed
			var angle: float = shared_angle
			
			if not rule.guaranteed_solution:
				speed = maxf(
					0.0,
					shared_speed + rng.randf_range(
						-rule.individual_speed_jitter,
						rule.individual_speed_jitter
					)
				)
				
				angle += rng.randf_range(
					-rule.individual_angle_jitter_degrees,
					rule.individual_angle_jitter_degrees
				)
			
			specs.append({
				"position": points[index],
				"speed": speed,
				"angle": fposmod(angle, 360.0),
				"kind": kinds[index],
				"formation": rule_index,
				"guaranteed": rule.guaranteed_solution
			})
		
		return {
			"ok": true,
			"specs": specs
		}
	
	return {
		"ok": false,
		"error": (
			"Could not place formation %d inside its authored margins." % rule_index
		)
	}

static func _build_offsets(
	rule: FormationRule,
	count: int,
	spacing: float,
	rotation: float,
) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	
	if count <= 0:
		return offsets
	
	if count == 1:
		offsets.append(Vector2.ZERO)
		return offsets
	
	match rule.pattern:
		FormationRule.Pattern.LINE:
			for index in range(count):
				var centered_index: float = (
					float(index) - float(count - 1) * 0.5
				)
				
				offsets.append(
					Vector2(centered_index * spacing, 0.0).rotated(
						rotation
					)
				)
		FormationRule.Pattern.RING:
			var ring_radius: float = spacing / (
				2.0 * sin(PI / float(count))
			)
			
			for index in range(count):
				var angle: float = (
					TAU * float(index) / float(count)
					+ rotation
				)
				
				offsets.append(
					Vector2.RIGHT.rotated(angle) * ring_radius
				)
		FormationRule.Pattern.ARC:
			var arc_radians: float = deg_to_rad(rule.arc_degrees)
			var step_angle: float = (
				arc_radians / float(count - 1)
			)
			var arc_radius: float = spacing / maxf(
				2.0 * sin(absf(step_angle) * 0.5),
				0.001
			)
			
			for index in range(count):
				var angle: float = (
					-arc_radians * 0.5 
					+ step_angle * float(index)
					+ rotation
				)
				
				offsets.append(
					Vector2.RIGHT.rotated(angle) * arc_radius
				)
	return offsets

static func _random_offset(
	rng: RandomNumberGenerator,
	maximum: float
) -> Vector2:
	if maximum <= 0.0:
		return Vector2.ZERO
	
	var angle: float = rng.randf_range(0.0, TAU)
	var distance: float = rng.randf_range(0.0, maximum)
	
	return Vector2.RIGHT.rotated(angle) * distance

static func _shuffle_kinds(
	kinds: Array[int],
	rng: RandomNumberGenerator
) -> void:
	for index in range(kinds.size() - 1, 0, -1):
		var other: int = rng.randi_range(0, index)
		
		var temporary: int = kinds[index]
		kinds[index] = kinds[other]
		kinds[other] = temporary

static func _assess_solution(
	specs: Array,
	power_target: int,
	heat_limit: int
) -> Dictionary:
	if specs.is_empty():
		return {
			"ok": false,
			"error": "formation has no bananas"
		}
	
	var power: int = 0
	var heat: int = 0
	
	for spec in specs:
		var which: Banana.Kind = spec["kind"]
		var stats: Dictionary = Banana.stats_for_kind(which)
		
		power += int(stats["power"])
		heat += int(stats["heat"])
	
	if power < power_target:
		return {
			"ok": false,
			"error": "not enough power"
		}
	
	if heat > heat_limit:
		return {
			"ok": false,
			"error": "exceeds heat limit"
		}
	
	if not _has_complete_chains(specs):
		return {
			"ok": false,
			"error": "starting positions are not chain-connected"
		}
	
	return {"ok": true}

static func _has_complete_chains(specs: Array) -> bool:
	if specs.is_empty():
		return false
	
	for starting_index in range(specs.size()):
		var visited: Array[bool] = []
		visited.resize(specs.size())
		visited.fill(false)
		
		var pending: Array[int] = [starting_index]
		visited[starting_index] = true
		
		var visited_count: int = 1
		
		while not pending.is_empty():
			var source_index: int = pending.pop_front()
			var source: Dictionary = specs[source_index]
			
			var source_kind: Banana.Kind = source["kind"]
			var source_stats: Dictionary = Banana.stats_for_kind(source_kind)
			var reaction_radius: float = float(source_stats["radius"])
			if reaction_radius <= 0.0:
				continue
			var reach: float = reaction_radius + HIT_RADIUS
			var source_position: Vector2 = source["position"]
			
			for target_index in range(specs.size()):
				if visited[target_index]:
					continue
				
				var target: Dictionary = specs[target_index]
				var target_position: Vector2 = target["position"]
				
				if source_position.distance_squared_to(target_position) <= reach * reach:
					visited[target_index] = true
					visited_count += 1
					pending.append(target_index)
		if visited_count == specs.size():
			return true
	
	return false
