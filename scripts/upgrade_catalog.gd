extends RefCounted
class_name UpgradeCatalog

const IGNITION_COIL: String = "ignition_coil"
const HEAT_SINK: String = "heat_sink"
const AUTO_SCRAM: String = "auto_scram"
const AUTO_IGNITE: String = "auto_ignite"
const PEEL_TURBINE: String = "peel_turbine"

const SHOP_UNLOCK_AFTER: int = 1

const ALL: Array = [
	{"id": IGNITION_COIL, "name": "Ignition Coil", "costs": [10, 20, 35], "unlock_after": 1, "description": "+8 starter pulse radius per level."},
	{"id": HEAT_SINK, "name": "Heat Sink", "costs": [15, 30], "unlock_after": 1, "description": "+1 heat limit per level. Doesnt change the gold target level"},
	{"id": AUTO_SCRAM, "name": "Auto-SCRAM", "costs": [20], "unlock_after": 1, "description": "Shuts down the reaction as soon as energy target is reached, caps rating at 2/3. [T] to toggle"},
	{"id": AUTO_IGNITE, "name": "Auto-Ignite", "costs": [30, 45], "unlock_after": 2, "description": "Fires the starter pulse for you. Level 2 fires faster. [Y] toggles."},
	{"id": PEEL_TURBINE, "name": "Peel Turbine", "costs": [25, 50], "unlock_after": 2, "description": "+25% energy per level from each clear."}
]

static func get_def(id: String) -> Dictionary:
	for def in ALL:
		if def["id"] == id:
			return def
	return {}

static func max_level(id: String) -> int:
	return (get_def(id).get("costs", []) as Array).size()

static func next_cost(id: String, current_level: int) -> int:
	var costs: Array = get_def(id).get("costs", [])
	if current_level >= costs.size():
		return -1
	return int(costs[current_level])

static func is_unlocked(id: String) -> bool:
	return Progress.highest_cleared >= int(get_def(id).get("unlock_after", 0))

static func shop_unlocked() -> bool:
	return Progress.highest_cleared >= SHOP_UNLOCK_AFTER
