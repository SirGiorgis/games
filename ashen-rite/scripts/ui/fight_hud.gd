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
var _hints: Array[CanvasItem] = []
var _hint_t := 0.0
var _show1 := 1.0
var _show2 := 1.0
var _chip1 := 1.0
var _chip2 := 1.0
var _delay1 := 0.0
var _delay2 := 0.0
var _sp_show1 := 0.0
var _sp_show2 := 0.0
var _ult_show1 := 0.0
var _ult_show2 := 0.0
var _last_timer := -1
var _combo_punch := 0.0
var _tbox: TextureRect


func bind(p1: Fighter, p2: Fighter, arena_name: String) -> void:
	layer = 12
	_p1 = p1
	_p2 = p2
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var veil := ColorRect.new()
	veil.color = Color(0.03, 0.05, 0.07, 0.32)
	veil.position = Vector2(0, 0)
	veil.size = Vector2(1280, 88)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(veil)

	var p1_name := _callsign(p1.def)
	var p2_name := _callsign(p2.def)
	var p1w: int = maxi(28, p1_name.length() * 6 + 10)
	var p2w: int = maxi(28, p2_name.length() * 6 + 10)

	var p1_pill := TextureRect.new()
	p1_pill.texture = PixelUI.name_pill(p1w, 10, Color(0.05, 0.05, 0.06))
	p1_pill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p1_pill.position = Vector2(16, 8)
	p1_pill.scale = Vector2(4, 4)
	root.add_child(p1_pill)
	PixelUI.label_at(root, p1_name, Vector2(24, 12), 2, Color(0.98, 0.98, 0.95))

	var p2_pill := TextureRect.new()
	p2_pill.texture = PixelUI.name_pill(p2w, 10, Color(0.05, 0.05, 0.06))
	p2_pill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p2_pill.position = Vector2(1280 - 16 - p2w * 4, 8)
	p2_pill.scale = Vector2(4, 4)
	root.add_child(p2_pill)
	var p2n := PixelUI.label_at(root, p2_name, Vector2(1280 - 16 - p2w * 4, 12), 2, Color(0.98, 0.98, 0.95), 0, p2w * 4)
	p2n.set_centered(p2w * 4)

	_p1_hp = _bar_tex(root, Vector2(16, 52), 140, 10, Color(0.28, 0.82, 0.22))
	_p2_hp = _bar_tex(root, Vector2(704, 52), 140, 10, Color(0.86, 0.18, 0.22))

	_tbox = TextureRect.new()
	_tbox.texture = PixelUI.timer_box()
	_tbox.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tbox.position = Vector2(592, 6)
	_tbox.scale = Vector2(4, 4)
	root.add_child(_tbox)
	_timer = PixelUI.label_at(root, "99", Vector2(592, 36), 3, Color(1, 1, 1), 0, 96)
	_timer.set_centered(96)

	_p1_sp = _meter_tex(root, Vector2(16, 100), 52, 5, Color(0.86, 0.32, 0.62))
	_p2_sp = _meter_tex(root, Vector2(1056, 100), 52, 5, Color(0.86, 0.32, 0.62))
	PixelUI.label_at(root, "BLOCK", Vector2(16, 88), 1, Color(0.92, 0.45, 0.7))
	PixelUI.label_at(root, "BLOCK", Vector2(1056, 88), 1, Color(0.92, 0.45, 0.7))

	for i in 2:
		_p1_rounds.append(_gem(root, Vector2(16 + p1w * 4 + 12 + i * 28, 12)))
		_p2_rounds.append(_gem(root, Vector2(1280 - 16 - p2w * 4 - 40 - i * 28, 12)))

	_p1_ult = _meter_tex(root, Vector2(16, 676), 80, 6, Color(0.25, 0.72, 0.95))
	_p2_ult = _meter_tex(root, Vector2(944, 676), 80, 6, Color(0.95, 0.78, 0.25))
	PixelUI.label_at(root, "SPECIAL", Vector2(16, 660), 1, Color(0.12, 0.16, 0.2))
	PixelUI.label_at(root, "SPECIAL", Vector2(944, 660), 1, Color(0.12, 0.16, 0.2))

	var hint := Color(0.95, 0.95, 0.92)
	_hints.append(PixelUI.label_at(root, "J LIGHT   K HEAVY   L SPECIAL   U BLOCK", Vector2(0, 696), 1, hint, 0, 1280))
	_hints[0].set_centered(1280)

	PixelUI.label_at(root, arena_name, Vector2(0, 124), 1, Color(0.16, 0.20, 0.14), 0, 1280).set_centered(1280)
	_combo = PixelUI.label_at(root, "", Vector2(0, 168), 3, Color(1, 0.85, 0.3), 0, 1280)
	_combo.set_centered(1280)
	_combo.visible = false

	_show1 = 1.0
	_show2 = 1.0
	_chip1 = 1.0
	_chip2 = 1.0
	_paint_hp(_p1_hp, 1.0, 1.0, true)
	_paint_hp(_p2_hp, 1.0, 1.0, false)


