class_name ChibiFighter
extends RefCounted
## Tiny Fight-style 3/4 chibi brawler. Guard stance, planted walk, punch windup.


static func paint(img: Image, def: CharacterDef, pose: String, f: int, n: int) -> void:
	var m: Dictionary = _motion(pose, f, n)
	var pal: Dictionary = _palette(def)
	var cx: int = 24 + int(m.lean) + int(m.xoff)
	var bob: int = int(m.bob)
	var squat: int = int(m.squat)
	var hip_y: int = 38 + bob + squat
	var hx: int = cx + int(m.head)
	var hy: int = hip_y - 22 + int(m.head_y)

	if pose in ["knockdown", "defeat"]:
		_paint_down(img, pal, def, float(f) / float(maxi(n - 1, 1)))
		return

	# Draw back-to-front so the lead fist sits on top.
	_leg(img, cx - 5 + int(m.back_x), hip_y, int(m.back_k), pal.jeans_dk, pal.shoe, pal.sock, def.style == "kit")
	_leg(img, cx + 4 + int(m.front_x), hip_y, int(m.front_k), pal.jeans, pal.shoe, pal.sock, def.style == "kit")
	_arm(img, cx - 6, hip_y - 10, int(m.rear_ax), int(m.rear_ay), pal.sleeve, pal.skin, false)
	_torso(img, def, pal, cx, hip_y)
	_head(img, def, pal, hx, hy, pose)
	_arm(img, cx + 5, hip_y - 10, int(m.lead_ax), int(m.lead_ay), pal.sleeve_hi, pal.skin, true)
	if bool(m.get("flash", false)):
		_flash(img, cx + int(m.lead_ax) + 8, hip_y - 10 + int(m.lead_ay), pal.trim)


static func _palette(def: CharacterDef) -> Dictionary:
	var kit: bool = def.style == "kit"
	var street: bool = def.style == "street"
	var jeans: Color = Color(0.20, 0.34, 0.58) if kit else (Color(0.14, 0.20, 0.38) if street else def.outfit.darkened(0.28))
	return {
		"skin": def.skin,
		"skin_dk": def.skin.darkened(0.16),
		"hair": def.hair,
		"hair_hi": def.hair.lightened(0.14),
		"hair_dk": def.hair.darkened(0.18),
		"eyes": def.eyes,
		"outfit": def.outfit,
		"trim": def.trim,
		"accent": def.accent,
		"sleeve": def.outfit if (kit or street or def.style == "racing") else def.skin,
		"sleeve_hi": (def.outfit if (kit or street or def.style == "racing") else def.skin).lightened(0.08),
		"jeans": jeans,
		"jeans_dk": jeans.darkened(0.12),
		"shoe": Color(0.10, 0.10, 0.12),
		"sock": Color(0.93, 0.93, 0.95),
		"silver": Color(0.80, 0.82, 0.86),
	}


