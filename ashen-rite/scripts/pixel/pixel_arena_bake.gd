class_name PixelArenaBake
extends RefCounted

const W := 320
const H := 180
const SCALE := 4


static func texture(id: String) -> ImageTexture:
	var img := Pix.image(W, H, Color(0.55, 0.78, 0.92))
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
	# Sky
	for y in 78:
		var t: float = float(y) / 78.0
		Pix.hline(img, 0, y, W, Color(0.62, 0.84, 0.94).lerp(Color(0.72, 0.88, 0.96), t))
	# Distant mountain
	Pix.rect(img, 0, 74, W, 28, Color(0.48, 0.62, 0.50))
	_mountain(img, 168, 88, 92, Color(0.42, 0.52, 0.48), Color(0.86, 0.88, 0.84))
	_mountain(img, 96, 92, 58, Color(0.38, 0.50, 0.42), Color(0.70, 0.76, 0.62))
	# Mid hills
	for x in W:
		var hy: int = 100 + int(sin(float(x) * 0.035) * 6.0) + int(sin(float(x) * 0.09) * 3.0)
		Pix.rect(img, x, hy, 1, 148 - hy, Color(0.34, 0.52, 0.28))
		Pix.put(img, x, hy, Color(0.42, 0.60, 0.34))
	# Far cottages
	_cottage(img, 28, 118, 18, 12, Color(0.78, 0.74, 0.62), Color(0.55, 0.38, 0.22))
	_cottage(img, 58, 116, 16, 11, Color(0.74, 0.70, 0.58), Color(0.50, 0.34, 0.20))
	_cottage(img, 92, 120, 14, 10, Color(0.80, 0.76, 0.64), Color(0.48, 0.32, 0.18))
	_cottage(img, 210, 118, 20, 12, Color(0.76, 0.72, 0.60), Color(0.52, 0.36, 0.20))
	# Pond
	Pix.rect(img, 248, 122, 48, 8, Color(0.42, 0.62, 0.72))
	Pix.hline(img, 250, 124, 40, Color(0.55, 0.74, 0.82))
	# Foreground grass bands
	Pix.rect(img, 0, 128, W, 52, Color(0.46, 0.62, 0.28))
	for y in range(128, H):
		var shade: float = float(y - 128) / 52.0
		var g: Color = Color(0.50, 0.66, 0.30).lerp(Color(0.32, 0.48, 0.18), shade)
		if y % 3 == 0:
			g = g.darkened(0.06)
		Pix.hline(img, 0, y, W, g)
	# Dirt patches / fight lane
	for x in range(40, 280, 18):
		var dx: int = x + (x % 7) - 3
		Pix.rect(img, dx, 150, 10, 4, Color(0.42, 0.34, 0.18, 0.55))
	# Grass tufts
	var rng := RandomNumberGenerator.new()
	rng.seed = 2014
	for i in 90:
		var gx: int = rng.randi_range(2, W - 3)
		var gy: int = rng.randi_range(132, 176)
		Pix.put(img, gx, gy, Color(0.28, 0.46, 0.16) if i % 2 == 0 else Color(0.62, 0.78, 0.34))
	# Fence posts
	for i in 6:
		var px: int = 12 + i * 18
		Pix.rect(img, px, 140, 2, 12, Color(0.42, 0.30, 0.18))
	Pix.hline(img, 12, 144, 100, Color(0.38, 0.28, 0.16))


static func _mountain(img: Image, cx: int, base_y: int, half: int, rock: Color, snow: Color) -> void:
	for y in half:
		var w: int = int(float(y) / float(maxi(half, 1)) * float(half))
		Pix.hline(img, cx - w, base_y - half + y, w * 2 + 1, rock if y > 10 else snow)
		if y <= 10:
			Pix.hline(img, cx - w + 2, base_y - half + y, maxi(1, w * 2 - 3), snow.lightened(0.08))


