extends Control

signal finished

const CHARS_PER_SECOND := 46.0

@onready var text_box: PanelContainer = $TextBox
@onready var speaker_label: Label = $Nameplate/Speaker
@onready var nameplate: PanelContainer = $Nameplate
@onready var body_label: Label = $TextBox/Margin/Body
@onready var cursor: Polygon2D = $Cursor
@onready var portrait_lyra: TextureRect = $Portraits/Lyra
@onready var portrait_pricxu: TextureRect = $Portraits/Pricxu
@onready var portrait_kaelen: TextureRect = $Portraits/Kaelen

var _portraits := {}
var _lines: Array = []
var _index := 0
var _active := false
var _typing := false
var _type_time := 0.0
var _full_text := ""
var _bob := 0.0


func apply_fonts(name_font: Font, body_font: Font) -> void:
	text_box.add_theme_stylebox_override("panel", _text_style())
	nameplate.add_theme_stylebox_override("panel", _name_style(Color("edbd72")))
	speaker_label.add_theme_font_override("font", name_font)
	speaker_label.add_theme_font_size_override("font_size", 22)
	speaker_label.add_theme_color_override("font_color", Color("18212b"))
	body_label.add_theme_font_override("font", body_font)
	body_label.add_theme_font_size_override("font_size", 22)
	body_label.add_theme_color_override("font_color", Color("f4f7f8"))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for rect in [portrait_lyra, portrait_pricxu, portrait_kaelen]:
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func set_portraits(faces: Dictionary) -> void:
	_portraits = {
		"Lyra": portrait_lyra,
		"Pricxu": portrait_pricxu,
		"Kaelen": portrait_kaelen,
	}
	for speaker in _portraits:
		var rect: TextureRect = _portraits[speaker]
		rect.texture = faces.get(speaker)
		rect.pivot_offset = Vector2(rect.size.x * 0.5, rect.size.y)


func start(lines: Array) -> void:
	_lines = lines
	_index = 0
	_active = true
	visible = true
	_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	var speaker := str(line["speaker"])
	var color := _speaker_color(speaker)
	speaker_label.text = speaker
	speaker_label.add_theme_color_override("font_color", color)
	nameplate.add_theme_stylebox_override("panel", _name_style(color))
	_full_text = str(line["text"])
	body_label.text = _full_text
	body_label.visible_characters = 0
	_type_time = 0.0
	_typing = true
	cursor.visible = false
	_focus_speaker(speaker)


func _focus_speaker(speaker: String) -> void:
	for name in _portraits:
		var rect: TextureRect = _portraits[name]
		var speaking: bool = name == speaker
		rect.visible = speaking
		rect.modulate = Color.WHITE
		rect.scale = Vector2.ONE
		if speaking:
			_place_bust(rect)


func _place_bust(rect: TextureRect) -> void:
	var texture := rect.texture
	if texture == null:
		return
	var height := 176.0
	var width := height * texture.get_width() / float(texture.get_height())
	rect.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	rect.offset_left = 52.0
	rect.offset_right = 52.0 + width
	rect.offset_bottom = -214.0
	rect.offset_top = -214.0 - height


func _process(delta: float) -> void:
	if not _active:
		return
	if _typing:
		_type_time += delta
		var shown := int(_type_time * CHARS_PER_SECOND)
		body_label.visible_characters = shown
		if shown >= _full_text.length():
			_finish_typing()
		return
	_bob += delta
	var box_origin := text_box.position
	var box_size := text_box.size
	cursor.position = box_origin + Vector2(box_size.x - 36.0, box_size.y - 18.0 + sin(_bob * 6.0) * 3.0)


func _finish_typing() -> void:
	_typing = false
	body_label.visible_characters = -1
	cursor.visible = true


func _speaker_color(speaker: String) -> Color:
	match speaker:
		"Lyra":
			return Color("8ad7bd")
		"Kaelen":
			return Color("edbd72")
		_:
			return Color("f2f6f8")


func _gui_input(event: InputEvent) -> void:
	if not _active or not visible or not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_progress()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not visible or not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	_progress()


func _progress() -> void:
	if _typing:
		_finish_typing()
		return
	_index += 1
	if _index >= _lines.size():
		_active = false
		visible = false
		finished.emit()
	else:
		_show_line()


func _text_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.055, 0.09, 0.12, 0.94)
	box.border_color = Color("d7b56a")
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.content_margin_left = 24
	box.content_margin_right = 42
	box.content_margin_top = 26
	box.content_margin_bottom = 18
	box.shadow_color = Color(0, 0, 0, 0.5)
	box.shadow_size = 10
	return box


func _name_style(accent: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("14202a")
	box.border_color = accent
	box.set_border_width_all(3)
	box.set_corner_radius_all(5)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box
