class_name ChibiFighter
extends RefCounted
## Tiny Fight-style 3/4 chibi. Guard stance, planted walk, punch windup / extend / recover.


static func paint(img: Image, def: CharacterDef, pose: String, f: int, n: int) -> void:
	var m: Dictionary = _motion(pose, f, n)
	var pal: Dictionary = _palette(def)
	var cx: int = 24 + int(m.lean) + int(m.xoff)
	var bob: int = int(m.bob)
	var squat: int = int(m.squat)
	var hip_y: int = 38 + bob + squat
	var hx: int = cx + int(m.head)
	var hy: int = hip_y - 22 + int(m.head_y)
	var blink: bool = bool(m.get("blink", false))
	var punch: int = int(m.get("punch", 0))

	if pose in ["knockdown", "defeat"]:
		_paint_down(img, pal, def, float(f) / float(maxi(n - 1, 1)))
		return

	# Far to near: rear leg, rear arm, torso, near leg, head, lead arm.
	_leg(img, cx - 5 + int(m.back_x), hip_y, int(m.back_k), int(m.get("back_lift", 0)), pal.jeans_dk, pal.shoe, pal.sock, def.style == "kit")
	_arm(img, cx - 7, hip_y - 11, int(m.rear_ax), int(m.rear_ay), pal.sleeve, pal.skin, false, punch)
	_torso(img, def, pal, cx, hip_y)
	_leg(img, cx + 4 + int(m.front_x), hip_y, int(m.front_k), int(m.get("front_lift", 0)), pal.jeans, pal.shoe, pal.sock, def.style == "kit")
	_head(img, def, pal, hx, hy, pose, blink)
	if punch == 2:
		_smear(img, cx + 6, hip_y - 12, pal.trim)
	_arm(img, cx + 6, hip_y - 11, int(m.lead_ax), int(m.lead_ay), pal.sleeve_hi, pal.skin, true, punch)
	if bool(m.get("flash", false)):
		_flash(img, cx + int(m.lead_ax) + 8, hip_y - 11 + int(m.lead_ay), pal.trim)


static func _palette(def: CharacterDef) -> Dictionary:
	var kit: bool = def.style == "kit"
	var street: bool = def.style == "street"
	var jeans: Color = Color(0.22, 0.38, 0.62) if kit else (Color(0.16, 0.22, 0.40) if street else def.outfit.darkened(0.28))
	return {
		"skin": def.skin,
		"skin_hi": def.skin.lightened(0.10),
		"skin_dk": def.skin.darkened(0.18),
		"hair": def.hair,
		"hair_hi": def.hair.lightened(0.18),
		"hair_dk": def.hair.darkened(0.22),
		"eyes": def.eyes,
		"outfit": def.outfit,
		"trim": def.trim,
		"accent": def.accent,
		"sleeve": def.outfit if (kit or street or def.style == "racing") else def.skin,
		"sleeve_hi": (def.outfit if (kit or street or def.style == "racing") else def.skin).lightened(0.10),
		"jeans": jeans,
		"jeans_dk": jeans.darkened(0.14),
		"jeans_hi": jeans.lightened(0.10),
		"shoe": Color(0.11, 0.10, 0.12),
		"shoe_hi": Color(0.28, 0.28, 0.30),
		"sock": Color(0.94, 0.94, 0.96),
		"silver": Color(0.84, 0.86, 0.90),
	}


