class_name CombatRules
extends RefCounted


static func make_attack(kind: String, def: CharacterDef) -> Dictionary:
	match kind:
		"light":
			return _atk("light", 40.0, 96.0, -22.0, 0.28, 0.032, 0.032, 0.05, 0.21, Vector2(34, 20), 44.0, -58.0, false, def, "mid", 78.0)
		"clight":
			return _atk("clight", 36.0, 82.0, -12.0, 0.26, 0.030, 0.034, 0.05, 0.22, Vector2(36, 16), 46.0, -28.0, false, def, "mid", 58.0)
		"jlight":
			return _atk("jlight", 38.0, 74.0, 36.0, 0.24, 0.030, 0.030, 0.08, 0.26, Vector2(32, 22), 38.0, -52.0, false, def, "high", 0.0)
		"heavy":
			return _atk("heavy", 90.0, 230.0, -170.0, 0.40, 0.072, 0.078, 0.09, 0.40, Vector2(44, 24), 52.0, -56.0, false, def, "mid", 118.0)
		"cheavy":
			return _atk("cheavy", 82.0, 190.0, -16.0, 0.42, 0.068, 0.072, 0.10, 0.46, Vector2(48, 18), 52.0, -22.0, true, def, "low", 92.0)
		"jheavy":
			return _atk("jheavy", 84.0, 188.0, 70.0, 0.34, 0.064, 0.064, 0.10, 0.36, Vector2(40, 26), 44.0, -48.0, false, def, "high", 0.0)
		"special":
			return _special(def)
		"ultimate":
			return _ultimate(def)
		"dash_atk":
			return _dash_atk(def)
		"grab":
			return _atk("grab", 90.0, 240.0, -140.0, 0.55, 0.07, 0.08, 0.08, 0.42, Vector2(24, 24), 22.0, -32.0, true, def, "throw", 0.0)
	return make_attack("light", def)


static func _atk(kind: String, dmg: float, kb: float, launch: float, stun: float, stop: float, start: float, active: float, dur: float, size: Vector2, reach: float, y: float, kd: bool, def: CharacterDef, guard: String = "mid", step: float = 0.0) -> Dictionary:
	return {
		"kind": kind,
		"damage": dmg * def.attack,
		"knockback": kb,
		"launch": launch,
		"hitstun": stun,
		"blockstun": stun * 0.62,
		"hitstop": stop,
		"meter": 7.0 if kind.begins_with("l") or kind.begins_with("c") or kind.begins_with("j") else 12.0,
		"startup": start,
		"active": active,
		"duration": dur,
		"size": size,
		"reach": reach,
		"y": y,
		"knockdown": kd,
		"projectile": "",
		"juggle": launch < -80.0 or kind.begins_with("j"),
		"guard": guard,
		"step": step,
		"hits": 1,
		"hit_gap": 0.08,
		"proj_count": 0,
		"proj_speed": 520.0,
		"proj_life": 0.7,
		"proj_spread": 0.0,
		"pierce": false,
		"teleport": false,
		"explode": false,
		"freeze": false,
		"quake": false,
		"ex": false,
		"dash_spd": 0.0,
		"invuln": 0.0,
		"armor": 0,
	}


static func _special(def: CharacterDef) -> Dictionary:
	var base := _atk("special", 105.0, 240.0, -240.0, 0.44, 0.09, 0.11, 0.12, 0.50, Vector2(56, 28), 56.0, -56.0, false, def)
	base.meter = 4.0
	match def.special_id:
		"bolt":
			base.projectile = "bolt"
			base.proj_count = 1
			base.proj_speed = 640.0
			base.proj_life = 0.85
			base.damage = 92.0 * def.attack
		"wave":
			base.projectile = "wave"
			base.proj_count = 1
			base.proj_speed = 480.0
			base.hits = 2
			base.hit_gap = 0.10
			base.active = 0.10
			base.duration = 0.58
			base.damage = 64.0 * def.attack
			if def.id == "kira_bloom":
				base.hits = 3
				base.hit_gap = 0.08
				base.damage = 48.0 * def.attack
			elif def.id == "sol_renn":
				base.proj_speed = 520.0
				base.damage = 70.0 * def.attack
		"dash":
			base.reach = 118.0
			base.startup = 0.07
			base.knockback = 188.0
			base.juggle = true
			base.dash_spd = 640.0
			base.invuln = 0.08
			if def.id == "nyx_hollow" or def.id == "maeve_thorn":
				base.teleport = true
				base.invuln = 0.16
				base.dash_spd = 0.0
				base.reach = 52.0
				base.damage = 88.0 * def.attack
			elif def.id == "hoodrich_stacks":
				base.dash_spd = 540.0
				base.invuln = 0.13
				base.damage = 100.0 * def.attack
			elif def.id == "chris_xrisakis" or def.id == "dax_coil":
				base.dash_spd = 720.0
				base.step = 160.0
		"slam":
			base.y = -16.0
			base.size = Vector2(86, 24)
			base.reach = 28.0
			base.knockdown = true
			base.launch = -70.0
			base.dash_spd = 0.0
		"blast":
			base.projectile = "ice"
			base.proj_count = 1
			base.proj_speed = 400.0
			base.proj_life = 0.9
			base.freeze = true
			base.hitstun = 0.62
	return base


