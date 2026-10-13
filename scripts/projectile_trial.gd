extends Node

signal resolved

const UiSkin = preload("res://scripts/ui_skin.gd")

const G := 9.81
const TARGET_X := 15.0
const TARGET_Y := 5.0
const HIT_RADIUS := 0.45
const PX_PER_M := 32.0

var _panel: PanelContainer
var _edits := {}
var _feedback: Label
var _equation: Label
var _knife: Polygon2D
var _trail: Line2D
var _pricxu: Sprite2D
var _origin := Vector2.ZERO
var _running := false
var _busy := false
var _v := 0.0
var _theta := 0.0
var _t := 0.0
var _closest := INF
var _hit := false

func setup(host: Control, knife: Polygon2D, trail: Line2D, pricxu: Sprite2D, equation: Label, font: Font) -> void:
	_knife = knife
	_trail = trail
	_pricxu = pricxu
	_equation = equation
	var form := UiSkin.build_form(host, font, "Trial — Projectile motion",
		"Lyra: The bullseye is 15 m away and 5 m above your hand. g = 9.81 m/s².\nx = (v cos θ) t\ny = (v sin θ) t − ½ g t²\nAny speed and angle whose arc passes through the bullseye will land the throw.",
		[
			{"key": "speed", "label": "Initial velocity (m/s)", "placeholder": "speed"},
			{"key": "angle", "label": "Angle of elevation (degrees)", "placeholder": "angle"},
		],
		"Throw the knife")
	_panel = form["panel"]
	_edits = form["edits"]
	_feedback = form["feedback"]
	form["button"].pressed.connect(_on_submit)
	for key in _edits:
		_edits[key].text_submitted.connect(func(_text): _on_submit())


func begin(origin: Vector2) -> void:
	_origin = origin
	_running = false
	_busy = false
	_panel.visible = true
	_feedback.text = ""
	_equation.visible = false
	_knife.visible = false
	_trail.clear_points()
	_edits["speed"].grab_focus()


func _on_submit() -> void:
	if _running or _busy:
		return
	var speed := float(_edits["speed"].text)
	var angle := float(_edits["angle"].text)
	if speed < 0.5 or speed > 80.0:
		_feedback.text = "Enter a speed between 0.5 and 80 m/s."
		return
	if angle <= 1.0 or angle >= 89.0:
		_feedback.text = "Enter an angle between 1 and 89 degrees."
		return
	_v = speed
	_theta = deg_to_rad(angle)
	_t = 0.0
	_closest = INF
	_hit = false
	_running = true
	_panel.visible = false
	_equation.visible = true
	_trail.clear_points()
	_knife.visible = true
	_knife.position = _origin
	_pricxu.play("attack")
	_update_equation(0.0, 0.0)


func _process(delta: float) -> void:
	if not _running:
		return
	var remaining := delta
	var step := clampf(0.12 / maxf(_v, 1.0), 0.004, 0.02)
	while _running and remaining > 0.0:
		var dt := minf(step, remaining)
		remaining -= dt
		_advance(dt)
	if not _running:
		_finish()


func _advance(dt: float) -> void:
	var previous := _position_at(_t)
	_t += dt
	var current := _position_at(_t)
	var screen := _origin + Vector2(current.x, -current.y) * PX_PER_M
	_knife.position = screen
	var velocity := _velocity_at(_t)
	_knife.rotation = atan2(-velocity.y, velocity.x)
	_trail.add_point(screen)
	_closest = minf(_closest, _segment_distance(previous, current, Vector2(TARGET_X, TARGET_Y)))
	_update_equation(current.x, current.y)
	if _closest <= HIT_RADIUS:
		_hit = true
		_running = false
		return
	if current.y <= 0.0 and _t > 0.05:
		_running = false


func _position_at(time: float) -> Vector2:
	var vx := _v * cos(_theta)
	var vy := _v * sin(_theta)
	return Vector2(vx * time, vy * time - 0.5 * G * time * time)


func _velocity_at(time: float) -> Vector2:
	return Vector2(_v * cos(_theta), _v * sin(_theta) - G * time)


func _segment_distance(a: Vector2, b: Vector2, point: Vector2) -> float:
	var segment := b - a
	var length_sq := segment.length_squared()
	if length_sq < 0.000001:
		return a.distance_to(point)
	var t := clampf((point - a).dot(segment) / length_sq, 0.0, 1.0)
	return a.lerp(b, t).distance_to(point)


func _update_equation(x: float, y: float) -> void:
	_equation.text = "x = (v cos θ) t = %.2f m\ny = (v sin θ) t − ½ g t² = %.2f m\ng = 9.81 m/s²    t = %.2f s" % [x, y, _t]


func _finish() -> void:
	_busy = true
	_pricxu.play("idle")
	if _hit:
		_equation.text = "The arc passes through the bullseye.\nx = (v cos θ) t    y = (v sin θ) t − ½ g t²"
		resolved.emit()
		return
	_panel.visible = true
	_feedback.text = _miss_reason()
	_busy = false


func _miss_reason() -> String:
	var vx := _v * cos(_theta)
	var vy := _v * sin(_theta)
	if vx <= 0.2:
		return "The knife has almost no forward speed, so it never crosses the ravine."
	var t_ground := 2.0 * vy / G if vy > 0.0 else 0.0
	var t_target := TARGET_X / vx
	if t_target >= t_ground:
		return "The knife falls short. It meets the ground before it travels 15 m."
	var y_at := vy * t_target - 0.5 * G * t_target * t_target
	if y_at > TARGET_Y:
		return "The knife flies over the bullseye. At 15 m it is still %.2f m too high." % (y_at - TARGET_Y)
	return "The knife passes under the bullseye. At 15 m it is %.2f m too low." % (TARGET_Y - y_at)
