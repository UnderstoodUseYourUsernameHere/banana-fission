extends Control

@onready var start_button: Button = $%Start
@onready var reset_button: Button = $%Reset
@onready var level_row: HBoxContainer = $Levels

func _ready() -> void:
	start_button.pressed.connect(_on_start)
	reset_button.pressed.connect(_on_reset)
	_build_level_buttons()

func _build_level_buttons() -> void:
	for child in level_row.get_children():
		child.queue_free()
	
	for index in range(Progress.level_count()):
		var button := Button.new()
		button.text = "Level %d" % (index + 1)
		button.custom_minimum_size = Vector2(110.0, 40.0)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = not Progress.is_unlocked(index)
		button.pressed.connect(_play_level.bind(index))
		level_row.add_child(button)

func _on_start() -> void:
	var next_index: int = clampi(Progress.highest_cleared + 1, 0, Progress.level_count() - 1)
	_play_level(next_index)

func _play_level(index: int) -> void:
	Progress.current_level = index
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_reset() -> void:
	Progress.reset_all()
	_build_level_buttons()
