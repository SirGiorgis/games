class_name ChibiFighter
extends RefCounted
## Tiny Fight-style 3/4 chibi. Guard stance, planted walk, punch windup / extend / recover.


static func paint(img: Image, def: CharacterDef, pose: String, f: int, n: int) -> void:
	var ripped := pose.ends_with("_rip")
	if ripped:
		pose = pose.substr(0, pose.length() - 4)
	var dripped := pose.ends_with("_drip")
	if dripped:
		pose = pose.substr(0, pose.length() - 5)
	var m: Dictionary = _motion(pose, f, n, def)
	var pal: Dictionary = _palette(def)
	var cx: int = 24 + int(m.lean) + int(m.xoff)
	var bob: int = int(m.bob)
	var squat: int = int(m.squat)
	var hip_y: int = 38 + bob + squat
	var hx: int = cx + int(m.head)
	var hy: int = hip_y - 22 + int(m.head_y)
	var blink: bool = bool(m.get("blink", false))
	var punch: int = int(m.get("punch", 0))
	var u: float = float(f) / float(maxi(n - 1, 1))
	if pose == "ultimate" and def.ultimate_id == "flex" and u > 0.28:
		ripped = true
	if pose == "ultimate" and def.ultimate_id == "drip" and u > 0.28:
		dripped = true

	if pose in ["knockdown", "defeat"]:
		_paint_down(img, pal, def, u, ripped, dripped)
		return

	# Far to near: rear leg, rear arm, torso, near leg, head, lead arm.
	var fat: int = 3 if def.style == "tee" else (2 if def.build == "heavy" else 0)
	_leg(img, cx - 5 - fat + int(m.back_x), hip_y, int(m.back_k), int(m.get("back_lift", 0)), pal.jeans_dk, pal.shoe, pal.sock, def.style == "kit")
	_arm(img, cx - 7 - fat, hip_y - 11, int(m.rear_ax), int(m.rear_ay), pal.sleeve, pal.skin, false, punch, fat > 0)
	_torso(img, def, pal, cx, hip_y, ripped, dripped)
	_leg(img, cx + 4 + fat + int(m.front_x), hip_y, int(m.front_k), int(m.get("front_lift", 0)), pal.jeans, pal.shoe, pal.sock, def.style == "kit")
	_head(img, def, pal, hx, hy, pose, blink, dripped)
	if punch == 2:
		_smear(img, cx + 6, hip_y - 12, pal.trim)
	_arm(img, cx + 6, hip_y - 11, int(m.lead_ax), int(m.lead_ay), pal.sleeve_hi, pal.skin, true, punch, fat > 0)
	if def.style == "tee":
		_watch(img, cx + 6 + int(m.lead_ax), hip_y - 11 + int(m.lead_ay))
	if str(m.get("prop", "")) == "bottle":
		_bottle(img, cx + 6 + int(m.lead_ax), hip_y - 11 + int(m.lead_ay) - 4, pal)
	if bool(m.get("flash", false)):
		_flash(img, cx + int(m.lead_ax) + 8, hip_y - 11 + int(m.lead_ay), pal.trim)
	if pose == "ultimate" and def.ultimate_id == "fart":
		_gas_cloud(img, cx - 6, hip_y + 2, f)
	if pose == "ultimate" and def.ultimate_id == "flex" and ripped:
		_shreds(img, cx, hip_y - 6, f)
	if pose == "ultimate" and def.ultimate_id == "cotton":
		_cotton_toss(img, cx, hip_y, f)
	if pose == "ultimate" and def.ultimate_id == "drip":
		_drip_notes(img, cx, hip_y, f, dripped)


static func _palette(def: CharacterDef) -> Dictionary:
	var kit: bool = def.style == "kit"
	var street: bool = def.style == "street"
	var bare: bool = def.style == "bare"
	var tee: bool = def.style == "tee"
	var shades: bool = def.style == "shades"
	var cargo: bool = def.style == "cargo"
	var trap: bool = def.style == "trap"
	var jeans: Color = Color(0.10, 0.10, 0.12) if trap else (Color(0.12, 0.16, 0.24) if cargo else (Color(0.10, 0.10, 0.12) if (bare or tee or shades) else (Color(0.22, 0.38, 0.62) if kit else (Color(0.16, 0.22, 0.40) if street else def.outfit.darkened(0.28)))))
	var shoe: Color = Color(0.92, 0.90, 0.86) if cargo else Color(0.11, 0.10, 0.12)
	var sleeved: bool = kit or street or tee or shades or cargo or trap or def.style == "racing"
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
		"sleeve": def.outfit if sleeved else def.skin,
		"sleeve_hi": (def.outfit if sleeved else def.skin).lightened(0.10),
		"jeans": jeans,
		"jeans_dk": jeans.darkened(0.14),
		"jeans_hi": jeans.lightened(0.10),
		"shoe": shoe,
		"shoe_hi": shoe.lightened(0.12),
		"sock": Color(0.94, 0.94, 0.96),
		"silver": Color(0.84, 0.86, 0.90),
	}


