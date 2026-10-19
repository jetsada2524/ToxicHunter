@tool
extends Control
## Stopwatch icon for the timer pill. Uses assets/ui/icon_clock.png when that
## file exists; otherwise draws a simple orange stopwatch.

const Ui := preload("res://scripts/ui_kit.gd")

var _tex: Texture2D


func _ready() -> void:
	_tex = Ui.art("icon_clock.png")
	queue_redraw()


func _draw() -> void:
	if _tex:
		draw_texture_rect(_tex, Rect2(Vector2.ZERO, size), false)
		return
	var c := size * 0.5 + Vector2(0, size.y * 0.04)
	var r := minf(size.x, size.y) * 0.42
	draw_rect(Rect2(c.x - r * 0.18, c.y - r * 1.22, r * 0.36, r * 0.26), Color("2B3A4A"))
	draw_circle(c, r + 3, Color("2B3A4A"))
	draw_circle(c, r, Color("F08C3A"))
	draw_circle(c, r * 0.76, Color("FFF8EC"))
	draw_line(c, c + Vector2(0, -r * 0.55), Color("2B3A4A"), r * 0.13, true)
	draw_line(c, c + Vector2(r * 0.38, 0), Color("2B3A4A"), r * 0.13, true)
	draw_circle(c, r * 0.1, Color("2B3A4A"))
