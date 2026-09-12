class_name PixelFighterBake
extends RefCounted
## Limb-rigged pixel fighter. Faces right; flip_h handles facing.
## Chris (style "kit") uses a keyed photo head plus a generic striped kit — no club badge.

const Chibi := preload("res://scripts/pixel/chibi_fighter.gd")
const PhotoSprite := preload("res://scripts/pixel/photo_fighter_sprite.gd")

const W := 48
const H := 56
const SCALE := 3
const MODEL_W := 160
const MODEL_H := 160
const MODEL_SCALE := 3
const _HEAD := Rect2i(40, 3, 48, 28)
const _TORSO := Rect2i(34, 28, 60, 44)
const _ARM_L := Rect2i(10, 32, 38, 40)
const _ARM_R := Rect2i(84, 30, 38, 42)
const _LEG_L := Rect2i(26, 68, 34, 54)
const _LEG_R := Rect2i(58, 68, 38, 54)
const _HIP_X := 64
const _HIP_Y := 72

static var _face_cache: Dictionary = {}
static var _model_cache: Dictionary = {}
static var _anim_cache: Dictionary = {}


static func bake(def: CharacterDef) -> Dictionary:
	if _anim_cache.has(def.id):
		return _anim_cache[def.id]
	var result := {
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
	_anim_cache[def.id] = result
	return result


static func clear_cache(id: String = "") -> void:
	if id.is_empty():
		_anim_cache.clear()
		_face_cache.clear()
		_model_cache.clear()
		return
	_anim_cache.erase(id)
	_face_cache.erase(id)
	_model_cache.erase(id)


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
	Chibi.paint(img, def, pose, f, n)
	Pix.outline(img, Color(0.08, 0.06, 0.07, 1))
	return Pix.tex(img)


static func _is_kit(def: CharacterDef) -> bool:
	return def.style == "kit"


static func _is_street(def: CharacterDef) -> bool:
	return def.style == "street"


static func _is_hero(def: CharacterDef) -> bool:
	return _is_kit(def) or _is_street(def)


static func _is_model(def: CharacterDef) -> bool:
	return def.style == "model"


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

	if pose in ["knockdown", "defeat"]:
		_paint_model_fall(img, sheet, pad_x, pad_y, u, pose)
		return

	var m: Dictionary = _model_pose(pose, u, ph, p)
	var ox: int = pad_x + int(m.get("xoff", 0))
	var oy: int = pad_y + int(m.get("bob", 0)) + int(m.get("squat", 0))
	var use_full: bool = bool(m.get("full_body", true))

	if use_full:
		_blit_sheet(img, sheet, ox, oy)
	else:
		_paint_model_parts(img, sheet, ox, oy, m)

	var lead: Dictionary = m["lead_arm"] as Dictionary
	var rear: Dictionary = m["rear_arm"] as Dictionary
	if use_full:
		if absf(float(lead.rot)) > 2.0:
			_blit_rot_part(img, sheet, _ARM_R, ox + int(lead.sx), oy + int(lead.sy), float(lead.rot), int(lead.px), int(lead.py))
		if absf(float(rear.rot)) > 2.0:
			_blit_rot_part(img, sheet, _ARM_L, ox + int(rear.sx), oy + int(rear.sy), float(rear.rot), int(rear.px), int(rear.py))

	if m.get("fx", false):
		_punch_flash(img, ox + int(m.get("fx_x", 108)), oy + int(m.get("fx_y", 46)), def.trim)
	if pose in ["special", "ultimate"]:
		_smear(img, ox + 80, oy + 100, def.accent, f)
	elif m.get("fx", false):
		_smear(img, ox + int(m.get("fx_x", 108)), oy + int(m.get("fx_y", 44)), def.trim, f)


static func _paint_model_parts(img: Image, sheet: Image, ox: int, oy: int, m: Dictionary) -> void:
	var leg_l: Dictionary = m["leg_l"] as Dictionary
	var leg_r: Dictionary = m["leg_r"] as Dictionary
	var hip_x: int = ox + _HIP_X
	var hip_y: int = oy + _HIP_Y
	_blit_rot_part(img, sheet, _LEG_L, hip_x + int(leg_l.dx) - 38, hip_y + int(leg_l.dy), float(leg_l.rot), 16, 4)
	_blit_rot_part(img, sheet, _LEG_R, hip_x + int(leg_r.dx) - 8, hip_y + int(leg_r.dy), float(leg_r.rot), 18, 4)
	var rear: Dictionary = m["rear_arm"] as Dictionary
	_blit_rot_part(img, sheet, _ARM_L, ox + int(rear.sx), oy + int(rear.sy), float(rear.rot), int(rear.px), int(rear.py))
	var lead: Dictionary = m["lead_arm"] as Dictionary
	_blit_rot_part(img, sheet, _ARM_R, ox + int(lead.sx), oy + int(lead.sy), float(lead.rot), int(lead.px), int(lead.py))
	var torso: Dictionary = m["torso"] as Dictionary
	_blit_rot_part(img, sheet, _TORSO, ox + int(torso.dx), oy + int(torso.dy), float(torso.rot), 30, 8)
	var head: Dictionary = m["head"] as Dictionary
	_blit_rot_part(img, sheet, _HEAD, ox + int(head.dx), oy + int(head.dy), float(head.rot), 24, 22)


static func _model_pose(pose: String, u: float, ph: float, p: Dictionary) -> Dictionary:
	var bob: int = int(p.bob) + int(p.squat)
	var lean: int = int(p.lean)
	var xoff: int = int(p.xoff)
	var base := {
		"xoff": xoff, "bob": bob, "squat": 0, "full_body": true,
		"leg_l": {"dx": 0, "dy": 0, "rot": 0.0},
		"leg_r": {"dx": 0, "dy": 0, "rot": 0.0},
		"torso": {"dx": lean, "dy": 0, "rot": 0.0},
		"head": {"dx": 0, "dy": 0, "rot": 0.0},
		"rear_arm": {"sx": 10, "sy": 32, "px": 8, "py": 8, "rot": 0.0},
		"lead_arm": {"sx": 84, "sy": 30, "px": 6, "py": 8, "rot": 0.0},
		"fx": false,
	}
	match pose:
		"idle":
			var breathe: float = sin(ph)
			base.bob = int(round(breathe * 2.0))
			base.xoff = int(round(breathe * 0.5))
		"walk":
			var step: int = int(floor(ph / TAU * 8.0)) % 8
			var s: Dictionary = _walk_table()[step]
			base.bob = int(s.bob)
			base.xoff = int(s.lean) + int(s.near_x)
			base.full_body = false
			base.leg_l.rot = float(s.get("ll_rot", 0.0))
			base.leg_r.rot = float(s.get("lr_rot", 0.0))
			base.rear_arm.rot = float(s.get("al_rot", 0.0))
			base.lead_arm.rot = float(s.get("ar_rot", 0.0))
		"run":
			var rs: int = int(floor(ph / TAU * 6.0)) % 6
			var rt: Dictionary = _run_table()[rs]
			base.bob = int(rt.bob)
			base.xoff = int(rt.xoff) + int(rt.near_x)
			base.full_body = false
			base.leg_l.rot = float(rt.get("ll_rot", 0.0))
			base.leg_r.rot = float(rt.get("lr_rot", 0.0))
			base.rear_arm.rot = float(rt.get("al_rot", 0.0))
			base.lead_arm.rot = float(rt.get("ar_rot", 0.0))
		"backdash":
			base.xoff = -10 + int(sin(ph * 2.0) * -3.0)
			base.bob = int(abs(sin(ph * 2.0)) * 2.0)
		"prejump", "crouch", "land", "getup":
			base.bob = bob
			base.squat = int(p.squat)
		"jump":
			base.bob = bob - int(_kf([[0.0, 0.0], [0.2, 4.0], [0.5, -6.0], [0.8, -2.0], [1.0, 2.0]], u))
			base.xoff = int(_kf([[0.0, 0.0], [0.35, 2.0], [0.7, -1.0], [1.0, 0.0]], u))
		"block", "block_hit":
			base.xoff = xoff + (5 if pose == "block_hit" else 0)
			base.bob = 1 if pose == "block_hit" else 0
		"light", "clight", "jlight":
			var au: float = _attack_phase(u, 0.20, 0.30)
			var strike: float = smoothstep(0.30, 0.55, au)
			var wind: float = 1.0 - strike
			base.xoff = int(lerpf(-4.0, 16.0, strike))
			base.bob = int(lerpf(0.0, -3.0, strike) + wind * 1.0)
			base.lead_arm.rot = lerpf(-14.0, 72.0, _ease_out_cubic(strike))
			base.rear_arm.rot = lerpf(4.0, -28.0, strike)
			if strike > 0.25:
				base.fx = true
				base.fx_x = 104 + int(strike * 18.0)
				base.fx_y = 56
		"heavy", "cheavy", "jheavy":
			var hu: float = _attack_phase(u, 0.30, 0.28)
			var hstrike: float = smoothstep(0.32, 0.58, hu)
			base.xoff = int(lerpf(-6.0, 18.0, hstrike))
			base.bob = int(lerpf(2.0, -5.0, hstrike))
			base.lead_arm.rot = lerpf(-22.0, 78.0, _ease_out_back(hstrike))
			base.rear_arm.rot = lerpf(8.0, -36.0, hstrike)
			if hstrike > 0.22:
				base.fx = true
				base.fx_x = 108 + int(hstrike * 20.0)
				base.fx_y = 54
		"special", "ultimate":
			var spu: float = _attack_phase(u, 0.14, 0.36)
			base.xoff = int(spu * 14.0)
			base.bob = int(sin(spu * PI) * -3.0)
			base.lead_arm.rot = lerpf(-6.0, 44.0, spu)
			base.rear_arm.rot = lerpf(0.0, -42.0, spu)
			if spu > 0.28:
				base.fx = spu < 0.88
				base.fx_x = 110 + int(spu * 14.0)
				base.fx_y = 44
		"grab":
			var gu: float = _attack_phase(u, 0.18, 0.38)
			base.xoff = int(gu * 8.0)
			base.lead_arm.rot = lerpf(-6.0, 22.0, gu)
			base.rear_arm.rot = lerpf(0.0, 20.0, gu)
		"hit", "air_hit", "launch":
			base.xoff = xoff + lean
			base.bob = int(p.head_x)
		"victory":
			base.bob = int(sin(ph * 2.0) * 2.0)
			base.lead_arm.rot = lerpf(-8.0, -55.0, _ease_out_back(minf(u * 1.3, 1.0)))
			base.rear_arm.rot = -12.0 + sin(ph) * 4.0
		_:
			pass
	return base


static func _walk_table() -> Array:
	return [
		{"bob": 0, "lean": 0, "near_x": 0, "ll_rot": 0.0, "lr_rot": 0.0, "al_rot": 0.0, "ar_rot": 0.0},
		{"bob": -2, "lean": 2, "near_x": 4, "ll_rot": -16.0, "lr_rot": 12.0, "al_rot": 6.0, "ar_rot": -4.0},
		{"bob": -3, "lean": 2, "near_x": 6, "ll_rot": -22.0, "lr_rot": 18.0, "al_rot": 10.0, "ar_rot": -8.0},
		{"bob": -2, "lean": 1, "near_x": 3, "ll_rot": -10.0, "lr_rot": 8.0, "al_rot": 4.0, "ar_rot": -2.0},
		{"bob": 0, "lean": 0, "near_x": 0, "ll_rot": 0.0, "lr_rot": 0.0, "al_rot": 0.0, "ar_rot": 0.0},
		{"bob": -2, "lean": -2, "near_x": -4, "ll_rot": 12.0, "lr_rot": -16.0, "al_rot": -4.0, "ar_rot": 6.0},
		{"bob": -3, "lean": -2, "near_x": -6, "ll_rot": 18.0, "lr_rot": -22.0, "al_rot": -8.0, "ar_rot": 10.0},
		{"bob": -2, "lean": -1, "near_x": -3, "ll_rot": 8.0, "lr_rot": -10.0, "al_rot": -2.0, "ar_rot": 4.0},
	]


static func _run_table() -> Array:
	return [
		{"bob": -1, "xoff": 3, "near_x": 4, "ll_rot": -20.0, "lr_rot": 16.0, "al_rot": 12.0, "ar_rot": -10.0},
		{"bob": -3, "xoff": 5, "near_x": 6, "ll_rot": -28.0, "lr_rot": 24.0, "al_rot": 16.0, "ar_rot": -14.0},
		{"bob": -2, "xoff": 4, "near_x": 2, "ll_rot": -8.0, "lr_rot": 10.0, "al_rot": 6.0, "ar_rot": -4.0},
		{"bob": -1, "xoff": 3, "near_x": -4, "ll_rot": 16.0, "lr_rot": -20.0, "al_rot": -10.0, "ar_rot": 12.0},
		{"bob": -3, "xoff": 5, "near_x": -6, "ll_rot": 24.0, "lr_rot": -28.0, "al_rot": -14.0, "ar_rot": 16.0},
		{"bob": -2, "xoff": 4, "near_x": -2, "ll_rot": 10.0, "lr_rot": -8.0, "al_rot": -4.0, "ar_rot": 6.0},
	]


static func _paint_model_fall(img: Image, sheet: Image, pad_x: int, pad_y: int, u: float, pose: String) -> void:
	if u < 0.38:
		var st: float = u / 0.38
		var ox: int = pad_x + int(st * 10.0)
		var oy: int = pad_y + int(st * 4.0)
		_blit_rot_part(img, sheet, _LEG_L, ox + 26, oy + 68, -12.0 - st * 16.0, 16, 4)
		_blit_rot_part(img, sheet, _LEG_R, ox + 58, oy + 68, 10.0 + st * 12.0, 18, 4)
		_blit_rot_part(img, sheet, _TORSO, ox + 34 + int(st * 6.0), oy + 28, 8.0 + st * 20.0, 30, 8)
		_blit_rot_part(img, sheet, _HEAD, ox + 40 + int(st * 8.0), oy + 3, 6.0 + st * 14.0, 24, 22)
		_blit_rot_part(img, sheet, _ARM_L, ox + 10, oy + 32, 30.0 + st * 20.0, 8, 8)
		_blit_rot_part(img, sheet, _ARM_R, ox + 84, oy + 30, -10.0, 6, 8)
	else:
		var laid := sheet.duplicate()
		laid.rotate_90(ClockDirection.CLOCKWISE)
		_blit_sheet(img, laid, pad_x - 12, pad_y + 14 + int((u - 0.38) * 28.0))


static func _punch_flash(img: Image, x: int, y: int, col: Color) -> void:
	Pix.disc(img, x, y, 2, Color(1.0, 0.98, 0.92, 0.85))
	Pix.disc(img, x + 1, y, 1, Color(col.lightened(0.4), 0.7))
	Pix.hline(img, x - 4, y, 4, Color(col, 0.3))


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
	var baked_path: String = "res://data/characters/refs/%s_model.png" % def.id
	var src: Image = CharacterForge._load_image(baked_path)
	if src == null:
		var path: String = def.reference_image
		if path.is_empty() and def.id == "chris_xrisakis":
			path = "res://data/characters/refs/chris_model.png"
		src = CharacterForge._load_image(path)
		if src == null:
			_model_cache[def.id] = null
			return null
		if PhotoSprite.is_portrait(src):
			src = PhotoSprite.build_from_photo(src, def)
		else:
			src.convert(Image.FORMAT_RGBA8)
			for y in src.get_height():
				for x in src.get_width():
					var c: Color = src.get_pixel(x, y)
					if _is_model_bg(c):
						src.set_pixel(x, y, Color(0, 0, 0, 0))
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
	var u: float = float(f) / float(maxi(n - 1, 1))
	var p: Dictionary = _rig(pose, f, n)
	p.xoff = int(round(float(p.xoff) * 0.32))
	p.bob = int(round(float(p.bob) * 0.35))
	p.lean = int(round(float(p.lean) * 0.35))
	p.head_x = int(round(float(p.head_x) * 0.4))
	var skinny: bool = def.build == "lean" or def.width_scale < 0.92
	var racing: bool = def.style == "racing"
	var kit: bool = _is_kit(def)
	var street: bool = _is_street(def)
	var hero: bool = _is_hero(def)
	var cx: int = 16 + int(p.xoff)
	var foot: int = 34
	var hip_y: int = foot - 10 + int(round(float(p.squat) * 0.38)) + int(p.bob)
	if pose in ["knockdown", "defeat"]:
		_downed(img, def, racing, hero, f, n, pose)
		return

	var pants: Color = Color(0.18, 0.32, 0.55) if kit else (Color(0.12, 0.16, 0.30) if street else (Color(0.12, 0.11, 0.14) if racing else def.outfit.darkened(0.25)))
	var shoes: Color = Color(0.08, 0.08, 0.09)
	var sleeve: Color = def.outfit if (street or kit or racing) else def.skin
	var lt: int = 2
	var ls: int = 2
	var at: int = 2

	_limb(img, cx - 2, hip_y, float(p.ll_a), float(p.ll_b), 6, 6, lt, ls, pants, shoes, true, kit)
	_limb(img, cx + 2, hip_y, float(p.lr_a), float(p.lr_b), 6, 6, lt, ls, pants.lightened(0.06), shoes, true, kit)
	_arm(img, cx - 4, hip_y - 8, float(p.al_a), float(p.al_b), 5, 5, at, sleeve, def.skin)
	_torso(img, def, cx, hip_y, skinny, racing, kit, street, int(p.lean))
	_arm(img, cx + 4 + int(p.lean), hip_y - 8, float(p.ar_a), float(p.ar_b), 6, 5, at, sleeve.lightened(0.06), def.skin)

	if (racing or hero) and pose in ["special", "ultimate"]:
		_smear(img, cx, hip_y, def.accent, f)
	if pose in ["light", "clight", "jlight", "heavy", "cheavy", "jheavy", "grab"] and u > 0.28 and u < 0.62:
		var fist_x: int = cx + 14 + int(p.lean) + int(p.xoff)
		var fist_y: int = hip_y - 10
		_punch_flash(img, fist_x, fist_y, def.trim)
		_smear(img, fist_x - 4, fist_y, def.trim, f)

	var hx: int = cx + int(p.lean) + int(p.head_x)
	var hy: int = hip_y - 16 + int(int(p.squat) / 4)
	if hero:
		_photo_head(img, def, hx, hy, pose, street)
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
			var au: float = _attack_phase(u, 0.20, 0.30)
			d.ar_a = lerpf(158.0, -2.0, _ease_out_cubic(au / 0.72))
			d.ar_b = lerpf(32.0, -6.0, _ease_out_cubic(au / 0.72))
			d.al_a = lerpf(118.0, 135.0, au)
			d.al_b = lerpf(16.0, 28.0, smoothstep(0.0, 0.35, au))
			d.lean = int(round(smoothstep(0.22, 0.52, au) * 5.0))
			d.xoff = int(round(smoothstep(0.28, 0.52, au) * 5.0))
			d.ll_a = lerpf(98.0, 92.0, au)
			d.lr_a = lerpf(82.0, 78.0, au)
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
		Pix.rect(img, ax - 1, ay - 3, 3, 3, Color(0.93, 0.93, 0.95))
		Pix.hline(img, ax - 1, ay - 3, 3, Color(0.78, 0.16, 0.22))
	if with_shoe:
		Pix.rect(img, ax - 1, ay, 4, 2, shoe)
		Pix.rect(img, ax + 2, ay + 1, 2, 1, shoe.lightened(0.35))


static func _arm(img: Image, sx: int, sy: int, ang: float, bend: float, upper: int, lower: int, r: int, col: Color, hand: Color) -> void:
	var a: float = deg_to_rad(ang)
	var ex: int = sx + int(round(cos(a) * float(upper)))
	var ey: int = sy + int(round(sin(a) * float(upper)))
	var a2: float = deg_to_rad(ang + bend)
	var hx: int = ex + int(round(cos(a2) * float(lower)))
	var hy: int = ey + int(round(sin(a2) * float(lower)))
	Pix.capsule(img, sx, sy, ex, ey, r, col)
	Pix.capsule(img, ex, ey, hx, hy, maxi(r - 1, 1), col.darkened(0.06))
	Pix.disc(img, hx, hy, 1, hand)


static func _torso(img: Image, def: CharacterDef, cx: int, hip_y: int, skinny: bool, racing: bool, kit: bool, street: bool, lean: int) -> void:
	var tw: int = 9 if kit else (10 if street else (4 if skinny else (7 if def.build == "heavy" else 5)))
	var h: int = 12 if (kit or street) else 8
	var top: int = hip_y - h
	var tx: int = cx - tw / 2 + lean
	if kit:
		# Red / white horizontal stripes, blue collar, short sleeves. No crest.
		Pix.rect(img, tx, top + 3, tw + 1, h - 3, def.trim)
		var row: int = top + 3
		while row < top + h - 1:
			var band: Color = def.outfit if (row - top) % 2 == 0 else def.trim
			Pix.rect(img, tx, row, tw + 1, 1, band)
			row += 1
		Pix.rect(img, tx, top, tw + 1, 4, def.accent)
		Pix.rect(img, tx + 1, top + 1, tw - 1, 2, def.accent.lightened(0.08))
		Pix.rect(img, tx - 3, top + 3, 4, 5, def.outfit)
		Pix.rect(img, tx + tw, top + 3, 4, 5, def.outfit)
		Pix.rect(img, tx, top + h - 2, tw + 1, 2, def.outfit.darkened(0.12))
	elif street:
		var shirt: Color = def.outfit
		var shirt_hi: Color = def.outfit.lightened(0.12)
		Pix.rect(img, tx - 1, top + 2, tw + 3, h - 2, shirt)
		Pix.rect(img, tx, top + 3, tw + 1, h - 4, shirt_hi)
		Pix.rect(img, tx - 3, top + 3, 4, 6, shirt)
		Pix.rect(img, tx + tw, top + 3, 4, 6, shirt)
		Pix.rect(img, tx + 1, top, tw - 1, 4, shirt.darkened(0.08))
		Pix.hline(img, tx + 2, top + 2, tw - 3, def.skin.darkened(0.06))
		Pix.hline(img, cx + lean - 2, top + 4, 5, Color(0.78, 0.80, 0.84))
		_logo_hoodrich(img, tx + 2, top + 6, def.trim, def.accent)
	elif racing:
		Pix.rect(img, tx, top, tw + 1, h, def.outfit)
		Pix.rect(img, tx, top, tw + 1, 2, def.accent.darkened(0.25))
		Pix.vline(img, cx + lean, top + 2, 6, def.accent)
	else:
		Pix.rect(img, tx, top, tw + 1, h, def.outfit)
		Pix.rect(img, tx + 1, top + 1, tw - 1, 3, def.outfit.lightened(0.08))
		Pix.rect(img, tx + 1, top + 3, tw - 1, 1, def.trim)


static func _photo_head(img: Image, def: CharacterDef, cx: int, cy: int, pose: String, street: bool) -> void:
	# Photo crops smear at chibi scale — draw readable pixel faces instead.
	Pix.oval(img, cx, cy + 1, 6, 7, def.skin)
	Pix.rect(img, cx - 1, cy + 6, 3, 3, def.skin.darkened(0.12))
	Pix.hline(img, cx - 3, cy, 3, def.hair.darkened(0.1))
	Pix.hline(img, cx + 1, cy, 3, def.hair.darkened(0.1))
	Pix.put(img, cx - 2, cy + 2, Color(0.95, 0.93, 0.9))
	Pix.put(img, cx + 2, cy + 2, Color(0.95, 0.93, 0.9))
	Pix.put(img, cx - 2, cy + 2, def.eyes)
	Pix.put(img, cx + 2, cy + 2, def.eyes)
	if pose == "hit":
		Pix.hline(img, cx - 1, cy + 4, 3, Color(0.45, 0.2, 0.2))
	else:
		Pix.hline(img, cx - 1, cy + 5, 3, def.skin.darkened(0.35))
	if street:
		_paint_street_hair(img, cx, cy, def)
	else:
		_paint_curly_hair(img, cx, cy, def)


static func _paint_curly_hair(img: Image, cx: int, cy: int, def: CharacterDef) -> void:
	var h1: Color = def.hair
	var h2: Color = def.hair.lightened(0.16)
	var h3: Color = def.hair.darkened(0.18)
	Pix.oval(img, cx, cy - 5, 7, 5, h1)
	Pix.disc(img, cx - 5, cy - 3, 2, h3)
	Pix.disc(img, cx + 5, cy - 4, 2, h2)
	Pix.disc(img, cx - 2, cy - 7, 2, h1)
	Pix.disc(img, cx + 2, cy - 7, 2, h2)
	Pix.disc(img, cx + 4, cy - 1, 2, h1)
	Pix.disc(img, cx - 5, cy - 1, 2, h1)


static func _paint_street_hair(img: Image, cx: int, cy: int, def: CharacterDef) -> void:
	var h: Color = def.hair
	Pix.oval(img, cx, cy - 5, 6, 4, h)
	Pix.rect(img, cx - 6, cy - 6, 13, 4, h)
	Pix.rect(img, cx - 5, cy - 3, 4, 4, h.darkened(0.08))
	var silver := Color(0.78, 0.80, 0.84)
	Pix.put(img, cx - 6, cy + 1, silver)
	Pix.put(img, cx - 6, cy + 2, silver.darkened(0.2))
	Pix.put(img, cx - 5, cy + 2, silver)


static func _logo_hoodrich(img: Image, x: int, y: int, white: Color, blue: Color) -> void:
	Pix.hline(img, x + 1, y + 1, 5, white)
	Pix.hline(img, x + 2, y + 2, 4, white)
	Pix.put(img, x + 1, y, blue.lightened(0.08))
	Pix.put(img, x + 2, y + 1, blue.lightened(0.08))


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
	var rx: int
	var ry: int
	var rw: int
	var rh: int
	var fw: int = 12 if def.id == "mako" else 8
	var fh: int = 14 if def.id == "mako" else 9
	if def.id == "mako":
		var face_path := "res://data/characters/refs/mako_face.png"
		var baked: Image = CharacterForge._load_image(face_path)
		if baked:
			baked.convert(Image.FORMAT_RGBA8)
			# drop gray wall leftovers
			for y in baked.get_height():
				for x in baked.get_width():
					var c: Color = baked.get_pixel(x, y)
					if c.s < 0.10 and c.get_luminance() > 0.38:
						baked.set_pixel(x, y, Color(0, 0, 0, 0))
			_face_cache[def.id] = baked
			return baked
		rx = int(round(float(sw) * 0.453))
		ry = int(round(float(sh) * 0.214))
		rw = int(round(float(sw) * 0.156))
		rh = int(round(float(sh) * 0.335))
	elif def.id == "hoodrich_stacks" or float(sh) > float(sw) * 1.1:
		rx = int(round(float(sw) * 0.26))
		ry = int(round(float(sh) * 0.05))
		rw = int(round(float(sw) * 0.48))
		rh = int(round(float(sh) * 0.28))
	else:
		rx = int(round(float(sw) * 0.438))
		ry = int(round(float(sh) * 0.250))
		rw = int(round(float(sw) * 0.229))
		rh = int(round(float(sh) * 0.455))
	rx = clampi(rx, 0, sw - 8)
	ry = clampi(ry, 0, sh - 8)
	rw = clampi(rw, 8, sw - rx)
	rh = clampi(rh, 8, sh - ry)
	var crop := src.get_region(Rect2i(rx, ry, rw, rh))
	crop.convert(Image.FORMAT_RGBA8)
	crop.resize(fw, fh, Image.INTERPOLATE_NEAREST)
	var out := Image.create(fw, fh, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in fh:
		for x in fw:
			var c: Color = crop.get_pixel(x, y)
			if _is_wall(c, def.id):
				continue
			out.set_pixel(x, y, c)
	_flood_key(out, def.id)
	_face_cache[def.id] = out
	return out


static func _is_wall(c: Color, char_id: String = "") -> bool:
	if c.a < 0.05:
		return true
	var lum: float = c.get_luminance()
	if lum > 0.78 and c.s < 0.16:
		return true
	if char_id == "mako":
		if c.s < 0.14 and lum > 0.30:
			return true
		return false
	if char_id == "hoodrich_stacks":
		if c.s < 0.22 and lum > 0.45 and lum < 0.92:
			return true
		return false
	var hue: float = c.h
	if hue > 0.22 and hue < 0.58 and lum > 0.38 and c.s < 0.45:
		return true
	if c.s < 0.16 and lum > 0.50 and lum < 0.88:
		return true
	return false


static func _flood_key(img: Image, char_id: String = "") -> void:
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
		if not _is_wall(c, char_id):
			continue
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))