static func _motion(pose: String, f: int, n: int, def: CharacterDef = null) -> Dictionary:
	var u: float = float(f) / float(maxi(n - 1, 1))
	var ph: float = TAU * float(f) / float(n)
	var d := {
		"xoff": 0, "bob": 0, "lean": 0, "squat": 0, "head": 0, "head_y": 0,
		"back_x": -1, "front_x": 1, "back_k": 1, "front_k": 0,
		"back_lift": 0, "front_lift": 0,
		"rear_ax": -4, "rear_ay": 4, "lead_ax": 6, "lead_ay": -2,
		"flash": false, "blink": false, "punch": 0, "prop": "",
	}
	var uid: String = def.ultimate_id if def else ""
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
			if def and def.style == "tee":
				d.squat = 0
				d.lead_ax = -2
				d.lead_ay = 6
				d.rear_ax = 7
				d.rear_ay = 5
			elif def and def.style == "trap":
				d.lean = 1
				d.lead_ax = 2
				d.lead_ay = 4
				d.rear_ax = -3
				d.rear_ay = 4
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
			if pose == "ultimate" and uid == "fart":
				d.punch = 0
				d.squat = 3
				d.lean = -1
				d.head = -1
				d.head_y = 1
				d.xoff = -2
				d.lead_ax = -2
				d.lead_ay = 6
				d.rear_ax = -8
				d.rear_ay = 5
				d.flash = u > 0.28 and u < 0.78
			elif pose == "ultimate" and uid == "vodka":
				d.punch = 0
				d.squat = 1
				d.lean = 1
				d.head = 1
				d.head_y = 1
				d.lead_ax = 3
				d.lead_ay = int(lerpf(2.0, -13.0, smoothstep(0.08, 0.42, u)))
				d.rear_ax = -5
				d.rear_ay = 3
				d.prop = "bottle"
				d.flash = u > 0.35 and u < 0.72
			elif pose == "ultimate" and uid == "dempsey":
				var weave: float = sin(ph * 3.0)
				d.punch = 2 if weave > 0.0 else 1
				d.xoff = int(weave * 5.0)
				d.lean = int(weave * 3.0)
				d.squat = 1
				d.head = int(-weave)
				d.lead_ax = 14 if weave > 0.0 else 8
				d.lead_ay = -4 if weave > 0.0 else 2
				d.rear_ax = -8 if weave > 0.0 else 6
				d.rear_ay = 2
				d.back_x = int(-weave * 3.0)
				d.front_x = int(weave * 3.0)
				d.flash = true
			elif pose == "ultimate" and uid == "grid":
				d.punch = 1
				d.xoff = int(smoothstep(0.12, 0.5, u) * 4.0)
				d.lean = 2
				d.lead_ax = int(lerpf(4.0, 14.0, smoothstep(0.12, 0.55, u)))
				d.lead_ay = -3
				d.rear_ax = -6
				d.rear_ay = 1
				d.flash = u > 0.28 and u < 0.8
			elif pose == "ultimate" and uid == "flex":
				d.punch = 0
				d.squat = 1 if u < 0.32 else 0
				d.head_y = -1 if u > 0.32 else 0
				if u < 0.32:
					d.lead_ax = 2
					d.lead_ay = 5
					d.rear_ax = -2
					d.rear_ay = 5
				else:
					d.lead_ax = 11
					d.lead_ay = -9
					d.rear_ax = -11
					d.rear_ay = -8
					d.flash = true
			elif pose == "ultimate" and uid == "drip":
				d.punch = 0
				d.squat = 1 if u < 0.32 else 0
				d.head_y = -1 if u > 0.32 else 0
				d.lean = 1
				if u < 0.32:
					# stacking the chain
					d.lead_ax = 1
					d.lead_ay = 3
					d.rear_ax = -1
					d.rear_ay = 4
				else:
					# swagger arms out
					d.lead_ax = 10
					d.lead_ay = -6
					d.rear_ax = -10
					d.rear_ay = -5
					d.flash = true
			elif pose == "ultimate" and uid == "cotton":
				d.punch = 0
				d.squat = 2
				d.lean = 1
				d.head = 1
				d.head_y = 2
				d.lead_ax = 5
				d.lead_ay = 9
				d.rear_ax = -5
				d.rear_ay = 7
				d.flash = u > 0.18 and u < 0.88
			else:
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
			if def and (def.style == "shades" or def.style == "trap"):
				d.lead_ax = 11
				d.lead_ay = -9
				d.rear_ax = -11
				d.rear_ay = -8
				d.head_y = -1
			else:
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


