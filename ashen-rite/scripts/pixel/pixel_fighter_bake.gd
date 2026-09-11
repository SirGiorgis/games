class_name PixelFighterBake
extends RefCounted
## Limb-rigged pixel fighter. Faces right; flip_h handles facing.
## Chris (style "kit") uses a keyed photo head plus a generic striped kit — no club badge.

const W := 72
const H := 96
const SCALE := 4

static var _face_cache: Dictionary = {}


static func bake(def: CharacterDef) -> Dictionary:
	return {
		"idle": _seq(def, "idle", 6),
		"walk": _seq(def, "walk", 8),
		"run": _seq(def, "run", 8),
		"jump": _seq(def, "jump", 6),
		"crouch": _seq(def, "crouch", 2),
		"light": _seq(def, "light", 6),
		"clight": _seq(def, "clight", 5),
		"jlight": _seq(def, "jlight", 5),
		"heavy": _seq(def, "heavy", 8),
		"cheavy": _seq(def, "cheavy", 6),
		"jheavy": _seq(def, "jheavy", 6),
		"special": _seq(def, "special", 8),
		"ultimate": _seq(def, "ultimate", 8),
		"block": _seq(def, "block", 2),
		"hit": _seq(def, "hit", 4),
		"knockdown": _seq(def, "knockdown", 4),
		"victory": _seq(def, "victory", 6),
		"defeat": _seq(def, "knockdown", 4),
		"grab": _seq(def, "grab", 6),
	}


static func _seq(def: CharacterDef, pose: String, n: int) -> Array:
	var arr: Array = []
	for i in n:
		arr.append(_frame(def, pose, i, n))
	return arr


static func _frame(def: CharacterDef, pose: String, f: int, n: int) -> ImageTexture:
	var img := Pix.image(W, H)
	_paint(img, def, pose, f, n)
	Pix.outline(img, Color(0.07, 0.05, 0.06, 1))
	return Pix.tex(img)


static func _is_kit(def: CharacterDef) -> bool:
	return def.style == "kit" or def.id == "chris_xrisakis"


static func _paint(img: Image, def: CharacterDef, pose: String, f: int, n: int) -> void:
	var p: Dictionary = _rig(pose, f, n)
	var skinny: bool = def.build == "lean" or def.width_scale < 0.92
	var racing: bool = def.style == "racing"
	var kit: bool = _is_kit(def)
	var cx: int = 36 + int(p.xoff)
	var foot: int = 90
	var hip_y: int = foot - (18 if skinny else 17) + int(p.squat) + int(p.bob)
	if pose == "knockdown":
		_downed(img, def, racing, kit, f)
		return

	var pants: Color = Color(0.10, 0.14, 0.32) if kit else (Color(0.12, 0.11, 0.14) if racing else def.outfit.darkened(0.25))
	var shoes: Color = Color(0.08, 0.08, 0.09)
	# football kit is short-sleeve — forearms are skin
	var sleeve: Color = def.skin if kit else (def.outfit if racing else def.skin)
	var lt: int = 2 if skinny else 3
	var ls: int = 2 if skinny else 3
	var at: int = 2 if skinny else 3

	_limb(img, cx - 2, hip_y, float(p.ll_a), float(p.ll_b), 14, 14, lt, ls, pants, shoes, true, kit)
	_arm(img, cx - (4 if skinny else 5), hip_y - 17, float(p.al_a), float(p.al_b), 10, 9, at, sleeve, def.skin)

	_torso(img, def, cx, hip_y, skinny, racing, kit, int(p.lean))
	_limb(img, cx + 2, hip_y, float(p.lr_a), float(p.lr_b), 14, 14, lt, ls, pants.lightened(0.06), shoes, true, kit)
	_arm(img, cx + (4 if skinny else 5) + int(p.lean), hip_y - 17, float(p.ar_a), float(p.ar_b), 10, 10, at, sleeve.lightened(0.06), def.skin)

	if (racing or kit) and pose in ["special", "ultimate"]:
		_smear(img, cx, hip_y, def.accent, f)

	var hx: int = cx - 1 + int(p.lean) + int(p.head_x)
	var hy: int = hip_y - 32 + int(int(p.squat) / 2)
	if kit:
		_kit_head(img, def, hx, hy, pose)
	else:
		_head(img, def, hx, hy, racing, skinny, pose)