static func _head(img: Image, def: CharacterDef, cx: int, cy: int, racing: bool, skinny: bool, pose: String) -> void:
	var skin_dk := def.skin.darkened(0.18)
	var rx: int = 4 if skinny else 5
	var ry: int = 5
	Pix.rect(img, cx - 1, cy + 4, 3, 2, def.skin.darkened(0.1))
	Pix.oval(img, cx, cy, rx, ry, def.skin)
	Pix.rect(img, cx - 1, cy + 2, 3, 3, skin_dk)
	var brow := def.hair.darkened(0.12)
	Pix.hline(img, cx - 2, cy - 1, 2, brow)
	Pix.hline(img, cx + 1, cy - 1, 2, brow)
	Pix.put(img, cx - 2, cy + 1, def.eyes)
	Pix.put(img, cx + 2, cy + 1, def.eyes)
	if pose != "hit":
		Pix.hline(img, cx - 1, cy + 3, 3, def.skin.darkened(0.35))
	else:
		Pix.hline(img, cx - 1, cy + 2, 3, Color(0.45, 0.2, 0.2))
	var h1 := def.hair
	var h2 := def.hair.lightened(0.14)
	Pix.oval(img, cx, cy - 4, 5 if racing else 4, 3, h1)
	Pix.disc(img, cx - 3, cy - 2, 2, h1)
	Pix.disc(img, cx + 3, cy - 3, 2, h2)
	Pix.put(img, cx, cy + 5, Color(0.08, 0.07, 0.07))


