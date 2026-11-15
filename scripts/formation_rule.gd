extends Resource
class_name FormationRule

enum Pattern {
	LINE,
	RING,
	ARC
}

enum DirectionMode {
	ANGLE,
	TOWARD_POINT,
	AWAY_FROM_POINT
}

@export_group("Contents")
@export_range(0, 30, 1) var normal_count: int = 5
@export_range(0, 10 ,1) var overripe_count: int = 0

@export var guaranteed_solution: bool = false ## Means this formation must have a solution
@export var shuffle_kinds: bool = true

@export_group("Shape")
@export var pattern: Pattern = Pattern.RING
@export var anchor: Vector2 = Vector2(480.0, 290.0)
@export var anchor_jitter: Vector2 = Vector2(30.0, 30.0)
@export_range(38.0, 100.0, 1.0) var spacing: float = 55.0
@export_range(0.0, 15.0, 1.0) var spacing_jitter: float = 4.0
@export_range(0.0, 12.0, 1.0) var position_jitter: float = 3.0
@export_range(-180.0, 180.0, 1.0) var rotation_degrees: float = 0.0
@export_range(0.0, 180.0, 1.0) var rotation_jitter_degrees: float = 180.0
@export_range(30.0, 330.0, 1.0) var arc_degrees: float = 180.0
@export_range(36.0, 220.0, 1.0) var separation_from_others: float = 80.0
@export_range(0.0, 150.0, 1.0) var wall_margin: float = 50.0

@export_group("Motion")
@export_range(0.0, 160.0, 1.0) var drift_speed: float = 60.0
@export_range(0.0, 30.0, 1.0) var speed_jitter: float = 4.0
@export_range(0.0, 30.0, 1.0) var individual_speed_jitter: float = 0.0
@export_range(0.0, 360.0, 1.0) var drift_angle_degrees: float = 0.0
@export var direction_mode: DirectionMode = DirectionMode.ANGLE
@export var motion_target: Vector2 = Vector2(480.0, 290.0)
@export_range(0.0, 180.0, 1.0) var drift_angle_jitter_degrees: float = 180.0
@export_range(0.0, 25.0, 1.0) var individual_angle_jitter_degrees: float = 4.0 ## Jitter degrees per banana, ignored when guaranteed is on
