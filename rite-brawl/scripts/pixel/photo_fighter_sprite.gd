class_name PhotoFighterSprite
extends RefCounted
## Portrait photo -> 128x128 limb-rigged pixel fighter (Chris-style layout).

const SIZE := 128

# Must match PixelFighterBake part rects for arm/leg overlays.
const _HEAD := Rect2i(40, 3, 48, 28)
const _TORSO := Rect2i(34, 28, 60, 44)
const _ARM_L := Rect2i(10, 32, 38, 40)
const _ARM_R := Rect2i(84, 30, 38, 42)
const _LEG_L := Rect2i(26, 68, 34, 54)
const _LEG_R := Rect2i(58, 68, 38, 54)


static func build_from_photo(photo: Image, def: CharacterDef) -> Image:
	var src := photo.duplicate()
	src.convert(Image.FORMAT_RGBA8)
	var palette := _sample_palette(src, def)
	var face := _extract_face(src)
	var canvas := Pix.image(SIZE, SIZE, Color(0, 0, 0, 0))
	_paint_legs(canvas, palette)
	_paint_torso(canvas, palette)
	_paint_arm(canvas, _ARM_L, true, palette)
	_paint_arm(canvas, _ARM_R, false, palette)
	_paint_neck(canvas, palette)
	_blit_face(canvas, face, palette)
	_paint_hair(canvas, palette)
	_paint_details(canvas, palette)
	Pix.outline(canvas, Color(0.06, 0.05, 0.07, 1))
	_ground_shadow(canvas)
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


static func is_portrait(img: Image) -> bool:
	if img == null:
		return false
	if img.get_width() == SIZE and img.get_height() == SIZE:
		return false
	return float(img.get_height()) >= float(img.get_width()) * 0.85


static func _sample_palette(src: Image, def: CharacterDef) -> Dictionary:
	_flood_bg(src)
	var bounds := _bounds(src)
	var crop: Image = src
	if bounds.size.x > 8 and bounds.size.y > 8:
		crop = src.get_region(bounds)
	return {
		"skin": _avg_color(crop, 0.08, 0.42, 0.22, 0.72, def.skin),
		"skin_dk": def.skin.darkened(0.16),
		"hair": _avg_color(crop, 0.0, 0.22, 0.18, 0.58, def.hair),
		"shirt": _avg_color(crop, 0.18, 0.72, 0.08, 0.95, def.outfit),
		"shirt_hi": def.outfit.lightened(0.12),
		"shirt_dk": def.outfit.darkened(0.14),
		"trim": def.trim,
		"accent": def.accent,
		"jeans": Color(0.16, 0.26, 0.48),
		"jeans_hi": Color(0.24, 0.36, 0.58),
		"jeans_dk": Color(0.10, 0.16, 0.32),
		"shoe": Color(0.12, 0.12, 0.14),
		"sole": Color(0.86, 0.88, 0.90),
		"silver": Color(0.78, 0.80, 0.84),
		"outline": Color(0.06, 0.05, 0.07),
	}


static func _extract_face(src: Image) -> Image:
	var sw: int = src.get_width()
	var sh: int = src.get_height()
	var rx: int = int(round(float(sw) * 0.28))
	var ry: int = int(round(float(sh) * 0.06))
	var rw: int = int(round(float(sw) * 0.44))
	var rh: int = int(round(float(sh) * 0.30))
	rx = clampi(rx, 0, sw - 8)
	ry = clampi(ry, 0, sh - 8)
	rw = clampi(rw, 8, sw - rx)
	rh = clampi(rh, 8, sh - ry)
	var crop := src.get_region(Rect2i(rx, ry, rw, rh))
	crop.convert(Image.FORMAT_RGBA8)
	crop.resize(26, 30, Image.INTERPOLATE_NEAREST)
	_posterize(crop, 18)
	var out := Pix.image(26, 30, Color(0, 0, 0, 0))
	for y in 30:
		for x in 26:
			var c: Color = crop.get_pixel(x, y)
			if c.a < 0.35 or _is_bg(c):
				continue
			out.set_pixel(x, y, c)
	_flood_key(out)
	return out


static func _paint_neck(img: Image, p: Dictionary) -> void:
	var cx: int = _HEAD.position.x + _HEAD.size.x / 2
	var cy: int = _HEAD.position.y + 18
	Pix.rect(img, cx - 4, cy + 6, 9, 8, p.skin_dk)
	Pix.rect(img, cx - 3, cy + 7, 7, 6, p.skin)