static func _smear(img: Image, cx: int, hip_y: int, accent: Color, f: int) -> void:
	for i in 4:
		Pix.hline(img, maxi(1, cx - 6 - i), hip_y - 6 - i, 8 + i, Color(accent, 0.22 + float(i) * 0.08))
		Pix.put(img, cx - 8 - i, hip_y - 8 + i, Color(accent, 0.5))


static func _downed(img: Image, def: CharacterDef, racing: bool, hero: bool, f: int, n: int, pose: String) -> void:
	var u: float = float(f) / float(maxi(n - 1, 1))
	var fall: float = _ease_in_out(clampf(u * 1.35, 0.0, 1.0))
	var y: int = int(lerpf(18.0, 26.0, fall))
	var tilt: int = int(lerpf(0.0, 6.0, fall))
	if _is_kit(def):
		Pix.capsule(img, 6 + tilt, y + 3, 16 + tilt, y + 4, 2, def.outfit)
		Pix.hline(img, 8 + tilt, y + 3, 7, def.trim)
	elif _is_street(def):
		Pix.capsule(img, 6 + tilt, y + 3, 16 + tilt, y + 4, 2, def.outfit)
	else:
		Pix.capsule(img, 5 + tilt, y + 3, 15 + tilt, y + 4, 2, def.outfit)
	Pix.oval(img, 18 + tilt, y + 2, 4, 3, def.skin)
	Pix.oval(img, 19 + tilt, y, 5, 3, def.hair)
	if racing:
		Pix.hline(img, 8 + tilt, y + 3, 6, def.accent)
	if pose == "defeat" and u > 0.55:
		Pix.hline(img, 20 + tilt, y + 3, 3, def.skin.darkened(0.2))
