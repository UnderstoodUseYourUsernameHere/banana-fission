extends RefCounted
class_name LevelGenerator

const MAX_TRIES_PER_BANANA: int = 80
const ROD_KEEP_OUT: float = 8.0
const HIT_RADIUS: float = 18.0

static func generate(
	rules: Array[SpawnRule],
	chamber: Rect2,
	rods: Array[Rect2],
	existing: Array[Vector2],
	seed_value: int
) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	 
	var placed: Array[Vector2] = existing.duplicate()
	var result: Array[Dictionary] = []
	var safe_chamber: Rect2 = chamber.grow(-HIT_RADIUS)
	
	for rule in rules:
		if rule == null:
			continue
		
		var area: Rect2 = rule.region.intersection(safe_chamber)
		if area.size.x <= 0.0 or area.size.y <= 0.0:
			push_error("SpanwRule region is outside the chamber!")
			return []
		
		for banana_index in range(rule.count):
			var point := Vector2.ZERO
			var found := false
			
			for _attempt in range(MAX_TRIES_PER_BANANA):
				point = Vector2(
					rng.randf_range(area.position.x, area.end.x),
					rng.randf_range(area.position.y, area.end.y)
				)
				if _is_clear(point, placed, rods, rule.min_spacing):
					found = true
					break
			
			if not found:
				push_error("SpawnRule could not place banana %d of %d." % [banana_index + 1, rule.count])
				return []
			
			placed.append(point)
			result.append({
				"position": point,
				"speed": rng.randf_range(rule.speed_min, rule.speed_max),
				"angle": rng.randf_range(0.0, 360.0),
				"kind": rule.kind,
			})
	return result

static func _is_clear(point: Vector2, placed: Array[Vector2], rods: Array[Rect2], spacing: float) -> bool:
	for other in placed:
		if point.distance_squared_to(other) < spacing * spacing:
			return false
	
	for rod in rods: 
		if rod.grow(HIT_RADIUS + ROD_KEEP_OUT).has_point(point):
			return false
	
	return true
