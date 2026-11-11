extends Node2D
class_name BananaHalf

const LIFETIME: float = 0.6
const DRAG: float = 4.0

var velocity: Vector2 = Vector2.ZERO
var spin: float = 0.0
var size: float = 18.0
var texture: Texture2D
var age: float = 0.0

func _process(delta: float) -> void:
	age += delta
	
	if age >= LIFETIME:
		queue_free()
		return
	
	position += velocity * delta
	velocity *= exp(-DRAG * delta)
	rotation += spin * delta
	modulate.a = 1.0 - age / LIFETIME

func _draw() -> void:
	if texture != null:
		var image_size: Vector2 = texture.get_size()
		var draw_size: Vector2 = image_size * (size * 2.0 / maxf(image_size.x, image_size.y))
		draw_texture_rect(texture, Rect2(-draw_size * 0.5, draw_size), false)
		return
	
	var points := PackedVector2Array([Vector2.ZERO])
	
	for i in range(13):
		var angle: float = lerpf(-PI * 0.5, PI * 0.5, float(i) / 12.0)
		points.append(Vector2.RIGHT.rotated(angle) * size)
	
	draw_colored_polygon(points, Color("ffd23f"))
