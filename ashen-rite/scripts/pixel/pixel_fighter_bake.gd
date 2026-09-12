class_name PixelFighterBake
extends RefCounted
## Limb-rigged pixel fighter. Faces right; flip_h handles facing.
## Chris (style "kit") uses a keyed photo head plus a generic striped kit — no club badge.

const W := 72
const H := 96
const SCALE := 4
const MODEL_W := 160
const MODEL_H := 160
const MODEL_SCALE := 3
const _UPPER := Rect2i(18, 2, 96, 70)
const _LEG_L := Rect2i(24, 68, 36, 54)
const _LEG_R := Rect2i(56, 68, 42, 54)

static var _face_cache: Dictionary = {}
static var _model_cache: Dictionary = {}


static func bake(def: CharacterDef) -> Dictionary:
	return {
		"idle": _seq(def, "idle", 12),
		"walk": _seq(def, "walk", 16),
		"run": _seq(def, "run", 12),
		"backdash": _seq(def, "backdash", 8),
		"prejump": _seq(def, "prejump", 4),
		"jump": _seq(def, "jump", 10),
		"land": _seq(def, "land", 6),
		"getup": _seq(def, "getup", 8),
		"crouch": _seq(def, "crouch", 4),
		"light": _seq(def, "light", 10),
		"clight": _seq(def, "clight", 8),
		"jlight": _seq(def, "jlight", 8),
		"heavy": _seq(def, "heavy", 14),
		"cheavy": _seq(def, "cheavy", 10),
		"jheavy": _seq(def, "jheavy", 10),
		"special": _seq(def, "special", 12),
		"ultimate": _seq(def, "ultimate", 14),
		"block": _seq(def, "block", 6),
		"block_hit": _seq(def, "block_hit", 4),
		"hit": _seq(def, "hit", 8),
		"air_hit": _seq(def, "air_hit", 6),
		"launch": _seq(def, "launch", 8),
		"knockdown": _seq(def, "knockdown", 10),
		"victory": _seq(def, "victory", 12),
		"defeat": _seq(def, "defeat", 8),
		"grab": _seq(def, "grab", 10),
	}


static func _seq(def: CharacterDef, pose: String, n: int) -> Array:
	var arr: Array = []
	for i in n:
		arr.append(_frame(def, pose, i, n))
	return arr


static func _frame(def: CharacterDef, pose: String, f: int, n: int) -> ImageTexture:
	if _is_model(def):
		var canvas := Pix.image(MODEL_W, MODEL_H)
		_paint_model(canvas, def, pose, f, n)
		return Pix.tex(canvas)
	var img := Pix.image(W, H)
	_paint(img, def, pose, f, n)
	Pix.outline(img, Color(0.07, 0.05, 0.06, 1))
	return Pix.tex(img)


static func _is_kit(def: CharacterDef) -> bool:
	return def.style == "kit"


static func _is_model(def: CharacterDef) -> bool:
	return def.style == "model" or def.id == "chris_xrisakis"