func _process(delta: float) -> void:
	if _p1 == null or _p2 == null:
		return
	_tick_bar(delta, true)
	_tick_bar(delta, false)
	_sp_show1 = move_toward(_sp_show1, _p1.special_meter / 100.0, 2.4 * delta)
	_sp_show2 = move_toward(_sp_show2, _p2.special_meter / 100.0, 2.4 * delta)
	_ult_show1 = move_toward(_ult_show1, _p1.ultimate_meter / 100.0, 1.8 * delta)
	_ult_show2 = move_toward(_ult_show2, _p2.ultimate_meter / 100.0, 1.8 * delta)
	_paint_meters()
	_hint_t += delta
	var ha: float = 1.0 if _hint_t < 4.2 else clampf(1.0 - (_hint_t - 4.2) * 0.7, 0.0, 1.0)
	for n in _hints:
		n.modulate.a = ha
	if _combo_punch > 0.0:
		_combo_punch = max(0.0, _combo_punch - delta * 4.0)
		_combo.modulate = Color.WHITE.lerp(Color(1.4, 1.15, 0.55), _combo_punch)
	if _tbox:
		var pulse: float = 1.0 + (0.06 * sin(Time.get_ticks_msec() * 0.012) if _last_timer <= 10 and _last_timer >= 0 else 0.0)
		_tbox.scale = Vector2(4 * pulse, 4 * pulse)
		_tbox.position = Vector2(640.0 - 48.0 * pulse, 6.0 + (1.0 - pulse) * 24.0)


func _tick_bar(delta: float, left: bool) -> void:
	var f: Fighter = _p1 if left else _p2
	var actual: float = clampf(f.health / max(f.max_health, 1.0), 0.0, 1.0)
	if left:
		if actual + 0.002 < _show1:
			_delay1 = 0.42
		_show1 = move_toward(_show1, actual, 5.5 * delta)
		if actual >= _chip1:
			_chip1 = actual
		else:
			_delay1 -= delta
			if _delay1 <= 0.0:
				_chip1 = move_toward(_chip1, actual, 0.75 * delta)
		_paint_hp(_p1_hp, _show1, _chip1, true)
	else:
		if actual + 0.002 < _show2:
			_delay2 = 0.42
		_show2 = move_toward(_show2, actual, 5.5 * delta)
		if actual >= _chip2:
			_chip2 = actual
		else:
			_delay2 -= delta
			if _delay2 <= 0.0:
				_chip2 = move_toward(_chip2, actual, 0.75 * delta)
		_paint_hp(_p2_hp, _show2, _chip2, false)


func _callsign(def: CharacterDef) -> String:
	var n: String = def.name.strip_edges()
	var sp: int = n.find(" ")
	if sp > 0:
		return n.substr(0, sp).to_upper()
	return n.to_upper()


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


func _paint_hp(bar: TextureRect, cur: float, chip: float, left: bool) -> void:
	var t := clampf(cur, 0.0, 1.0)
	var base: Color = bar.get_meta("col")
	var col: Color = base if t > 0.3 else Color(0.95, 0.75, 0.15)
	if t <= 0.15:
		col = Color(0.95, 0.22, 0.18)
	bar.texture = PixelUI.tiny_hp(int(bar.get_meta("bw")), int(bar.get_meta("bh")), col, t, not left, chip)


func _paint_meters() -> void:
	var spc: Color = _p1_sp.get_meta("col")
	var uc: Color = _p1_ult.get_meta("col")
	_p1_sp.texture = PixelUI.meter_bar(int(_p1_sp.get_meta("bw")), int(_p1_sp.get_meta("bh")), spc, _sp_show1, _sp_show1 >= 0.99)
	_p2_sp.texture = PixelUI.meter_bar(int(_p2_sp.get_meta("bw")), int(_p2_sp.get_meta("bh")), _p2_sp.get_meta("col"), _sp_show2, _sp_show2 >= 0.99)
	_p1_ult.texture = PixelUI.meter_bar(int(_p1_ult.get_meta("bw")), int(_p1_ult.get_meta("bh")), uc, _ult_show1, _ult_show1 >= 0.99)
	_p2_ult.texture = PixelUI.meter_bar(int(_p2_ult.get_meta("bw")), int(_p2_ult.get_meta("bh")), _p2_ult.get_meta("col"), _ult_show2, _ult_show2 >= 0.99)


func set_timer(v: int) -> void:
	if v == _last_timer:
		return
	_last_timer = v
	_timer.set_pix("%02d" % v, 3, Color(1, 0.35, 0.3) if v <= 10 else Color(1, 1, 1))
	_timer.position = Vector2(592, 36)
	_timer.set_centered(96)


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
		_combo_punch = 1.0
	else:
		_combo.visible = false
		_combo.modulate = Color.WHITE