static func _arm(img: Image, sx: int, sy: int, dx: int, dy: int, sleeve: Color, skin: Color, lead: bool, punch: int, heavy: bool = false) -> void:
	var mx: int = sx + dx / 2
	var my: int = sy + dy / 2 + (1 if lead else 2)
	var hx: int = sx + dx
	var hy: int = sy + dy
	var thick: int = (4 if heavy else 3) if lead else (3 if heavy else 2)
	Pix.capsule(img, sx, sy, mx, my, thick, sleeve)
	Pix.capsule(img, mx, my, hx, hy, 2 if not heavy else 3, sleeve.darkened(0.08))
	if lead:
		Pix.put(img, sx + 1, sy, sleeve.lightened(0.14))
	var fist_r: int = 3 if punch == 2 and lead else 2
	Pix.disc(img, hx, hy, fist_r, skin)
	Pix.disc(img, hx + (1 if lead else 0), hy, 1, skin.darkened(0.16))
	if lead and punch == 2:
		Pix.put(img, hx + 2, hy - 1, skin.lightened(0.12))
		Pix.put(img, hx + 2, hy + 1, skin.darkened(0.2))


static func _torso(img: Image, def: CharacterDef, pal: Dictionary, cx: int, hip_y: int, ripped: bool = false, dripped: bool = false) -> void:
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
	elif def.style == "bare":
		Pix.rect(img, cx - 8, top + 2, 17, 11, pal.skin)
		Pix.rect(img, cx - 6, top + 3, 13, 10, pal.skin_hi)
		Pix.rect(img, cx - 9, top + 3, 4, 7, pal.skin_dk)
		Pix.rect(img, cx + 6, top + 3, 4, 7, pal.skin)
		Pix.hline(img, cx - 5, top + 6, 4, pal.skin_dk)
		Pix.hline(img, cx + 2, top + 6, 4, pal.skin_dk)
		Pix.put(img, cx, top + 8, pal.skin_dk)
		Pix.put(img, cx - 2, top + 10, pal.skin_dk)
		Pix.put(img, cx + 2, top + 10, pal.skin_dk)
		Pix.rect(img, cx - 6, hip_y - 3, 13, 4, pal.jeans)
		Pix.hline(img, cx - 5, hip_y - 3, 11, pal.jeans_hi)
	elif def.style == "tee":
		var shirt: Color = pal.outfit
		var shirt_hi: Color = pal.outfit.lightened(0.10)
		var shirt_dk: Color = pal.outfit.darkened(0.12)
		Pix.oval(img, cx, hip_y - 3, 11, 8, shirt)
		Pix.rect(img, cx - 10, top + 3, 21, 12, shirt)
		Pix.rect(img, cx - 8, top + 4, 17, 9, shirt_hi)
		Pix.rect(img, cx - 12, top + 4, 5, 8, shirt)
		Pix.rect(img, cx + 8, top + 4, 5, 8, shirt_hi)
		Pix.rect(img, cx - 5, top, 11, 4, shirt_dk)
		Pix.hline(img, cx - 3, top + 3, 7, pal.skin_dk)
		# pocket only — original, no brand
		Pix.rect(img, cx + 1, top + 6, 5, 5, shirt_dk)
		Pix.hline(img, cx + 1, top + 6, 5, pal.trim.darkened(0.2))
		Pix.put(img, cx + 3, top + 8, pal.trim)
		Pix.rect(img, cx - 9, hip_y - 3, 19, 5, pal.jeans)
		Pix.hline(img, cx - 7, hip_y - 3, 15, pal.jeans_hi)
	elif def.style == "shades":
		_hoodie_torso(img, pal, cx, hip_y, ripped)
	elif def.style == "cargo":
		var shirt: Color = pal.outfit
		var shirt_hi: Color = pal.outfit.lightened(0.08)
		var shirt_dk: Color = pal.outfit.darkened(0.10)
		Pix.rect(img, cx - 8, top + 3, 17, 11, shirt)
		Pix.rect(img, cx - 7, top + 4, 15, 9, shirt_hi)
		Pix.rect(img, cx - 11, top + 4, 5, 7, shirt)
		Pix.rect(img, cx + 7, top + 4, 5, 7, shirt_hi)
		Pix.rect(img, cx - 4, top, 9, 4, shirt_dk)
		# v-neck — original, no marks
		Pix.put(img, cx, top + 2, pal.skin)
		Pix.put(img, cx - 1, top + 3, pal.skin)
		Pix.put(img, cx + 1, top + 3, pal.skin)
		Pix.hline(img, cx - 2, top + 4, 5, pal.skin_dk)
		Pix.rect(img, cx - 7, hip_y - 3, 15, 5, pal.jeans)
		Pix.hline(img, cx - 6, hip_y - 3, 13, pal.jeans_hi)
		# cargo flap
		Pix.rect(img, cx + 2, hip_y - 1, 5, 3, pal.jeans_dk)
		Pix.hline(img, cx + 2, hip_y - 1, 5, pal.jeans_hi)
	elif def.style == "trap":
		_trap_torso(img, pal, cx, hip_y, dripped)
	elif def.style == "racing":
		Pix.rect(img, cx - 5, top, 11, 14, pal.outfit)
		Pix.vline(img, cx, top + 2, 10, pal.accent)
		Pix.rect(img, cx - 5, top, 11, 3, pal.accent.darkened(0.2))
	else:
		Pix.rect(img, cx - 5, top, 11, 14, pal.outfit)
		Pix.rect(img, cx - 4, top + 1, 9, 5, pal.outfit.lightened(0.1))
		Pix.hline(img, cx - 4, top + 6, 9, pal.trim)


