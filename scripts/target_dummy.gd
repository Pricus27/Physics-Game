extends Node2D

func _draw() -> void:
	draw_line(Vector2(0, -210), Vector2(0, -30), Color("cbb48a"), 2.0)
	draw_circle(Vector2.ZERO, 30, Color("f4f1ea"))
	draw_circle(Vector2.ZERO, 22, Color("b3392b"))
	draw_circle(Vector2.ZERO, 13, Color("f4f1ea"))
	draw_circle(Vector2.ZERO, 5, Color("b3392b"))
