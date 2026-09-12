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

	PixelUI.label_at(root, p1.def.name.to_upper(), Vector2(20, 8), 1, Color(0.12, 0.12, 0.12))
	var p2n := PixelUI.label_at(root, p2.def.name.to_upper(), Vector2(980, 8), 1, Color(0.12, 0.12, 0.12), 0, 280)
	p2n.set_centered(280)

	_p1_hp = _bar_tex(root, Vector2(16, 24), 132, 9, Color(0.28, 0.82, 0.22))
	_p2_hp = _bar_tex(root, Vector2(736, 24), 132, 9, Color(0.86, 0.18, 0.22))

	var tbox := TextureRect.new()
	tbox.texture = PixelUI.timer_box()
	tbox.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tbox.position = Vector2(596, 8)
	tbox.scale = Vector2(4, 4)
	root.add_child(tbox)
	_timer = PixelUI.label_at(root, "99", Vector2(0, 28), 3, Color(1, 1, 1), 0, 1280)
	_timer.set_centered(1280)

	_p1_sp = _meter_tex(root, Vector2(16, 68), 48, 5, Color(0.86, 0.32, 0.62))
	_p2_sp = _meter_tex(root, Vector2(1072, 68), 48, 5, Color(0.86, 0.32, 0.62))
	PixelUI.label_at(root, "BLOCK", Vector2(16, 56), 1, Color(0.92, 0.45, 0.7))
	PixelUI.label_at(root, "BLOCK", Vector2(1072, 56), 1, Color(0.92, 0.45, 0.7))

	for i in 2:
		_p1_rounds.append(_gem(root, Vector2(220 + i * 28, 64)))
		_p2_rounds.append(_gem(root, Vector2(1032 - i * 28, 64)))

	_p1_ult = _meter_tex(root, Vector2(16, 676), 80, 6, Color(0.25, 0.72, 0.95))
	_p2_ult = _meter_tex(root, Vector2(944, 676), 80, 6, Color(0.95, 0.78, 0.25))
	PixelUI.label_at(root, "SPECIAL", Vector2(16, 660), 1, Color(0.15, 0.18, 0.22))
	PixelUI.label_at(root, "SPECIAL", Vector2(944, 660), 1, Color(0.15, 0.18, 0.22))

	var hint := Color(0.95, 0.95, 0.92)
	PixelUI.label_at(root, "J  LIGHT", Vector2(16, 560), 1, hint)
	PixelUI.label_at(root, "K  HEAVY", Vector2(16, 576), 1, hint)
	PixelUI.label_at(root, "L  SPECIAL", Vector2(16, 592), 1, hint)
	PixelUI.label_at(root, "ATTACK        J", Vector2(1000, 544), 1, hint)
	PixelUI.label_at(root, "POWER ATTACK  K", Vector2(1000, 560), 1, hint)
	PixelUI.label_at(root, "DASH          L", Vector2(1000, 576), 1, hint)
	PixelUI.label_at(root, "BLOCK         U", Vector2(1000, 592), 1, hint)

	PixelUI.label_at(root, arena_name, Vector2(0, 96), 1, Color(0.18, 0.22, 0.16), 0, 1280).set_centered(1280)
	_combo = PixelUI.label_at(root, "", Vector2(0, 140), 3, Color(1, 0.85, 0.3), 0, 1280)
	_combo.set_centered(1280)

	p1.health_changed.connect(func(c, m): _paint_hp(_p1_hp, c, m, true))
	p2.health_changed.connect(func(c, m): _paint_hp(_p2_hp, c, m, false))
	p1.meters_changed.connect(func(s, u): _paint_meters(true, s, u))
	p2.meters_changed.connect(func(s, u): _paint_meters(false, s, u))
	_paint_hp(_p1_hp, p1.health, p1.max_health, true)
	_paint_hp(_p2_hp, p2.health, p2.max_health, false)
	_paint_meters(true, p1.special_meter, p1.ultimate_meter)
	_paint_meters(false, p2.special_meter, p2.ultimate_meter)


func _bar_tex(root: Control, pos: Vector2, w: int, h: int, col: Color) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.texture = PixelUI.tiny_hp(w, h, col, 1.0)
	t.scale = Vector2(4, 4)
	root.add_child(t)
	t.set_meta("bw", w)
	t.set_meta("bh", h)
	t.set_meta("col", col)
	return t


func _meter_tex(root: Control, pos: Vector2, w: int, h: int, col: Color) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.texture = PixelUI.meter_bar(w, h, col, 0.0)
	t.scale = Vector2(4, 4)
	root.add_child(t)
	t.set_meta("bw", w)
	t.set_meta("bh", h)
	t.set_meta("col", col)
	return t


func _gem(root: Control, pos: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.position = pos
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.scale = Vector2(3, 3)
	root.add_child(t)
	return t


func _paint_hp(bar: TextureRect, cur: float, mx: float, left: bool) -> void:
	var t := clampf(cur / max(mx, 1.0), 0.0, 1.0)
	var base: Color = bar.get_meta("col")
	var col: Color = base if t > 0.3 else Color(0.95, 0.75, 0.15)
	bar.texture = PixelUI.tiny_hp(int(bar.get_meta("bw")), int(bar.get_meta("bh")), col, t, not left)


func _paint_meters(left: bool, s: float, u: float) -> void:
	var sp: TextureRect = _p1_sp if left else _p2_sp
	var ult: TextureRect = _p1_ult if left else _p2_ult
	var spc: Color = sp.get_meta("col")
	var uc: Color = ult.get_meta("col")
	sp.texture = PixelUI.meter_bar(int(sp.get_meta("bw")), int(sp.get_meta("bh")), spc, s / 100.0, s >= 100.0)
	ult.texture = PixelUI.meter_bar(int(ult.get_meta("bw")), int(ult.get_meta("bh")), uc, u / 100.0, u >= 100.0)


func set_timer(v: int) -> void:
	_timer.set_pix("%02d" % v, 3, Color(1, 0.35, 0.3) if v <= 10 else Color(1, 1, 1))
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
