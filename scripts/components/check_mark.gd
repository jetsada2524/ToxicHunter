@tool
extends Control
## Chunky green tick with a dark outline - the "found it!" badge on the FOUND
## slots and on the hotspot in the room. Drawn, so it stays crisp at any size.

@export var color := Color("49C25A")
@export var outline := Color("1F5E2A")


func _draw() -> void:
	var s := size
	var pts := PackedVector2Array([
		Vector2(0.10, 0.55) * s, Vector2(0.40, 0.84) * s, Vector2(0.92, 0.16) * s])
	var w := s.x * 0.30
	_stroke(pts, outline, w)
	_stroke(pts, color, w * 0.58)


func _stroke(pts: PackedVector2Array, c: Color, w: float) -> void:
	draw_polyline(pts, c, w, true)
	for p in pts:
		draw_circle(p, w * 0.5, c)