static func _paint_hair(img: Image, p: Dictionary) -> void:
	var r: Rect2i = _HEAD
	var cx: int = r.position.x + r.size.x / 2 + 1
	var cy: int = r.position.y + 14
	Pix.oval(img, cx, cy - 4, 16, 11, p.hair)
	Pix.rect(img, cx - 15, cy - 8, 30, 7, p.hair)
	Pix.rect(img, cx - 14, cy - 2, 5, 9, p.hair.darkened(0.06))
	Pix.rect(img, cx + 10, cy - 1, 4, 7, p.hair.darkened(0.04))
	Pix.hline(img, cx - 6, cy - 1, 5, p.hair.darkened(0.12))
	Pix.hline(img, cx + 2, cy - 1, 5, p.hair.darkened(0.12))
	# Ears + hoop
	Pix.rect(img, cx - 13, cy + 2, 3, 5, p.skin.darkened(0.05))
	Pix.disc(img, cx - 12, cy + 4, 1, p.silver)
	Pix.put(img, cx - 12, cy + 3, p.silver.darkened(0.15))


static func _blit_face(img: Image, face: Image, p: Dictionary) -> void:
	var r: Rect2i = _HEAD
	var cx: int = r.position.x + r.size.x / 2
	var cy: int = r.position.y + 16
	Pix.oval(img, cx, cy + 2, 12, 13, p.skin)
	var ox: int = r.position.x + (r.size.x - face.get_width()) / 2 + 1
	var oy: int = r.position.y + 6
	for y in face.get_height():
		for x in face.get_width():
			var c: Color = face.get_pixel(x, y)
			if c.a < 0.35:
				continue
			var dx: int = ox + x
			var dy: int = oy + y
			if dx < r.position.x + 1 or dx >= r.position.x + r.size.x - 1:
				continue
			if dy < r.position.y + 3 or dy >= r.position.y + r.size.y - 1:
				continue
			Pix.put(img, dx, dy, c)


static func _paint_torso(img: Image, p: Dictionary) -> void:
	var r: Rect2i = _TORSO
	var x0: int = r.position.x
	var y0: int = r.position.y
	# Long-sleeve sweatshirt body + shoulder bridges into arm rects
	Pix.rect(img, x0 + 4, y0 + 8, 52, 30, p.shirt)
	Pix.rect(img, x0 + 8, y0 + 10, 44, 26, p.shirt_hi)
	Pix.rect(img, x0 + 2, y0 + 30, 56, 10, p.shirt_dk)
	Pix.rect(img, x0 - 2, y0 + 12, 8, 14, p.shirt) # left shoulder
	Pix.rect(img, x0 + 54, y0 + 10, 8, 16, p.shirt) # right shoulder
	# Crew neck
	Pix.hline(img, x0 + 22, y0 + 6, 16, p.shirt_dk)
	Pix.rect(img, x0 + 24, y0 + 4, 12, 5, p.skin_dk)
	Pix.hline(img, x0 + 25, y0 + 5, 10, p.skin)
	# Chain
	for i in 4:
		Pix.put(img, x0 + 28 + i, y0 + 7 + (i & 1), p.silver.darkened(0.08))
	# Fold shading
	Pix.vline(img, x0 + 14, y0 + 12, 22, p.shirt_dk)
	Pix.vline(img, x0 + 46, y0 + 14, 20, p.shirt_dk)
	# HoodRich logo (stylized)
	_logo_hoodrich(img, x0 + 16, y0 + 16, p.trim, p.accent)
	Pix.hline(img, x0 + 40, y0 + 12, 8, p.trim.darkened(0.15))
	Pix.put(img, x0 + 41, y0 + 13, p.trim)
	Pix.put(img, x0 + 44, y0 + 13, p.trim)
	Pix.put(img, x0 + 47, y0 + 13, p.trim)


static func _logo_hoodrich(img: Image, x: int, y: int, white: Color, blue: Color) -> void:
	# Chunky cursive-ish "HR" mark readable at 128px
	var pts: Array[Vector2i] = [
		Vector2i(0, 8), Vector2i(2, 4), Vector2i(4, 2), Vector2i(8, 2), Vector2i(10, 5),
		Vector2i(9, 9), Vector2i(6, 11), Vector2i(3, 10), Vector2i(1, 7),
	]
	for pt in pts:
		Pix.disc(img, x + pt.x, y + pt.y, 1, white)
	Pix.hline(img, x + 12, y + 3, 10, white)
	Pix.hline(img, x + 13, y + 6, 9, white)
	Pix.hline(img, x + 14, y + 9, 8, white)
	for i in 5:
		Pix.put(img, x + 11 + i, y + 1 + i, blue.lightened(0.1))