static func _motion(pose: String, f: int, n: int) -> Dictionary:
	var u: float = float(f) / float(maxi(n - 1, 1))
	var ph: float = TAU * float(f) / float(n)
	var d := {
		"xoff": 0, "bob": 0, "lean": 0, "squat": 0, "head": 0, "head_y": 0,
		"back_x": -1, "front_x": 1, "back_k": 1, "front_k": 0,
		"back_lift": 0, "front_lift": 0,
		"rear_ax": -4, "rear_ay": 4, "lead_ax": 6, "lead_ay": -2,
		"flash": false, "blink": false, "punch": 0,
	}
	match pose:
		"idle":
			var step: int = f % 12
			d.bob = 1 if (step >= 3 and step <= 5) or (step >= 9) else 0
			d.lean = 1 if step < 6 else 0
			d.head = 1 if step < 4 else (0 if step < 8 else -1)
			d.back_x = -2 if step < 6 else 0
			d.front_x = 2 if step >= 6 else 1
			d.lead_ax = 6
			d.lead_ay = -2 if step % 6 < 3 else -1
			d.rear_ax = -5
			d.rear_ay = 3 + (1 if step % 2 == 0 else 0)
			d.blink = step == 4 or step == 10
		"block":
			d.bob = 0 if sin(ph) < 0.2 else 1
			d.squat = 1
			d.lean = 1
			d.lead_ax = 5
			d.lead_ay = 0
			d.rear_ax = -3
			d.rear_ay = 1
		"walk":
			var table := [
				{"bx": -4, "fx": 3, "bk": 0, "fk": 2, "bl": 0, "fl": 3, "bob": 0, "rax": -1, "lax": 8, "lean": 1},
				{"bx": -3, "fx": 2, "bk": 1, "fk": 1, "bl": 1, "fl": 2, "bob": 1, "rax": -2, "lax": 7, "lean": 1},
				{"bx": -1, "fx": 0, "bk": 3, "fk": 0, "bl": 4, "fl": 0, "bob": 0, "rax": -4, "lax": 5, "lean": 1},
				{"bx": 1, "fx": -2, "bk": 2, "fk": 1, "bl": 2, "fl": 1, "bob": 1, "rax": -5, "lax": 4, "lean": 0},
				{"bx": 3, "fx": -4, "bk": 0, "fk": 2, "bl": 0, "fl": 3, "bob": 0, "rax": -6, "lax": 3, "lean": 0},
				{"bx": 2, "fx": -3, "bk": 1, "fk": 1, "bl": 1, "fl": 2, "bob": 1, "rax": -5, "lax": 4, "lean": 0},
				{"bx": 0, "fx": -1, "bk": 0, "fk": 3, "bl": 0, "fl": 4, "bob": 0, "rax": -3, "lax": 6, "lean": 1},
				{"bx": -2, "fx": 1, "bk": 1, "fk": 2, "bl": 1, "fl": 1, "bob": 1, "rax": -2, "lax": 7, "lean": 1},
			]
			var s: Dictionary = table[f % 8]
			d.back_x = int(s.bx)
			d.front_x = int(s.fx)
			d.back_k = int(s.bk)
			d.front_k = int(s.fk)
			d.back_lift = int(s.bl)
			d.front_lift = int(s.fl)
			d.bob = int(s.bob)
			d.rear_ax = int(s.rax)
			d.lead_ax = int(s.lax)
			d.lean = int(s.lean)
			d.xoff = 1 if (f % 8) == 2 or (f % 8) == 6 else 0
			d.head = -d.lean
		"run":
			var rs: int = f % 6
			d.bob = 0 if rs % 2 == 0 else 2
			d.xoff = 2
			d.lean = 2
			d.back_x = -5 if rs < 3 else 4
			d.front_x = 5 if rs < 3 else -4
			d.back_k = 0 if rs < 3 else 3
			d.front_k = 3 if rs < 3 else 0
			d.back_lift = 0 if rs < 3 else 5
			d.front_lift = 5 if rs < 3 else 0
			d.rear_ax = -7
			d.rear_ay = -1
			d.lead_ax = 10
			d.lead_ay = -4
		"backdash":
			d.xoff = -4
			d.lean = -2
			d.bob = 1
			d.back_x = 3
			d.front_x = -2
			d.back_lift = 2
			d.rear_ax = 2
			d.lead_ax = -2
		"prejump", "crouch", "land", "getup":
			d.squat = 4 if pose == "land" and u < 0.4 else (3 if pose != "prejump" else 2)
			d.back_x = -3
			d.front_x = 3
			d.back_k = 3
			d.front_k = 3
			d.lead_ay = 2
			d.rear_ay = 5
			d.lead_ax = 4
			d.rear_ax = -5
		"jump":
			d.bob = -4
			d.squat = -1
			d.back_x = -2
			d.front_x = 3
			d.back_k = 1
			d.front_k = 2
			d.back_lift = 6
			d.front_lift = 4
			d.rear_ay = -7
			d.lead_ay = -6
			d.lead_ax = 4
			d.rear_ax = -3
		"jlight", "jheavy":
			d.bob = -4
			d.squat = -1
			d.back_lift = 5
			d.front_lift = 3
			d.rear_ay = -6
			d.punch = 1 if u < 0.22 else (2 if u < 0.58 else 3)
			d.lead_ax = int(lerpf(2.0, 15.0, smoothstep(0.12, 0.48, u)))
			d.lead_ay = int(lerpf(-2.0, -6.0, smoothstep(0.12, 0.48, u)))
			d.flash = u > 0.28 and u < 0.62
		"light", "clight", "heavy", "cheavy", "grab":
			var wind: float = 0.22 if pose.begins_with("h") else 0.18
			var ext_end: float = 0.58 if pose.begins_with("h") else 0.52
			if u < wind:
				d.punch = 1
				d.xoff = -1
				d.lean = -1
				d.lead_ax = -1
				d.lead_ay = 2
				d.rear_ax = -6
				d.rear_ay = 2
				d.head = -1
			elif u < ext_end:
				var ext: float = smoothstep(wind, ext_end - 0.06, u)
				d.punch = 2
				d.xoff = int(ext * 5.0)
				d.lean = int(ext * 3.0)
				d.lead_ax = int(lerpf(4.0, 16.0, ext))
				d.lead_ay = int(lerpf(-1.0, -4.0, ext))
				d.rear_ax = int(lerpf(-4.0, -7.0, ext))
				d.rear_ay = 3
				d.front_x = int(ext * 2.0)
				d.flash = ext > 0.55
				d.head = 1
			else:
				var rec: float = smoothstep(ext_end, 1.0, u)
				d.punch = 3
				d.xoff = int((1.0 - rec) * 3.0)
				d.lean = 1
				d.lead_ax = int(lerpf(14.0, 7.0, rec))
				d.lead_ay = int(lerpf(-3.0, -1.0, rec))
				d.rear_ax = -4
			if pose.begins_with("c"):
				d.squat = 3
				d.lead_ay += 5
			if pose == "grab":
				d.lead_ay = 1
				d.rear_ax = 4
				d.rear_ay = 0
		"special", "ultimate":
			var sp: float = smoothstep(0.10, 0.52, u)
			d.punch = 2 if sp > 0.4 and u < 0.85 else 1
			d.xoff = int(sp * 6.0)
			d.lean = int(sp * 3.0)
			d.lead_ax = int(lerpf(4.0, 16.0, sp))
			d.rear_ax = int(lerpf(-2.0, 8.0, sp))
			d.lead_ay = int(lerpf(-2.0, -6.0, sp))
			d.flash = sp > 0.4 and u < 0.85
		"hit", "block_hit":
			d.xoff = 3
			d.lean = 2
			d.head = 2
			d.head_y = 1
			d.lead_ax = 2
			d.rear_ax = 3
			d.blink = true
		"air_hit", "launch":
			d.xoff = 2
			d.lean = 2
			d.bob = -2
			d.back_lift = 4
			d.front_lift = 5
			d.lead_ax = 3
			d.rear_ay = -5
			d.blink = true
		"victory":
			d.bob = 0 if sin(ph * 2.0) < 0.0 else 1
			d.lead_ay = int(lerpf(0.0, -16.0, minf(u * 1.4, 1.0)))
			d.lead_ax = 2
			d.rear_ax = -3
			d.rear_ay = 2
		_:
			pass
	return d