static func _rig(pose: String, f: int, n: int) -> Dictionary:
	var u: float = float(f) / float(maxi(n - 1, 1))
	var d := {
		"xoff": 0, "bob": 0, "squat": 0, "lean": 0, "head_x": 0,
		"ll_a": 98.0, "ll_b": 8.0, "lr_a": 82.0, "lr_b": 8.0,
		"al_a": 108.0, "al_b": 18.0, "ar_a": 72.0, "ar_b": 16.0,
	}
	match pose:
		"idle":
			var ph: float = TAU * float(f) / float(n)
			d.bob = int(round(sin(ph) * 1.2))
			d.al_a = 108.0 + sin(ph) * 6.0
			d.ar_a = 72.0 - sin(ph) * 6.0
			d.al_b = 16.0 + sin(ph) * 4.0
		"walk":
			var phw: float = TAU * float(f) / float(n)
			d.bob = int(round(abs(sin(phw)) * 2.0))
			d.ll_a = 90.0 + sin(phw) * 32.0
			d.lr_a = 90.0 + sin(phw + PI) * 32.0
			d.ll_b = 10.0 + maxf(0.0, sin(phw)) * 18.0
			d.lr_b = 10.0 + maxf(0.0, sin(phw + PI)) * 18.0
			d.al_a = 90.0 + sin(phw + PI) * 28.0
			d.ar_a = 90.0 + sin(phw) * 28.0
			d.al_b = 14.0
			d.ar_b = 14.0
			d.lean = int(round(sin(phw) * 1.0))
		"run":
			var phr: float = TAU * float(f) / float(n)
			d.bob = int(round(abs(sin(phr)) * 3.0))
			d.xoff = int(round(sin(phr) * 2.0))
			d.lean = 3
			d.ll_a = 90.0 + sin(phr) * 48.0
			d.lr_a = 90.0 + sin(phr + PI) * 48.0
			d.ll_b = 8.0 + maxf(0.0, sin(phr)) * 28.0
			d.lr_b = 8.0 + maxf(0.0, sin(phr + PI)) * 28.0
			d.al_a = 90.0 + sin(phr + PI) * 50.0
			d.ar_a = 90.0 + sin(phr) * 50.0
			d.al_b = 8.0
			d.ar_b = 8.0
		"jump":
			d.squat = 4 if u < 0.2 else (-2 if u < 0.55 else 1)
			d.ll_a = 70.0 if u < 0.5 else 110.0
			d.lr_a = 110.0 if u < 0.5 else 70.0
			d.ll_b = 28.0
			d.lr_b = 22.0
			d.al_a = 230.0
			d.ar_a = -40.0
			d.al_b = 10.0
			d.ar_b = 10.0
		"crouch":
			d.squat = 14
			d.ll_a = 125.0
			d.lr_a = 55.0
			d.ll_b = 40.0
			d.lr_b = 35.0
			d.al_a = 100.0
			d.ar_a = 80.0
		"block":
			d.squat = 5
			d.lean = 2
			d.al_a = 20.0
			d.ar_a = 10.0
			d.al_b = 70.0
			d.ar_b = 75.0
		"light":
			d.ar_a = lerpf(140.0, 8.0, smoothstep(0.0, 0.55, u))
			d.ar_b = lerpf(20.0, 4.0, smoothstep(0.2, 0.6, u))
			d.al_a = 120.0
			d.lean = int(round(smoothstep(0.3, 0.7, u) * 3.0))
			d.lr_a = 78.0
		"clight":
			d.squat = 12
			d.ar_a = lerpf(100.0, 12.0, smoothstep(0.0, 0.55, u))
			d.ar_b = lerpf(24.0, 6.0, u)
			d.al_a = 110.0
			d.ll_a = 125.0
			d.lr_a = 58.0
			d.ll_b = 38.0
			d.lr_b = 32.0
			d.lean = 2
		"jlight":
			d.squat = -2
			d.ar_a = lerpf(160.0, 10.0, u)
			d.ar_b = 8.0
			d.al_a = 220.0
			d.ll_a = 60.0
			d.lr_a = 120.0
			d.ll_b = 24.0
			d.lr_b = 18.0
		"heavy":
			d.squat = int(round((1.0 - abs(u - 0.45)) * 4.0))
			d.ar_a = lerpf(160.0, -8.0, smoothstep(0.15, 0.62, u))
			d.ar_b = lerpf(30.0, 2.0, smoothstep(0.2, 0.65, u))
			d.al_a = 130.0
			d.lean = int(round(smoothstep(0.25, 0.7, u) * 5.0))
			d.ll_a = 105.0
			d.lr_a = 70.0
		"cheavy":
			d.squat = 13
			d.lean = int(round(smoothstep(0.2, 0.7, u) * 4.0))
			d.ar_a = lerpf(150.0, 8.0, smoothstep(0.1, 0.6, u))
			d.ar_b = lerpf(28.0, 4.0, u)
			d.al_a = 120.0
			d.ll_a = 130.0
			d.lr_a = 40.0
			d.lr_b = 8.0
			d.ll_b = 42.0
		"jheavy":
			d.squat = -1
			d.ar_a = lerpf(180.0, -5.0, u)
			d.ar_b = lerpf(20.0, 2.0, u)
			d.al_a = 200.0
			d.ll_a = 50.0
			d.lr_a = 130.0
			d.lean = 3
		"special":
			d.lean = int(round(u * 8.0))
			d.xoff = int(round(u * 6.0))
			d.ar_a = lerpf(40.0, -10.0, u)
			d.al_a = lerpf(140.0, 200.0, u)
			d.ll_a = 60.0
			d.lr_a = 50.0
			d.ll_b = 8.0
			d.lr_b = 8.0
			d.ar_b = 4.0
		"ultimate":
			d.squat = int(round(sin(u * PI) * -3.0))
			d.ar_a = lerpf(90.0, -20.0, u)
			d.al_a = lerpf(90.0, 210.0, u)
			d.lean = int(round(u * 4.0))
			d.ll_a = 100.0
			d.lr_a = 80.0
		"hit":
			d.xoff = 3 + f
			d.head_x = 2
			d.lean = 4
			d.al_a = 200.0
			d.ar_a = 160.0
			d.ll_a = 70.0
			d.lr_a = 110.0
		"grab":
			d.ar_a = lerpf(40.0, 5.0, u)
			d.ar_b = lerpf(40.0, 10.0, u)
			d.al_a = lerpf(80.0, 25.0, u)
			d.lean = 3
			d.squat = 2
		"victory":
			d.ar_a = lerpf(-70.0, -95.0, 0.5 + 0.5 * sin(float(f)))
			d.al_a = 100.0
			d.bob = int(f % 2)
			d.ll_a = 95.0
			d.lr_a = 85.0
	return d


