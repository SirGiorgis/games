class_name CombatRules
extends RefCounted


static func make_attack(kind: String, def: CharacterDef) -> Dictionary:
	match kind:
		"light":
			return _atk("light", 34.0, 70.0, -10.0, 0.22, 0.042, 0.058, 0.04, 0.36, Vector2(30, 18), 38.0, -58.0, false, def, "mid", 24.0)
		"clight":
			return _atk("clight", 32.0, 64.0, -8.0, 0.20, 0.040, 0.062, 0.04, 0.38, Vector2(32, 16), 40.0, -28.0, false, def, "mid", 18.0)
		"jlight":
			return _atk("jlight", 32.0, 62.0, 28.0, 0.18, 0.038, 0.050, 0.06, 0.32, Vector2(30, 20), 34.0, -52.0, false, def, "high", 0.0)
		"heavy":
			return _atk("heavy", 88.0, 220.0, -160.0, 0.36, 0.078, 0.100, 0.08, 0.56, Vector2(42, 24), 50.0, -56.0, false, def, "mid", 72.0)
		"cheavy":
			return _atk("cheavy", 80.0, 180.0, -12.0, 0.34, 0.074, 0.096, 0.08, 0.58, Vector2(46, 18), 50.0, -22.0, true, def, "low", 54.0)
		"jheavy":
			return _atk("jheavy", 80.0, 176.0, 58.0, 0.28, 0.070, 0.086, 0.08, 0.42, Vector2(38, 24), 42.0, -48.0, false, def, "high", 0.0)
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
		"blockstun": stun * 0.46,
		"hitstop": stop,
		"meter": 3.0 if kind in ["light", "clight", "jlight"] else 8.0,
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
		"heal": 0.0,
		"atk_boost": 1.0,
		"atk_boost_t": 0.0,
		"poison": false,
		"poison_t": 0.0,
		"poison_dps": 0.0,
		"stun": false,
		"cotton": false,
	}