static func _leg(img: Image, hx: int, hy: int, knee: int, lift: int, jeans: Color, shoe: Color, sock: Color, socks: bool) -> void:
	var ky: int = hy + 6 + knee
	var fx: int = hx + (1 if knee < 2 else 0)
	var fy: int = 53 - lift
	Pix.rect(img, hx - 3, hy - 1, 6, 4, jeans)
	Pix.capsule(img, hx, hy, hx - 1, ky, 3, jeans)
	Pix.put(img, hx + 1, hy + 1, jeans.lightened(0.12))
	Pix.capsule(img, hx - 1, ky, fx, fy - 3, 2, jeans.darkened(0.10))
	Pix.put(img, hx, ky, jeans.darkened(0.22))
	if socks:
		Pix.rect(img, fx - 2, fy - 5, 5, 3, sock)
		Pix.hline(img, fx - 2, fy - 5, 5, Color(0.78, 0.16, 0.22))
	Pix.rect(img, fx - 2, fy - 2, 7, 3, shoe)
	Pix.rect(img, fx - 1, fy - 2, 5, 1, shoe.lightened(0.22))
	Pix.hline(img, fx + 3, fy - 1, 2, Color(0.86, 0.86, 0.88))
	Pix.hline(img, fx - 2, fy + 1, 7, shoe.darkened(0.25))


