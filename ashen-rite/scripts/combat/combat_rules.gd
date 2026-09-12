class_name CombatRules
extends RefCounted


static func make_attack(kind: String, def: CharacterDef) -> Dictionary:
	match kind:
		"light":
			return _atk("light", 42.0, 110.0, -30.0, 0.30, 0.045, 0.05, 0.06, 0.28, Vector2(34, 20), 42.0, -58.0, false, def, "mid", 55.0)
		"clight":
			return _atk("clight", 38.0, 90.0, -16.0, 0.28, 0.04, 0.05, 0.07, 0.30, Vector2(36, 16), 44.0, -28.0, false, def, "mid", 40.0)
		"jlight":
			return _atk("jlight", 40.0, 80.0, 50.0, 0.26, 0.04, 0.04, 0.10, 0.32, Vector2(32, 22), 36.0, -52.0, false, def, "high", 0.0)
		"heavy":
			return _atk("heavy", 92.0, 240.0, -180.0, 0.42, 0.09, 0.10, 0.10, 0.48, Vector2(44, 24), 50.0, -56.0, false, def, "mid", 90.0)
		"cheavy":
			return _atk("cheavy", 84.0, 200.0, -20.0, 0.46, 0.08, 0.09, 0.12, 0.54, Vector2(48, 18), 50.0, -22.0, true, def, "low", 70.0)
		"jheavy":
			return _atk("jheavy", 88.0, 200.0, 90.0, 0.36, 0.08, 0.07, 0.12, 0.42, Vector2(40, 26), 42.0, -48.0, false, def, "high", 0.0)
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
