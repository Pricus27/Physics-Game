extends RefCounted

static func load_png(path: String) -> ImageTexture:
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		push_error("Could not load image %s (error %s)" % [path, err])
		return null
	var texture := ImageTexture.create_from_image(image)
	return texture
