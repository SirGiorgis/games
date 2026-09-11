class_name FightHUD
extends CanvasLayer

var _p1_hp: ColorRect
var _p2_hp: ColorRect
var _p1_sp: ColorRect
var _p2_sp: ColorRect
var _p1_ult: ColorRect
var _p2_ult: ColorRect
var _timer: Label
var _p1_name: Label
var _p2_name: Label
var _arena: Label
var _combo: Label
var _p1_rounds: Array[ColorRect] = []
var _p2_rounds: Array[ColorRect] = []
var _p1_hp_max := 220.0
var _p2_hp_max := 220.0
var _p1: Fighter
var _p2: Fighter


func bind(p1: Fighter, p2: Fighter, arena_name: String) -> void:
	layer = 12
	_p1 = p1
	_p2 = p2
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := ColorRect.new()
	top.color = Color(0.02, 0.01, 0.03, 0.55)
	top.position = Vector2(0, 0)
	top.size = Vector2(1280, 86)
	root.add_child(top)

	_p1_name = Label.new()
	_p1_name.position = Vector2(40, 8)
	_p1_name.text = p1.def.name
	UIKit.style_label(_p1_name, 22, Color(0.95, 0.9, 0.8))
	root.add_child(_p1_name)

	_p2_name = Label.new()
	_p2_name.position = Vector2(900, 8)
	_p2_name.size = Vector2(340, 30)
	_p2_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_p2_name.text = p2.def.name
	UIKit.style_label(_p2_name, 22, Color(0.95, 0.9, 0.8))
	root.add_child(_p2_name)

	_p1_hp = _bar(root, Vector2(40, 40), Vector2(420, 18), Color(0.82, 0.16, 0.22))
	_p2_hp = _bar(root, Vector2(820, 40), Vector2(420, 18), Color(0.82, 0.16, 0.22))
	_p1_hp.pivot_offset = Vector2(0, 0)
	_p2_hp.pivot_offset = Vector2(420, 0)

	_p1_sp = _bar(root, Vector2(40, 62), Vector2(200, 8), Color(0.3, 0.75, 1.0))
	_p2_sp = _bar(root, Vector2(1040, 62), Vector2(200, 8), Color(0.3, 0.75, 1.0))
	_p1_ult = _bar(root, Vector2(250, 62), Vector2(210, 8), Color(0.95, 0.75, 0.2))
	_p2_ult = _bar(root, Vector2(820, 62), Vector2(210, 8), Color(0.95, 0.75, 0.2))

	_timer = Label.new()
	_timer.position = Vector2(590, 18)
	_timer.size = Vector2(100, 50)
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer.text = "99"
	UIKit.style_label(_timer, 40, Color(1, 0.92, 0.55))
	root.add_child(_timer)

	_arena = Label.new()
	_arena.position = Vector2(0, 88)
	_arena.size = Vector2(1280, 24)
	_arena.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arena.text = arena_name
	UIKit.style_label(_arena, 14, Color(0.8, 0.75, 0.7, 0.8))
	root.add_child(_arena)

	_combo = Label.new()
	_combo.position = Vector2(490, 140)
	_combo.size = Vector2(300, 40)
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo.text = ""
	UIKit.style_label(_combo, 28, Color(1.0, 0.85, 0.3))
	root.add_child(_combo)

	for i in 2:
		var a := _pip(root, Vector2(40 + i * 22, 78))
		var b := _pip(root, Vector2(1218 - i * 22, 78))
		_p1_rounds.append(a)
		_p2_rounds.append(b)

	p1.health_changed.connect(func(c, m): _set_hp(_p1_hp, c, m, false))
	p2.health_changed.connect(func(c, m): _set_hp(_p2_hp, c, m, true))
	p1.meters_changed.connect(func(s, u): _set_meters(_p1_sp, _p1_ult, s, u))
	p2.meters_changed.connect(func(s, u): _set_meters(_p2_sp, _p2_ult, s, u))
	_set_hp(_p1_hp, p1.health, p1.max_health, false)
	_set_hp(_p2_hp, p2.health, p2.max_health, true)
	_set_meters(_p1_sp, _p1_ult, p1.special_meter, p1.ultimate_meter)
	_set_meters(_p2_sp, _p2_ult, p2.special_meter, p2.ultimate_meter)


func _bar(root: Control, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.position = pos
	bg.size = size
	bg.color = Color(0.08, 0.06, 0.08)
	root.add_child(bg)
	var fill := ColorRect.new()
	fill.position = pos
	fill.size = size
	fill.color = color
	root.add_child(fill)
	return fill


func _pip(root: Control, pos: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = Vector2(16, 8)
	r.color = Color(0.25, 0.22, 0.2)
	root.add_child(r)
	return r


func _set_hp(bar: ColorRect, cur: float, mx: float, from_right: bool) -> void:
	var t := clampf(cur / max(mx, 1.0), 0.0, 1.0)
	var full := 420.0
	bar.size.x = full * t
	if from_right:
		bar.position.x = 820.0 + full * (1.0 - t)
	bar.color = Color(0.82, 0.16, 0.22).lerp(Color(0.95, 0.8, 0.2), 1.0 - t)


func _set_meters(sp: ColorRect, ult: ColorRect, s: float, u: float) -> void:
	sp.size.x = 200.0 * clampf(s / 100.0, 0.0, 1.0)
	ult.size.x = 210.0 * clampf(u / 100.0, 0.0, 1.0)
	if u >= 100.0:
		ult.color = Color(1, 0.9, 0.3)
	else:
		ult.color = Color(0.75, 0.55, 0.15)


func set_timer(v: int) -> void:
	_timer.text = "%02d" % v
	_timer.add_theme_color_override("font_color", Color(1, 0.35, 0.3) if v <= 10 else Color(1, 0.92, 0.55))


func set_rounds(a: int, b: int) -> void:
	for i in _p1_rounds.size():
		_p1_rounds[i].color = Color(0.95, 0.75, 0.25) if i < a else Color(0.25, 0.22, 0.2)
	for i in _p2_rounds.size():
		_p2_rounds[i].color = Color(0.95, 0.75, 0.25) if i < b else Color(0.25, 0.22, 0.2)


func set_combo(side: int, n: int) -> void:
	if n >= 2:
		_combo.text = "COMBO x%d" % n
	else:
		_combo.text = ""