static func _paint_model(img: Image, def: CharacterDef, pose: String, f: int, n: int) -> void:
	var sheet: Image = _model_sheet(def)
	if sheet == null:
		_paint(img, def, pose, f, n)
		Pix.outline(img, Color(0.07, 0.05, 0.06, 1))
		return
	var u: float = float(f) / float(maxi(n - 1, 1))
	var ph: float = TAU * float(f) / float(n)
	var p: Dictionary = _pose_sample(pose, u, ph, f)
	var pad_x: int = (img.get_width() - 128) / 2
	var pad_y: int = img.get_height() - 128 - 2
	var bob: int = int(p.bob) + int(p.squat)
	var lean: float = float(p.lean)
	var xoff: int = int(p.xoff)

	if pose in ["knockdown", "defeat"]:
		var fall_u: float = clampf(u, 0.0, 1.0)
		if fall_u < 0.42:
			var stagger: float = fall_u / 0.42
			_blit_rot_part(img, sheet, _LEG_L, pad_x + 30 + xoff, pad_y + 68, -18.0 - stagger * 20.0, 18, 6)
			_blit_rot_part(img, sheet, _LEG_R, pad_x + 54 + xoff, pad_y + 68, 14.0 + stagger * 16.0, 20, 6)
			_blit_rot_part(img, sheet, _UPPER, pad_x + 24 + xoff + int(stagger * 8.0), pad_y + 6 + int(stagger * 6.0), 8.0 + stagger * 24.0, 48, 66)
		else:
			var laid := sheet.duplicate()
			laid.rotate_90(ClockDirection.CLOCKWISE)
			_blit_sheet(img, laid, xoff - 10, pad_y + 12 + int((fall_u - 0.42) * 24.0))
		return

	var leg_amp: float = 18.0
	if pose == "run":
		leg_amp = 28.0
	elif pose == "walk":
		leg_amp = 20.0
	elif pose == "backdash":
		leg_amp = 14.0

	var ll_rot: float = (float(p.ll_a) - 90.0) * 0.55 + sin(ph) * leg_amp * 0.35
	var lr_rot: float = (float(p.lr_a) - 90.0) * 0.55 - sin(ph) * leg_amp * 0.35
	if pose in ["walk", "run", "backdash"]:
		ll_rot = sin(ph) * leg_amp
		lr_rot = sin(ph + PI) * leg_amp

	var hip_y: int = pad_y + 68 + bob
	var ux: int = pad_x + 18 + xoff + int(lean)
	var uy: int = pad_y + 2 + bob - int(maxf(0.0, -float(p.squat)) * 0.4)

	_blit_rot_part(img, sheet, _LEG_L, pad_x + 24 + xoff, hip_y, ll_rot + float(p.ll_b) * 0.25, 18, 6)
	_blit_rot_part(img, sheet, _LEG_R, pad_x + 56 + xoff, hip_y, lr_rot - float(p.lr_b) * 0.25, 20, 6)
	var upper_rot: float = -lean * 1.4 - (float(p.ar_a) - 70.0) * 0.08
	_blit_rot_part(img, sheet, _UPPER, ux, uy, upper_rot, 48, 66)

	if pose in ["special", "ultimate"]:
		_smear(img, img.get_width() / 2 + xoff, img.get_height() - 48, def.accent, f)
	if pose in ["light", "heavy", "clight", "cheavy", "jlight", "jheavy"] and u > 0.22 and u < 0.58:
		_smear(img, ux + 40, uy + 30, def.trim, f)


static func _scale_img(src: Image, sx: float, sy: float) -> Image:
	var nw: int = maxi(1, int(round(float(src.get_width()) * sx)))
	var nh: int = maxi(1, int(round(float(src.get_height()) * sy)))
	var out := src.duplicate()
	out.resize(nw, nh, Image.INTERPOLATE_NEAREST)
	return out


static func _blit_part(dst: Image, sheet: Image, r: Rect2i, dx: int, dy: int) -> void:
	_blit_rot_part(dst, sheet, r, dx, dy, 0.0, r.size.x / 2, 2)


static func _blit_rot_part(dst: Image, sheet: Image, r: Rect2i, dx: int, dy: int, deg: float, px: int, py: int) -> void:
	var rad: float = deg_to_rad(deg)
	var cs: float = cos(rad)
	var sn: float = sin(rad)
	var rw: int = r.size.x
	var rh: int = r.size.y
	# inverse-map a padded dest box so rotated pixels land
	var pad: int = 8
	for oy in range(-pad, rh + pad):
		for ox in range(-pad, rw + pad):
			var lx: float = float(ox - px)
			var ly: float = float(oy - py)
			var sx: int = int(round(float(px) + lx * cs + ly * sn))
			var sy: int = int(round(float(py) - lx * sn + ly * cs))
			if sx < 0 or sy < 0 or sx >= rw or sy >= rh:
				continue
			var c: Color = sheet.get_pixel(r.position.x + sx, r.position.y + sy)
			if c.a < 0.4:
				continue
			Pix.put(dst, dx + ox, dy + oy, c)


