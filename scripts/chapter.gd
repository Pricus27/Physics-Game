extends Node2D

const TextureLoader = preload("res://scripts/texture_loader.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")

const GROUND_Y := 607.0
const PX_PER_M := 32.0
const STONE_X := 760.0

const ENCOUNTER := [
	{"speaker": "Lyra", "text": "Fascinating. Did you see that, Pricxu? That wasn't just speed. That was a perfect calculation of trajectory and force."},
	{"speaker": "Pricxu", "text": "Who is he? He moved like the wind, but his strike was as heavy as a falling boulder."},
	{"speaker": "Kaelen", "text": "The wind and the boulder are governed by the same laws, wanderer. I am Kaelen. I perceive the world not in magic, but in mass, motion, and momentum. To swing a sword without understanding the forces behind it is to fight blind."},
	{"speaker": "Pricxu", "text": "I wish to learn this... this discipline. Will you teach me?"},
	{"speaker": "Kaelen", "text": "Words teach nothing. The world itself is the best simulation. If you wish to learn, you must calculate."},
]

const PROJECTILE_INTRO := [
	{"speaker": "Kaelen", "text": "A master archer or a master swordsman knows where their strike will land before they move. We will start with motion in two dimensions. Take these throwing knives."},
	{"speaker": "Pricxu", "text": "Just aim and throw?"},
	{"speaker": "Kaelen", "text": "No. Understand the arc. Gravity will pull your blade down at a constant rate. You must determine the exact initial velocity and the angle of elevation required to hit the center of that target. If you guess, you fail."},
	{"speaker": "Lyra", "text": "He's right, Pricxu. We need to use the kinematic equations for projectile motion. The target is 15 meters away, and elevated 5 meters from our hands."},
]

const PROJECTILE_SUCCESS := [
	{"speaker": "Kaelen", "text": "A perfect parabola. You understand that gravity is not your enemy, Pricxu. It is a constant variable you must simply account for."},
	{"speaker": "Pricxu", "text": "It felt natural once I understood the math behind the motion. The angle dictates the peak, and the velocity carries it forward."},
]

const FRICTION_INTRO := [
	{"speaker": "Lyra", "text": "Well, this is a problem. We can't go around it. The brush is too thick."},
	{"speaker": "Kaelen", "text": "A physical obstacle is just a puzzle of forces. Tell me, Pricxu, what keeps this stone anchored to the earth?"},
	{"speaker": "Pricxu", "text": "Its weight? It looks incredibly heavy."},
	{"speaker": "Kaelen", "text": "Mass is only half the equation. The earth beneath it grips the stone. We call this friction. To move it, your applied force must exceed the static friction. Strike the stone with your palm, but channel exactly enough force to break the friction, or you will merely shatter your own bones."},
]

const FRICTION_SUCCESS := [
	{"speaker": "Pricxu", "text": "I felt it... the exact moment my force overcame the resistance."},
	{"speaker": "Kaelen", "text": "Newton's laws in action. You applied an unbalanced force, and thus, the mass accelerated. You are learning to read the invisible threads that govern our world, Pricxu. But the final lesson will not be against a stationary rock."},
	{"speaker": "Kaelen", "text": "The final lesson is momentum and collision. Prepare your blade, wanderer. Let us see if you can calculate the kinetic energy of a moving target before it strikes you."},
]

const MOMENTUM_INTRO := [
	{"speaker": "Kaelen", "text": "This blade carries momentum. Mass times velocity. You cannot wish it away. You must meet it with an impulse."},
	{"speaker": "Lyra", "text": "Impulse is the change in momentum, Pricxu. A clean parry brings that incoming momentum to rest."},
	{"speaker": "Pricxu", "text": "Then the impulse of my parry has to match the momentum coming at me."},
]

const MOMENTUM_SUCCESS := [
	{"speaker": "Kaelen", "text": "The swing stopped in your guard. Momentum was not destroyed. Your parry changed it."},
	{"speaker": "Pricxu", "text": "Mass, motion, and momentum. The forest finally reads like a page I can turn."},
	{"speaker": "Lyra", "text": "Chapter one is closed. The path ahead will ask for the same honesty with the numbers."},
]

