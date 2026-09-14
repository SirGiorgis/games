class_name CharacterDef
extends Resource

var id: String = ""
var name: String = "Unknown"
var title: String = ""
var description: String = ""
var personality: String = "balanced"
var ai_profile: String = "balanced"
var gender: String = "androgynous"
var build: String = "athletic"
var height_scale: float = 1.0
var width_scale: float = 1.0
var health: float = 1000.0
var speed: float = 260.0
var jump: float = 560.0
var attack: float = 1.0
var defense: float = 1.0
var skin: Color = Color(0.76, 0.56, 0.42)
var hair: Color = Color(0.12, 0.1, 0.1)
var outfit: Color = Color(0.15, 0.15, 0.18)
var trim: Color = Color(0.75, 0.65, 0.3)
var accent: Color = Color(0.4, 0.75, 1.0)
var eyes: Color = Color(0.9, 0.9, 1.0)
var special_id: String = "blast"
var special_name: String = "Rift Surge"
var special_desc: String = "A forward burst of elemental force."
var ultimate_id: String = "catastrophe"
var ultimate_name: String = "Rite Unbound"
var ultimate_desc: String = "A screen-shaking finishing assault."
var reference_image: String = ""
var source_description: String = ""
var style: String = ""
var keep_outfit: bool = false
var keep_palette: bool = false
var roster_order: int = 50
var win_quote: String = "THE RITE IS MINE."
var intro_quote: String = "LET'S GO."


func from_dict(d: Dictionary) -> CharacterDef:
	id = str(d.get("id", id))
	name = str(d.get("name", name))
	title = str(d.get("title", title))
	description = str(d.get("description", description))
	personality = str(d.get("personality", personality))
	ai_profile = str(d.get("ai_profile", ai_profile))
	gender = str(d.get("gender", gender))
	build = str(d.get("build", build))
	height_scale = float(d.get("height_scale", height_scale))
	width_scale = float(d.get("width_scale", width_scale))
	health = float(d.get("health", health))
	speed = float(d.get("speed", speed))
	jump = float(d.get("jump", jump))
	attack = float(d.get("attack", attack))
	defense = float(d.get("defense", defense))
	skin = _col(d.get("skin", skin))
	hair = _col(d.get("hair", hair))
	outfit = _col(d.get("outfit", outfit))
	trim = _col(d.get("trim", trim))
	accent = _col(d.get("accent", accent))
	eyes = _col(d.get("eyes", eyes))
	special_id = str(d.get("special_id", special_id))
	special_name = str(d.get("special_name", special_name))
	special_desc = str(d.get("special_desc", special_desc))
	ultimate_id = str(d.get("ultimate_id", ultimate_id))
	ultimate_name = str(d.get("ultimate_name", ultimate_name))
	ultimate_desc = str(d.get("ultimate_desc", ultimate_desc))
	reference_image = str(d.get("reference_image", reference_image))
	source_description = str(d.get("source_description", source_description))
	style = str(d.get("style", style))
	keep_outfit = bool(d.get("keep_outfit", keep_outfit))
	keep_palette = bool(d.get("keep_palette", keep_palette))
	roster_order = int(d.get("roster_order", roster_order))
	win_quote = str(d.get("win_quote", win_quote)).to_upper()
	intro_quote = str(d.get("intro_quote", intro_quote)).to_upper()
	return self


func duplicate_def() -> CharacterDef:
	var c := CharacterDef.new()
	c.from_dict(to_dict())
	return c


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"title": title,
		"description": description,
		"personality": personality,
		"ai_profile": ai_profile,
		"gender": gender,
		"build": build,
		"height_scale": height_scale,
		"width_scale": width_scale,
		"health": health,
		"speed": speed,
		"jump": jump,
		"attack": attack,
		"defense": defense,
		"skin": skin.to_html(false),
		"hair": hair.to_html(false),
		"outfit": outfit.to_html(false),
		"trim": trim.to_html(false),
		"accent": accent.to_html(false),
		"eyes": eyes.to_html(false),
		"special_id": special_id,
		"special_name": special_name,
		"special_desc": special_desc,
		"ultimate_id": ultimate_id,
		"ultimate_name": ultimate_name,
		"ultimate_desc": ultimate_desc,
		"reference_image": reference_image,
		"source_description": source_description,
		"style": style,
		"keep_outfit": keep_outfit,
		"keep_palette": keep_palette,
		"roster_order": roster_order,
		"win_quote": win_quote,
		"intro_quote": intro_quote,
	}


func callsign() -> String:
	var n: String = name.strip_edges()
	var sp: int = n.find(" ")
	if sp > 0:
		return n.substr(0, sp).to_upper()
	return n.to_upper()


func _col(v) -> Color:
	if v is Color:
		return v
	return Color.html(str(v))