static func _motion(pose: String, f: int, n: int) -> Dictionary:
	var u: float = float(f) / float(maxi(n - 1, 1))
	var ph: float = TAU * float(f) / float(n)
	var d := {
		"xoff": 0, "bob": 0, "lean": 0, "squat": 0, "head": 0, "head_y": 0,
		"back_x": -1, "front_x": 1, "back_k": 1, "front_k": 0,
		"rear_ax": -3, "rear_ay": 3, "lead_ax": 6, "lead_ay": -2,
		"flash": false,
	}
	match pose:
		"idle", "block":
			d.bob = 0 if sin(ph) < 0.15 else 1
			d.lead_ay = -2 + (1 if pose == "block" else 0)
			d.lead_ax = 5 if pose == "block" else 6
			d.rear_ax = -4 if pose == "block" else -3
			if pose == "block":
				d.squat = 1
				d.lean = 1
		"walk":
			var step: int = f % 8
			var table := [
				{"bx": -3, "fx": 3, "bk": 0, "fk": 2, "bob": 0, "rax": -1, "lax": 7},
				{"bx": -2, "fx": 2, "bk": 1, "fk": 1, "bob": 1, "rax": -2, "lax": 6},
				{"bx": 0, "fx": 0, "bk": 2, "fk": 0, "bob": 0, "rax": -3, "lax": 5},
				{"bx": 2, "fx": -2, "bk": 1, "fk": 1, "bob": 1, "rax": -4, "lax": 4},
				{"bx": 3, "fx": -3, "bk": 0, "fk": 2, "bob": 0, "rax": -5, "lax": 3},
				{"bx": 2, "fx": -2, "bk": 1, "fk": 1, "bob": 1, "rax": -4, "lax": 4},
				{"bx": 0, "fx": 0, "bk": 2, "fk": 0, "bob": 0, "rax": -3, "lax": 5},
				{"bx": -2, "fx": 2, "bk": 1, "fk": 1, "bob": 1, "rax": -2, "lax": 6},
			]
			var s: Dictionary = table[step]
			d.back_x = int(s.bx)
			d.front_x = int(s.fx)
			d.back_k = int(s.bk)
			d.front_k = int(s.fk)
			d.bob = int(s.bob)
			d.rear_ax = int(s.rax)
			d.lead_ax = int(s.lax)
			d.lean = 1 if step < 4 else 0
			d.xoff = 1 if (step == 1 or step == 5) else 0
		"run":
			var rs: int = f % 6
			d.bob = 0 if rs % 2 == 0 else 2
			d.xoff = 2
			d.lean = 2
			d.back_x = -4 if rs < 3 else 3
			d.front_x = 4 if rs < 3 else -3
			d.back_k = 0 if rs < 3 else 2
			d.front_k = 2 if rs < 3 else 0
			d.rear_ax = -6
			d.lead_ax = 9
			d.lead_ay = -4
		"backdash":
			d.xoff = -4
			d.lean = -2
			d.bob = 1
			d.back_x = 3
			d.front_x = -2
			d.rear_ax = 2
			d.lead_ax = -2
		"prejump", "crouch", "land", "getup":
			d.squat = 3 if pose != "prejump" else 2
			d.back_x = -3
			d.front_x = 3
			d.back_k = 3
			d.front_k = 3
			d.lead_ay = 2
			d.rear_ay = 4
			if pose == "land":
				d.squat = 4 if u < 0.4 else 2
		"jump", "jlight", "jheavy":
			d.bob = -3
			d.squat = -1
			d.back_x = -2
			d.front_x = 3
			d.back_k = 0
			d.front_k = 1
			d.rear_ay = -6
			d.lead_ay = -5
			d.lead_ax = 8 if pose != "jump" else 4
			if pose != "jump":
				d.flash = u > 0.28 and u < 0.62
				d.lead_ax = int(lerpf(2.0, 14.0, smoothstep(0.15, 0.5, u)))
		"light", "clight", "heavy", "cheavy", "grab":
			var strike: float = smoothstep(0.18, 0.48, u)
			var rec: float = smoothstep(0.55, 1.0, u)
			var ext: float = strike * (1.0 - rec)
			d.xoff = int(ext * 4.0)
			d.lean = int(ext * 3.0)
			d.lead_ax = int(lerpf(4.0, 16.0, ext))
			d.lead_ay = int(lerpf(-1.0, -4.0, ext))
			d.rear_ax = int(lerpf(-3.0, -6.0, ext))
			d.front_x = int(ext * 2.0)
			d.flash = ext > 0.55
			if pose.begins_with("c"):
				d.squat = 3
				d.lead_ay = int(lerpf(4.0, 6.0, ext))
		"special", "ultimate":
			var sp: float = smoothstep(0.12, 0.55, u)
			d.xoff = int(sp * 5.0)
			d.lean = int(sp * 3.0)
			d.lead_ax = int(lerpf(4.0, 15.0, sp))
			d.rear_ax = int(lerpf(-2.0, 8.0, sp))
			d.lead_ay = int(lerpf(-2.0, -6.0, sp))
			d.flash = sp > 0.4 and u < 0.85
		"hit", "block_hit", "air_hit", "launch":
			d.xoff = 3
			d.lean = 2
			d.head = 2
			d.lead_ax = 2
			d.rear_ax = 3
		"victory":
			d.bob = 0 if sin(ph * 2.0) < 0.0 else 1
			d.lead_ay = int(lerpf(0.0, -14.0, minf(u * 1.4, 1.0)))
			d.lead_ax = 2
		_:
			pass
	return d