static func _limb(img: Image, hx: int, hy: int, ang: float, bend: float, thigh: int, shin: int, tr: int, sr: int, col: Color, shoe: Color, with_shoe: bool, kit: bool = false) -> void:
	var a: float = deg_to_rad(ang)
	var kx: int = hx + int(round(cos(a) * float(thigh)))
	var ky: int = hy + int(round(sin(a) * float(thigh)))
	var a2: float = deg_to_rad(ang + bend)
	var ax: int = kx + int(round(cos(a2) * float(shin)))
	var ay: int = ky + int(round(sin(a2) * float(shin)))
	Pix.capsule(img, hx, hy, kx, ky, tr, col)
	Pix.capsule(img, kx, ky, ax, ay, sr, col.darkened(0.08))
	if kit:
		Pix.rect(img, ax - 2, ay - 5, 5, 5, Color(0.93, 0.93, 0.95))
		Pix.hline(img, ax - 2, ay - 5, 5, Color(0.78, 0.16, 0.22))
	if with_shoe:
		Pix.rect(img, ax - 2, ay - 1, 7, 3, shoe)
		Pix.rect(img, ax + 3, ay, 3, 2, shoe.lightened(0.35))


static func _arm(img: Image, sx: int, sy: int, ang: float, bend: float, upper: int, lower: int, r: int, col: Color, hand: Color) -> void:
	var a: float = deg_to_rad(ang)
	var ex: int = sx + int(round(cos(a) * float(upper)))
	var ey: int = sy + int(round(sin(a) * float(upper)))
	var a2: float = deg_to_rad(ang + bend)
	var hx: int = ex + int(round(cos(a2) * float(lower)))
	var hy: int = ey + int(round(sin(a2) * float(lower)))
	Pix.capsule(img, sx, sy, ex, ey, r, col)
	Pix.capsule(img, ex, ey, hx, hy, maxi(r - 1, 1), col.darkened(0.06))
	Pix.disc(img, hx, hy, 2, hand)


