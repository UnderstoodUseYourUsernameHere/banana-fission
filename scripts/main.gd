extends Node2D

func _ready() -> void:
	print("Reactor, READY")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()
