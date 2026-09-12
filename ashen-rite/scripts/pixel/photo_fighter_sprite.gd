class_name PhotoFighterSprite
extends RefCounted
## Portrait photo -> 128x128 fighting stance pixel sheet for smooth model animation.

const SIZE := 128


static func build_from_photo(photo: Image, def: CharacterDef) -> Image:
	var src := photo.duplicate()
	src.convert(Image.FORMAT_RGBA8)
	_flood_bg(src)
	var bounds := _bounds(src)
	if bounds.size.x < 12 or bounds.size.y < 12:
		return _fallback(def)
	if float(bounds.size.y) / float(bounds.size.x) > 1.05:
		var trim_h: int = int(float(bounds.size.y) * 0.9)
		bounds = Rect2i(bounds.position.x, bounds.position.y, bounds.size.x, trim_h)
	var crop: Image = src.get_region(bounds)
	var canvas := Pix.image(SIZE, SIZE, Color(0, 0, 0, 0))
	var target_w: int = 88
	var target_h: int = clampi(int(round(float(crop.get_height()) / float(crop.get_width()) * float(target_w))), 52, 72)
	crop.resize(target_w, target_h, Image.INTERPOLATE_NEAREST)
	_posterize(crop, 22)
	var ux: int = (SIZE - target_w) / 2
	var uy: int = 4
	for y in target_h:
		for x in target_w:
			var c: Color = crop.get_pixel(x, y)
			if c.a < 0.35:
				continue
			Pix.put(canvas, ux + x, uy + y, c)
	var jeans: Color = Color(0.14, 0.24, 0.44)
	var shoe: Color = Color(0.1, 0.1, 0.12)
	var hem: int = _lowest_row(canvas, ux + 4, ux + target_w - 4)
	var gap: int = 74 - hem
	if gap > 3:
		Pix.rect(canvas, ux + 12, hem, target_w - 24, gap + 2, def.outfit.darkened(0.03))
	var leg_y: int = clampi(hem + gap, 70, 78)
	_stance_legs(canvas, 46, leg_y, 64, leg_y, jeans, shoe)
	Pix.outline(canvas, Color(0.06, 0.05, 0.07, 1))
	return canvas


static func save_baked(def: CharacterDef) -> String:
	var ref := CharacterForge._load_image(def.reference_image)
	if ref == null:
		return ""
	var img := build_from_photo(ref, def)
	var out_path: String = "res://data/characters/refs/%s_model.png" % def.id
	var disk: String = ProjectSettings.globalize_path(out_path)
	img.save_png(disk)
	return out_path


static func _fallback(def: CharacterDef) -> Image:
	var img := Pix.image(SIZE, SIZE, Color(0, 0, 0, 0))
	Pix.oval(img, 64, 24, 10, 12, def.skin)
	Pix.rect(img, 52, 36, 24, 36, def.outfit)
	_stance_legs(img, 46, 74, 64, 74, def.outfit.darkened(0.15), Color(0.1, 0.1, 0.12))
	Pix.outline(img, Color(0.06, 0.05, 0.07))
	return img


static func is_portrait(img: Image) -> bool:
	if img == null:
		return false
	if img.get_width() == SIZE and img.get_height() == SIZE:
		return false
	return float(img.get_height()) >= float(img.get_width()) * 0.85


static func _sample_shirt(crop: Image, fallback: Color) -> Color:
	var acc := Vector3.ZERO
	var n := 0
	for y in int(float(crop.get_height()) * 0.45):
		for x in crop.get_width():
			var c: Color = crop.get_pixel(x, y)
			if c.a < 0.4:
				continue
			var lum: float = c.get_luminance()
			if lum < 0.15 or lum > 0.85:
				continue
			acc += Vector3(c.r, c.g, c.b)
			n += 1
	if n == 0:
		return fallback
	acc /= float(n)
	return Color(acc.x, acc.y, acc.z)


static func _lowest_row(img: Image, x0: int, x1: int) -> int:
	for y in range(img.get_height() - 1, 0, -1):
		for x in range(x0, x1):
			if img.get_pixel(x, y).a > 0.35:
				return y
	return 70


static func _stance_legs(img: Image, lx: int, ly: int, rx: int, ry: int, col: Color, shoe: Color) -> void:
	_limb(img, lx, ly, 104.0, 18.0, 20, 20, 4, col, shoe)
	_limb(img, rx, ry, 76.0, 16.0, 20, 20, 4, col.lightened(0.05), shoe)


static func _flood_bg(img: Image) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var c: Color = img.get_pixel(p.x, p.y)
		if c.a < 0.1:
			continue
		if not _is_bg(c):
			continue
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))


static func _is_bg(c: Color) -> bool:
	if c.a < 0.05:
		return true
	var lum: float = c.get_luminance()
	if lum > 0.82 and c.s < 0.2:
		return true
	if c.s < 0.22 and lum > 0.45 and lum < 0.88:
		return true
	return false


static func _bounds(img: Image) -> Rect2i:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var min_x: int = w
	var min_y: int = h
	var max_x: int = 0
	var max_y: int = 0
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a < 0.35:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x <= min_x:
		return Rect2i(0, 0, 0, 0)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


static func _posterize(img: Image, levels: int) -> void:
	var step: float = 1.0 / float(maxi(levels, 2))
	for y in img.get_height():
		for x in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.a < 0.05:
				continue
			c.r = floor(c.r / step) * step
			c.g = floor(c.g / step) * step
			c.b = floor(c.b / step) * step
			img.set_pixel(x, y, c)


static func _limb(img: Image, hx: int, hy: int, ang: float, bend: float, thigh: int, shin: int, r: int, col: Color, shoe: Color) -> void:
	var a: float = deg_to_rad(ang)
	var kx: int = hx + int(round(cos(a) * float(thigh)))
	var ky: int = hy + int(round(sin(a) * float(thigh)))
	var a2: float = deg_to_rad(ang + bend)
	var ax: int = kx + int(round(cos(a2) * float(shin)))
	var ay: int = ky + int(round(sin(a2) * float(shin)))
	Pix.capsule(img, hx, hy, kx, ky, r, col)
	Pix.capsule(img, kx, ky, ax, ay, maxi(r - 1, 1), col.darkened(0.08))
	Pix.rect(img, ax - 3, ay - 1, 8, 3, shoe)
