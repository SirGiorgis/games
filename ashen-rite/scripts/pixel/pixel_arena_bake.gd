class_name PixelArenaBake
extends RefCounted

const W := 320
const H := 180
const SCALE := 4


static func texture(id: String) -> ImageTexture:
	var img := Pix.image(W, H, Color(0.55, 0.76, 0.90))
	match id:
		"neon_street":
			_neon(img)
		"the_pit":
			_pit(img)
		"crimson_keep":
			_keep(img)
		"moonlit_temple":
			_temple(img)
		_:
			_meadow(img)
	if id != "grass_field":
		_floor(img, id)
	return Pix.tex(img)


static func _stars(img: Image, n: int, c: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 17 + 3
	for i in n:
		Pix.put(img, rng.randi_range(0, W - 1), rng.randi_range(4, 70), c)


static func _floor(img: Image, id: String) -> void:
	var y := 148
	var a := Color(0.12, 0.1, 0.12)
	var b := Color(0.08, 0.07, 0.09)
	var line := Color(0.85, 0.72, 0.28)
	if id == "neon_street":
		a = Color(0.1, 0.08, 0.14)
		line = Color(0.2, 0.9, 0.85)
	elif id == "the_pit":
		a = Color(0.14, 0.06, 0.06)
		line = Color(0.7, 0.18, 0.12)
	elif id == "crimson_keep":
		a = Color(0.16, 0.1, 0.1)
		line = Color(0.55, 0.22, 0.18)
	Pix.rect(img, 0, y, W, H - y, a)
	for x in range(0, W, 8):
		Pix.rect(img, x, y + 2, 7, 4, b)
	Pix.hline(img, 0, y, W, line)
	Pix.hline(img, 0, y + 1, W, line.darkened(0.4))


static func _meadow(img: Image) -> void:
	for y in 92:
		var t: float = float(y) / 92.0
		Pix.hline(img, 0, y, W, Color(0.48, 0.72, 0.90).lerp(Color(0.82, 0.90, 0.96), t))
	# Sun + clouds
	Pix.disc(img, 42, 22, 11, Color(0.98, 0.92, 0.55))
	Pix.disc(img, 42, 22, 7, Color(1.0, 0.97, 0.78))
	_cloud(img, 78, 18, 8)
	_cloud(img, 118, 12, 6)
	_cloud(img, 250, 16, 9)
	_cloud(img, 290, 24, 5)
	# Fill ridge so peaks never leave a fake horizon sea
	Pix.rect(img, 0, 78, W, 62, Color(0.34, 0.48, 0.28))
	_peak(img, 200, 112, 52, Color(0.44, 0.52, 0.46), Color(0.90, 0.91, 0.86))
	_peak(img, 128, 114, 40, Color(0.36, 0.48, 0.38), Color(0.62, 0.70, 0.52))
	_peak(img, 252, 116, 32, Color(0.40, 0.52, 0.42), Color(0.72, 0.76, 0.62))
	_peak(img, 72, 118, 24, Color(0.42, 0.54, 0.40), Color(0.68, 0.72, 0.56))
	# Rolling hills
	for x in W:
		var hy: int = 96 + int(sin(float(x) * 0.028) * 9.0) + int(sin(float(x) * 0.11 + 0.6) * 5.0)
		Pix.rect(img, x, hy, 1, maxi(1, 136 - hy), Color(0.32, 0.50, 0.26))
		Pix.put(img, x, hy, Color(0.48, 0.64, 0.34))
	for x in W:
		var hy2: int = 118 + int(sin(float(x) * 0.045 + 1.4) * 6.0) + int(sin(float(x) * 0.19) * 2.0)
		Pix.rect(img, x, hy2, 1, maxi(1, 142 - hy2), Color(0.38, 0.54, 0.24))
	# Tree line
	_tree(img, 8, 126, 10)
	_tree(img, 22, 130, 7)
	_tree(img, 148, 124, 8)
	_tree(img, 164, 128, 11)
	_tree(img, 186, 126, 6)
	_tree(img, 292, 128, 9)
	_tree(img, 308, 132, 7)
	_cottage(img, 30, 116, 18, 12)
	_cottage(img, 54, 114, 16, 11)
	_cottage(img, 78, 118, 15, 10)
	_cottage(img, 210, 116, 20, 12)
	_cottage(img, 236, 120, 14, 9)
	# Pond with lilies
	Pix.oval(img, 276, 130, 24, 7, Color(0.34, 0.56, 0.66))
	Pix.hline(img, 262, 128, 28, Color(0.58, 0.76, 0.84))
	Pix.put(img, 268, 130, Color(0.42, 0.62, 0.32))
	Pix.put(img, 282, 131, Color(0.46, 0.66, 0.34))
	Pix.put(img, 274, 132, Color(0.85, 0.82, 0.40))
	# Grass field — dither, not stripes
	Pix.dither_fill(img, 0, 136, W, H - 136, Color(0.52, 0.64, 0.28), Color(0.44, 0.56, 0.22))
	for y in range(150, H):
		var t2: float = float(y - 150) / 30.0
		var g: Color = Color(0.46, 0.58, 0.24).lerp(Color(0.32, 0.44, 0.16), t2)
		for x in range(0, W, 2):
			Pix.put(img, x + (y & 1), y, g)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2014
	for i in 220:
		var gx: int = rng.randi_range(1, W - 2)
		var gy: int = rng.randi_range(138, 176)
		var tuft: Color = Color(0.26, 0.40, 0.12) if i % 3 == 0 else Color(0.64, 0.74, 0.32)
		Pix.put(img, gx, gy, tuft)
		if i % 4 == 0:
			Pix.put(img, gx, gy - 1, tuft.lightened(0.08))
	# Flowers
	for i in 28:
		var fx: int = rng.randi_range(8, W - 8)
		var fy: int = rng.randi_range(142, 172)
		var bloom: Color = Color(0.92, 0.42, 0.48) if i % 3 == 0 else (Color(0.95, 0.88, 0.35) if i % 3 == 1 else Color(0.90, 0.90, 0.95))
		Pix.put(img, fx, fy - 1, bloom)
		Pix.put(img, fx, fy, Color(0.28, 0.46, 0.16))
	# Dirt fight lane
	for i in 22:
		var dx: int = 40 + i * 11 + rng.randi_range(-2, 2)
		var dy: int = 154 + rng.randi_range(-2, 2)
		Pix.oval(img, dx, dy, 8, 3, Color(0.52, 0.40, 0.22, 0.58))
	# Fence
	for i in 9:
		var px: int = 6 + i * 11
		Pix.rect(img, px, 140, 2, 16, Color(0.42, 0.28, 0.16))
	Pix.hline(img, 6, 144, 98, Color(0.38, 0.26, 0.14))
	Pix.hline(img, 6, 151, 98, Color(0.34, 0.22, 0.12))
	# Rocks
	Pix.rect(img, 118, 160, 6, 4, Color(0.42, 0.40, 0.34))
	Pix.put(img, 119, 160, Color(0.55, 0.52, 0.44))
	Pix.rect(img, 246, 158, 5, 3, Color(0.40, 0.38, 0.32))
	# Distant birds
	Pix.put(img, 160, 28, Color(0.18, 0.16, 0.14, 0.7))
	Pix.put(img, 161, 27, Color(0.18, 0.16, 0.14, 0.7))
	Pix.put(img, 162, 28, Color(0.18, 0.16, 0.14, 0.7))
	Pix.put(img, 188, 22, Color(0.18, 0.16, 0.14, 0.55))
	Pix.put(img, 189, 21, Color(0.18, 0.16, 0.14, 0.55))


static func _cloud(img: Image, cx: int, cy: int, r: int) -> void:
	var puff := Color(0.96, 0.97, 0.98, 0.92)
	var shade := Color(0.86, 0.90, 0.94, 0.75)
	Pix.disc(img, cx, cy, r, puff)
	Pix.disc(img, cx + r, cy + 1, r - 1, puff)
	Pix.disc(img, cx - r + 1, cy + 1, r - 2, puff)
	Pix.disc(img, cx + 2, cy - 2, r - 2, Color(1, 1, 1, 0.85))
	Pix.disc(img, cx + r - 1, cy + 2, r - 2, shade)


static func _peak(img: Image, cx: int, base_y: int, half: int, rock: Color, snow: Color) -> void:
	for y in half:
		var wobble: int = int(sin(float(y) * 0.31) * 5.0) + int(sin(float(y) * 0.17) * 3.0)
		var w: int = int(float(y) / float(maxi(half, 1)) * float(half) * 0.92) + wobble
		w = maxi(1, w)
		var yy: int = base_y - half + y
		var col: Color = snow if y < int(float(half) * 0.16) else rock
		if y > int(float(half) * 0.55):
			col = col.darkened(0.06)
		Pix.hline(img, cx - w, yy, w * 2 + 1, col)
		if y < int(float(half) * 0.16):
			Pix.hline(img, cx - w + 2, yy, maxi(1, w * 2 - 3), snow.lightened(0.08))


static func _tree(img: Image, x: int, y: int, r: int) -> void:
	Pix.rect(img, x - 1, y, 3, 10, Color(0.32, 0.22, 0.12))
	Pix.disc(img, x, y - 2, r, Color(0.20, 0.38, 0.16))
	Pix.disc(img, x - 3, y - 4, maxi(2, r - 3), Color(0.28, 0.48, 0.20))
	Pix.disc(img, x + 3, y - 3, maxi(2, r - 4), Color(0.24, 0.44, 0.18))
	Pix.disc(img, x, y - r + 1, maxi(2, r - 4), Color(0.34, 0.54, 0.24))


static func _cottage(img: Image, x: int, y: int, w: int, h: int) -> void:
	var wall := Color(0.80, 0.76, 0.64)
	var roof := Color(0.50, 0.34, 0.18)
	Pix.rect(img, x + 1, y + 2, w, h, Color(0.22, 0.28, 0.16, 0.35))
	Pix.rect(img, x, y, w, h, wall)
	Pix.rect(img, x + 1, y + 1, w - 2, 2, wall.lightened(0.08))
	for i in int(w / 2) + 2:
		Pix.hline(img, x + i - 2, y - 1 - i, w - i * 2 + 4, roof)
	Pix.rect(img, x + w - 4, y - 6, 2, 5, Color(0.36, 0.24, 0.14))
	Pix.rect(img, x + 3, y + h - 5, 3, 5, Color(0.28, 0.16, 0.10))
	Pix.rect(img, x + w - 7, y + 3, 3, 3, Color(0.35, 0.55, 0.70))
	Pix.put(img, x + w - 6, y + 4, Color(0.85, 0.82, 0.55))


static func _temple(img: Image) -> void:
	for y in 148:
		var t: float = float(y) / 148.0
		Pix.hline(img, 0, y, W, Color(0.04, 0.05, 0.12).lerp(Color(0.10, 0.08, 0.20), t))
	_stars(img, 70, Color(0.78, 0.84, 1.0, 0.85))
	Pix.disc(img, 252, 26, 16, Color(0.82, 0.86, 0.98))
	Pix.disc(img, 247, 24, 11, Color(0.05, 0.06, 0.14))
	Pix.disc(img, 258, 28, 4, Color(0.9, 0.92, 1.0, 0.35))
	for x in W:
		var ridge: int = 58 + int(sin(float(x) * 0.04) * 6.0)
		Pix.put(img, x, ridge, Color(0.16, 0.12, 0.22, 0.8))
	Pix.rect(img, 36, 62, 248, 8, Color(0.28, 0.16, 0.12))
	Pix.rect(img, 40, 58, 240, 5, Color(0.38, 0.22, 0.14))
	for i in 6:
		var x := 22 + i * 50
		Pix.rect(img, x, 70, 16, 78, Color(0.20, 0.14, 0.24))
		Pix.rect(img, x + 2, 74, 5, 12, Color(0.55, 0.72, 0.9, 0.45))
		Pix.rect(img, x + 9, 74, 5, 12, Color(0.55, 0.72, 0.9, 0.3))
		Pix.rect(img, x - 2, 66, 20, 6, Color(0.36, 0.22, 0.16))
		Pix.rect(img, x + 6, 52, 4, 16, Color(0.24, 0.16, 0.18))
	Pix.rect(img, 118, 78, 84, 70, Color(0.18, 0.12, 0.22))
	Pix.rect(img, 130, 90, 18, 28, Color(0.08, 0.06, 0.1))
	Pix.rect(img, 172, 90, 18, 28, Color(0.08, 0.06, 0.1))
	for i in 8:
		Pix.put(img, 40 + i * 30, 50, Color(0.85, 0.75, 0.45, 0.7))


static func _neon(img: Image) -> void:
	for y in 148:
		Pix.hline(img, 0, y, W, Color(0.06, 0.02, 0.10).lerp(Color(0.12, 0.04, 0.16), float(y) / 148.0))
	_stars(img, 22, Color(0.95, 0.4, 0.85, 0.7))
	Pix.rect(img, 0, 118, W, 4, Color(0.2, 0.9, 0.85, 0.35))
	for i in 9:
		var x := 4 + i * 36
		var h := 64 + (i % 4) * 14
		Pix.rect(img, x, 148 - h, 30, h, Color(0.09, 0.07, 0.16))
		Pix.rect(img, x + 1, 148 - h + 2, 28, 3, Color(0.16, 0.12, 0.22))
		var signc := Color(0.15, 0.95, 0.88) if i % 2 == 0 else Color(0.95, 0.22, 0.58)
		Pix.rect(img, x + 4, 148 - h + 8, 22, 7, signc)
		Pix.rect(img, x + 5, 148 - h + 9, 20, 2, signc.lightened(0.25))
		for wy in range(148 - h + 20, 138, 11):
			Pix.rect(img, x + 5, wy, 7, 6, Color(0.95, 0.85, 0.4, 0.55 + 0.2 * float(i % 2)))
			Pix.rect(img, x + 16, wy, 7, 6, Color(0.35, 0.7, 1.0, 0.4))
	Pix.hline(img, 0, 146, W, Color(0.85, 0.25, 0.65, 0.5))


static func _pit(img: Image) -> void:
	Pix.rect(img, 0, 0, W, 148, Color(0.07, 0.03, 0.03))
	for y in 28:
		Pix.hline(img, 0, 16 + y, W, Color(0.18, 0.05, 0.05).lerp(Color(0.07, 0.03, 0.03), float(y) / 28.0))
	for i in 7:
		var x := 12 + i * 46
		Pix.rect(img, x, 48, 10, 100, Color(0.22, 0.08, 0.07))
		Pix.rect(img, x + 2, 56, 6, 8, Color(0.95, 0.38, 0.12))
		Pix.rect(img, x + 3, 58, 4, 4, Color(1.0, 0.75, 0.3))
		for spark in 4:
			Pix.put(img, x + 1 + spark, 52 - spark, Color(1.0, 0.5, 0.15, 0.6))
	Pix.rect(img, 60, 54, 200, 5, Color(0.55, 0.12, 0.1))
	Pix.rect(img, 64, 52, 192, 3, Color(0.7, 0.18, 0.12))
	for i in 18:
		Pix.put(img, 70 + i * 10, 64, Color(0.9, 0.3, 0.12, 0.5))


static func _keep(img: Image) -> void:
	for y in 148:
		Pix.hline(img, 0, y, W, Color(0.10, 0.06, 0.08).lerp(Color(0.18, 0.08, 0.08), float(y) / 180.0))
	Pix.disc(img, 46, 24, 13, Color(0.92, 0.48, 0.28))
	Pix.disc(img, 46, 24, 8, Color(1.0, 0.78, 0.4))
	_stars(img, 28, Color(0.92, 0.72, 0.5, 0.7))
	for i in 5:
		var x := 18 + i * 60
		Pix.rect(img, x, 50, 40, 98, Color(0.22, 0.14, 0.16))
		for by in range(50, 140, 7):
			Pix.hline(img, x, by, 40, Color(0.14, 0.10, 0.12))
		Pix.rect(img, x + 6, 62, 10, 14, Color(0.05, 0.04, 0.05))
		Pix.rect(img, x + 22, 62, 10, 14, Color(0.05, 0.04, 0.05))
		Pix.rect(img, x + 8, 64, 6, 5, Color(0.55, 0.18, 0.12, 0.7))
		Pix.rect(img, x + 14, 42, 10, 12, Color(0.18, 0.12, 0.14))
		Pix.rect(img, x + 16, 36, 6, 8, Color(0.16, 0.1, 0.12))
	Pix.rect(img, 14, 46, 292, 7, Color(0.32, 0.14, 0.14))
	Pix.rect(img, 18, 44, 284, 3, Color(0.45, 0.2, 0.16))