static func _torso(img: Image, def: CharacterDef, cx: int, hip_y: int, skinny: bool, racing: bool, kit: bool, lean: int) -> void:
	var tw: int = 12 if kit else (5 if skinny else (9 if def.build == "heavy" else 7))
	var h: int = 22 if kit else 18
	var top: int = hip_y - h
	var tx: int = cx - tw / 2 + lean
	if kit:
		# Generic red / white vertical stripes + blue V-collar. No crest.
		Pix.rect(img, tx, top, tw + 1, h, def.outfit)
		var stripe: int = 0
		while stripe <= tw:
			if int(stripe / 2) % 2 == 1:
				Pix.rect(img, tx + stripe, top + 4, mini(2, tw + 1 - stripe), h - 6, def.trim)
			stripe += 2
		# short sleeves
		Pix.rect(img, tx - 3, top + 3, 4, 6, def.outfit)
		Pix.rect(img, tx + tw, top + 3, 4, 6, def.outfit)
		Pix.rect(img, tx - 2, top + 4, 2, 5, def.trim)
		Pix.rect(img, tx + tw + 1, top + 4, 2, 5, def.trim)
		Pix.rect(img, tx, top, tw + 1, 4, def.accent)
		Pix.put(img, tx + 1, top + 3, def.accent.darkened(0.2))
		Pix.put(img, tx + tw - 1, top + 3, def.accent.darkened(0.2))
		Pix.put(img, cx + lean, top + 2, def.trim)
		Pix.rect(img, tx, top + h - 2, tw + 1, 2, def.outfit.darkened(0.18))
		# thin black necklace
		Pix.put(img, cx + lean - 2, top + 3, Color(0.06, 0.05, 0.05))
		Pix.put(img, cx + lean, top + 5, Color(0.08, 0.07, 0.07))
		Pix.put(img, cx + lean + 2, top + 3, Color(0.06, 0.05, 0.05))
	elif racing:
		Pix.rect(img, tx, top, tw + 1, h, def.outfit)
		Pix.rect(img, tx, top, tw + 1, 4, def.accent.darkened(0.25))
		Pix.vline(img, cx + lean, top + 3, 14, def.accent)
		Pix.vline(img, cx + lean + 2, top + 4, 13, def.trim)
		Pix.rect(img, tx + tw - 1, top + 5, 2, 10, def.trim)
		Pix.put(img, cx + lean, top + 4, Color(0.15, 0.14, 0.12))
		Pix.put(img, cx + lean, top + 5, Color(0.15, 0.14, 0.12))
	else:
		Pix.rect(img, tx, top, tw + 1, h, def.outfit)
		Pix.rect(img, tx + 1, top + 1, tw - 1, 8, def.outfit.lightened(0.08))
		Pix.rect(img, tx + 1, top + 4, tw - 1, 2, def.trim)
	if skinny and not kit:
		Pix.rect(img, tx + 1, hip_y - 6, tw - 1, 6, def.outfit.darkened(0.1))


