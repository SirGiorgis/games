class_name PixelFighterBake
extends RefCounted
## Limb-rigged pixel fighter. Faces right; flip_h handles facing.

const W := 64
const H := 80
const SCALE := 4


static func bake(def: CharacterDef) -> Dictionary:
	return {
		"idle": _seq(def, "idle", 6),
		"walk": _seq(def, "walk", 8),
		"run": _seq(def, "walk", 8),
		"jump": _seq(def, "jump", 6),
		"crouch": _seq(def, "crouch", 2),
		"light": _seq(def, "light", 6),
		"heavy": _seq(def, "heavy", 8),
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


static func _paint(img: Image, def: CharacterDef, pose: String, f: int, n: int) -> void:
	var p: Dictionary = _rig(pose, f, n)
	var skinny: bool = def.build == "lean" or def.width_scale < 0.92
	var racing: bool = def.style == "racing" or def.id == "chris_xrisakis"
	var cx: int = 32 + int(p.xoff)
	var foot: int = 76
	var hip_y: int = foot - (15 if skinny else 16) + int(p.squat) + int(p.bob)
	if pose == "knockdown":
		_downed(img, def, racing, f)
		return

	var pants := Color(0.12, 0.12, 0.14) if racing else def.outfit.darkened(0.25)
	var shoes := Color(0.08, 0.08, 0.09)
	var sleeve := def.outfit if racing else def.skin
	var lt: int = 2 if skinny else 3
	var ls: int = 2 if skinny else 3
	var at: int = 2 if skinny else 3

	# far leg / far arm first
	_limb(img, cx - 2, hip_y, float(p.ll_a), float(p.ll_b), 12, 12, lt, ls, pants, shoes, true)
	_arm(img, cx - (4 if skinny else 5), hip_y - 15, float(p.al_a), float(p.al_b), 9, 8, at, sleeve, def.skin)

	_torso(img, def, cx, hip_y, skinny, racing, int(p.lean))
	_limb(img, cx + 2, hip_y, float(p.lr_a), float(p.lr_b), 12, 12, lt, ls, pants.lightened(0.05), shoes, true)
	_arm(img, cx + (4 if skinny else 5) + int(p.lean), hip_y - 15, float(p.ar_a), float(p.ar_b), 9, 9, at, sleeve.lightened(0.06), def.skin)

	if racing and pose in ["special", "ultimate"]:
		_smear(img, cx, hip_y, def.accent, f)

	var hx: int = cx - 1 + int(p.lean) + int(p.head_x)
	var hy: int = hip_y - 28 + int(int(p.squat) / 2)
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
			d.squat = 12
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
		"heavy":
			d.squat = int(round((1.0 - abs(u - 0.45)) * 4.0))
			d.ar_a = lerpf(160.0, -8.0, smoothstep(0.15, 0.62, u))
			d.ar_b = lerpf(30.0, 2.0, smoothstep(0.2, 0.65, u))
			d.al_a = 130.0
			d.lean = int(round(smoothstep(0.25, 0.7, u) * 5.0))
			d.ll_a = 105.0
			d.lr_a = 70.0
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


static func _limb(img: Image, hx: int, hy: int, ang: float, bend: float, thigh: int, shin: int, tr: int, sr: int, col: Color, shoe: Color, with_shoe: bool) -> void:
	var a: float = deg_to_rad(ang)
	var kx: int = hx + int(round(cos(a) * float(thigh)))
	var ky: int = hy + int(round(sin(a) * float(thigh)))
	var a2: float = deg_to_rad(ang + bend)
	var ax: int = kx + int(round(cos(a2) * float(shin)))
	var ay: int = ky + int(round(sin(a2) * float(shin)))
	Pix.capsule(img, hx, hy, kx, ky, tr, col)
	Pix.capsule(img, kx, ky, ax, ay, sr, col.darkened(0.08))
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


static func _torso(img: Image, def: CharacterDef, cx: int, hip_y: int, skinny: bool, racing: bool, lean: int) -> void:
	var tw: int = 5 if skinny else (9 if def.build == "heavy" else 7)
	var top: int = hip_y - 18
	var tx: int = cx - tw / 2 + lean
	Pix.rect(img, tx, top, tw + 1, 18, def.outfit)
	Pix.rect(img, tx + 1, top + 1, tw - 1, 8, def.outfit.lightened(0.08))
	if racing:
		Pix.rect(img, tx, top, tw + 1, 4, def.accent.darkened(0.25))
		Pix.vline(img, cx + lean, top + 3, 14, def.accent)
		Pix.vline(img, cx + lean + 2, top + 4, 13, def.trim)
		Pix.rect(img, tx + tw - 1, top + 5, 2, 10, def.trim)
		# necklace
		Pix.put(img, cx + lean, top + 4, Color(0.15, 0.14, 0.12))
		Pix.put(img, cx + lean, top + 5, Color(0.15, 0.14, 0.12))
	else:
		Pix.rect(img, tx + 1, top + 4, tw - 1, 2, def.trim)
	# skinny waist
	if skinny:
		Pix.rect(img, tx + 1, hip_y - 6, tw - 1, 6, def.outfit.darkened(0.1))


static func _head(img: Image, def: CharacterDef, cx: int, cy: int, racing: bool, skinny: bool, pose: String) -> void:
	var skin_dk := def.skin.darkened(0.18)
	var rx: int = 5 if skinny else 6
	var ry: int = 6
	Pix.oval(img, cx, cy, rx, ry, def.skin)
	Pix.rect(img, cx - 2, cy + 4, 5, 3, skin_dk)
	# ears
	Pix.rect(img, cx - rx - 1, cy, 2, 3, def.skin)
	Pix.rect(img, cx + rx, cy, 2, 3, def.skin)
	# brows + eyes (photo: dark, close-set)
	var brow := def.hair.darkened(0.1)
	Pix.hline(img, cx - 3, cy - 1, 3, brow)
	Pix.hline(img, cx + 1, cy - 1, 3, brow)
	Pix.put(img, cx - 2, cy + 1, Color(0.95, 0.93, 0.9))
	Pix.put(img, cx + 2, cy + 1, Color(0.95, 0.93, 0.9))
	Pix.put(img, cx - 2, cy + 1, def.eyes)
	Pix.put(img, cx + 2, cy + 1, def.eyes)
	# nose / mouth
	Pix.put(img, cx, cy + 2, skin_dk)
	if pose != "hit":
		Pix.hline(img, cx - 1, cy + 4, 3, def.skin.darkened(0.35))
	else:
		Pix.hline(img, cx - 1, cy + 3, 3, Color(0.45, 0.2, 0.2))
	# curly volume hair
	var h1 := def.hair
	var h2 := def.hair.lightened(0.12)
	Pix.oval(img, cx, cy - 5, 7 if racing else 6, 4, h1)
	Pix.disc(img, cx - 5, cy - 3, 3, h1)
	Pix.disc(img, cx + 5, cy - 4, 3, h1)
	Pix.disc(img, cx - 4, cy - 6, 2, h2)
	Pix.disc(img, cx + 3, cy - 7, 2, h2)
	Pix.disc(img, cx + 6, cy - 1, 2, h1)
	Pix.disc(img, cx - 6, cy - 1, 2, h1)
	Pix.disc(img, cx - 2, cy - 8, 2, h1)
	if racing:
		Pix.disc(img, cx + 1, cy - 8, 2, h2)
		Pix.put(img, cx - 7, cy + 1, h1)
		Pix.put(img, cx + 7, cy, h1)
		Pix.disc(img, cx + 4, cy + 1, 2, h1)


static func _smear(img: Image, cx: int, hip_y: int, accent: Color, f: int) -> void:
	for i in 4:
		var y: int = hip_y - 8 - i * 5
		Pix.hline(img, 4, y, 8 + f + i, Color(accent, 0.45))
		Pix.put(img, cx - 12 - i, hip_y - 16 + i, Color(accent, 0.7))


static func _downed(img: Image, def: CharacterDef, racing: bool, f: int) -> void:
	var y: int = 52 + mini(f, 2)
	Pix.capsule(img, 12, y + 6, 34, y + 8, 3, def.outfit)
	Pix.oval(img, 40, y + 4, 6, 5, def.skin)
	Pix.oval(img, 42, y + 1, 7, 4, def.hair)
	Pix.capsule(img, 10, y + 8, 18, y + 12, 2, def.outfit.darkened(0.15))
	Pix.capsule(img, 22, y + 9, 30, y + 13, 2, def.outfit.darkened(0.1))
	if racing:
		Pix.hline(img, 20, y + 6, 10, def.accent)
