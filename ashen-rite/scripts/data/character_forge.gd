class_name CharacterForge
extends RefCounted
## Builds a playable fighter from a text description + optional reference photo.
## No online APIs. Photo is sampled for palette; missing photo still works.

const COLOR_WORDS := {
	"black": Color(0.08, 0.08, 0.09),
	"white": Color(0.92, 0.92, 0.94),
	"red": Color(0.78, 0.16, 0.18),
	"crimson": Color(0.7, 0.08, 0.14),
	"blue": Color(0.2, 0.38, 0.82),
	"navy": Color(0.1, 0.16, 0.38),
	"gold": Color(0.86, 0.7, 0.28),
	"yellow": Color(0.9, 0.82, 0.22),
	"green": Color(0.18, 0.62, 0.32),
	"purple": Color(0.48, 0.22, 0.7),
	"violet": Color(0.45, 0.2, 0.72),
	"orange": Color(0.9, 0.45, 0.12),
	"pink": Color(0.9, 0.4, 0.62),
	"silver": Color(0.72, 0.76, 0.82),
	"grey": Color(0.45, 0.45, 0.48),
	"gray": Color(0.45, 0.45, 0.48),
	"brown": Color(0.42, 0.26, 0.16),
	"teal": Color(0.12, 0.62, 0.62),
	"cyan": Color(0.25, 0.85, 0.9),
	"ivory": Color(0.93, 0.88, 0.78),
}

const POWER_MAP := {
	"lightning": {"special": "bolt", "accent": Color(0.45, 0.82, 1.0), "name": "Rift Bolt", "ult": "Tempest Breaker", "ult_id": "storm"},
	"thunder": {"special": "bolt", "accent": Color(0.45, 0.82, 1.0), "name": "Rift Bolt", "ult": "Tempest Breaker", "ult_id": "storm"},
	"electric": {"special": "bolt", "accent": Color(0.55, 0.9, 1.0), "name": "Arc Lash", "ult": "Skyfall Circuit", "ult_id": "storm"},
	"fire": {"special": "wave", "accent": Color(1.0, 0.45, 0.15), "name": "Cinder Arc", "ult": "Ashen Sun", "ult_id": "nova"},
	"flame": {"special": "wave", "accent": Color(1.0, 0.4, 0.12), "name": "Cinder Arc", "ult": "Ashen Sun", "ult_id": "nova"},
	"ice": {"special": "blast", "accent": Color(0.55, 0.85, 1.0), "name": "Frost Spire", "ult": "Glacier Verdict", "ult_id": "nova"},
	"shadow": {"special": "dash", "accent": Color(0.45, 0.2, 0.7), "name": "Umbral Cut", "ult": "Nightfall", "ult_id": "void"},
	"dark": {"special": "dash", "accent": Color(0.35, 0.15, 0.55), "name": "Umbral Cut", "ult": "Nightfall", "ult_id": "void"},
	"earth": {"special": "slam", "accent": Color(0.72, 0.5, 0.22), "name": "Stone Breaker", "ult": "Titanfall", "ult_id": "quake"},
	"rock": {"special": "slam", "accent": Color(0.7, 0.48, 0.2), "name": "Stone Breaker", "ult": "Titanfall", "ult_id": "quake"},
	"wind": {"special": "dash", "accent": Color(0.7, 0.9, 0.75), "name": "Gale Step", "ult": "Sky Rend", "ult_id": "storm"},
	"blood": {"special": "wave", "accent": Color(0.72, 0.08, 0.14), "name": "Crimson Lash", "ult": "Rite of Ichor", "ult_id": "void"},
	"light": {"special": "blast", "accent": Color(1.0, 0.92, 0.55), "name": "Solar Brand", "ult": "Dawn Collapse", "ult_id": "nova"},
}