static func _head(img: Image, def: CharacterDef, pal: Dictionary, cx: int, cy: int, pose: String, blink: bool, dripped: bool = false) -> void:
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
	# brows — trap crop gets a thicker set
	var brow_y: int = cy - 1 if pose != "hit" else cy
	Pix.hline(img, cx - 4, brow_y, 4, pal.hair_dk)
	Pix.hline(img, cx + 1, brow_y, 4, pal.hair_dk)
	if def.style == "trap":
		Pix.hline(img, cx - 4, brow_y - 1, 4, pal.hair)
		Pix.hline(img, cx + 1, brow_y - 1, 4, pal.hair)
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
	if def.style == "tee":
		var frame := Color(0.12, 0.12, 0.14)
		Pix.rect(img, cx - 5, cy - 1, 5, 5, Color(0, 0, 0, 0))
		Pix.hline(img, cx - 5, cy - 1, 5, frame)
		Pix.hline(img, cx - 5, cy + 3, 5, frame)
		Pix.vline(img, cx - 5, cy - 1, 5, frame)
		Pix.vline(img, cx - 1, cy - 1, 5, frame)
		Pix.hline(img, cx + 1, cy - 1, 5, frame)
		Pix.hline(img, cx + 1, cy + 3, 5, frame)
		Pix.vline(img, cx + 1, cy - 1, 5, frame)
		Pix.vline(img, cx + 5, cy - 1, 5, frame)
		Pix.hline(img, cx - 1, cy + 1, 3, frame)
	# nose + mouth
	Pix.put(img, cx, cy + 3, pal.skin_dk)
	if pose == "hit":
		Pix.hline(img, cx - 2, cy + 4, 5, Color(0.52, 0.16, 0.16))
	elif pose == "victory":
		Pix.hline(img, cx - 1, cy + 5, 3, pal.skin_dk)
		Pix.put(img, cx - 2, cy + 4, pal.skin_dk)
		Pix.put(img, cx + 2, cy + 4, pal.skin_dk)
	elif pose == "ultimate" and def.ultimate_id == "vodka":
		Pix.rect(img, cx - 1, cy + 5, 3, 2, Color(0.38, 0.14, 0.16))
		Pix.put(img, cx, cy + 6, Color(0.22, 0.10, 0.12))
	elif pose == "ultimate" and def.ultimate_id == "flex":
		Pix.rect(img, cx - 1, cy + 5, 3, 2, pal.skin_dk)
		Pix.put(img, cx, cy + 6, Color(0.28, 0.12, 0.12))
	elif def.style == "trap" and dripped:
		# gold grill — original, no artist mark
		Pix.rect(img, cx - 2, cy + 5, 5, 2, pal.trim)
		Pix.put(img, cx, cy + 6, pal.accent)
		Pix.put(img, cx - 1, cy + 5, pal.accent.lightened(0.12))
		Pix.put(img, cx + 1, cy + 5, pal.trim.darkened(0.12))
	elif def.style == "tee":
		Pix.hline(img, cx - 2, cy + 5, 5, pal.skin_dk)
		Pix.put(img, cx - 2, cy + 4, pal.skin_dk)
		Pix.put(img, cx + 2, cy + 4, pal.skin_dk)
	elif def.style == "shades":
		Pix.rect(img, cx - 1, cy + 5, 3, 2, pal.skin_dk)
		Pix.put(img, cx, cy + 6, Color(0.22, 0.12, 0.12))
	else:
		Pix.hline(img, cx - 1, cy + 5, 3, pal.skin_dk)
		Pix.put(img, cx, cy + 6, pal.skin_dk)
	if def.style == "bare":
		_hair_mako(img, cx, cy, pal)
	elif def.style == "street":
		_hair_short(img, cx, cy, pal)
		# hoop earring on the near ear
		Pix.put(img, cx + 8, cy + 3, pal.silver)
		Pix.put(img, cx + 8, cy + 4, pal.silver.darkened(0.18))
		Pix.put(img, cx + 7, cy + 4, pal.silver)
	elif def.style == "tee":
		_hair_short(img, cx, cy, pal)
	elif def.style == "shades":
		_hair_curly(img, cx, cy, pal)
		_shades(img, cx, cy)
	elif def.style == "cargo":
		_hair_buzz(img, cx, cy, pal)
	elif def.style == "trap":
		_hair_crop(img, cx, cy, pal)
		if dripped:
			_trap_shades(img, cx, cy)
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


