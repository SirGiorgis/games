class_name FightHUD
extends CanvasLayer

var _p1_hp: TextureRect
var _p2_hp: TextureRect
var _p1_sp: TextureRect
var _p2_sp: TextureRect
var _p1_ult: TextureRect
var _p2_ult: TextureRect
var _timer: PixelLabel
var _combo: PixelLabel
var _p1_rounds: Array[TextureRect] = []
var _p2_rounds: Array[TextureRect] = []
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

	var plate := TextureRect.new()
	plate.texture = PixelUI.panel(320, 28, Color(0.05, 0.03, 0.07, 0.85), Color(0.35, 0.28, 0.18))
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	plate.position = Vector2(0, 0)
	plate.size = Vector2(1280, 112)
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(plate)

	PixelUI.label_at(root, p1.def.name.to_upper(), Vector2(32, 8), 2, Color(0.95, 0.9, 0.8))
	var p2n := PixelUI.label_at(root, p2.def.name.to_upper(), Vector2(0, 8), 2, Color(0.95, 0.9, 0.8))
	p2n.set_centered(1280)
	p2n.position = Vector2(700, 8)
	p2n.set_centered(548)

	_p1_hp = _bar_tex(root, Vector2(32, 36), 104, 8)
	_p2_hp = _bar_tex(root, Vector2(832, 36), 104, 8)
	_p1_sp = _bar_tex(root, Vector2(32, 72), 48, 5)
	_p2_sp = _bar_tex(root, Vector2(1056, 72), 48, 5)
	_p1_ult = _bar_tex(root, Vector2(240, 72), 52, 5)
	_p2_ult = _bar_tex(root, Vector2(832, 72), 52, 5)

	_timer = PixelUI.label_at(root, "99", Vector2(0, 20), 4, Color(1, 0.9, 0.45), 0, 1280)
	_timer.set_centered(1280)
	PixelUI.label_at(root, arena_name, Vector2(0, 96), 2, Color(0.7, 0.68, 0.62), 0, 1280).set_centered(1280)
	_combo = PixelUI.label_at(root, "", Vector2(0, 140), 3, Color(1, 0.85, 0.3), 0, 1280)
	_combo.set_centered(1280)

	for i in 2:
		_p1_rounds.append(_pip(root, Vector2(32 + i * 28, 92)))
		_p2_rounds.append(_pip(root, Vector2(1220 - i * 28, 92)))

	p1.health_changed.connect(func(c, m): _paint_hp(_p1_hp, c, m))
	p2.health_changed.connect(func(c, m): _paint_hp(_p2_hp, c, m))
	p1.meters_changed.connect(func(s, u): _paint_meters(true, s, u))
	p2.meters_changed.connect(func(s, u): _paint_meters(false, s, u))
	_paint_hp(_p1_hp, p1.health, p1.max_health)
	_paint_hp(_p2_hp, p2.health, p2.max_health)
	_paint_meters(true, p1.special_meter, p1.ultimate_meter)
	_paint_meters(false, p2.special_meter, p2.ultimate_meter)


func _bar_tex(root: Control, pos: Vector2, w: int, h: int) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.texture = PixelUI.bar(w, h, Color(0.82, 0.16, 0.22), 1.0)
	t.scale = Vector2(4, 4)
	root.add_child(t)
	t.set_meta("bw", w)
	t.set_meta("bh", h)
	return t


func _pip(root: Control, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.scale = Vector2(4, 4)
	root.add_child(t)
	return t


func _paint_hp(bar: TextureRect, cur: float, mx: float) -> void:
	var t := clampf(cur / max(mx, 1.0), 0.0, 1.0)
	var col := Color(0.82, 0.16, 0.22).lerp(Color(0.95, 0.8, 0.2), 1.0 - t)
	bar.texture = PixelUI.bar(int(bar.get_meta("bw")), int(bar.get_meta("bh")), col, t)


func _paint_meters(left: bool, s: float, u: float) -> void:
	var sp: TextureRect = _p1_sp if left else _p2_sp
	var ult: TextureRect = _p1_ult if left else _p2_ult
	sp.texture = PixelUI.bar(int(sp.get_meta("bw")), int(sp.get_meta("bh")), Color(0.3, 0.75, 1.0), s / 100.0)
	var ucol := Color(1, 0.9, 0.3) if u >= 100.0 else Color(0.75, 0.55, 0.15)
	ult.texture = PixelUI.bar(int(ult.get_meta("bw")), int(ult.get_meta("bh")), ucol, u / 100.0)


func set_timer(v: int) -> void:
	_timer.set_pix("%02d" % v, 4, Color(1, 0.35, 0.3) if v <= 10 else Color(1, 0.9, 0.45))
	_timer.set_centered(1280)


func set_rounds(a: int, b: int) -> void:
	for i in _p1_rounds.size():
		var on := i < a
		_p1_rounds[i].texture = PixelUI.panel(5, 3, Color(0.95, 0.75, 0.25) if on else Color(0.18, 0.16, 0.14), Color(0.4, 0.3, 0.15))
	for i in _p2_rounds.size():
		var on2 := i < b
		_p2_rounds[i].texture = PixelUI.panel(5, 3, Color(0.95, 0.75, 0.25) if on2 else Color(0.18, 0.16, 0.14), Color(0.4, 0.3, 0.15))


func set_combo(_side: int, n: int) -> void:
	if n >= 2:
		_combo.set_pix("COMBO x%d" % n, 3, Color(1, 0.85, 0.3))
		_combo.set_centered(1280)
		_combo.visible = true
	else:
		_combo.visible = false
