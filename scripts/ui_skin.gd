extends RefCounted

static func style_panel() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("101922e8")
	box.border_color = Color("edbd72")
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box


static func style_button() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("edbd72")
	box.set_corner_radius_all(4)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


static func style_edit() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("14222d")
	box.border_color = Color("304552")
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


static func paint(control: Control, font: Font, size: int, color: Color = Color("e8eee9")) -> void:
	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_color", color)
	control.add_theme_color_override("font_hover_color", color)
	control.add_theme_color_override("font_pressed_color", color)
	control.add_theme_color_override("font_placeholder_color", Color("9fb1b7"))


static func make_label(text: String, font: Font, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paint(label, font, size, color)
	label.add_theme_constant_override("outline_size", 0)
	return label


static func build_form(host: Control, font: Font, title: String, hint: String, field_defs: Array, button_text: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 24
	panel.offset_top = -292
	panel.offset_right = -24
	panel.offset_bottom = -16
	panel.add_theme_stylebox_override("panel", style_panel())
	panel.visible = false
	host.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(make_label(title, font, 20, Color("edbd72")))
	box.add_child(make_label(hint, font, 14, Color("8ad7bd")))

	var edits := {}
	for field in field_defs:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var name := make_label(field["label"], font, 16, Color("e8eee9"))
		name.custom_minimum_size = Vector2(320, 0)
		name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var edit := LineEdit.new()
		edit.placeholder_text = field["placeholder"]
		edit.custom_minimum_size = Vector2(240, 36)
		edit.add_theme_stylebox_override("normal", style_edit())
		edit.add_theme_stylebox_override("focus", style_edit())
		paint(edit, font, 16)
		row.add_child(name)
		row.add_child(edit)
		box.add_child(row)
		edits[field["key"]] = edit

	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(180, 36)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var button_style := style_button()
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_stylebox_override("hover", button_style)
	button.add_theme_stylebox_override("pressed", button_style)
	button.add_theme_stylebox_override("focus", button_style)
	paint(button, font, 16, Color("18212b"))
	box.add_child(button)

	var feedback := make_label("", font, 14, Color("f3c7b4"))
	box.add_child(feedback)
	return {"panel": panel, "edits": edits, "button": button, "feedback": feedback}