static func _blit_sheet(dst: Image, src: Image, xoff: int, yoff: int) -> void:
	var dw: int = dst.get_width()
	var dh: int = dst.get_height()
	var sw: int = src.get_width()
	var sh: int = src.get_height()
	var ox: int = (dw - sw) / 2 + xoff
	var oy: int = dh - sh - 2 + yoff
	for y in sh:
		for x in sw:
			var c: Color = src.get_pixel(x, y)
			if c.a < 0.4:
				continue
			Pix.put(dst, ox + x, oy + y, c)


static func _model_sheet(def: CharacterDef) -> Image:
	if _model_cache.has(def.id):
		return _model_cache[def.id]
	var path: String = def.reference_image
	if path.is_empty():
		path = "res://data/characters/refs/chris_model.png"
	var src: Image = CharacterForge._load_image(path)
	if src == null:
		_model_cache[def.id] = null
		return null
	src.convert(Image.FORMAT_RGBA8)
	for y in src.get_height():
		for x in src.get_width():
			var c: Color = src.get_pixel(x, y)
			if _is_model_bg(c):
				src.set_pixel(x, y, Color(0, 0, 0, 0))
	# Keep 128x128 so part rects stay aligned to the uploaded sprite.
	if src.get_width() != 128 or src.get_height() != 128:
		var canvas := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0, 0, 0, 0))
		canvas.blit_rect(src, Rect2i(0, 0, mini(128, src.get_width()), mini(128, src.get_height())), Vector2i.ZERO)
		src = canvas
	_model_cache[def.id] = src
	return src


static func _is_model_bg(c: Color) -> bool:
	if c.a < 0.08:
		return true
	var lum: float = c.get_luminance()
	# flat gray studio backdrop on the uploaded sprite
	if c.s < 0.08 and lum > 0.36 and lum < 0.68:
		return true
	return false


static func _paint(img: Image, def: CharacterDef, pose: String, f: int, n: int) -> void:
	var p: Dictionary = _rig(pose, f, n)
	var skinny: bool = def.build == "lean" or def.width_scale < 0.92
	var racing: bool = def.style == "racing"
	var kit: bool = _is_kit(def)
	var cx: int = 36 + int(p.xoff)
	var foot: int = 90
	var hip_y: int = foot - (18 if skinny else 17) + int(p.squat) + int(p.bob)
	if pose in ["knockdown", "defeat"]:
		_downed(img, def, racing, kit, f, n, pose)
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
	var ph: float = TAU * float(f) / float(n)
	return _pose_sample(pose, u, ph, f)


static func _ease_out_back(t: float) -> float:
	var s: float = 1.70158
	return 1.0 + (s + 1.0) * pow(t - 1.0, 3.0) + s * pow(t - 1.0, 2.0)


static func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)


static func _ease_in_cubic(t: float) -> float:
	var x: float = clampf(t, 0.0, 1.0)
	return x * x * x


static func _ease_in_out(t: float) -> float:
	return smoothstep(0.0, 1.0, clampf(t, 0.0, 1.0))


static func _attack_phase(u: float, wind: float, strike: float) -> float:
	if u < wind:
		return _ease_out_cubic(u / maxf(wind, 0.001)) * 0.38
	var su: float = (u - wind) / maxf(strike, 0.001)
	if u < wind + strike:
		return lerpf(0.38, 0.72, _ease_in_out(su))
	return lerpf(0.72, 1.0, _ease_in_cubic((u - wind - strike) / maxf(1.0 - wind - strike, 0.001)))


static func _kf(keys: Array, u: float) -> float:
	if keys.is_empty():
		return 0.0
	if u <= float(keys[0][0]):
		return float(keys[0][1])
	for i in keys.size() - 1:
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if u >= float(a[0]) and u <= float(b[0]):
			var t: float = (u - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.001)
			return lerpf(float(a[1]), float(b[1]), _ease_in_out(t))
	return float(keys[-1][1])


