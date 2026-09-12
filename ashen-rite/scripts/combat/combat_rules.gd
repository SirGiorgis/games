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
	}


static func _special(def: CharacterDef) -> Dictionary:
	var base := _atk("special", 105.0, 240.0, -240.0, 0.44, 0.09, 0.11, 0.12, 0.50, Vector2(56, 28), 56.0, -56.0, false, def)
	base.meter = 4.0
	match def.special_id:
		"bolt":
			base.projectile = "bolt"
			base.damage = 90.0 * def.attack
		"wave":
			base.projectile = "wave"
			base.damage = 72.0 * def.attack
			base.active = 0.16
		"dash":
			base.reach = 120.0
			base.startup = 0.08
			base.knockback = 180.0
			base.juggle = true
		"slam":
			base.y = -16.0
			base.size = Vector2(80, 22)
			base.reach = 24.0
			base.knockdown = true
			base.launch = -60.0
		"blast":
			base.projectile = "blast"
			base.hitstun = 0.55
	return base


static func _ultimate(def: CharacterDef) -> Dictionary:
	var u := _atk("ultimate", 220.0, 420.0, -380.0, 0.75, 0.14, 0.18, 0.18, 0.72, Vector2(96, 52), 58.0, -52.0, true, def)
	u.meter = 0.0
	u.projectile = "ult"
	u.proj_speed = 400.0
	u.element = def.ultimate_id
	return u


static func combo_scale(hits: int) -> float:
	return clampf(1.0 - hits * 0.10, 0.32, 1.0)
