extends Control

const LINES: Array[String] = [
	"RATTICUS IS VERY PLEASED!",
	"TERRA TOWN HAS (A COUPLE) LIGHTS AGAIN!",
	"fin."
]

@onready var line: Label = $%Line
@onready var prompt: Label = $%Prompt

var index: int = 0

func _ready() -> void:
	_show()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ignite"):
		get_viewport().set_input_as_handled()
		_advance()

func _advance() -> void:
	index += 1
	
	if index < LINES.size():
		_show()
		return
	
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func _show() -> void:
	line.text = LINES[index]
	
	if index == LINES.size() - 1:
		prompt.text = "click to return to the title"
	else:
		prompt.text = "click to continue"
