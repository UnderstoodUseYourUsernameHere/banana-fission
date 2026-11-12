extends Node

const SAVE_PATH := "user://progress.cfg"

var levels: Array[PackedScene] = [preload("res://scenes/levels/level_01.tscn"), preload("res://scenes/levels/level_02.tscn")]
var current_level: int = 0
var highest_cleared: int = -1
var attempts: Dictionary = {}

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

func record_clear() -> void:
	highest_cleared = maxi(highest_cleared, current_level)
	save_progress()

func reset_all() -> void:
	highest_cleared = -1
	attempts.clear()
	save_progress()

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "highest_cleared", highest_cleared)
	config.set_value("progress", "attempts", attempts)
	config.save(SAVE_PATH)

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	highest_cleared = config.get_value("progress", "highest_cleared", -1)
	attempts = config.get_value("progress", "attempts", {})
