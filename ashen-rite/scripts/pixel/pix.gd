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


static func round_rect(img: Image, x: int, y: int, w: int, h: int, r: int, c: Color) -> void:
	var rr: int = mini(r, mini(w, h) / 2)
	rect(img, x + rr, y, w - rr * 2, h, c)
	rect(img, x, y + rr, w, h - rr * 2, c)
	disc(img, x + rr, y + rr, rr, c)
	disc(img, x + w - 1 - rr, y + rr, rr, c)
	disc(img, x + rr, y + h - 1 - rr, rr, c)
	disc(img, x + w - 1 - rr, y + h - 1 - rr, rr, c)


static func star(img: Image, cx: int, cy: int, on: bool) -> void:
	var a: Color = Color(0.98, 0.82, 0.18) if on else Color(0.16, 0.16, 0.16)
	var b: Color = Color(1.0, 0.95, 0.55) if on else Color(0.10, 0.10, 0.10)
	put(img, cx, cy - 3, a)
	put(img, cx, cy - 2, a)
	hline(img, cx - 1, cy - 1, 3, a)
	hline(img, cx - 3, cy, 7, a)
	hline(img, cx - 1, cy + 1, 3, a)
	put(img, cx - 2, cy + 2, a)
	put(img, cx + 2, cy + 2, a)
	put(img, cx - 3, cy + 3, a)
	put(img, cx + 3, cy + 3, a)
	put(img, cx, cy, b)


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


static func car(color: Color = Color(0.78, 0.08, 0.10)) -> Image:
	# Original open-wheel racer. Rosso body, yellow CX roundel. No team badges.
	var img := image(26, 12, Color(0, 0, 0, 0))
	var body: Color = Color(0.78, 0.08, 0.10) if color.r > 0.4 else color
	var body_hi: Color = body.lightened(0.16)
	var body_dk: Color = body.darkened(0.22)
	var wing: Color = Color(0.12, 0.11, 0.12)
	var yellow := Color(0.96, 0.78, 0.12)
	var tire := Color(0.08, 0.08, 0.09)
	var rim := Color(0.62, 0.62, 0.66)
	rect(img, 1, 1, 5, 2, wing)
	vline(img, 3, 3, 3, wing)
	rect(img, 18, 4, 7, 2, body)
	rect(img, 21, 3, 4, 1, yellow)
	rect(img, 20, 6, 6, 1, wing)
	hline(img, 19, 7, 7, wing)
	rect(img, 5, 3, 16, 4, body)
	rect(img, 7, 2, 11, 2, body_hi)
	rect(img, 6, 6, 13, 1, body_dk)
	rect(img, 10, 1, 6, 3, Color(0.18, 0.22, 0.28))
	rect(img, 11, 1, 4, 2, Color(0.55, 0.72, 0.88))
	put(img, 12, 2, Color(0.85, 0.92, 1.0))
	disc(img, 16, 5, 2, yellow)
	put(img, 15, 4, Color(0.12, 0.10, 0.10))
	put(img, 16, 5, Color(0.12, 0.10, 0.10))
	put(img, 17, 4, Color(0.12, 0.10, 0.10))
	put(img, 17, 6, Color(0.12, 0.10, 0.10))
	rect(img, 4, 7, 4, 4, tire)
	rect(img, 5, 8, 2, 2, rim)
	rect(img, 18, 7, 4, 4, tire)
	rect(img, 19, 8, 2, 2, rim)
	outline(img, Color(0.05, 0.04, 0.06))
	return img


static func cotton() -> Image:
	var img := image(12, 10, Color(0, 0, 0, 0))
	var fluff := Color(0.96, 0.94, 0.88)
	var fluff_hi := Color(1.0, 0.99, 0.96)
	var fluff_dk := Color(0.82, 0.78, 0.70)
	var stem := Color(0.42, 0.32, 0.18)
	disc(img, 6, 4, 3, fluff)
	disc(img, 4, 5, 2, fluff_dk)
	disc(img, 8, 5, 2, fluff_hi)
	disc(img, 6, 6, 2, fluff)
	put(img, 5, 3, Color(1, 1, 1, 0.9))
	put(img, 7, 4, fluff_hi)
	rect(img, 5, 8, 2, 2, stem)
	put(img, 6, 7, stem.lightened(0.15))
	outline(img, Color(0.18, 0.14, 0.10, 0.55))
	return img


static func gas(color: Color = Color(0.48, 0.78, 0.32)) -> Image:
	var img := image(18, 14, Color(0, 0, 0, 0))
	var g1: Color = color
	var g2: Color = Color(0.58, 0.62, 0.22)
	disc(img, 8, 7, 6, Color(g1, 0.72))
	disc(img, 5, 6, 4, Color(g2, 0.55))
	disc(img, 12, 8, 4, Color(g1.lightened(0.12), 0.6))
	disc(img, 9, 4, 3, Color(0.72, 0.88, 0.40, 0.5))
	put(img, 8, 7, Color(0.85, 0.95, 0.55, 0.7))
	return img


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
