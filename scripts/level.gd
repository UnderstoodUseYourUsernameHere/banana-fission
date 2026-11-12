extends Node2D
class_name Level

@export var title: String = "Untitled"
@export_multiline var ratticus_line: String = ""
@export_range(1, 100, 1) var power_target: int = 6
@export_range(1, 100, 1) var heat_limit: int = 7
@export_range(0, 100, 1) var gold_heat_limit: int = 6
