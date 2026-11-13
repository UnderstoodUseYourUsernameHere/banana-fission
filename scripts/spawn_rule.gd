extends Resource
class_name SpawnRule

@export var kind: Banana.Kind = Banana.Kind.NORMAL
@export_range(1, 40, 1) var count: int = 4

@export var region: Rect2 = Rect2(60.0, 100.0, 840.0, 380.0)
@export_range(0.0, 200.0, 1.0) var speed_min: float = 45.0
@export_range(0.0, 200.0, 1.0) var speed_max: float = 70.0

@export_range(20.0, 200.0, 1.0) var min_spacing: float = 52.0
