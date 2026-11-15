extends Node2D
class_name FloatText

const LIFETIME: float = 0.8
const RISE_SPEED: float = 40.0

var text: String = ""
var color: Color = Color.WHITE
var font_size: int = 16
var age: float = 0.0

func _process(delta: float) -> void:
	age += delta
	if age >= LIFETIME:
		queue_free()
		return
	
	position.y -= RISE_SPEED * delta
	modulate.a = 1.0 - pow(age / LIFETIME, 2.0)

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(-width * 0.5, 0.0)
	
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.8))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