static func _arm(img: Image, sx: int, sy: int, dx: int, dy: int, sleeve: Color, skin: Color, lead: bool, punch: int) -> void:
	var mx: int = sx + dx / 2
	var my: int = sy + dy / 2 + (1 if lead else 2)
	var hx: int = sx + dx
	var hy: int = sy + dy
	var thick: int = 3 if lead else 2
	Pix.capsule(img, sx, sy, mx, my, thick, sleeve)
	Pix.capsule(img, mx, my, hx, hy, 2, sleeve.darkened(0.08))
	if lead:
		Pix.put(img, sx + 1, sy, sleeve.lightened(0.14))
	var fist_r: int = 3 if punch == 2 and lead else 2
	Pix.disc(img, hx, hy, fist_r, skin)
	Pix.disc(img, hx + (1 if lead else 0), hy, 1, skin.darkened(0.16))
	if lead and punch == 2:
		Pix.put(img, hx + 2, hy - 1, skin.lightened(0.12))
		Pix.put(img, hx + 2, hy + 1, skin.darkened(0.2))


static func _torso(img: Image, def: CharacterDef, pal: Dictionary, cx: int, hip_y: int) -> void:
	var top: int = hip_y - 14
	if def.style == "kit":
		Pix.rect(img, cx - 6, top + 4, 13, 11, pal.trim)
		for row in 11:
			var band: Color = pal.outfit if (row % 2) == 0 else pal.trim
			Pix.hline(img, cx - 6, top + 4 + row, 13, band)
		Pix.rect(img, cx - 6, top, 13, 5, pal.accent)
		Pix.rect(img, cx - 4, top + 2, 9, 2, pal.accent.lightened(0.14))
		Pix.put(img, cx, top + 3, pal.trim)
		Pix.rect(img, cx - 9, top + 4, 4, 6, pal.outfit)
		Pix.rect(img, cx + 6, top + 4, 4, 6, pal.outfit.lightened(0.08))
		Pix.put(img, cx + 8, top + 5, pal.outfit.lightened(0.16))
		Pix.rect(img, cx - 6, hip_y - 2, 13, 3, pal.jeans)
		Pix.hline(img, cx - 4, hip_y - 2, 9, pal.jeans_hi)
		# necklace
		Pix.put(img, cx - 2, top + 5, Color(0.08, 0.07, 0.07))
		Pix.put(img, cx, top + 6, Color(0.12, 0.10, 0.10))
		Pix.put(img, cx + 2, top + 5, Color(0.08, 0.07, 0.07))
		Pix.put(img, cx, top + 7, pal.silver.darkened(0.2))
	elif def.style == "street":
		var hoodie: Color = pal.outfit
		var hoodie_hi: Color = pal.outfit.lightened(0.12)
		var hoodie_dk: Color = pal.outfit.darkened(0.14)
		Pix.rect(img, cx - 7, top + 3, 15, 12, hoodie)
		Pix.rect(img, cx - 6, top + 4, 13, 9, hoodie_hi)
		Pix.rect(img, cx - 10, top + 4, 5, 8, hoodie)
		Pix.rect(img, cx + 6, top + 4, 5, 8, hoodie_hi)
		# hood around the neck
		Pix.rect(img, cx - 5, top, 11, 5, hoodie_dk)
		Pix.hline(img, cx - 4, top + 3, 9, pal.skin_dk)
		Pix.put(img, cx - 3, top + 4, pal.silver)
		Pix.put(img, cx + 3, top + 4, pal.silver)
		# drawstrings
		Pix.vline(img, cx - 3, top + 5, 4, pal.trim.darkened(0.15))
		Pix.vline(img, cx + 3, top + 5, 4, pal.trim.darkened(0.15))
		Pix.put(img, cx - 3, top + 9, pal.trim)
		Pix.put(img, cx + 3, top + 9, pal.trim)
		# G print, kept clear of the pocket seam
		Pix.hline(img, cx - 1, top + 6, 3, pal.trim)
		Pix.vline(img, cx - 1, top + 6, 4, pal.trim)
		Pix.hline(img, cx - 1, top + 9, 3, pal.trim)
		Pix.put(img, cx + 1, top + 8, pal.trim)
		Pix.hline(img, cx - 5, top + 11, 11, hoodie_dk)
		# chain
		Pix.hline(img, cx - 2, top + 5, 5, pal.silver.darkened(0.08))
		Pix.rect(img, cx - 6, hip_y - 2, 13, 3, pal.jeans)
		Pix.hline(img, cx - 4, hip_y - 2, 9, pal.jeans_hi)
	elif def.style == "racing":
		Pix.rect(img, cx - 5, top, 11, 14, pal.outfit)
		Pix.vline(img, cx, top + 2, 10, pal.accent)
		Pix.rect(img, cx - 5, top, 11, 3, pal.accent.darkened(0.2))
	else:
		Pix.rect(img, cx - 5, top, 11, 14, pal.outfit)
		Pix.rect(img, cx - 4, top + 1, 9, 5, pal.outfit.lightened(0.1))
		Pix.hline(img, cx - 4, top + 6, 9, pal.trim)


