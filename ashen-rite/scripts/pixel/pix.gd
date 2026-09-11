class_name Pix
extends RefCounted

static func image(w: int, h: int, fill: Color = Color(0, 0, 0, 0)) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(fill)
	return img


static func put(img: Image, x: int, y: int, c: Color) -> void:
	if c.a <= 0.0:
		return
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)


static func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in h:
		for xx in w:
			put(img, x + xx, y + yy, c)


static func hline(img: Image, x: int, y: int, w: int, c: Color) -> void:
	rect(img, x, y, w, 1, c)


static func vline(img: Image, x: int, y: int, h: int, c: Color) -> void:
	rect(img, x, y, 1, h, c)


static func dither_fill(img: Image, x: int, y: int, w: int, h: int, a: Color, b: Color) -> void:
	for yy in h:
		for xx in w:
			put(img, x + xx, y + yy, a if ((x + xx + y + yy) & 1) == 0 else b)


static func disc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for yy in range(-r, r + 1):
		for xx in range(-r, r + 1):
			if xx * xx + yy * yy <= r * r:
				put(img, cx + xx, cy + yy, c)


static func capsule(img: Image, x0: int, y0: int, x1: int, y1: int, r: int, c: Color) -> void:
	var dx: float = float(x1 - x0)
	var dy: float = float(y1 - y0)
	var dist: float = sqrt(dx * dx + dy * dy)
	var steps: int = maxi(1, int(dist))
	for i in steps + 1:
		var t: float = float(i) / float(steps)
		var px: int = int(round(lerpf(float(x0), float(x1), t)))
		var py: int = int(round(lerpf(float(y0), float(y1), t)))
		disc(img, px, py, r, c)


static func oval(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	for yy in range(-ry, ry + 1):
		for xx in range(-rx, rx + 1):
			var nx: float = float(xx) / float(maxi(rx, 1))
			var ny: float = float(yy) / float(maxi(ry, 1))
			if nx * nx + ny * ny <= 1.0:
				put(img, cx + xx, cy + yy, c)


static func outline(img: Image, oc: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var marks: Array[Vector2i] = []
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a < 0.5:
				continue
			var edge := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = int(x) + int(d.x)
				var ny: int = int(y) + int(d.y)
				if nx < 0 or ny < 0 or nx >= w or ny >= h or img.get_pixel(nx, ny).a < 0.5:
					edge = true
					break
			if edge:
				marks.append(Vector2i(int(x), int(y)))
	for m in marks:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = m.x + int(d.x)
			var ny: int = m.y + int(d.y)
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			if img.get_pixel(nx, ny).a < 0.5:
				put(img, nx, ny, oc)


static func tex(img: Image) -> ImageTexture:
	var t := ImageTexture.create_from_image(img)
	return t


static func scaled_tex(img: Image, scale: int) -> ImageTexture:
	var big := img.duplicate()
	big.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	return tex(big)


static func sprite(texure: Texture2D, scale: int = 4) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texure
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(scale, scale)
	s.centered = false
	return s
