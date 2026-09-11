class_name CombatRules
extends RefCounted


static func make_attack(kind: String, def: CharacterDef) -> Dictionary:
	match kind:
		"light":
			return {
				"kind": "light", "damage": 42.0 * def.attack, "knockback": 140.0,
				"launch": -80.0, "hitstun": 0.22, "hitstop": 0.04, "meter": 8.0,
				"startup": 0.08, "active": 0.07, "duration": 0.28,
				"size": Vector2(46, 28), "reach": 44.0, "y": -72.0,
				"knockdown": false, "projectile": "",
			}
		"heavy":
			return {
				"kind": "heavy", "damage": 92.0 * def.attack, "knockback": 340.0,
				"launch": -220.0, "hitstun": 0.42, "hitstop": 0.09, "meter": 14.0,
				"startup": 0.16, "active": 0.1, "duration": 0.48,
				"size": Vector2(58, 36), "reach": 52.0, "y": -70.0,
				"knockdown": false, "projectile": "",
			}
		"special":
			return _special(def)
		"ultimate":
			return _ultimate(def)
		"grab":
			return {
				"kind": "grab", "damage": 80.0 * def.attack, "knockback": 260.0,
				"launch": -160.0, "hitstun": 0.5, "hitstop": 0.08, "meter": 10.0,
				"startup": 0.1, "active": 0.08, "duration": 0.4,
				"size": Vector2(40, 40), "reach": 32.0, "y": -60.0,
				"knockdown": true, "projectile": "",
			}
	return make_attack("light", def)


static func _special(def: CharacterDef) -> Dictionary:
	var base := {
		"kind": "special", "damage": 110.0 * def.attack, "knockback": 280.0,
		"launch": -280.0, "hitstun": 0.46, "hitstop": 0.1, "meter": 6.0,
		"startup": 0.18, "active": 0.12, "duration": 0.52,
		"size": Vector2(70, 40), "reach": 70.0, "y": -74.0,
		"knockdown": false, "projectile": "", "proj_speed": 560.0,
	}
	match def.special_id:
		"bolt":
			base.projectile = "bolt"
			base.damage = 96.0 * def.attack
		"wave":
			base.projectile = "wave"
			base.damage = 70.0 * def.attack
			base.active = 0.18
		"dash":
			base.reach = 110.0
			base.knockback = 200.0
			base.startup = 0.1
		"slam":
			base.y = -30.0
			base.size = Vector2(120, 40)
			base.reach = 20.0
			base.knockdown = true
			base.launch = -80.0
		"blast":
			base.projectile = "blast"
			base.hitstun = 0.58
	return base


static func _ultimate(def: CharacterDef) -> Dictionary:
	return {
		"kind": "ultimate", "damage": 210.0 * def.attack, "knockback": 480.0,
		"launch": -420.0, "hitstun": 0.8, "hitstop": 0.16, "meter": 0.0,
		"startup": 0.22, "active": 0.2, "duration": 0.7,
		"size": Vector2(160, 90), "reach": 80.0, "y": -70.0,
		"knockdown": true, "projectile": "ult", "proj_speed": 420.0,
		"element": def.ultimate_id,
	}


static func combo_scale(hits: int) -> float:
	return clampf(1.0 - hits * 0.12, 0.35, 1.0)