static func _hair_mako(img: Image, cx: int, cy: int, pal: Dictionary) -> void:
	Pix.oval(img, cx, cy - 4, 8, 6, pal.hair)
	Pix.rect(img, cx - 8, cy - 8, 16, 7, pal.hair)
	# longer sides like the photo
	Pix.rect(img, cx - 8, cy - 1, 3, 9, pal.hair_dk)
	Pix.rect(img, cx + 6, cy - 1, 3, 9, pal.hair)
	Pix.put(img, cx - 7, cy + 7, pal.hair_dk)
	Pix.put(img, cx + 7, cy + 7, pal.hair)
	# bangs sit above the eyes
	Pix.hline(img, cx - 5, cy - 4, 5, pal.hair_dk)
	Pix.hline(img, cx + 1, cy - 4, 5, pal.hair)
	Pix.put(img, cx - 1, cy - 4, pal.hair_hi)
	Pix.put(img, cx + 3, cy - 5, pal.hair_hi)


static func _hair_buzz(img: Image, cx: int, cy: int, pal: Dictionary) -> void:
	# Tight stubble on the crown. Scalp stays visible. No cap, no logo.
	Pix.hline(img, cx - 5, cy - 7, 11, pal.hair_dk)
	Pix.hline(img, cx - 6, cy - 6, 13, pal.hair)
	Pix.hline(img, cx - 4, cy - 5, 9, pal.hair_dk)
	Pix.put(img, cx - 7, cy - 5, pal.hair_dk)
	Pix.put(img, cx + 7, cy - 5, pal.hair)
	Pix.put(img, cx - 1, cy - 7, pal.hair_hi)
	Pix.put(img, cx + 2, cy - 6, pal.hair_hi)


static func _cotton_toss(img: Image, cx: int, hip_y: int, f: int) -> void:
	var fluff := Color(0.96, 0.94, 0.88)
	var spots: Array[Vector2i] = [
		Vector2i(-12, 6), Vector2i(10, 8), Vector2i(-6, 12), Vector2i(14, 4), Vector2i(2, 14), Vector2i(-14, 10),
	]
	for i in spots.size():
		var p: Vector2i = spots[i]
		var oy: int = int(sin(float(f * 2 + i) * 0.55) * 2.0)
		Pix.disc(img, cx + p.x, hip_y + p.y + oy, 2, fluff)
		Pix.put(img, cx + p.x, hip_y + p.y + oy - 1, Color(1, 1, 1))


static func _hair_short(img: Image, cx: int, cy: int, pal: Dictionary) -> void:
	Pix.oval(img, cx, cy - 5, 8, 5, pal.hair)
	Pix.rect(img, cx - 7, cy - 8, 15, 6, pal.hair)
	Pix.hline(img, cx - 5, cy - 8, 11, pal.hair_hi)
	# fade / sideburns stay off the eyes
	Pix.rect(img, cx - 8, cy - 2, 2, 5, pal.hair_dk)
	Pix.rect(img, cx + 6, cy - 2, 2, 4, pal.hair)
	Pix.hline(img, cx - 7, cy + 2, 2, pal.hair_dk)
	Pix.put(img, cx - 5, cy - 3, pal.hair_hi)