static func _pose_sample(pose: String, u: float, ph: float, f: int) -> Dictionary:
	var d := {
		"xoff": 0, "bob": 0, "squat": 0, "lean": 0, "head_x": 0,
		"ll_a": 98.0, "ll_b": 8.0, "lr_a": 82.0, "lr_b": 8.0,
		"al_a": 108.0, "al_b": 18.0, "ar_a": 72.0, "ar_b": 16.0,
	}
	match pose:
		"idle":
			d.bob = int(round(sin(ph) * 1.8 + sin(ph * 2.0) * 0.4))
			d.head_x = int(round(sin(ph * 0.5) * 1.0))
			d.al_a = 108.0 + sin(ph) * 8.0
			d.ar_a = 72.0 - sin(ph) * 8.0
			d.al_b = 16.0 + sin(ph + 0.4) * 5.0
			d.ar_b = 16.0 - sin(ph + 0.4) * 4.0
			d.ll_a = 96.0 + sin(ph * 0.5) * 4.0
			d.lr_a = 84.0 - sin(ph * 0.5) * 4.0
		"walk":
			var s: float = sin(ph)
			var c: float = cos(ph)
			d.bob = int(round(abs(s) * 3.0))
			d.lean = int(round(s * 2.0))
			d.head_x = int(round(-s * 1.5))
			d.ll_a = 92.0 + s * 38.0
			d.lr_a = 92.0 - s * 38.0
			d.ll_b = 8.0 + maxf(0.0, s) * 22.0
			d.lr_b = 8.0 + maxf(0.0, -s) * 22.0
			d.al_a = 92.0 - s * 32.0
			d.ar_a = 92.0 + s * 32.0
			d.al_b = 12.0 + abs(c) * 4.0
			d.ar_b = 12.0 + abs(c) * 4.0
		"run":
			var rs: float = sin(ph)
			d.bob = int(round(abs(rs) * 4.0))
			d.xoff = int(round(rs * 3.0))
			d.lean = 5
			d.ll_a = 88.0 + rs * 54.0
			d.lr_a = 88.0 - rs * 54.0
			d.ll_b = 6.0 + maxf(0.0, rs) * 32.0
			d.lr_b = 6.0 + maxf(0.0, -rs) * 32.0
			d.al_a = 86.0 - rs * 58.0
			d.ar_a = 86.0 + rs * 58.0
			d.al_b = 6.0
			d.ar_b = 6.0
		"backdash":
			var dash: float = sin(ph * 2.0)
			d.lean = -4
			d.xoff = int(round(-6.0 - abs(dash) * 2.0))
			d.bob = int(round(abs(dash) * 2.0))
			d.ll_a = 108.0 + dash * 18.0
			d.lr_a = 72.0 - dash * 14.0
			d.ll_b = 18.0
			d.lr_b = 12.0
			d.al_a = 130.0
			d.ar_a = 40.0
			d.al_b = 24.0
			d.ar_b = 30.0
		"prejump":
			d.squat = int(round(_kf([[0.0, 0.0], [0.5, 16.0], [1.0, 8.0]], u)))
			d.ll_a = _kf([[0.0, 98.0], [0.5, 118.0], [1.0, 90.0]], u)
			d.lr_a = _kf([[0.0, 82.0], [0.5, 62.0], [1.0, 92.0]], u)
			d.ll_b = _kf([[0.0, 8.0], [0.5, 34.0], [1.0, 12.0]], u)
			d.lr_b = _kf([[0.0, 8.0], [0.5, 28.0], [1.0, 10.0]], u)
			d.al_a = 120.0
			d.ar_a = 60.0
		"jump":
			d.squat = int(round(_kf([[0.0, 6.0], [0.12, 10.0], [0.28, -4.0], [0.55, -6.0], [0.82, 2.0], [1.0, 5.0]], u)))
			d.ll_a = _kf([[0.0, 118.0], [0.18, 62.0], [0.45, 48.0], [0.72, 88.0], [1.0, 104.0]], u)
			d.lr_a = _kf([[0.0, 62.0], [0.18, 118.0], [0.45, 132.0], [0.72, 96.0], [1.0, 78.0]], u)
			d.ll_b = _kf([[0.0, 34.0], [0.25, 18.0], [0.55, 8.0], [1.0, 24.0]], u)
			d.lr_b = _kf([[0.0, 18.0], [0.25, 8.0], [0.55, 22.0], [1.0, 16.0]], u)
			d.al_a = _kf([[0.0, 130.0], [0.2, 220.0], [0.55, 240.0], [1.0, 110.0]], u)
			d.ar_a = _kf([[0.0, 50.0], [0.2, -30.0], [0.55, -50.0], [1.0, 70.0]], u)
			d.al_b = 8.0
			d.ar_b = 8.0
		"land":
			d.squat = int(round(_kf([[0.0, 12.0], [0.35, 18.0], [0.65, 6.0], [1.0, 0.0]], u)))
			d.bob = int(round(_kf([[0.0, 4.0], [0.35, 6.0], [1.0, 0.0]], u)))
			d.ll_a = _kf([[0.0, 118.0], [0.4, 108.0], [1.0, 98.0]], u)
			d.lr_a = _kf([[0.0, 68.0], [0.4, 78.0], [1.0, 82.0]], u)
			d.ll_b = _kf([[0.0, 36.0], [0.5, 16.0], [1.0, 8.0]], u)
			d.lr_b = _kf([[0.0, 24.0], [0.5, 12.0], [1.0, 8.0]], u)
			d.al_a = 115.0
			d.ar_a = 68.0
		"getup":
			d.squat = int(round(_kf([[0.0, 16.0], [0.45, 10.0], [1.0, 0.0]], u)))
			d.lean = int(round(_kf([[0.0, -3.0], [0.6, 1.0], [1.0, 0.0]], u)))
			d.ll_a = _kf([[0.0, 130.0], [0.5, 108.0], [1.0, 98.0]], u)
			d.lr_a = _kf([[0.0, 48.0], [0.5, 72.0], [1.0, 82.0]], u)
			d.ll_b = _kf([[0.0, 42.0], [0.5, 18.0], [1.0, 8.0]], u)
			d.lr_b = _kf([[0.0, 30.0], [0.5, 12.0], [1.0, 8.0]], u)
			d.al_a = _kf([[0.0, 90.0], [0.5, 108.0], [1.0, 108.0]], u)
			d.ar_a = _kf([[0.0, 70.0], [0.5, 72.0], [1.0, 72.0]], u)
		"crouch":
			var cu: float = _ease_in_out(u)
			d.squat = int(round(lerpf(4.0, 16.0, cu)))
			d.ll_a = lerpf(105.0, 128.0, cu)
			d.lr_a = lerpf(78.0, 52.0, cu)
			d.ll_b = lerpf(14.0, 42.0, cu)
			d.lr_b = lerpf(12.0, 36.0, cu)
			d.al_a = lerpf(108.0, 98.0, cu)
			d.ar_a = lerpf(78.0, 72.0, cu)
		"block":
			d.squat = 6
			d.lean = 3
			d.al_a = 18.0
			d.ar_a = 8.0
			d.al_b = 72.0 + sin(ph * 2.0) * 2.0
			d.ar_b = 78.0 + sin(ph * 2.0) * 2.0
			d.ll_a = 102.0
			d.lr_a = 74.0
		"block_hit":
			d.squat = 8
			d.lean = int(round(_kf([[0.0, 2.0], [0.25, 8.0], [1.0, 3.0]], u)))
			d.xoff = int(round(_kf([[0.0, 0.0], [0.25, 5.0], [1.0, 1.0]], u)))
			d.al_a = 12.0
			d.ar_a = 4.0
			d.al_b = 68.0
			d.ar_b = 74.0
		"light":
			var au: float = _attack_phase(u, 0.22, 0.28)
			d.ar_a = lerpf(150.0, -5.0, _ease_out_cubic(au / 0.72))
			d.ar_b = lerpf(24.0, 2.0, smoothstep(0.15, 0.65, au))
			d.al_a = lerpf(118.0, 128.0, au)
			d.lean = int(round(smoothstep(0.25, 0.55, au) * 4.0))
			d.xoff = int(round(smoothstep(0.3, 0.55, au) * 3.0))
		"clight":
			var cu: float = _attack_phase(u, 0.18, 0.30)
			d.squat = 14
			d.ar_a = lerpf(108.0, 0.0, _ease_out_cubic(cu / 0.72))
			d.ar_b = lerpf(28.0, 4.0, cu)
			d.al_a = 112.0
			d.ll_a = 128.0
			d.lr_a = 54.0
			d.ll_b = 40.0
			d.lr_b = 30.0
			d.lean = 3
		"jlight":
			var ju: float = _attack_phase(u, 0.16, 0.32)
			d.squat = -3
			d.ar_a = lerpf(168.0, 0.0, ju)
			d.ar_b = 6.0
			d.al_a = 225.0
			d.ll_a = 52.0
			d.lr_a = 128.0
			d.ll_b = 22.0
			d.lr_b = 16.0
		"heavy":
			var hu: float = _attack_phase(u, 0.32, 0.26)
			d.squat = int(round((1.0 - absf(hu - 0.45)) * 6.0))
			d.ar_a = lerpf(168.0, -12.0, _ease_out_back(hu / 0.72))
			d.ar_b = lerpf(34.0, 0.0, smoothstep(0.2, 0.68, hu))
			d.al_a = lerpf(128.0, 142.0, hu)
			d.lean = int(round(smoothstep(0.22, 0.62, hu) * 6.0))
			d.ll_a = 108.0
			d.lr_a = 66.0
		"cheavy":
			var chu: float = _attack_phase(u, 0.28, 0.28)
			d.squat = 15
			d.lean = int(round(smoothstep(0.18, 0.62, chu) * 5.0))
			d.ar_a = lerpf(158.0, 0.0, _ease_out_cubic(chu / 0.72))
			d.ar_b = lerpf(30.0, 2.0, chu)
			d.al_a = 122.0
			d.ll_a = 132.0
			d.lr_a = 36.0
			d.ll_b = 44.0
			d.lr_b = 6.0
		"jheavy":
			var jhu: float = _attack_phase(u, 0.24, 0.30)
			d.squat = -2
			d.ar_a = lerpf(188.0, -8.0, _ease_out_back(jhu / 0.72))
			d.ar_b = lerpf(22.0, 0.0, jhu)
			d.al_a = 205.0
			d.ll_a = 44.0
			d.lr_a = 136.0
			d.lean = 4
		"special":
			var spu: float = _attack_phase(u, 0.14, 0.34)
			d.lean = int(round(spu * 10.0))
			d.xoff = int(round(spu * 8.0))
			d.ar_a = lerpf(48.0, -18.0, spu)
			d.al_a = lerpf(138.0, 215.0, spu)
			d.ll_a = lerpf(88.0, 52.0, spu)
			d.lr_a = lerpf(78.0, 44.0, spu)
			d.ll_b = 6.0
			d.lr_b = 6.0
			d.ar_b = 2.0
		"ultimate":
			var upu: float = _attack_phase(u, 0.20, 0.32)
			d.squat = int(round(sin(upu * PI) * -4.0))
			d.ar_a = lerpf(96.0, -28.0, upu)
			d.al_a = lerpf(92.0, 225.0, upu)
			d.lean = int(round(upu * 6.0))
			d.xoff = int(round(sin(upu * PI) * 4.0))
			d.ll_a = 102.0
			d.lr_a = 76.0
		"hit":
			var hu2: float = _kf([[0.0, 0.0], [0.18, 1.0], [0.55, 0.7], [1.0, 0.2]], u)
			d.xoff = int(round(2.0 + hu2 * 6.0))
			d.head_x = int(round(hu2 * 3.0))
			d.lean = int(round(hu2 * 6.0))
			d.al_a = lerpf(108.0, 210.0, hu2)
			d.ar_a = lerpf(72.0, 168.0, hu2)
			d.ll_a = lerpf(98.0, 68.0, hu2)
			d.lr_a = lerpf(82.0, 112.0, hu2)
		"air_hit":
			d.squat = -4
			d.lean = int(round(sin(u * PI) * 5.0))
			d.al_a = 200.0 + u * 20.0
			d.ar_a = 150.0
			d.ll_a = 58.0
			d.lr_a = 120.0
			d.ll_b = 20.0
			d.lr_b = 14.0
		"launch":
			d.squat = int(round(_kf([[0.0, 2.0], [0.3, -6.0], [0.7, -4.0], [1.0, 0.0]], u)))
			d.al_a = _kf([[0.0, 120.0], [0.35, 230.0], [1.0, 140.0]], u)
			d.ar_a = _kf([[0.0, 60.0], [0.35, -40.0], [1.0, 80.0]], u)
			d.ll_a = _kf([[0.0, 90.0], [0.4, 48.0], [1.0, 78.0]], u)
			d.lr_a = _kf([[0.0, 78.0], [0.4, 130.0], [1.0, 96.0]], u)
		"grab":
			var gu: float = _attack_phase(u, 0.20, 0.35)
			d.ar_a = lerpf(36.0, -2.0, gu)
			d.ar_b = lerpf(42.0, 8.0, gu)
			d.al_a = lerpf(78.0, 18.0, gu)
			d.al_b = lerpf(20.0, 36.0, gu)
			d.lean = int(round(gu * 5.0))
			d.squat = int(round(gu * 4.0))
			d.xoff = int(round(gu * 5.0))
		"victory":
			var vu: float = _ease_out_back(minf(u * 1.2, 1.0))
			d.ar_a = lerpf(-40.0, -105.0, vu)
			d.al_a = lerpf(90.0, 115.0, vu)
			d.al_b = lerpf(16.0, 8.0, vu)
			d.bob = int(round(sin(ph * 2.0) * 2.0))
			d.ll_a = 94.0
			d.lr_a = 86.0
			d.lean = int(round(sin(ph) * 2.0))
		_:
			pass
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
	for i in 6:
		var y: int = hip_y - 10 - i * 4
		var w: int = 10 + f + i * 2
		Pix.hline(img, maxi(2, cx - w), y, mini(w * 2, img.get_width() - 4), Color(accent, 0.18 + float(i) * 0.06))
		Pix.put(img, cx - 14 - i * 2, hip_y - 18 + i, Color(accent, 0.55 + float(i) * 0.05))
		Pix.put(img, cx - 8 - i, hip_y - 12 + i, Color(accent.lightened(0.2), 0.35))