static func _paint_arm(img: Image, r: Rect2i, rear: bool, p: Dictionary) -> void:
	var x0: int = r.position.x
	var y0: int = r.position.y
	if rear:
		# Left / rear guard arm bent near chest
		Pix.capsule(img, x0 + 30, y0 + 6, x0 + 14, y0 + 16, 5, p.shirt)
		Pix.capsule(img, x0 + 14, y0 + 16, x0 + 10, y0 + 28, 4, p.shirt_dk)
		Pix.capsule(img, x0 + 10, y0 + 28, x0 + 16, y0 + 35, 3, p.skin)
		Pix.disc(img, x0 + 18, y0 + 33, 4, p.skin)
		Pix.disc(img, x0 + 19, y0 + 32, 3, p.skin.darkened(0.08))
	else:
		# Right / lead arm extended guard
		Pix.capsule(img, x0 + 4, y0 + 8, x0 + 16, y0 + 14, 5, p.shirt)
		Pix.capsule(img, x0 + 16, y0 + 14, x0 + 26, y0 + 22, 4, p.shirt_hi)
		Pix.capsule(img, x0 + 26, y0 + 22, x0 + 31, y0 + 32, 3, p.skin)
		Pix.disc(img, x0 + 32, y0 + 33, 4, p.skin)
		Pix.disc(img, x0 + 33, y0 + 32, 3, p.skin.darkened(0.06))


static func _paint_legs(img: Image, p: Dictionary) -> void:
	_paint_leg(img, _LEG_L, true, p)
	_paint_leg(img, _LEG_R, false, p)


static func _paint_leg(img: Image, r: Rect2i, forward: bool, p: Dictionary) -> void:
	var x0: int = r.position.x
	var y0: int = r.position.y
	var col: Color = p.jeans if forward else p.jeans_hi
	var dk: Color = p.jeans_dk
	if forward:
		Pix.capsule(img, x0 + 16, y0 + 4, x0 + 12, y0 + 24, 5, col)
		Pix.capsule(img, x0 + 12, y0 + 24, x0 + 18, y0 + 42, 4, dk)
		Pix.rect(img, x0 + 10, y0 + 42, 14, 8, col.darkened(0.05))
		Pix.rect(img, x0 + 8, y0 + 48, 18, 4, p.shoe)
		Pix.hline(img, x0 + 7, y0 + 50, 20, p.sole)
	else:
		Pix.capsule(img, x0 + 18, y0 + 6, x0 + 22, y0 + 26, 5, col)
		Pix.capsule(img, x0 + 22, y0 + 26, x0 + 16, y0 + 44, 4, dk)
		Pix.rect(img, x0 + 12, y0 + 44, 14, 8, col.darkened(0.04))
		Pix.rect(img, x0 + 10, y0 + 50, 18, 4, p.shoe)
		Pix.hline(img, x0 + 9, y0 + 52, 20, p.sole)


static func _paint_details(img: Image, p: Dictionary) -> void:
	# Belt line hint
	Pix.hline(img, 40, 68, 48, p.jeans_dk.darkened(0.08))
	# Wrist bands / cuff highlights
	Pix.hline(img, 18, 66, 6, p.shirt_dk)
	Pix.hline(img, 96, 62, 6, p.shirt_dk)


static func _ground_shadow(img: Image) -> void:
	for x in range(34, 94):
		var t: float = absf(float(x - 64)) / 30.0
		var a: float = clampf(0.28 - t * 0.22, 0.04, 0.28)
		for y in range(122, 126):
			var c: Color = Color(0, 0, 0, a)
			if img.get_pixel(x, y).a < 0.2:
				Pix.put(img, x, y, c)


static func _avg_color(crop: Image, y0f: float, y1f: float, lum_min: float, lum_max: float, fallback: Color) -> Color:
	var acc := Vector3.ZERO
	var n := 0
	var h: int = crop.get_height()
	var w: int = crop.get_width()
	var y0: int = int(float(h) * y0f)
	var y1: int = int(float(h) * y1f)
	for y in range(y0, y1):
		for x in w:
			var c: Color = crop.get_pixel(x, y)
			if c.a < 0.4:
				continue
			var lum: float = c.get_luminance()
			if lum < lum_min or lum > lum_max:
				continue
			acc += Vector3(c.r, c.g, c.b)
			n += 1
	if n == 0:
		return fallback
	acc /= float(n)
	return Color(acc.x, acc.y, acc.z)


static func _fallback(def: CharacterDef) -> Image:
	return build_from_photo(Pix.image(64, 96, def.skin), def)


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


static func _flood_key(img: Image) -> void:
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