static func _ultimate(def: CharacterDef) -> Dictionary:
	var u := _atk("ultimate", 220.0, 420.0, -380.0, 0.75, 0.14, 0.18, 0.18, 0.72, Vector2(96, 52), 58.0, -52.0, true, def)
	u.meter = 0.0
	u.invuln = 0.18
	match def.ultimate_id:
		"nova":
			u.explode = true
			u.projectile = ""
			u.size = Vector2(168, 96)
			u.reach = 8.0
			u.y = -52.0
			u.hits = 2
			u.hit_gap = 0.12
			u.active = 0.14
			u.duration = 0.78
			u.damage = 150.0 * def.attack
			if def.id == "asha_wren" or def.id == "juniper_vale":
				u.freeze = true
				u.hitstun = 0.9
		"void":
			u.projectile = "void"
			u.proj_count = 3
			u.proj_speed = 460.0
			u.proj_spread = 140.0
			u.proj_life = 0.85
			u.pierce = true
			u.damage = 70.0 * def.attack
		"quake":
			u.quake = true
			u.projectile = ""
			u.size = Vector2(420, 30)
			u.reach = 0.0
			u.y = -18.0
			u.knockdown = true
			u.launch = -40.0
			u.hits = 2
			u.hit_gap = 0.14
			u.duration = 0.82
		_:
			u.projectile = "ult"
			u.proj_count = 1
			u.proj_speed = 420.0
			u.proj_life = 0.9
			u.dash_spd = 520.0 if def.special_id == "dash" else 0.0
			u.element = def.ultimate_id
	return u


static func _dash_atk(def: CharacterDef) -> Dictionary:
	var d := _atk("dash_atk", 78.0, 210.0, -90.0, 0.34, 0.055, 0.04, 0.08, 0.34, Vector2(42, 22), 50.0, -50.0, false, def, "mid", 210.0)
	d.dash_spd = 560.0
	d.invuln = 0.05
	d.armor = 1
	d.juggle = true
	d.meter = 10.0
	return d


static func apply_ex(atk: Dictionary, def: CharacterDef) -> Dictionary:
	atk.ex = true
	atk.damage = float(atk.damage) * 1.38
	var sz: Vector2 = atk.size
	atk.size = Vector2(sz.x * 1.18, sz.y * 1.12)
	atk.hitstun = float(atk.hitstun) * 1.12
	atk.invuln = maxf(float(atk.get("invuln", 0.0)), 0.12)
	if str(atk.get("projectile", "")) != "":
		atk.proj_count = maxi(int(atk.get("proj_count", 1)), 1) + 1
		atk.proj_speed = float(atk.get("proj_speed", 520.0)) * 1.12
	atk.hits = maxi(int(atk.get("hits", 1)), 2)
	return atk


static func combo_scale(hits: int) -> float:
	return clampf(1.0 - hits * 0.10, 0.32, 1.0)


static func juggle_scale(hits: int) -> float:
	return clampf(1.0 - float(maxi(hits - 1, 0)) * 0.11, 0.42, 1.0)


static func combo_rank(hits: int) -> String:
	if hits >= 12:
		return "RITE BREAKER"
	if hits >= 8:
		return "UNBELIEVABLE"
	if hits >= 6:
		return "EXCELLENT"
	if hits >= 4:
		return "GREAT"
	if hits >= 3:
		return "GOOD"
	return ""


static func guard_gain(kind: String) -> float:
	match kind:
		"light", "clight", "jlight":
			return 8.0
		"heavy", "cheavy", "jheavy", "dash_atk":
			return 16.0
		"special":
			return 28.0
		"ultimate":
			return 44.0
		_:
			return 10.0


static func chip_mul(kind: String, just: bool) -> float:
	var m: float = 0.07
	if kind == "special":
		m = 0.16
	elif kind == "ultimate":
		m = 0.22
	elif kind in ["heavy", "cheavy", "jheavy", "dash_atk"]:
		m = 0.10
	if just:
		m *= 0.45
	return m
