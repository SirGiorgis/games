extends Node

var roster: Array[CharacterDef] = []
var by_id: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	roster.clear()
	by_id.clear()
	var dir := DirAccess.open("res://data/characters")
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if not fname.begins_with(".") and fname.ends_with(".json") and not dir.current_is_dir():
				_load_json("res://data/characters/%s" % fname)
			fname = dir.get_next()
		dir.list_dir_end()
	roster.sort_custom(func(a, b): return a.roster_order < b.roster_order or (a.roster_order == b.roster_order and a.name < b.name))
	if roster.is_empty():
		_fallback_roster()
	_ensure_custom_slot()


func get_def(id: String) -> CharacterDef:
	if by_id.has(id):
		return by_id[id]
	if roster.size() > 0:
		return roster[0]
	return CharacterDef.new()


func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for c in roster:
		out.append(c.id)
	return out


func rebuild_custom(description: String, photo_path: String) -> CharacterDef:
	var forged := CharacterForge.forge(description, photo_path, "custom")
	forged.name = "Custom Rite"
	forged.title = "Player-Forged"
	_register(forged)
	return forged


func _load_json(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var def := CharacterDef.new().from_dict(parsed)
	var outfit := def.outfit
	var trim := def.trim
	var accent := def.accent
	if not def.reference_image.is_empty():
		CharacterForge.apply_photo(def, def.reference_image)
	if def.keep_outfit:
		def.outfit = outfit
		def.trim = trim
		def.accent = accent
	if def.source_description.is_empty() == false and def.id == "custom":
		def = CharacterForge.forge(def.source_description, def.reference_image, def.id)
	_register(def)


func _register(def: CharacterDef) -> void:
	if by_id.has(def.id):
		for i in roster.size():
			if roster[i].id == def.id:
				roster[i] = def
				break
	else:
		roster.append(def)
	by_id[def.id] = def


func _ensure_custom_slot() -> void:
	if by_id.has("custom"):
		return
	rebuild_custom(GameState.custom_description, GameState.custom_photo_path)


func _fallback_roster() -> void:
	var specs := [
		["kael_voss", "Male fighter, skinny lean build, curly brown hair, black teal racing jacket, aggressive personality, formula racing speed powers."],
		["mira_solen", "Female fighter, athletic, crimson hair, red dancer wraps, fierce personality, fire-based powers."],
		["rook_ironveil", "Male fighter, tall, heavy muscular build, brown hair, gold-trim armor, stoic personality, earth-based powers."],
		["nyx_hollow", "Female fighter, lean, black hair, violet cloak, cunning personality, shadow-based powers."],
		["asha_wren", "Female fighter, compact, ivory hair, teal robes, patient personality, ice-based powers."],
	]
	for s in specs:
		var def := CharacterForge.forge(s[1], "", s[0])
		_register(def)