static func _special(def: CharacterDef) -> Dictionary:
	var base := _atk("special", 105.0, 240.0, -240.0, 0.44, 0.09, 0.12, 0.10, 0.62, Vector2(56, 28), 56.0, -56.0, false, def)
	base.meter = 3.0
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
			base.reach = 110.0
			base.startup = 0.10
			base.knockback = 188.0
			base.juggle = true
			base.dash_spd = 560.0
			base.invuln = 0.04
			base.duration = 0.64
			if def.id == "nyx_hollow" or def.id == "maeve_thorn":
				base.teleport = true
				base.invuln = 0.12
				base.dash_spd = 0.0
				base.reach = 52.0
				base.damage = 88.0 * def.attack
			elif def.id == "hoodrich_stacks":
				base.dash_spd = 500.0
				base.invuln = 0.06
				base.damage = 100.0 * def.attack
			elif def.id == "chris_xrisakis" or def.id == "dax_coil":
				base.dash_spd = 640.0
				base.step = 120.0
			elif def.id == "giannis":
				base.dash_spd = 580.0
				base.startup = 0.11
			elif def.id == "vag":
				base.dash_spd = 600.0
				base.startup = 0.09
		"slam":
			base.y = -16.0
			base.size = Vector2(86, 24)
			base.reach = 28.0
			base.knockdown = true
			base.launch = -70.0
			base.dash_spd = 0.0
			if def.id == "mako":
				base.damage = 118.0 * def.attack
				base.armor = 1
				base.size = Vector2(96, 28)
			elif def.id == "fogas":
				base.damage = 128.0 * def.attack
				base.armor = 2
				base.size = Vector2(110, 32)
				base.startup = 0.14
				base.duration = 0.62
				base.knockback = 210.0
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
		"grid":
			u.projectile = "car"
			u.proj_count = 3
			u.proj_speed = 760.0
			u.proj_life = 0.95
			u.pierce = true
			u.dash_spd = 220.0
			u.invuln = 0.12
			u.damage = 62.0 * def.attack
			u.knockback = 280.0
			u.launch = -160.0
			u.hitstun = 0.42
			u.size = Vector2(48, 28)
			u.reach = 36.0
			u.y = -28.0
			u.startup = 0.12
			u.active = 0.08
			u.duration = 0.62
			u.knockdown = false
		"dempsey":
			u.projectile = ""
			u.quake = false
			u.hits = 6
			u.hit_gap = 0.05
			u.dash_spd = 520.0
			u.invuln = 0.20
			u.armor = 2
			u.damage = 38.0 * def.attack
			u.knockback = 90.0
			u.launch = -70.0
			u.hitstun = 0.18
			u.blockstun = 0.12
			u.size = Vector2(58, 36)
			u.reach = 46.0
			u.y = -48.0
			u.startup = 0.08
			u.active = 0.05
			u.duration = 0.58
			u.knockdown = false
			u.juggle = true
		"vodka":
			u.projectile = ""
			u.damage = 0.0
			u.knockback = 0.0
			u.launch = 0.0
			u.hitstun = 0.0
			u.blockstun = 0.0
			u.size = Vector2(8, 8)
			u.reach = 0.0
			u.y = -40.0
			u.startup = 0.10
			u.active = 0.02
			u.duration = 0.62
			u.invuln = 0.22
			u.armor = 2
			u.heal = 0.28
			u.atk_boost = 1.38
			u.atk_boost_t = 10.0
			u.knockdown = false
		"fart":
			u.projectile = "gas"
			u.proj_count = 1
			u.proj_speed = 110.0
			u.proj_life = 1.55
			u.pierce = true
			u.damage = 110.0 * def.attack
			u.knockback = 50.0
			u.launch = 0.0
			u.hitstun = 1.05
			u.blockstun = 0.42
			u.size = Vector2(118, 52)
			u.reach = 28.0
			u.y = -30.0
			u.startup = 0.16
			u.active = 0.16
			u.duration = 0.72
			u.invuln = 0.18
			u.armor = 2
			u.knockdown = false
			u.poison = true
			u.poison_t = 5.0
			u.poison_dps = 26.0
			u.stun = true
		"flex":
			u.projectile = ""
			u.quake = true
			u.damage = 52.0 * def.attack
			u.knockback = 620.0
			u.launch = -48.0
			u.hitstun = 0.52
			u.blockstun = 0.28
			u.size = Vector2(1600, 96)
			u.reach = 0.0
			u.y = -48.0
			u.startup = 0.18
			u.active = 0.16
			u.duration = 0.72
			u.invuln = 0.22
			u.armor = 2
			u.knockdown = false
			u.push_away = true
			u.atk_boost = 1.42
			u.atk_boost_t = 10.0
		"cotton":
			u.projectile = ""
			u.damage = 0.0
			u.knockback = 0.0
			u.launch = 0.0
			u.hitstun = 0.0
			u.blockstun = 0.0
			u.size = Vector2(8, 8)
			u.reach = 0.0
			u.y = -20.0
			u.startup = 0.10
			u.active = 0.04
			u.duration = 0.52
			u.invuln = 0.20
			u.armor = 1
			u.knockdown = false
			u.cotton = true
		_:
			u.projectile = "ult"
			u.proj_count = 1
			u.proj_speed = 420.0
			u.proj_life = 0.9
			u.dash_spd = 520.0 if def.special_id == "dash" else 0.0
			u.element = def.ultimate_id
	return u


static func _dash_atk(def: CharacterDef) -> Dictionary:
	var d := _atk("dash_atk", 70.0, 190.0, -70.0, 0.28, 0.060, 0.08, 0.08, 0.50, Vector2(40, 22), 46.0, -50.0, false, def, "mid", 160.0)
	d.dash_spd = 480.0
	d.invuln = 0.0
	d.armor = 0
	d.juggle = false
	d.meter = 6.0
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
	return clampf(1.0 - hits * 0.14, 0.22, 1.0)


static func juggle_scale(hits: int) -> float:
	return clampf(1.0 - float(maxi(hits - 1, 0)) * 0.16, 0.28, 1.0)


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
			return 4.0
		"heavy", "cheavy", "jheavy", "dash_atk":
			return 12.0
		"special":
			return 28.0
		"ultimate":
			return 44.0
		_:
			return 10.0


static func chip_mul(kind: String, just: bool) -> float:
	var m: float = 0.04
	if kind == "special":
		m = 0.14
	elif kind == "ultimate":
		m = 0.18
	elif kind in ["heavy", "cheavy", "jheavy", "dash_atk"]:
		m = 0.08
	if just:
		m *= 0.45
	return m