static func _head(img: Image, def: CharacterDef, pal: Dictionary, cx: int, cy: int, pose: String, blink: bool) -> void:
	# neck
	Pix.rect(img, cx - 1, cy + 6, 4, 4, pal.skin_dk)
	# ears
	Pix.disc(img, cx - 7, cy + 2, 2, pal.skin_dk)
	Pix.disc(img, cx + 7, cy + 2, 2, pal.skin)
	Pix.put(img, cx - 7, cy + 2, pal.skin)
	# skull + jaw
	Pix.oval(img, cx, cy + 1, 7, 8, pal.skin)
	Pix.oval(img, cx + 1, cy + 2, 5, 6, pal.skin_hi)
	Pix.rect(img, cx - 3, cy + 5, 7, 3, pal.skin)
	Pix.hline(img, cx - 2, cy + 7, 5, pal.skin_dk)
	# brows
	var brow_y: int = cy - 1 if pose != "hit" else cy
	Pix.hline(img, cx - 4, brow_y, 4, pal.hair_dk)
	Pix.hline(img, cx + 1, brow_y, 4, pal.hair_dk)
	if pose == "hit":
		Pix.put(img, cx - 4, brow_y - 1, pal.hair_dk)
		Pix.put(img, cx + 4, brow_y - 1, pal.hair_dk)
	# eyes
	if blink or pose == "hit":
		Pix.hline(img, cx - 4, cy + 1, 3, pal.hair_dk)
		Pix.hline(img, cx + 2, cy + 1, 3, pal.hair_dk)
	else:
		Pix.rect(img, cx - 4, cy, 3, 3, Color(0.97, 0.96, 0.93))
		Pix.rect(img, cx + 2, cy, 3, 3, Color(0.97, 0.96, 0.93))
		Pix.put(img, cx - 3, cy + 1, pal.eyes)
		Pix.put(img, cx + 3, cy + 1, pal.eyes)
		Pix.put(img, cx - 4, cy + 1, Color(0.18, 0.14, 0.12))
		Pix.put(img, cx + 2, cy + 1, Color(0.18, 0.14, 0.12))
		Pix.put(img, cx - 2, cy, Color(1, 1, 1, 0.85))
		Pix.put(img, cx + 4, cy, Color(1, 1, 1, 0.85))
	# nose + mouth
	Pix.put(img, cx, cy + 3, pal.skin_dk)
	if pose == "hit":
		Pix.hline(img, cx - 2, cy + 4, 5, Color(0.52, 0.16, 0.16))
	elif pose == "victory":
		Pix.hline(img, cx - 1, cy + 5, 3, pal.skin_dk)
		Pix.put(img, cx - 2, cy + 4, pal.skin_dk)
		Pix.put(img, cx + 2, cy + 4, pal.skin_dk)
	else:
		Pix.hline(img, cx - 1, cy + 5, 3, pal.skin_dk)
		Pix.put(img, cx, cy + 6, pal.skin_dk)
	if def.style == "street":
		_hair_short(img, cx, cy, pal)
		# hoop earring on the near ear
		Pix.put(img, cx + 8, cy + 3, pal.silver)
		Pix.put(img, cx + 8, cy + 4, pal.silver.darkened(0.18))
		Pix.put(img, cx + 7, cy + 4, pal.silver)
	else:
		_hair_curly(img, cx, cy, pal)


