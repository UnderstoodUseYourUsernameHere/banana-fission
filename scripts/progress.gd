extends Node

var levels: Array[PackedScene] = [preload("res://scenes/levels/level_01.tscn"), preload("res://scenes/levels/level_02.tscn")]
var current_level: int = 0

func level_count() -> int:
	return levels.size()

func is_last_level() -> bool:
	return current_level >= levels.size() - 1