static func _leg(img: Image, hx: int, hy: int, knee: int, jeans: Color, shoe: Color, sock: Color, socks: bool) -> void:
	Pix.rect(img, hx - 3, hy - 1, 6, 4, jeans)
	var ky: int = hy + 6 + knee
	var fx: int = hx + (1 if knee < 2 else 0)
	var fy: int = 52
	Pix.capsule(img, hx, hy, hx - 1, ky, 3, jeans)
	Pix.capsule(img, hx - 1, ky, fx, fy - 2, 2, jeans.darkened(0.08))
	if socks:
		Pix.rect(img, fx - 2, fy - 4, 5, 3, sock)
		Pix.hline(img, fx - 2, fy - 4, 5, Color(0.78, 0.16, 0.22))
	Pix.rect(img, fx - 2, fy - 1, 6, 3, shoe)
	Pix.hline(img, fx - 2, fy + 1, 6, shoe.lightened(0.35))


static func _arm(img: Image, sx: int, sy: int, dx: int, dy: int, sleeve: Color, skin: Color, lead: bool) -> void:
	var mx: int = sx + dx / 2
	var my: int = sy + dy / 2 + (1 if lead else 2)
	var hx: int = sx + dx
	var hy: int = sy + dy
	Pix.capsule(img, sx, sy, mx, my, 2, sleeve)
	Pix.capsule(img, mx, my, hx, hy, 2, sleeve.darkened(0.06))
	Pix.disc(img, hx, hy, 2, skin)
	Pix.disc(img, hx + (1 if lead else 0), hy, 1, skin.darkened(0.12))


static func _torso(img: Image, def: CharacterDef, pal: Dictionary, cx: int, hip_y: int) -> void:
	var top: int = hip_y - 14
	if def.style == "kit":
		Pix.rect(img, cx - 6, top + 4, 13, 11, pal.trim)
		for row in 11:
			var band: Color = pal.outfit if (row % 2) == 0 else pal.trim
			Pix.hline(img, cx - 6, top + 4 + row, 13, band)
		Pix.rect(img, cx - 6, top, 13, 5, pal.accent)
		Pix.rect(img, cx - 4, top + 2, 9, 2, pal.accent.lightened(0.12))
		Pix.put(img, cx, top + 3, pal.trim)
		Pix.rect(img, cx - 9, top + 4, 4, 5, pal.outfit)
		Pix.rect(img, cx + 6, top + 4, 4, 5, pal.outfit.lightened(0.06))
		Pix.rect(img, cx - 6, hip_y - 2, 13, 3, pal.jeans)
		Pix.put(img, cx - 2, top + 5, Color(0.06, 0.05, 0.05))
		Pix.put(img, cx, top + 6, Color(0.08, 0.07, 0.07))
		Pix.put(img, cx + 2, top + 5, Color(0.06, 0.05, 0.05))
	elif def.style == "street":
		Pix.rect(img, cx - 7, top + 3, 15, 12, pal.outfit)
		Pix.rect(img, cx - 6, top + 4, 13, 9, pal.outfit.lightened(0.10))
		Pix.rect(img, cx - 9, top + 4, 4, 8, pal.outfit)
		Pix.rect(img, cx + 6, top + 4, 4, 8, pal.outfit.lightened(0.06))
		Pix.rect(img, cx - 4, top + 1, 9, 4, pal.outfit.darkened(0.08))
		Pix.hline(img, cx - 3, top + 3, 7, pal.skin_dk)
		Pix.hline(img, cx - 2, top + 4, 5, pal.silver.darkened(0.1))
		# HoodRich mark
		Pix.hline(img, cx - 4, top + 7, 6, pal.trim)
		Pix.hline(img, cx - 3, top + 8, 5, pal.trim)
		Pix.put(img, cx - 4, top + 6, pal.accent)
		Pix.put(img, cx + 2, top + 6, pal.accent)
		Pix.rect(img, cx - 6, hip_y - 2, 13, 3, pal.jeans)
	elif def.style == "racing":
		Pix.rect(img, cx - 5, top, 11, 14, pal.outfit)
		Pix.vline(img, cx, top + 2, 10, pal.accent)
		Pix.rect(img, cx - 5, top, 11, 3, pal.accent.darkened(0.2))
	else:
		Pix.rect(img, cx - 5, top, 11, 14, pal.outfit)
		Pix.rect(img, cx - 4, top + 1, 9, 5, pal.outfit.lightened(0.1))
		Pix.hline(img, cx - 4, top + 6, 9, pal.trim)