static func _hair_curly(img: Image, cx: int, cy: int, pal: Dictionary) -> void:
	Pix.oval(img, cx, cy - 5, 8, 6, pal.hair)
	var curls: Array[Vector2i] = [
		Vector2i(-7, -3), Vector2i(-5, -6), Vector2i(-2, -8), Vector2i(1, -8),
		Vector2i(4, -7), Vector2i(7, -4), Vector2i(6, -1), Vector2i(-6, 0),
		Vector2i(-4, -7), Vector2i(3, -6), Vector2i(0, -7), Vector2i(5, -3),
		Vector2i(-7, -1), Vector2i(7, -2), Vector2i(-1, -9), Vector2i(2, -9),
	]
	for d in curls:
		var col: Color = pal.hair_hi if ((d.x + d.y) & 1) == 0 else pal.hair_dk
		Pix.disc(img, cx + d.x, cy + d.y, 2, col)
	Pix.disc(img, cx - 6, cy - 4, 2, pal.hair)
	Pix.disc(img, cx + 6, cy - 5, 2, pal.hair)
	# bangs over the brow
	Pix.hline(img, cx - 4, cy - 3, 3, pal.hair_dk)
	Pix.hline(img, cx + 2, cy - 3, 3, pal.hair)


static func _hair_short(img: Image, cx: int, cy: int, pal: Dictionary) -> void:
	Pix.oval(img, cx, cy - 5, 8, 5, pal.hair)
	Pix.rect(img, cx - 7, cy - 8, 15, 6, pal.hair)
	Pix.hline(img, cx - 5, cy - 8, 11, pal.hair_hi)
	# fade / sideburns stay off the eyes
	Pix.rect(img, cx - 8, cy - 2, 2, 5, pal.hair_dk)
	Pix.rect(img, cx + 6, cy - 2, 2, 4, pal.hair)
	Pix.hline(img, cx - 7, cy + 2, 2, pal.hair_dk)
	Pix.put(img, cx - 5, cy - 3, pal.hair_hi)


static func _smear(img: Image, x: int, y: int, col: Color) -> void:
	for i in 5:
		Pix.hline(img, x - 2 - i, y - 1 + (i % 3) - 1, 4 + i, Color(col, 0.18 + float(i) * 0.08))
		Pix.put(img, x - 4 - i, y + (i % 2), Color(1, 0.95, 0.7, 0.35))


static func _flash(img: Image, x: int, y: int, col: Color) -> void:
	Pix.disc(img, x, y, 3, Color(1, 0.96, 0.78, 0.9))
	Pix.disc(img, x + 1, y, 1, Color(1, 1, 1, 0.95))
	Pix.hline(img, x - 6, y, 6, Color(col, 0.5))
	Pix.vline(img, x, y - 4, 4, Color(1, 1, 1, 0.45))
	Pix.put(img, x + 4, y - 2, Color(1, 1, 1, 0.7))
	Pix.put(img, x + 5, y + 1, Color(col, 0.6))


static func _paint_down(img: Image, pal: Dictionary, def: CharacterDef, u: float) -> void:
	var y: int = int(lerpf(28.0, 42.0, clampf(u * 1.2, 0.0, 1.0)))
	Pix.capsule(img, 8, y + 4, 28, y + 5, 5, pal.outfit)
	Pix.oval(img, 32, y + 2, 7, 6, pal.skin)
	Pix.oval(img, 33, y, 8, 5, pal.hair)
	Pix.capsule(img, 6, y + 6, 16, y + 11, 2, pal.jeans)
	Pix.capsule(img, 18, y + 6, 26, y + 11, 2, pal.jeans)
	Pix.rect(img, 14, y + 10, 6, 2, pal.shoe)
	if def.style == "kit":
		Pix.hline(img, 12, y + 4, 10, pal.trim)
		Pix.hline(img, 12, y + 5, 10, pal.outfit)
