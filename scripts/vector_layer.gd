extends Node2D

var arrows: Array = []
var font: Font

func _draw() -> void:
	var draw_font: Font = font if font != null else ThemeDB.fallback_font
	for arrow in arrows:
		var origin: Vector2 = arrow["origin"]
		var tip: Vector2 = arrow["tip"]
		var color: Color = arrow["color"]
		draw_line(origin, tip, color, 3.0, true)
		var direction := tip - origin
		if direction.length() < 8.0:
			continue
		direction = direction.normalized()
		var side := Vector2(-direction.y, direction.x)
		var head := PackedVector2Array([
			tip,
			tip - direction * 14.0 + side * 7.0,
			tip - direction * 14.0 - side * 7.0,
		])
		draw_colored_polygon(head, color)
		var label := str(arrow["label"])
		if label != "":
			draw_string(draw_font, tip + Vector2(10, 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