static func forge(description: String, photo_path: String = "", id_override: String = "custom") -> CharacterDef:
	var d := CharacterDef.new()
	d.id = id_override
	d.source_description = description
	d.reference_image = photo_path
	d.description = description.strip_edges()
	var text := description.to_lower()

	d.gender = "androgynous"
	if _has_any(text, ["female", "woman", "girl", "she"]):
		d.gender = "female"
	elif _has_any(text, ["male", "man", "boy", "he"]):
		d.gender = "male"

	d.height_scale = 1.0
	if _has_any(text, ["tall", "towering", "huge"]):
		d.height_scale = 1.12
	elif _has_any(text, ["short", "small", "compact"]):
		d.height_scale = 0.9

	d.build = "athletic"
	d.width_scale = 1.0
	if _has_any(text, ["heavy", "muscular", "tank", "broad", "stocky", "chubby", "fat"]):
		d.build = "heavy"
		d.width_scale = 1.18
		d.health = 1150
		d.speed = 220
		d.attack = 1.15
		d.defense = 1.2
		d.jump = 520
	elif _has_any(text, ["slim", "lean", "slender", "agile", "lithe"]):
		d.build = "lean"
		d.width_scale = 0.88
		d.health = 880
		d.speed = 310
		d.attack = 0.95
		d.defense = 0.88
		d.jump = 600
	else:
		d.health = 1000
		d.speed = 265
		d.attack = 1.0
		d.defense = 1.0
		d.jump = 560

	if _has_any(text, ["aggressive", "ruthless", "fierce", "hot-headed"]):
		d.personality = "aggressive"
		d.ai_profile = "rushdown"
		d.attack *= 1.06
	elif _has_any(text, ["calm", "patient", "stoic", "defensive"]):
		d.personality = "stoic"
		d.ai_profile = "turtle"
		d.defense *= 1.08
	elif _has_any(text, ["trick", "cunning", "sly", "unpredictable"]):
		d.personality = "cunning"
		d.ai_profile = "mixup"
	else:
		d.personality = "focused"
		d.ai_profile = "balanced"

	d.hair = Color(0.12, 0.1, 0.09)
	d.outfit = Color(0.14, 0.14, 0.16)
	d.trim = Color(0.7, 0.62, 0.28)
	d.skin = Color(0.76, 0.56, 0.42)
	if _has_any(text, ["pale", "fair"]):
		d.skin = Color(0.9, 0.76, 0.66)
	elif _has_any(text, ["dark skin", "brown skin", "deep brown"]):
		d.skin = Color(0.42, 0.26, 0.16)
	elif _has_any(text, ["olive"]):
		d.skin = Color(0.7, 0.55, 0.38)

	for word in COLOR_WORDS.keys():
		if text.find(word + " hair") != -1 or text.find(word + "-haired") != -1:
			d.hair = COLOR_WORDS[word]
		if text.find(word + " jacket") != -1 or text.find(word + " coat") != -1 or text.find(word + " armor") != -1 or text.find(word + " robe") != -1:
			d.outfit = COLOR_WORDS[word]
		if text.find(word + " eyes") != -1:
			d.eyes = COLOR_WORDS[word]

	var power := _detect_power(text)
	d.accent = power["accent"]
	d.eyes = d.accent.lerp(Color.WHITE, 0.35)
	d.special_id = power["special"]
	d.special_name = power["name"]
	d.ultimate_id = power["ult_id"]
	d.ultimate_name = power["ult"]
	d.special_desc = "Signature %s technique drawn from the fighter's element." % d.special_name
	d.ultimate_desc = "A match-turning super: %s." % d.ultimate_name

	d.name = _name_from_text(text, d)
	d.title = _title_from_power(d)

	if not photo_path.is_empty():
		apply_photo(d, photo_path)

	if _has_any(text, ["striped", "kit", "football", "jersey", "collar"]):
		d.style = "kit"
		d.outfit = Color(0.77, 0.12, 0.23)
		d.trim = Color(0.96, 0.96, 0.97)
		d.accent = Color(0.11, 0.31, 0.64)
	elif _has_any(text, ["racing", "jacket", "paddock"]):
		d.style = "racing"
	return d


static func _detect_power(text: String) -> Dictionary:
	for k in POWER_MAP.keys():
		if text.find(k) != -1:
			return POWER_MAP[k]
	return {"special": "blast", "accent": Color(0.85, 0.35, 0.55), "name": "Rift Pulse", "ult": "Ashen Rite", "ult_id": "nova"}


static func _name_from_text(text: String, d: CharacterDef) -> String:
	if d.gender == "female":
		if text.find("fire") != -1 or text.find("flame") != -1:
			return "Mira Solen"
		if text.find("shadow") != -1:
			return "Nyx Hollow"
		return "Asha Wren"
	if text.find("lightning") != -1 or text.find("thunder") != -1 or text.find("racing") != -1:
		return "Chris Xrisakis"
	if text.find("earth") != -1 or text.find("armor") != -1:
		return "Rook Ironveil"
	return "Vesper Quill"


static func _title_from_power(d: CharacterDef) -> String:
	match d.special_id:
		"bolt":
			return "Stormclad"
		"wave":
			return "Cinder Dancer"
		"dash":
			return "Night Edge"
		"slam":
			return "Iron Vow"
		_:
			return "Riftborn"


static func apply_photo(d: CharacterDef, path: String) -> void:
	var img := _load_image(path)
	if img == null:
		return
	img.resize(48, 48, Image.INTERPOLATE_NEAREST)
	var samples: Array[Color] = []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.4:
				continue
			if c.get_luminance() < 0.06 or c.get_luminance() > 0.96:
				continue
			samples.append(c)
	if samples.is_empty():
		return
	samples.sort_custom(func(a, b): return a.get_luminance() < b.get_luminance())
	d.hair = samples[int(samples.size() * 0.12)]
	d.outfit = samples[int(samples.size() * 0.28)]
	d.skin = samples[int(samples.size() * 0.55)].lerp(d.skin, 0.35)
	d.trim = samples[int(samples.size() * 0.75)]
	var vivid := samples[0]
	var best_sat := 0.0
	for c in samples:
		var s := c.s
		if s > best_sat:
			best_sat = s
			vivid = c
	if best_sat > 0.25:
		d.accent = vivid
		d.eyes = vivid.lerp(Color.WHITE, 0.4)


static func _load_image(path: String) -> Image:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex is Texture2D:
			return (tex as Texture2D).get_image()
	var disk := path
	if path.begins_with("res://"):
		disk = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path) or FileAccess.file_exists(disk):
		var img := Image.load_from_file(disk)
		if img:
			return img
	return null


static func _has_any(text: String, words: Array) -> bool:
	for w in words:
		if text.find(w) != -1:
			return true
	return false