static func _hair_crop(img: Image, cx: int, cy: int, pal: Dictionary) -> void:
	# Tight curly crop with a fade — photo-like, shorter than Giannis curls.
	Pix.oval(img, cx, cy - 5, 8, 5, pal.hair)
	Pix.rect(img, cx - 7, cy - 8, 15, 6, pal.hair)
	var tufts: Array[Vector2i] = [
		Vector2i(-6, -4), Vector2i(-3, -7), Vector2i(0, -8), Vector2i(3, -7),
		Vector2i(6, -4), Vector2i(-5, -6), Vector2i(2, -6), Vector2i(5, -2),
		Vector2i(-4, -2), Vector2i(1, -9),
	]
	for d in tufts:
		var col: Color = pal.hair_hi if ((d.x + d.y) & 1) == 0 else pal.hair_dk
		Pix.disc(img, cx + d.x, cy + d.y, 2, col)
	Pix.rect(img, cx - 8, cy - 2, 2, 4, pal.hair_dk)
	Pix.rect(img, cx + 6, cy - 2, 2, 4, pal.hair)
	Pix.hline(img, cx - 4, cy - 3, 3, pal.hair_dk)
	Pix.hline(img, cx + 2, cy - 3, 3, pal.hair)


static func _trap_torso(img: Image, pal: Dictionary, cx: int, hip_y: int, dripped: bool) -> void:
	var top: int = hip_y - 14
	var tee: Color = pal.outfit
	var tee_hi: Color = pal.outfit.lightened(0.10)
	var tee_dk: Color = pal.outfit.darkened(0.12)
	var gold: Color = pal.trim
	var gold_hi: Color = pal.accent
	if dripped:
		# black puffer over the tee — original quilt, no brand
		Pix.rect(img, cx - 9, top + 2, 19, 13, tee)
		Pix.rect(img, cx - 8, top + 3, 17, 10, tee_hi)
		Pix.rect(img, cx - 12, top + 4, 5, 8, tee)
		Pix.rect(img, cx + 8, top + 4, 5, 8, tee_hi)
		Pix.rect(img, cx - 5, top, 11, 4, tee_dk)
		Pix.hline(img, cx - 3, top + 3, 7, pal.skin_dk)
		for row in 3:
			Pix.hline(img, cx - 6, top + 6 + row * 3, 13, tee_dk)
		Pix.vline(img, cx - 2, top + 5, 9, tee_dk)
		Pix.vline(img, cx + 2, top + 5, 9, tee_dk)
		# stacked chains
		Pix.hline(img, cx - 3, top + 5, 7, gold)
		Pix.put(img, cx, top + 6, gold_hi)
		Pix.hline(img, cx - 2, top + 7, 5, gold.darkened(0.12))
		Pix.put(img, cx, top + 8, gold_hi)
		Pix.rect(img, cx - 1, top + 9, 3, 2, gold)
		Pix.rect(img, cx - 7, hip_y - 2, 15, 3, pal.jeans)
		Pix.hline(img, cx - 5, hip_y - 2, 11, pal.jeans_hi)
		return
	# black crew tee + thin gold chain
	Pix.rect(img, cx - 7, top + 3, 15, 12, tee)
	Pix.rect(img, cx - 6, top + 4, 13, 9, tee_hi)
	Pix.rect(img, cx - 10, top + 4, 5, 8, tee)
	Pix.rect(img, cx + 6, top + 4, 5, 8, tee_hi)
	Pix.rect(img, cx - 5, top, 11, 4, tee_dk)
	Pix.hline(img, cx - 3, top + 3, 7, pal.skin_dk)
	Pix.hline(img, cx - 2, top + 5, 5, gold.darkened(0.08))
	Pix.put(img, cx, top + 6, gold)
	Pix.put(img, cx, top + 7, gold_hi)
	Pix.rect(img, cx - 6, hip_y - 2, 13, 3, pal.jeans)
	Pix.hline(img, cx - 4, hip_y - 2, 9, pal.jeans_hi)


static func _trap_shades(img: Image, cx: int, cy: int) -> void:
	# Dark wrap with gold rim — original, not a brand or cyan/pink split.
	var frame := Color(0.10, 0.09, 0.08)
	var lens := Color(0.12, 0.11, 0.10)
	var gold := Color(0.83, 0.70, 0.40)
	Pix.hline(img, cx - 7, cy, 15, gold)
	Pix.rect(img, cx - 6, cy, 6, 3, lens)
	Pix.rect(img, cx + 1, cy, 6, 3, lens.lightened(0.06))
	Pix.vline(img, cx - 6, cy, 3, gold)
	Pix.vline(img, cx, cy, 3, gold)
	Pix.vline(img, cx + 6, cy, 3, gold)
	Pix.hline(img, cx - 6, cy + 3, 6, frame)
	Pix.hline(img, cx + 1, cy + 3, 6, frame)
	Pix.put(img, cx - 5, cy, Color(0.95, 0.88, 0.62, 0.55))
	Pix.put(img, cx + 2, cy, Color(1, 1, 1, 0.28))
	Pix.put(img, cx - 7, cy + 1, gold)
	Pix.put(img, cx + 7, cy + 1, gold)


