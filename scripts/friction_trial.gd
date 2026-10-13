extends Node

signal resolved

const UiSkin = preload("res://scripts/ui_skin.gd")

const MASS := 200.0
const MU_S := 0.50
const MU_K := 0.40
const G := 9.81
const PUSH_TIME := 0.80
const ZONE_MIN := 3.0
const ZONE_MAX := 5.0
const PX_PER_M := 32.0

var _panel: PanelContainer
var _edits := {}
var _feedback: Label
var _equation: Label
var _stone: Node2D
var _vectors: Node2D
var _pricxu: Sprite2D
var _force := 0.0
var _home_set := false
var _home := 0.0
var _start_x := 0.0
var _distance := 0.0
var _goal := 0.0
var _speed := 0.0
var _elapsed := 0.0
var _phase := ""
var _static_limit := 0.0
var _kinetic := 0.0

func setup(host: Control, stone: Node2D, vectors: Node2D, pricxu: Sprite2D, equation: Label, font: Font) -> void:
	_stone = stone
	_vectors = vectors
	_pricxu = pricxu
	_equation = equation
	_vectors.font = font
	_static_limit = MU_S * MASS * G
	_kinetic = MU_K * MASS * G
	var form := UiSkin.build_form(host, font, "Trial — Newton's laws and friction",
		"Lyra: The stone is 200 kg. μs = 0.50, μk = 0.40, g = 9.81 m/s². Your palm pushes for 0.80 s.\nIt moves only if F > μs m g.\nWhile you push, a = (F − μk m g) / m. Afterward it coasts s = v² / (2 μk g).\nThe path opens if the stone stops between 3.0 m and 5.0 m.",
		[
			{"key": "force", "label": "Applied force (N)", "placeholder": "force"},
		],
		"Strike the stone")
	_panel = form["panel"]
	_edits = form["edits"]
	_feedback = form["feedback"]
	form["button"].pressed.connect(_on_submit)
	_edits["force"].text_submitted.connect(func(_text): _on_submit())


func begin() -> void:
	if not _home_set:
		_home = _stone.position.x
		_home_set = true
	_stone.position.x = _home
	_phase = ""
	_panel.visible = true
	_feedback.text = ""
	_equation.visible = false
	_vectors.arrows = []
	_vectors.queue_redraw()
	_edits["force"].grab_focus()


func _on_submit() -> void:
	if _phase == "push" or _phase == "coast" or _phase == "shake":
		return
	var force := float(_edits["force"].text)
	if force <= 0.0 or force > 8000.0:
		_feedback.text = "Enter a force greater than 0 N."
		return
	_force = force
	_stone.position.x = _home
	_start_x = _home
	_distance = 0.0
	_goal = _travel_distance(_force)
	_speed = 0.0
	_elapsed = 0.0
	_panel.visible = false
	_equation.visible = true
	_pricxu.play("attack")
	_draw_vectors(true, 0.0)
	if _force <= _static_limit:
		_phase = "shake"
		return
	_phase = "push"


func _process(delta: float) -> void:
	if _phase == "shake":
		_elapsed += delta
		var wobble := sin(_elapsed * 40.0) * 5.0 * (1.0 - clampf(_elapsed / 0.45, 0.0, 1.0))
		_stone.position.x = _start_x + wobble
		_equation.text = "F = %.0f N    static friction = μs m g = %.0f N\nThe applied force does not exceed static friction, so a = 0." % [_force, _static_limit]
		if _elapsed >= 0.45:
			_stone.position.x = _start_x
			_phase = ""
			_pricxu.play("idle")
			_panel.visible = true
			_feedback.text = "The stone does not move. Static friction is %.0f N, and your force does not exceed it." % _static_limit
		return
	if _phase != "push" and _phase != "coast":
		return

	var acceleration := 0.0
	if _phase == "push":
		acceleration = (_force - _kinetic) / MASS
		_elapsed += delta
		if _elapsed >= PUSH_TIME:
			delta -= _elapsed - PUSH_TIME
			_elapsed = PUSH_TIME
			_phase = "coast"
	if _phase == "coast":
		acceleration = -MU_K * G
	_speed = maxf(0.0, _speed + acceleration * delta)
	_distance += _speed * delta
	_stone.position.x = _start_x + _distance * PX_PER_M
	_draw_vectors(_phase == "push", acceleration)
	var shown_acceleration := acceleration if _phase == "push" else -MU_K * G
	_equation.text = "a = (F − μk m g) / m = %.2f m/s²\nv = %.2f m/s    distance = %.2f m\nStop the stone between %.1f m and %.1f m." % [shown_acceleration, _speed, _distance, ZONE_MIN, ZONE_MAX]
	if _phase == "coast" and _speed <= 0.01:
		_speed = 0.0
		_distance = _goal
		_stone.position.x = _start_x + _goal * PX_PER_M
		_phase = ""
		_finish()


func _draw_vectors(_pushing: bool, _acceleration: float) -> void:
	var body := _stone.get_node("Body") as Node2D
	var center := _stone.position + body.position
	var weight := MASS * G
	var longest := maxf(weight, _force)
	var scale := 150.0 / longest
	var friction := _force if not _pushing and _distance <= 0.0 else _kinetic
	if _phase == "shake" or (_distance <= 0.0 and _force <= _static_limit):
		friction = minf(_force, _static_limit)
	var arrows := [
		{"origin": center, "tip": center + Vector2(0, weight * scale), "color": Color("d7e4ea"), "label": "Weight %.0f N" % weight},
		{"origin": center, "tip": center + Vector2(0, -weight * scale), "color": Color("8ad7bd"), "label": "Normal %.0f N" % weight},
		{"origin": center, "tip": center + Vector2(-friction * scale, 0), "color": Color("e07a5f"), "label": "Friction %.0f N" % friction},
	]
	arrows.append({"origin": center, "tip": center + Vector2(_force * scale, 0), "color": Color("edbd72"), "label": "Applied %.0f N" % _force})
	_vectors.arrows = arrows
	_vectors.queue_redraw()


func _travel_distance(force: float) -> float:
	if force <= _static_limit:
		return 0.0
	var acceleration := (force - _kinetic) / MASS
	var launch := acceleration * PUSH_TIME
	var pushed := 0.5 * acceleration * PUSH_TIME * PUSH_TIME
	var coast := launch * launch / (2.0 * MU_K * G)
	return pushed + coast


func _finish() -> void:
	_pricxu.play("idle")
	_draw_vectors(false, 0.0)
	_distance = _goal
	if _distance >= ZONE_MIN and _distance <= ZONE_MAX:
		_equation.text = "Unbalanced force while pushing, then kinetic friction brings the stone to rest at %.2f m." % _distance
		resolved.emit()
		return
	_panel.visible = true
	if _distance < ZONE_MIN:
		_feedback.text = "The stone grinds %.2f m and stops short of the path. The marked ground begins at %.1f m." % [_distance, ZONE_MIN]
	else:
		_pricxu.play("hurt")
		_feedback.text = "The strike is too strong. The stone travels %.2f m and overshoots the %.1f m mark." % [_distance, ZONE_MAX]