static func _head(img: Image, def: CharacterDef, pal: Dictionary, cx: int, cy: int, pose: String) -> void:
	Pix.rect(img, cx - 1, cy + 6, 4, 3, pal.skin_dk)
	Pix.oval(img, cx, cy + 1, 7, 8, pal.skin)
	Pix.oval(img, cx + 1, cy + 2, 5, 6, pal.skin.lightened(0.05))
	# brows + eyes
	Pix.hline(img, cx - 4, cy - 1, 4, pal.hair_dk)
	Pix.hline(img, cx + 1, cy - 1, 4, pal.hair_dk)
	Pix.put(img, cx - 3, cy + 1, Color(0.96, 0.94, 0.9))
	Pix.put(img, cx + 3, cy + 1, Color(0.96, 0.94, 0.9))
	Pix.put(img, cx - 3, cy + 1, pal.eyes)
	Pix.put(img, cx + 3, cy + 1, pal.eyes)
	Pix.put(img, cx, cy + 2, pal.skin_dk)
	if pose == "hit":
		Pix.hline(img, cx - 2, cy + 3, 5, Color(0.5, 0.18, 0.18))
	else:
		Pix.hline(img, cx - 1, cy + 4, 3, pal.skin_dk)
		Pix.put(img, cx, cy + 5, pal.skin_dk)
	if def.style == "street":
		_hair_short(img, cx, cy, pal)
		Pix.put(img, cx + 6, cy + 2, pal.silver)
		Pix.put(img, cx + 6, cy + 3, pal.silver.darkened(0.2))
	else:
		_hair_curly(img, cx, cy, pal)


static func _hair_curly(img: Image, cx: int, cy: int, pal: Dictionary) -> void:
	Pix.oval(img, cx, cy - 5, 8, 6, pal.hair)
	for d in [Vector2i(-6, -3), Vector2i(6, -4), Vector2i(-4, -7), Vector2i(3, -8), Vector2i(0, -8), Vector2i(5, -1), Vector2i(-6, -1), Vector2i(-2, -6), Vector2i(4, -6)]:
		Pix.disc(img, cx + d.x, cy + d.y, 2, pal.hair_hi if (d.x + d.y) & 1 == 0 else pal.hair_dk)
	Pix.disc(img, cx - 5, cy - 4, 2, pal.hair)
	Pix.disc(img, cx + 5, cy - 5, 2, pal.hair)


static func _hair_short(img: Image, cx: int, cy: int, pal: Dictionary) -> void:
	Pix.oval(img, cx, cy - 5, 8, 5, pal.hair)
	Pix.rect(img, cx - 7, cy - 6, 15, 5, pal.hair)
	Pix.rect(img, cx - 7, cy - 2, 4, 5, pal.hair_dk)
	Pix.hline(img, cx - 5, cy - 1, 4, pal.hair_dk)


static func _flash(img: Image, x: int, y: int, col: Color) -> void:
	Pix.disc(img, x, y, 2, Color(1, 0.96, 0.8, 0.9))
	Pix.hline(img, x - 5, y, 5, Color(col, 0.45))
	Pix.put(img, x + 3, y - 1, Color(1, 1, 1, 0.7))


static func _paint_down(img: Image, pal: Dictionary, def: CharacterDef, u: float) -> void:
	var y: int = int(lerpf(28.0, 40.0, clampf(u * 1.2, 0.0, 1.0)))
	Pix.capsule(img, 10, y + 4, 26, y + 5, 4, pal.outfit)
	Pix.oval(img, 30, y + 2, 6, 5, pal.skin)
	Pix.oval(img, 31, y, 7, 4, pal.hair)
	Pix.capsule(img, 8, y + 6, 16, y + 10, 2, pal.jeans)
	Pix.capsule(img, 18, y + 6, 24, y + 10, 2, pal.jeans)