static func _drip_notes(img: Image, cx: int, hip_y: int, f: int, dripped: bool) -> void:
	var gold := Color(0.90, 0.78, 0.38, 0.85)
	var hi := Color(1.0, 0.94, 0.62, 0.9)
	var spots: Array[Vector2i] = [
		Vector2i(-12, -8), Vector2i(11, -10), Vector2i(-8, 4), Vector2i(10, 2), Vector2i(0, -14),
	]
	for i in spots.size():
		var p: Vector2i = spots[i]
		var oy: int = int(sin(float(f * 2 + i) * 0.7) * 2.0)
		Pix.put(img, cx + p.x, hip_y + p.y + oy, gold if (i % 2) == 0 else hi)
		if dripped:
			Pix.put(img, cx + p.x + 1, hip_y + p.y + oy - 2, hi)


static func _hoodie_torso(img: Image, pal: Dictionary, cx: int, hip_y: int, ripped: bool) -> void:
	var top: int = hip_y - 14
	var hoodie: Color = pal.outfit
	var hoodie_hi: Color = pal.outfit.lightened(0.12)
	var hoodie_dk: Color = pal.outfit.darkened(0.14)
	if ripped:
		Pix.rect(img, cx - 7, top + 3, 15, 12, pal.skin)
		Pix.rect(img, cx - 5, top + 4, 11, 9, pal.skin_hi)
		Pix.hline(img, cx - 2, top + 7, 5, pal.skin_dk)
		Pix.hline(img, cx - 2, top + 10, 5, pal.skin_dk)
		Pix.vline(img, cx, top + 6, 6, pal.skin_dk)
		Pix.put(img, cx - 3, top + 8, pal.skin_dk)
		Pix.put(img, cx + 3, top + 8, pal.skin_dk)
		Pix.rect(img, cx - 10, top + 3, 4, 10, hoodie)
		Pix.rect(img, cx + 7, top + 3, 4, 10, hoodie_hi)
		Pix.put(img, cx - 7, top + 6, hoodie_dk)
		Pix.put(img, cx + 7, top + 6, hoodie)
		Pix.rect(img, cx - 5, top, 11, 4, hoodie_dk)
		Pix.hline(img, cx - 3, top + 3, 7, pal.skin_dk)
		Pix.rect(img, cx - 6, hip_y - 3, 13, 4, pal.jeans)
		Pix.hline(img, cx - 4, hip_y - 3, 9, pal.jeans_hi)
		return
	Pix.rect(img, cx - 7, top + 3, 15, 12, hoodie)
	Pix.rect(img, cx - 6, top + 4, 13, 9, hoodie_hi)
	Pix.rect(img, cx - 10, top + 4, 5, 8, hoodie)
	Pix.rect(img, cx + 6, top + 4, 5, 8, hoodie_hi)
	Pix.rect(img, cx - 5, top, 11, 5, hoodie_dk)
	Pix.hline(img, cx - 4, top + 3, 9, pal.skin_dk)
	Pix.vline(img, cx - 3, top + 5, 4, pal.trim.darkened(0.15))
	Pix.vline(img, cx + 3, top + 5, 4, pal.trim.darkened(0.15))
	Pix.put(img, cx - 3, top + 9, pal.trim)
	Pix.put(img, cx + 3, top + 9, pal.trim)
	Pix.hline(img, cx - 5, top + 11, 11, hoodie_dk)
	Pix.rect(img, cx - 6, hip_y - 2, 13, 3, pal.jeans)
	Pix.hline(img, cx - 4, hip_y - 2, 9, pal.jeans_hi)


static func _shades(img: Image, cx: int, cy: int) -> void:
	var frame := Color(0.08, 0.08, 0.10)
	var l1 := Color(0.28, 0.82, 0.92)
	var l2 := Color(0.92, 0.38, 0.72)
	Pix.hline(img, cx - 7, cy, 15, frame)
	Pix.rect(img, cx - 6, cy, 6, 3, l1)
	Pix.rect(img, cx + 1, cy, 6, 3, l2)
	Pix.vline(img, cx - 6, cy, 3, frame)
	Pix.vline(img, cx, cy, 3, frame)
	Pix.vline(img, cx + 6, cy, 3, frame)
	Pix.hline(img, cx - 6, cy + 3, 6, frame)
	Pix.hline(img, cx + 1, cy + 3, 6, frame)
	Pix.put(img, cx - 5, cy, Color(1, 1, 1, 0.7))
	Pix.put(img, cx + 2, cy, Color(1, 1, 1, 0.45))
	Pix.put(img, cx - 7, cy + 1, frame)
	Pix.put(img, cx + 7, cy + 1, frame)


