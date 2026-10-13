extends Sprite2D

const FRAME_SIZE := 128
const TextureLoader = preload("res://scripts/texture_loader.gd")

var _durations := {}
var _textures := {}
var _anim := "idle"
var _frame := 0
var _time := 0.0
var _playing := false

func load_character(folder: String) -> void:
	var folder_name := folder.get_file()
	var json_text := FileAccess.get_file_as_string("%s/%s.json" % [folder, folder_name])
	var data = JSON.parse_string(json_text)
	if data == null:
		push_error("Could not read sprite data for %s" % folder)
		return

	var groups := {}
	for frame_data in data["frames"]:
		var anim := str(frame_data["animation"])
		if not groups.has(anim):
			groups[anim] = []
		groups[anim].append({
			"index": int(frame_data["index"]),
			"duration": float(frame_data["duration"]) / 1000.0,
		})

	for anim in groups:
		var frames: Array = groups[anim]
		frames.sort_custom(func(a, b): return int(a["index"]) < int(b["index"]))
		var strip_path := "%s/%s_right.png" % [folder, anim]
		if not FileAccess.file_exists(strip_path):
			continue
		var durations := PackedFloat32Array()
		for entry in frames:
			durations.append(float(entry["duration"]))
		_durations[anim] = durations
		_textures[anim] = TextureLoader.load_png(strip_path)

	centered = true
	offset = Vector2(0, -48)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2(2, 2)
	play("idle")


func portrait_texture() -> AtlasTexture:
	var source: Texture2D = _textures["idle"]
	var frame := source.get_image().get_region(Rect2i(0, 0, FRAME_SIZE, FRAME_SIZE))
	var used := frame.get_used_rect()
	var bust_height := maxi(int(round(used.size.y * 0.64)), 1)
	var region := Rect2(used.position.x - 6, used.position.y - 4, used.size.x + 12, bust_height + 6)
	region = region.intersection(Rect2(0, 0, FRAME_SIZE, FRAME_SIZE))
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = region
	return atlas


func play(anim: String) -> void:
	if not _textures.has(anim):
		anim = "idle"
	_anim = anim
	_frame = 0
	_time = 0.0
	_playing = true
	texture = _textures[anim]
	hframes = maxi(1, int(texture.get_width() / float(FRAME_SIZE)))
	vframes = 1
	frame = 0


func face_left(left: bool) -> void:
	flip_h = left


func animation_name() -> String:
	return _anim


func _process(delta: float) -> void:
	if not _playing or not _durations.has(_anim):
		return
	var durations: PackedFloat32Array = _durations[_anim]
	_time += delta
	while _playing and _time >= durations[_frame]:
		_time -= durations[_frame]
		_frame += 1
		if _frame >= durations.size():
			if _anim == "idle" or _anim == "walk" or _anim == "run":
				_frame = 0
			else:
				_frame = durations.size() - 1
				_playing = false
		frame = _frame