@onready var sky: Sprite2D = $Sky
@onready var mid: Sprite2D = $Mid
@onready var canopy: Sprite2D = $Canopy
@onready var foreground: Sprite2D = $Foreground
@onready var ravine: Polygon2D = $Ravine
@onready var zone: Polygon2D = $Zone
@onready var leaf: Polygon2D = $Leaf
@onready var leaf_left: Polygon2D = $LeafLeft
@onready var leaf_right: Polygon2D = $LeafRight
@onready var trail: Line2D = $Trail
@onready var target: Node2D = $Target
@onready var stone: Node2D = $Stone
@onready var pricxu: Sprite2D = $Pricxu
@onready var kaelen: Sprite2D = $Kaelen
@onready var lyra: Sprite2D = $Lyra
@onready var knife: Polygon2D = $Knife
@onready var vectors: Node2D = $Vectors
@onready var projectile = $ProjectileTrial
@onready var friction = $FrictionTrial
@onready var momentum = $MomentumTrial
@onready var dialogue: Control = $UI/Dialogue
@onready var trial_host: Control = $UI/TrialHost
@onready var equation: Label = $UI/Equation
@onready var title: Label = $UI/Title

const WALK_SPEED := 170.0
const EXPLORE_MARK := 420.0
const APPROACH_RANGE := 110.0

var step := ""
var font: Font
var display_font: Font
var player_control := false
var kaelen_phase := "away"
var approach_hint: Label


func _ready() -> void:
	display_font = _load_display_font()
	font = _load_body_font()
	_dress_forest()
	_dress_props()
	pricxu.load_character("res://assets/characters/dunewind_lancer")
	kaelen.load_character("res://assets/characters/stormsilk_samurai")
	lyra.load_character("res://assets/characters/dawnward_cleric")
	dialogue.apply_fonts(display_font, font)
	dialogue.set_portraits({
		"Pricxu": pricxu.portrait_texture(),
		"Kaelen": kaelen.portrait_texture(),
		"Lyra": lyra.portrait_texture(),
	})
	UiSkin.paint(equation, font, 18, Color("f4e7c8"))
	title.text = "The Kinetic Path\nChapter 1: The Forest of Variables"
	UiSkin.paint(title, display_font, 22, Color("edbd72"))
	equation.add_theme_constant_override("outline_size", 4)
	equation.add_theme_color_override("font_outline_color", Color("101922"))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color("101922"))
	projectile.setup(trial_host, knife, trail, pricxu, equation, font)
	friction.setup(trial_host, stone, vectors, pricxu, equation, font)
	momentum.setup(trial_host, pricxu, kaelen, equation, font)
	dialogue.finished.connect(_on_dialogue_finished)
	projectile.resolved.connect(_on_projectile_resolved)
	friction.resolved.connect(_on_friction_resolved)
	momentum.resolved.connect(_on_momentum_resolved)
	_play_intro()


func _load_display_font() -> Font:
	var loaded := FontFile.new()
	var err := loaded.load_dynamic_font("res://assets/fonts/BoldPixels.ttf")
	if err != OK:
		push_warning("Bold Pixels font failed to load. Using the engine fallback.")
		return ThemeDB.fallback_font
	loaded.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	return loaded


func _load_body_font() -> Font:
	var body := SystemFont.new()
	body.font_names = PackedStringArray(["Georgia", "Palatino Linotype", "Segoe UI"])
	body.font_weight = 400
	body.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	return body


func _dress_forest() -> void:
	_place_layer(sky, "res://assets/forest/Forest-7a05.png")
	_place_layer(mid, "res://assets/forest/Forest-7a0d.png")
	_place_layer(canopy, "res://assets/forest/Forest-7a11.png")
	_place_layer(foreground, "res://assets/forest/Forest-7e8e.png")


func _place_layer(sprite: Sprite2D, path: String) -> void:
	var texture := TextureLoader.load_png(path)
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var factor := 1280.0 / float(texture.get_width())
	sprite.scale = Vector2(factor, factor)
	sprite.position = Vector2(0, 720.0 - texture.get_height() * factor)