static func _kit_head(img: Image, def: CharacterDef, cx: int, cy: int, pose: String) -> void:
	var face: Image = _photo_face(def)
	if face != null:
		var fw: int = face.get_width()
		var fh: int = face.get_height()
		var ox: int = cx - fw / 2
		var oy: int = cy - fh / 2 - 2
		if pose == "hit":
			ox += 2
			oy += 1
		for y in fh:
			for x in fw:
				var c: Color = face.get_pixel(x, y)
				if c.a < 0.4:
					continue
				Pix.put(img, ox + x, oy + y, c)
		# neck join under photo chin
		Pix.rect(img, cx - 1, cy + fh / 2 - 2, 3, 4, def.skin.darkened(0.08))
		return
	_head(img, def, cx, cy, true, true, pose)


static func _photo_face(def: CharacterDef) -> Image:
	if _face_cache.has(def.id):
		return _face_cache[def.id]
	if def.reference_image.is_empty():
		_face_cache[def.id] = null
		return null
	var src: Image = CharacterForge._load_image(def.reference_image)
	if src == null:
		_face_cache[def.id] = null
		return null
	var sw: int = src.get_width()
	var sh: int = src.get_height()
	# Tuned for the 960x720 selfie: hair through chin, no chest badge.
	var rx: int = int(round(float(sw) * 0.438))
	var ry: int = int(round(float(sh) * 0.250))
	var rw: int = int(round(float(sw) * 0.229))
	var rh: int = int(round(float(sh) * 0.455))
	rx = clampi(rx, 0, sw - 8)
	ry = clampi(ry, 0, sh - 8)
	rw = clampi(rw, 8, sw - rx)
	rh = clampi(rh, 8, sh - ry)
	var crop := src.get_region(Rect2i(rx, ry, rw, rh))
	crop.convert(Image.FORMAT_RGBA8)
	crop.resize(22, 28, Image.INTERPOLATE_NEAREST)
	var out := Image.create(22, 28, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in 28:
		for x in 22:
			var c: Color = crop.get_pixel(x, y)
			if _is_wall(c):
				continue
			out.set_pixel(x, y, c)
	_flood_key(out)
	_face_cache[def.id] = out
	return out


static func _is_wall(c: Color) -> bool:
	# Mint bedroom wall. Skin is orange-hued; wall is green-cyan.
	if c.a < 0.05:
		return true
	var lum: float = c.get_luminance()
	if lum > 0.78 and c.s < 0.16:
		return true
	var hue: float = c.h
	if hue > 0.22 and hue < 0.58 and lum > 0.38 and c.s < 0.45:
		return true
	# leftover beige wall (desaturated, not skin)
	if c.s < 0.16 and lum > 0.50 and lum < 0.88:
		return true
	return false


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
		if not _is_wall(c):
			continue
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))