static func _downed(img: Image, def: CharacterDef, racing: bool, kit: bool, f: int, n: int, pose: String) -> void:
	var u: float = float(f) / float(maxi(n - 1, 1))
	var fall: float = _ease_in_out(clampf(u * 1.35, 0.0, 1.0))
	var y: int = int(lerpf(40.0, 64.0, fall))
	var tilt: int = int(lerpf(0.0, 14.0, fall))
	if kit:
		Pix.capsule(img, 14 + tilt, y + 6, 36 + tilt, y + 8, 4, def.outfit)
		Pix.hline(img, 18 + tilt, y + 6, 14, def.trim)
		Pix.hline(img, 18 + tilt, y + 8, 14, def.accent)
	else:
		Pix.capsule(img, 12 + tilt, y + 6, 34 + tilt, y + 8, 3, def.outfit)
	Pix.oval(img, 42 + tilt, y + 4, 6, 5, def.skin)
	Pix.oval(img, 44 + tilt, y + 1, 8, 5, def.hair)
	Pix.capsule(img, 10 + tilt, y + 8, 18 + tilt, y + 12, 2, def.outfit.darkened(0.15))
	Pix.capsule(img, 22 + tilt, y + 9, 30 + tilt, y + 13, 2, def.outfit.darkened(0.1))
	if racing:
		Pix.hline(img, 20 + tilt, y + 6, 10, def.accent)
	if pose == "defeat" and u > 0.55:
		Pix.hline(img, 46 + tilt, y + 6, 4, def.skin.darkened(0.2))
