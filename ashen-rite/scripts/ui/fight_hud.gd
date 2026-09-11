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

	var top := TextureRect.new()
	top.texture = PixelUI.hud_top()
	top.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	top.position = Vector2(0, 0)
	top.size = Vector2(1280, 112)
	top.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(top)

	var p1_plate := TextureRect.new()
	p1_plate.texture = PixelUI.name_plate(80, 8, p1.def.accent)
	p1_plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p1_plate.position = Vector2(24, 8)
	p1_plate.scale = Vector2(4, 4)
	root.add_child(p1_plate)
	PixelUI.label_at(root, p1.def.name.to_upper(), Vector2(56, 10), 2, Color(0.95, 0.9, 0.82))

	var p2_plate := TextureRect.new()
	p2_plate.texture = PixelUI.name_plate(80, 8, p2.def.accent)
	p2_plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p2_plate.position = Vector2(960, 8)
	p2_plate.scale = Vector2(4, 4)
	root.add_child(p2_plate)
	var p2n := PixelUI.label_at(root, p2.def.name.to_upper(), Vector2(960, 10), 2, Color(0.95, 0.9, 0.82), 0, 264)
	p2n.set_centered(264)

	var tbox := TextureRect.new()
	tbox.texture = PixelUI.timer_box()
	tbox.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tbox.position = Vector2(600, 12)
	tbox.scale = Vector2(4, 4)
	root.add_child(tbox)
	_timer = PixelUI.label_at(root, "99", Vector2(0, 18), 4, Color(1, 0.9, 0.45), 0, 1280)
	_timer.set_centered(1280)

	_p1_hp = _bar_tex(root, Vector2(24, 44), 120, 8)
	_p2_hp = _bar_tex(root, Vector2(808, 44), 120, 8)
	_p1_sp = _meter_tex(root, Vector2(24, 80), 40, 5)
	_p2_sp = _meter_tex(root, Vector2(1080, 80), 40, 5)
	_p1_ult = _meter_tex(root, Vector2(200, 80), 44, 5)
	_p2_ult = _meter_tex(root, Vector2(808, 80), 44, 5)

	PixelUI.label_at(root, "SP", Vector2(24, 68), 1, Color(0.45, 0.78, 1.0))
	PixelUI.label_at(root, "ULT", Vector2(200, 68), 1, Color(0.95, 0.82, 0.35))
	PixelUI.label_at(root, "SP", Vector2(1080, 68), 1, Color(0.45, 0.78, 1.0))
	PixelUI.label_at(root, "ULT", Vector2(952, 68), 1, Color(0.95, 0.82, 0.35))

	for i in 2:
		_p1_rounds.append(_gem(root, Vector2(24 + i * 36, 96)))
		_p2_rounds.append(_gem(root, Vector2(1216 - i * 36, 96)))

	PixelUI.label_at(root, arena_name, Vector2(0, 108), 2, Color(0.68, 0.64, 0.58), 0, 1280).set_centered(1280)
	_combo = PixelUI.label_at(root, "", Vector2(0, 140), 3, Color(1, 0.85, 0.3), 0, 1280)
	_combo.set_centered(1280)

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


func _meter_tex(root: Control, pos: Vector2, w: int, h: int) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.texture = PixelUI.meter_bar(w, h, Color(0.3, 0.75, 1.0), 0.0)
	t.scale = Vector2(4, 4)
	root.add_child(t)
	t.set_meta("bw", w)
	t.set_meta("bh", h)
	return t


func _gem(root: Control, pos: Vector2) -> TextureRect:
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
	sp.texture = PixelUI.meter_bar(int(sp.get_meta("bw")), int(sp.get_meta("bh")), Color(0.3, 0.75, 1.0), s / 100.0, s >= 100.0)
	ult.texture = PixelUI.meter_bar(int(ult.get_meta("bw")), int(ult.get_meta("bh")), Color(0.95, 0.78, 0.25), u / 100.0, u >= 100.0)


func set_timer(v: int) -> void:
	_timer.set_pix("%02d" % v, 4, Color(1, 0.35, 0.3) if v <= 10 else Color(1, 0.9, 0.45))
	_timer.set_centered(1280)


func set_rounds(a: int, b: int) -> void:
	for i in _p1_rounds.size():
		_p1_rounds[i].texture = PixelUI.round_gem(i < a)
	for i in _p2_rounds.size():
		_p2_rounds[i].texture = PixelUI.round_gem(i < b)


func set_combo(_side: int, n: int) -> void:
	if n >= 2:
		_combo.set_pix("COMBO x%d" % n, 3, Color(1, 0.85, 0.3))
		_combo.set_centered(1280)
		_combo.visible = true
	else:
		_combo.visible = false
