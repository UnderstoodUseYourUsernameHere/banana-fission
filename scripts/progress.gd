extends Node

const SAVE_PATH := "user://progress.cfg"

var levels: Array[PackedScene] = [
	preload("res://scenes/levels/level_01.tscn"),
	preload("res://scenes/levels/level_02.tscn"),
	preload("res://scenes/levels/level_03.tscn"),
	preload("res://scenes/levels/level_04.tscn"),
]

var current_level: int = 0
var attempt_seed: int = 0
var highest_cleared: int = -1
var attempts: Dictionary = {}
var best_stars: Dictionary = {}
var energy: int = 0

var upgrades: Dictionary = {}
var toggles: Dictionary = {}
var shop_return_scene: String = "res://scenes/title.tscn"


func level_count() -> int:
	return levels.size()

func is_last_level() -> bool:
	return current_level >= levels.size() - 1

func _ready() -> void:
	load_progress()

func is_unlocked(index: int) -> bool:
	return index <= highest_cleared + 1

func attempts_for(index: int) -> int:
	return attempts.get(index, 0)

func record_attempt() -> void:
	attempts[current_level] = attempts_for(current_level) + 1
	save_progress()

func record_clear(star_count: int) -> void:
	var awarded: int = clampi(star_count, 0, 3)
	if awarded == 0:
		return
	
	highest_cleared = maxi(highest_cleared, current_level)
	best_stars[current_level] = maxi(stars_for(current_level), awarded)
	save_progress()

func reset_all() -> void:
	highest_cleared = -1
	current_level = 0
	attempt_seed = 0
	attempts.clear()
	best_stars.clear()
	upgrades.clear()
	toggles.clear()
	energy = 0
	shop_return_scene = "res://scenes/title.tscn"
	save_progress()

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_cleared", highest_cleared)
	config.set_value("progress", "attempts", attempts)
	config.set_value("progress", "best_stars", best_stars)
	config.set_value("progress", "energy", energy)
	config.set_value("progress", "upgrades", upgrades)
	config.set_value("progress", "toggles", toggles)
	var save_error: Error = config.save(SAVE_PATH)
	if save_error != OK:
		push_warning("Could not save progress: %s" % error_string(save_error))

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	highest_cleared = config.get_value("progress", "highest_cleared", -1)
	attempts = config.get_value("progress", "attempts", {})
	var loaded_stars: Variant = config.get_value("progress", "best_stars", {})
	best_stars = loaded_stars if loaded_stars is Dictionary else {}
	energy = int(config.get_value("progress", "energy", 0))
	var loaded_upgrades: Variant = config.get_value("progress", "upgrades", {})
	upgrades = loaded_upgrades if loaded_upgrades is Dictionary else {}
	var loaded_toggles: Variant = config.get_value("progress", "toggles", {})
	toggles = loaded_toggles if loaded_toggles is Dictionary else {}

func stars_for(index: int) -> int:
	return clampi(int(best_stars.get(index, 0)), 0, 3)

func add_energy(amount: int) -> void:
	energy += maxi(amount, 0)
	save_progress()

func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))

func has_upgrade(id: String) -> bool:
	return upgrade_level(id) > 0

func buy_upgrade(id: String) -> bool:
	var cost: int = UpgradeCatalog.next_cost(id, upgrade_level(id))
	if cost < 0 or energy < cost or not UpgradeCatalog.is_unlocked(id):
		return false
	
	energy -= cost
	upgrades[id] = upgrade_level(id) + 1
	save_progress()
	return true

func is_toggle_on(id: String) -> bool:
	return bool(toggles.get(id, true))

func set_toggle(id: String, on: bool) -> void:
	toggles[id] = on
	save_progress()
