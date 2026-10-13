extends Node

signal resolved

const UiSkin = preload("res://scripts/ui_skin.gd")

const MASS := 4.0
const SPEED := 8.0
const MOMENTUM := 32.0
const TOLERANCE := 1.6

var _panel: PanelContainer
var _edits := {}
var _feedback: Label
var _equation: Label
var _pricxu: Sprite2D
var _kaelen: Sprite2D
var _pricxu_x := 0.0
var _kaelen_x := 0.0
var _busy := false
var _tween: Tween

func setup(host: Control, pricxu: Sprite2D, kaelen: Sprite2D, equation: Label, font: Font) -> void:
	_pricxu = pricxu
	_kaelen = kaelen
	_equation = equation
	var form := UiSkin.build_form(host, font, "Trial — Momentum and collision",
		"Lyra: Kaelen's sword is 4 kg and reaches you at 8 m/s.\np = m v\nYour parry is an impulse, J = Δp, opposite the swing.\nBring the remaining speed close to zero.",
		[
			{"key": "impulse", "label": "Parry impulse (N·s)", "placeholder": "impulse"},
		],
		"Parry")
	_panel = form["panel"]
	_edits = form["edits"]
	_feedback = form["feedback"]
	form["button"].pressed.connect(_on_submit)
	_edits["impulse"].text_submitted.connect(func(_text): _on_submit())


func begin() -> void:
	_busy = false
	_pricxu_x = _pricxu.position.x
	_kaelen_x = _kaelen.position.x
	_panel.visible = true
	_feedback.text = ""
	_equation.visible = true
	_equation.text = "p = m v = %.0f kg × %.0f m/s = %.0f kg·m/s\nJ = Δp    remaining momentum = p − J" % [MASS, SPEED, MOMENTUM]
	_edits["impulse"].grab_focus()


func _on_submit() -> void:
	if _busy:
		return
	var impulse := float(_edits["impulse"].text)
	if impulse < 0.0 or impulse > 200.0:
		_feedback.text = "Enter an impulse of 0 N·s or more."
		return
	_busy = true
	_panel.visible = false
	var remaining := MOMENTUM - impulse
	var speed_after := remaining / MASS
	_equation.text = "p = m v = %.0f kg·m/s\nJ = %.1f N·s\np' = p − J = %.1f kg·m/s    v' = %.2f m/s" % [MOMENTUM, impulse, remaining, speed_after]
	_clash(absf(remaining) <= TOLERANCE, remaining)


func _clash(success: bool, remaining: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_kaelen.face_left(true)
	_kaelen.play("attack")
	_pricxu.face_left(false)
	_tween = create_tween()
	_tween.tween_property(_kaelen, "position:x", _pricxu_x + 150.0, 0.28)
	await _tween.finished
	if success:
		_pricxu.play("attack")
	else:
		_pricxu.play("hurt")
		if remaining > 0.0:
			_tween = create_tween()
			_tween.tween_property(_pricxu, "position:x", _pricxu_x - 28.0, 0.12)
			_tween.tween_property(_pricxu, "position:x", _pricxu_x, 0.18)
		else:
			_tween = create_tween()
			_tween.tween_property(_kaelen, "position:x", _kaelen_x + 20.0, 0.12)
	await get_tree().create_timer(0.55).timeout
	_reset_positions()
	if success:
		_kaelen.play("idle")
		_pricxu.play("idle")
		resolved.emit()
		return
	_kaelen.play("idle")
	_pricxu.play("idle")
	_panel.visible = true
	_busy = false
	if remaining > 0.0:
		_feedback.text = "The parry is too light. The blade still carries %.1f kg·m/s into your guard." % remaining
	else:
		_feedback.text = "The impulse is too large. Your guard is thrown aside, and %.1f kg·m/s remains the other way." % absf(remaining)


func _reset_positions() -> void:
	_pricxu.position.x = _pricxu_x
	_kaelen.position.x = _kaelen_x