func _dress_props() -> void:
	ravine.polygon = PackedVector2Array([
		Vector2(430, GROUND_Y - 8),
		Vector2(700, GROUND_Y - 8),
		Vector2(760, 730),
		Vector2(370, 730),
	])
	ravine.color = Color(0.03, 0.05, 0.045, 0.92)
	ravine.visible = false

	zone.color = Color(0.45, 0.72, 0.48, 0.45)
	zone.visible = false

	leaf.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(16, 5), Vector2(10, 18), Vector2(-4, 14), Vector2(-12, 3),
	])
	leaf.color = Color("6ea84a")
	leaf.visible = false
	leaf_left.polygon = leaf.polygon
	leaf_left.color = Color("6ea84a")
	leaf_left.visible = false
	leaf_right.polygon = PackedVector2Array([
		Vector2(0, 2), Vector2(12, -2), Vector2(8, 12), Vector2(-2, 8),
	])
	leaf_right.color = Color("8fbf62")
	leaf_right.visible = false

	var body := stone.get_node("Body") as Sprite2D
	var rocks := TextureLoader.load_png("res://assets/forest/dark_stone.png")
	body.texture = rocks
	body.centered = true
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var rock_scale := 2.0
	body.scale = Vector2(rock_scale, rock_scale)
	var half := rocks.get_size() * rock_scale * 0.5
	body.position = Vector2(half.x, -half.y)
	stone.position = Vector2(STONE_X, GROUND_Y)
	stone.visible = false

	knife.polygon = PackedVector2Array([
		Vector2(18, 0), Vector2(-6, 5), Vector2(-12, 0), Vector2(-6, -5),
	])
	knife.color = Color("e7ebef")
	knife.visible = false

	trail.width = 3.0
	trail.default_color = Color("edbd72cc")
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND

	target.visible = false
	equation.visible = false
	dialogue.visible = false


func _play_intro() -> void:
	pricxu.position = Vector2(150, GROUND_Y)
	lyra.position = Vector2(70, GROUND_Y)
	kaelen.position = Vector2(1400, GROUND_Y)
	pricxu.face_left(false)
	lyra.face_left(false)
	kaelen.face_left(true)
	pricxu.play("idle")
	lyra.play("idle")
	kaelen.play("idle")
	title.visible = true
	_make_approach_hint()
	player_control = true
	step = "explore"
	var fade := create_tween()
	fade.tween_interval(2.0)
	fade.tween_property(title, "modulate:a", 0.0, 0.5)


func _make_approach_hint() -> void:
	approach_hint = Label.new()
	approach_hint.text = "Walk up to Kaelen"
	approach_hint.visible = false
	approach_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	approach_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	approach_hint.offset_left = -240
	approach_hint.offset_right = 240
	approach_hint.offset_top = -260
	approach_hint.offset_bottom = -220
	approach_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiSkin.paint(approach_hint, font, 18, Color("edbd72"))
	approach_hint.add_theme_constant_override("outline_size", 4)
	approach_hint.add_theme_color_override("font_outline_color", Color("101922"))
	$UI.add_child(approach_hint)


func _process(delta: float) -> void:
	if not player_control or dialogue.visible:
		return
	_move_player(delta)
	if kaelen_phase == "away" and pricxu.position.x >= EXPLORE_MARK:
		kaelen_phase = "entering"
		_kaelen_entrance()
	elif kaelen_phase == "waiting":
		approach_hint.visible = true
		if absf(pricxu.position.x - kaelen.position.x) <= APPROACH_RANGE:
			_begin_encounter()


func _move_player(delta: float) -> void:
	var direction := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction += 1.0
	if direction == 0.0:
		if pricxu.animation_name() == "walk":
			pricxu.play("idle")
		return
	pricxu.face_left(direction < 0.0)
	if pricxu.animation_name() != "walk":
		pricxu.play("walk")
	pricxu.position.x = clampf(pricxu.position.x + direction * WALK_SPEED * delta, 48.0, 1200.0)


func _kaelen_entrance() -> void:
	leaf.position = Vector2(700, 150)
	leaf.visible = true
	var fall := create_tween()
	fall.tween_property(leaf, "position:y", 440.0, 0.72)
	kaelen.face_left(true)
	kaelen.play("run")
	var dash := create_tween()
	dash.tween_property(kaelen, "position:x", 860.0, 0.55)
	await dash.finished
	kaelen.play("attack")
	await get_tree().create_timer(0.26).timeout
	_split_leaf()
	await get_tree().create_timer(0.35).timeout
	kaelen.play("idle")
	kaelen.face_left(true)
	kaelen_phase = "waiting"