static func _shreds(img: Image, cx: int, cy: int, f: int) -> void:
	var navy := Color(0.14, 0.20, 0.28, 0.85)
	var bits: Array[Vector2i] = [
		Vector2i(-8, -4), Vector2i(7, -6), Vector2i(-4, 2), Vector2i(5, 1),
		Vector2i(-10, 0), Vector2i(9, -2),
	]
	for i in bits.size():
		var b: Vector2i = bits[i]
		var ox: int = b.x + ((f + i) % 3) - 1
		Pix.rect(img, cx + ox, cy + b.y, 2, 3, navy)
		Pix.put(img, cx + ox, cy + b.y, Color(0.85, 0.88, 0.92, 0.5))


static func _watch(img: Image, x: int, y: int) -> void:
	Pix.hline(img, x - 1, y - 2, 3, Color(0.10, 0.10, 0.12))
	Pix.put(img, x, y - 2, Color(0.18, 0.52, 0.58))


static func _gas_cloud(img: Image, x: int, y: int, f: int) -> void:
	var a: float = 0.35 + 0.12 * sin(float(f) * 0.9)
	var g1 := Color(0.42, 0.78, 0.38, a)
	var g2 := Color(0.55, 0.62, 0.22, a * 0.85)
	Pix.disc(img, x, y, 4, g1)
	Pix.disc(img, x - 5, y - 2, 3, g2)
	Pix.disc(img, x + 3, y - 3, 3, g1)
	Pix.disc(img, x - 2, y + 3, 2, Color(0.62, 0.72, 0.28, a))
	Pix.put(img, x + 1, y - 1, Color(0.78, 0.92, 0.45, 0.7))


static func _bottle(img: Image, x: int, y: int, pal: Dictionary) -> void:
	var glass := Color(0.72, 0.88, 0.82, 0.95)
	var glass_dk := Color(0.42, 0.62, 0.58)
	var fill := Color(0.92, 0.94, 0.96)
	var cap: Color = pal.silver
	Pix.rect(img, x - 1, y - 8, 3, 3, cap)
	Pix.put(img, x, y - 9, cap.lightened(0.12))
	Pix.rect(img, x - 1, y - 5, 3, 2, glass_dk)
	Pix.rect(img, x - 2, y - 3, 5, 7, glass)
	Pix.rect(img, x - 1, y - 2, 3, 5, fill)
	Pix.hline(img, x - 1, y + 1, 3, Color(0.78, 0.80, 0.84))
	Pix.put(img, x + 1, y - 2, Color(1, 1, 1, 0.7))
	Pix.hline(img, x - 2, y + 4, 5, glass_dk)


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


static func _paint_down(img: Image, pal: Dictionary, def: CharacterDef, u: float, ripped: bool = false, dripped: bool = false) -> void:
	var y: int = int(lerpf(28.0, 42.0, clampf(u * 1.2, 0.0, 1.0)))
	Pix.capsule(img, 8, y + 4, 28, y + 5, 5, pal.outfit if not ripped else pal.skin)
	Pix.oval(img, 32, y + 2, 7, 6, pal.skin)
	Pix.oval(img, 33, y, 8, 5, pal.hair)
	Pix.capsule(img, 6, y + 6, 16, y + 11, 2, pal.jeans)
	Pix.capsule(img, 18, y + 6, 26, y + 11, 2, pal.jeans)
	Pix.rect(img, 14, y + 10, 6, 2, pal.shoe)
	if def.style == "kit":
		Pix.hline(img, 12, y + 4, 10, pal.trim)
		Pix.hline(img, 12, y + 5, 10, pal.outfit)
	elif def.style == "tee":
		Pix.hline(img, 10, y + 4, 14, pal.outfit)
		Pix.hline(img, 10, y + 5, 14, pal.outfit.darkened(0.1))
	elif def.style == "shades":
		Pix.hline(img, 10, y + 3, 14, pal.outfit)
		if ripped:
			Pix.hline(img, 14, y + 5, 8, pal.skin)
	elif def.style == "cargo":
		Pix.hline(img, 10, y + 4, 14, pal.outfit)
		Pix.hline(img, 10, y + 6, 12, pal.jeans)
	elif def.style == "trap":
		Pix.hline(img, 10, y + 4, 14, pal.outfit)
		if dripped:
			Pix.hline(img, 12, y + 5, 10, pal.trim.darkened(0.2))
			Pix.put(img, 16, y + 6, pal.accent)