static func _head(img: Image, def: CharacterDef, cx: int, cy: int, racing: bool, skinny: bool, pose: String) -> void:
	var skin_dk := def.skin.darkened(0.18)
	var rx: int = 5 if skinny else 6
	var ry: int = 7 if skinny else 6
	Pix.rect(img, cx - 1, cy + 6, 3, 4, def.skin.darkened(0.1))
	Pix.oval(img, cx, cy, rx, ry, def.skin)
	Pix.rect(img, cx - 2, cy + 4, 5, 4, skin_dk)
	Pix.rect(img, cx - rx - 1, cy, 2, 3, def.skin)
	Pix.rect(img, cx + rx, cy, 2, 3, def.skin)
	var brow := def.hair.darkened(0.12)
	Pix.hline(img, cx - 3, cy - 1, 3, brow)
	Pix.hline(img, cx + 1, cy - 1, 3, brow)
	Pix.put(img, cx - 2, cy + 1, Color(0.95, 0.93, 0.9))
	Pix.put(img, cx + 2, cy + 1, Color(0.95, 0.93, 0.9))
	Pix.put(img, cx - 2, cy + 1, def.eyes)
	Pix.put(img, cx + 2, cy + 1, def.eyes)
	Pix.put(img, cx, cy + 2, skin_dk)
	if pose != "hit":
		Pix.hline(img, cx - 1, cy + 5, 3, def.skin.darkened(0.35))
	else:
		Pix.hline(img, cx - 1, cy + 4, 3, Color(0.45, 0.2, 0.2))
	var h1 := def.hair
	var h2 := def.hair.lightened(0.14)
	var h3 := def.hair.darkened(0.18)
	Pix.oval(img, cx, cy - 6, 8 if racing else 6, 5, h1)
	Pix.disc(img, cx - 5, cy - 3, 3, h3)
	Pix.disc(img, cx + 5, cy - 4, 3, h1)
	Pix.disc(img, cx - 4, cy - 7, 2, h2)
	Pix.disc(img, cx + 3, cy - 8, 2, h2)
	Pix.disc(img, cx + 6, cy - 1, 2, h1)
	Pix.disc(img, cx - 6, cy - 1, 2, h1)
	Pix.disc(img, cx - 1, cy - 9, 2, h1)
	Pix.disc(img, cx + 2, cy - 9, 2, h3)
	Pix.disc(img, cx - 3, cy - 5, 2, h2)
	if racing:
		Pix.disc(img, cx + 1, cy - 8, 2, h2)
		Pix.put(img, cx - 7, cy + 1, h1)
		Pix.put(img, cx + 7, cy, h1)
		Pix.disc(img, cx + 4, cy + 1, 2, h1)
	Pix.put(img, cx - 2, cy + 8, Color(0.06, 0.05, 0.05))
	Pix.put(img, cx, cy + 9, Color(0.08, 0.07, 0.07))
	Pix.put(img, cx + 2, cy + 8, Color(0.06, 0.05, 0.05))


static func _smear(img: Image, cx: int, hip_y: int, accent: Color, f: int) -> void:
	for i in 4:
		var y: int = hip_y - 8 - i * 5
		Pix.hline(img, 4, y, 8 + f + i, Color(accent, 0.45))
		Pix.put(img, cx - 12 - i, hip_y - 16 + i, Color(accent, 0.7))


static func _downed(img: Image, def: CharacterDef, racing: bool, kit: bool, f: int) -> void:
	var y: int = 64 + mini(f, 2)
	if kit:
		Pix.capsule(img, 14, y + 6, 36, y + 8, 4, def.outfit)
		Pix.hline(img, 18, y + 6, 14, def.trim)
		Pix.hline(img, 18, y + 8, 14, def.accent)
	else:
		Pix.capsule(img, 12, y + 6, 34, y + 8, 3, def.outfit)
	Pix.oval(img, 42, y + 4, 6, 5, def.skin)
	Pix.oval(img, 44, y + 1, 8, 5, def.hair)
	Pix.capsule(img, 10, y + 8, 18, y + 12, 2, def.outfit.darkened(0.15))
	Pix.capsule(img, 22, y + 9, 30, y + 13, 2, def.outfit.darkened(0.1))
	if racing:
		Pix.hline(img, 20, y + 6, 10, def.accent)