static func _cottage(img: Image, x: int, y: int, w: int, h: int, wall: Color, roof: Color) -> void:
	Pix.rect(img, x, y, w, h, wall)
	for i in w / 2 + 2:
		Pix.hline(img, x + i - 1, y - 1 - i, w - i * 2 + 2, roof)
	Pix.rect(img, x + 2, y + h - 5, 3, 5, Color(0.28, 0.18, 0.12))
	Pix.rect(img, x + w - 6, y + 2, 3, 3, Color(0.35, 0.55, 0.72))


static func _temple(img: Image) -> void:
	Pix.rect(img, 0, 0, W, 148, Color(0.05, 0.06, 0.14))
	Pix.rect(img, 0, 40, W, 40, Color(0.07, 0.08, 0.18))
	_stars(img, 40, Color(0.75, 0.8, 1.0))
	Pix.disc(img, 250, 28, 14, Color(0.78, 0.82, 0.95))
	Pix.disc(img, 246, 26, 10, Color(0.05, 0.06, 0.14))
	for i in 5:
		var x := 18 + i * 62
		Pix.rect(img, x, 70, 14, 78, Color(0.18, 0.14, 0.22))
		Pix.rect(img, x + 2, 74, 4, 10, Color(0.08, 0.07, 0.1))
		Pix.rect(img, x + 8, 74, 4, 10, Color(0.08, 0.07, 0.1))
		Pix.rect(img, x - 2, 66, 18, 6, Color(0.32, 0.2, 0.14))
	Pix.rect(img, 40, 62, 240, 5, Color(0.3, 0.18, 0.12))


static func _neon(img: Image) -> void:
	Pix.rect(img, 0, 0, W, 148, Color(0.07, 0.03, 0.1))
	_stars(img, 18, Color(0.9, 0.4, 0.8))
	for i in 8:
		var x := 6 + i * 40
		var h := 70 + (i % 3) * 16
		Pix.rect(img, x, 148 - h, 28, h, Color(0.1, 0.08, 0.16))
		var signc := Color(0.15, 0.9, 0.85) if i % 2 == 0 else Color(0.95, 0.2, 0.55)
		Pix.rect(img, x + 4, 148 - h + 8, 20, 6, signc)
		for wy in range(148 - h + 18, 140, 10):
			Pix.rect(img, x + 4, wy, 6, 5, Color(0.95, 0.85, 0.4, 0.7))
			Pix.rect(img, x + 16, wy, 6, 5, Color(0.4, 0.7, 1.0, 0.5))


static func _pit(img: Image) -> void:
	Pix.rect(img, 0, 0, W, 148, Color(0.06, 0.03, 0.03))
	Pix.rect(img, 0, 20, W, 24, Color(0.16, 0.05, 0.05))
	for i in 6:
		var x := 16 + i * 52
		Pix.rect(img, x, 50, 8, 98, Color(0.2, 0.08, 0.07))
		Pix.rect(img, x + 2, 58, 4, 6, Color(0.9, 0.35, 0.12))
	Pix.rect(img, 70, 56, 180, 4, Color(0.55, 0.12, 0.1))


static func _keep(img: Image) -> void:
	Pix.rect(img, 0, 0, W, 148, Color(0.08, 0.06, 0.08))
	Pix.disc(img, 48, 26, 11, Color(0.9, 0.5, 0.32))
	_stars(img, 22, Color(0.9, 0.7, 0.5))
	for i in 4:
		var x := 30 + i * 70
		Pix.rect(img, x, 55, 36, 93, Color(0.2, 0.14, 0.16))
		Pix.rect(img, x + 6, 64, 8, 12, Color(0.05, 0.04, 0.05))
		Pix.rect(img, x + 20, 64, 8, 12, Color(0.05, 0.04, 0.05))
		for by in range(55, 140, 6):
			Pix.hline(img, x, by, 36, Color(0.12, 0.09, 0.1))
	Pix.rect(img, 20, 50, 280, 6, Color(0.28, 0.14, 0.14))