func _begin_encounter() -> void:
	player_control = false
	kaelen_phase = "met"
	approach_hint.visible = false
	if pricxu.animation_name() != "idle":
		pricxu.play("idle")
	pricxu.face_left(pricxu.position.x > kaelen.position.x)
	kaelen.face_left(kaelen.position.x > pricxu.position.x)
	step = "encounter"
	dialogue.start(ENCOUNTER)


func _split_leaf() -> void:
	leaf_left.position = leaf.position
	leaf_right.position = leaf.position
	leaf.visible = false
	leaf_left.visible = true
	leaf_right.visible = true
	var split := create_tween()
	split.set_parallel(true)
	split.tween_property(leaf_left, "position", leaf.position + Vector2(-36, 80), 0.7)
	split.tween_property(leaf_right, "position", leaf.position + Vector2(42, 96), 0.7)
	split.tween_property(leaf_left, "rotation", -1.2, 0.7)
	split.tween_property(leaf_right, "rotation", 1.4, 0.7)
	await split.finished
	leaf_left.visible = false
	leaf_right.visible = false


func _on_dialogue_finished() -> void:
	match step:
		"encounter":
			_join_for_projectile()
		"projectile_intro":
			step = "projectile_trial"
			projectile.begin(_throw_origin())
		"projectile_success":
			_stage_stone()
		"friction_intro":
			step = "friction_trial"
			friction.begin()
		"friction_success":
			_stage_duel()
		"momentum_intro":
			step = "momentum_trial"
			momentum.begin()
		"momentum_success":
			step = "done"
			_show_ending()


func _join_for_projectile() -> void:
	await _move_actor(kaelen, 390, 1.15, "walk")
	kaelen.face_left(false)
	kaelen.play("idle")
	var origin := _throw_origin()
	target.position = origin + Vector2(15.0, -5.0) * PX_PER_M
	target.visible = true
	ravine.visible = true
	step = "projectile_intro"
	dialogue.start(PROJECTILE_INTRO)


func _stage_stone() -> void:
	target.visible = false
	ravine.visible = false
	knife.visible = false
	trail.clear_points()
	equation.visible = false
	stone.visible = true
	stone.position = Vector2(STONE_X, GROUND_Y)
	var zone_start := STONE_X + 3.0 * PX_PER_M
	var zone_end := STONE_X + 5.0 * PX_PER_M
	zone.polygon = PackedVector2Array([
		Vector2(zone_start, GROUND_Y - 8),
		Vector2(zone_end, GROUND_Y - 8),
		Vector2(zone_end, GROUND_Y + 10),
		Vector2(zone_start, GROUND_Y + 10),
	])
	zone.visible = true
	pricxu.face_left(false)
	kaelen.face_left(false)
	step = "friction_intro"
	dialogue.start(FRICTION_INTRO)


func _stage_duel() -> void:
	equation.visible = false
	vectors.arrows = []
	vectors.queue_redraw()
	await _move_actor(kaelen, 470, 0.8, "walk")
	kaelen.face_left(true)
	kaelen.play("idle")
	pricxu.face_left(false)
	step = "momentum_intro"
	dialogue.start(MOMENTUM_INTRO)


func _on_projectile_resolved() -> void:
	step = "projectile_success"
	dialogue.start(PROJECTILE_SUCCESS)


func _on_friction_resolved() -> void:
	step = "friction_success"
	dialogue.start(FRICTION_SUCCESS)


func _on_momentum_resolved() -> void:
	step = "momentum_success"
	dialogue.start(MOMENTUM_SUCCESS)


func _show_ending() -> void:
	equation.visible = false
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280
	panel.offset_top = -70
	panel.offset_right = 280
	panel.offset_bottom = 70
	panel.add_theme_stylebox_override("panel", UiSkin.style_panel())
	var label := Label.new()
	label.text = "Chapter 1 complete\nThe Forest of Variables"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiSkin.paint(label, font, 22, Color("edbd72"))
	panel.add_child(label)
	$UI.add_child(panel)


func _throw_origin() -> Vector2:
	return pricxu.position + Vector2(48, -108)


func _move_actor(actor: Sprite2D, x: float, duration: float, anim: String) -> void:
	actor.face_left(x < actor.position.x)
	actor.play(anim)
	var tween := create_tween()
	tween.tween_property(actor, "position:x", x, duration)
	await tween.finished
	if anim == "walk" or anim == "run":
		actor.play("idle")
