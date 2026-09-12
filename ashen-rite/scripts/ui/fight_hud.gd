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
var _max1: PixelLabel
var _max2: PixelLabel
var _ex1: PixelLabel
var _ex2: PixelLabel
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
var _hp_kick1 := 0.0
var _hp_kick2 := 0.0
var _t := 0.0
var _hp1_pos := Vector2(16, 56)
var _hp2_pos := Vector2(712, 56)
var _low1 := false
var _low2 := false
var _hp_n1: PixelLabel
var _hp_n2: PixelLabel
var _rank: PixelLabel
var _g1: TextureRect
var _g2: TextureRect
var _rage1: PixelLabel
var _rage2: PixelLabel
var _buff1: PixelLabel
var _buff2: PixelLabel
var _poison1: PixelLabel
var _poison2: PixelLabel
var _train: PixelLabel
var _mode: PixelLabel
var _p1_port: TextureRect
var _p2_port: TextureRect


func bind(p1: Fighter, p2: Fighter, arena_name: String) -> void:
	layer = 12
	_p1 = p1
	_p2 = p2
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var veil := ColorRect.new()
	veil.color = Color(0.02, 0.03, 0.04, 0.42)
	veil.position = Vector2(0, 0)
	veil.size = Vector2(1280, 108)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(veil)
	var hair := ColorRect.new()
	hair.color = Color(0.92, 0.74, 0.28, 0.55)
	hair.position = Vector2(0, 108)
	hair.size = Vector2(1280, 2)
	hair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hair)

	var p1_name := _callsign(p1.def)
	var p2_name := _callsign(p2.def)
	var p1w: int = maxi(30, p1_name.length() * 6 + 12)
	var p2w: int = maxi(30, p2_name.length() * 6 + 12)

	var p1_port := TextureRect.new()
	p1_port.texture = PixelUI.fighter_portrait(_idle_tex(p1), p1.def.accent)
	p1_port.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p1_port.position = Vector2(16, 8)
	p1_port.scale = Vector2(4, 4)
	root.add_child(p1_port)
	_p1_port = p1_port

	var p1_pill := TextureRect.new()
	p1_pill.texture = PixelUI.name_pill(p1w, 11, Color(0.05, 0.05, 0.06), p1.def.accent)
	p1_pill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p1_pill.position = Vector2(112, 10)
	p1_pill.scale = Vector2(4, 4)
	root.add_child(p1_pill)
	PixelUI.label_at(root, p1_name, Vector2(124, 16), 2, Color(0.98, 0.98, 0.95))

	var p2_port := TextureRect.new()
	p2_port.texture = PixelUI.fighter_portrait(_idle_tex(p2), p2.def.accent)
	p2_port.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p2_port.position = Vector2(1280 - 16 - 88, 8)
	p2_port.scale = Vector2(4, 4)
	root.add_child(p2_port)
	_p2_port = p2_port

	var p2_pill := TextureRect.new()
	p2_pill.texture = PixelUI.name_pill(p2w, 11, Color(0.05, 0.05, 0.06), p2.def.accent)
	p2_pill.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p2_pill.position = Vector2(1280 - 112 - p2w * 4, 10)
	p2_pill.scale = Vector2(4, 4)
	root.add_child(p2_pill)
	var p2n := PixelUI.label_at(root, p2_name, Vector2(1280 - 112 - p2w * 4, 16), 2, Color(0.98, 0.98, 0.95), 0, p2w * 4)
	p2n.set_centered(p2w * 4)

	_hp1_pos = Vector2(16, 60)
	_hp2_pos = Vector2(712, 60)
	_p1_hp = _bar_tex(root, _hp1_pos, 138, 11, Color(0.30, 0.84, 0.24).lerp(p1.def.accent, 0.22))
	_p2_hp = _bar_tex(root, _hp2_pos, 138, 11, Color(0.90, 0.18, 0.22).lerp(p2.def.accent, 0.18))
	_hp_n1 = PixelUI.label_at(root, "%d" % int(p1.max_health), Vector2(24, 64), 1, Color(0.98, 0.98, 0.94))
	_hp_n2 = PixelUI.label_at(root, "%d" % int(p2.max_health), Vector2(712, 64), 1, Color(0.98, 0.98, 0.94), 0, 552)
	_hp_n2.set_centered(552)

	_tbox = TextureRect.new()
	_tbox.texture = PixelUI.timer_box()
	_tbox.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tbox.position = Vector2(588, 4)
	_tbox.scale = Vector2(4, 4)
	root.add_child(_tbox)
	_timer = PixelUI.label_at(root, "99", Vector2(588, 34), 3, Color(1, 1, 1), 0, 104)
	_timer.set_centered(104)
	var vs := PixelUI.label_at(root, "VS", Vector2(588, 88), 1, Color(0.95, 0.78, 0.32), 0, 104)
	vs.set_centered(104)

	_p1_sp = _meter_tex(root, Vector2(16, 116), 56, 6, Color(0.88, 0.34, 0.64))
	_p2_sp = _meter_tex(root, Vector2(1040, 116), 56, 6, Color(0.88, 0.34, 0.64))
	PixelUI.label_at(root, "METER", Vector2(16, 104), 1, Color(0.94, 0.48, 0.72))
	PixelUI.label_at(root, "METER", Vector2(1040, 104), 1, Color(0.94, 0.48, 0.72))
	_g1 = _meter_tex(root, Vector2(16, 142), 56, 4, Color(0.95, 0.78, 0.28))
	_g2 = _meter_tex(root, Vector2(1040, 142), 56, 4, Color(0.95, 0.78, 0.28))
	PixelUI.label_at(root, "GUARD", Vector2(16, 132), 1, Color(0.9, 0.82, 0.5))
	PixelUI.label_at(root, "GUARD", Vector2(1040, 132), 1, Color(0.9, 0.82, 0.5))
	_rage1 = PixelUI.label_at(root, "RAGE", Vector2(248, 84), 1, Color(1.0, 0.35, 0.28))
	_rage1.visible = false
	_rage2 = PixelUI.label_at(root, "RAGE", Vector2(990, 84), 1, Color(1.0, 0.35, 0.28))
	_rage2.visible = false
	_buff1 = PixelUI.label_at(root, "VODKA", Vector2(300, 84), 1, Color(0.62, 0.95, 0.88))
	_buff1.visible = false
	_buff2 = PixelUI.label_at(root, "VODKA", Vector2(930, 84), 1, Color(0.62, 0.95, 0.88))
	_buff2.visible = false
	_poison1 = PixelUI.label_at(root, "POISON", Vector2(360, 84), 1, Color(0.55, 0.92, 0.32))
	_poison1.visible = false
	_poison2 = PixelUI.label_at(root, "POISON", Vector2(860, 84), 1, Color(0.55, 0.92, 0.32))
	_poison2.visible = false
	_ex1 = PixelUI.label_at(root, "EX", Vector2(248, 104), 1, Color(1.0, 0.55, 0.85))
	_ex1.visible = false
	_ex2 = PixelUI.label_at(root, "EX", Vector2(990, 104), 1, Color(1.0, 0.55, 0.85))
	_ex2.visible = false

	for i in 2:
		_p1_rounds.append(_gem(root, Vector2(112 + p1w * 4 + 10 + i * 32, 14)))
		_p2_rounds.append(_gem(root, Vector2(1280 - 112 - p2w * 4 - 42 - i * 32, 14)))

	var bot := ColorRect.new()
	bot.color = Color(0.03, 0.04, 0.04, 0.38)
	bot.position = Vector2(0, 648)
	bot.size = Vector2(1280, 72)
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bot)

	_p1_ult = _meter_tex(root, Vector2(16, 668), 88, 7, Color(0.25, 0.74, 0.96))
	_p2_ult = _meter_tex(root, Vector2(912, 668), 88, 7, Color(0.96, 0.80, 0.26))
	PixelUI.label_at(root, "SUPER", Vector2(16, 652), 1, Color(0.92, 0.90, 0.84))
	PixelUI.label_at(root, "SUPER", Vector2(912, 652), 1, Color(0.92, 0.90, 0.84))
	_max1 = PixelUI.label_at(root, "MAX", Vector2(380, 668), 2, Color(0.45, 0.9, 1.0))
	_max1.visible = false
	_max2 = PixelUI.label_at(root, "MAX", Vector2(860, 668), 2, Color(1.0, 0.88, 0.35))
	_max2.visible = false

	var hint := Color(0.96, 0.96, 0.92)
	_hints.append(PixelUI.label_at(root, "J LIGHT   K HEAVY   L SPECIAL / EX   U BLOCK   FWD+U PARRY   RUN+J DASH   O SUPER", Vector2(0, 700), 1, hint, 0, 1280))
	_hints[0].set_centered(1280)

	PixelUI.label_at(root, arena_name.to_upper(), Vector2(0, 132), 1, Color(0.18, 0.22, 0.14), 0, 1280).set_centered(1280)
	var sub: String = "TRAINING" if GameState.training else (GameState.difficulty_name() if GameState.p2_is_cpu else "VS HUMAN")
	if GameState.attract:
		sub = "DEMO"
	if GameState.arcade:
		sub = "ARCADE  %d / %d" % [GameState.arcade_index + 1, maxi(GameState.arcade_queue.size(), 1)]
	elif GameState.survival:
		sub = "SURVIVAL  WAVE %d" % GameState.survival_wave
	elif GameState.time_attack:
		sub = "TIME ATTACK"
	_mode = PixelUI.label_at(root, sub, Vector2(0, 148), 1, Color(0.22, 0.26, 0.18, 0.85), 0, 1280)
	_mode.set_centered(1280)
	_combo = PixelUI.label_at(root, "", Vector2(0, 168), 4, Color(1, 0.86, 0.28), 0, 1280)
	_combo.set_centered(1280)
	_combo.visible = false
	_combo.pivot_offset = Vector2(640, 14)
	_rank = PixelUI.label_at(root, "", Vector2(0, 214), 2, Color(1.0, 0.72, 0.28), 0, 1280)
	_rank.set_centered(1280)
	_rank.visible = false
	_train = PixelUI.label_at(root, "", Vector2(16, 520), 1, Color(0.88, 0.9, 0.78), 42)
	_train.visible = GameState.training or GameState.survival or GameState.time_attack

	_show1 = 1.0
	_show2 = 1.0
	_chip1 = 1.0
	_chip2 = 1.0
	_paint_hp(_p1_hp, 1.0, 1.0, true)
	_paint_hp(_p2_hp, 1.0, 1.0, false)


func _idle_tex(f: Fighter) -> Texture2D:
	if f and f.visual:
		return f.visual.idle_tex()
	return PixelFighterBake.bake(f.def)["idle"][0]


func _process(delta: float) -> void:
	if _p1 == null or _p2 == null:
		return
	_t += delta
	_tick_bar(delta, true)
	_tick_bar(delta, false)
	_sp_show1 = lerpf(_sp_show1, _p1.special_meter / 100.0, 1.0 - exp(-delta * 8.0))
	_sp_show2 = lerpf(_sp_show2, _p2.special_meter / 100.0, 1.0 - exp(-delta * 8.0))
	_ult_show1 = lerpf(_ult_show1, _p1.ultimate_meter / 100.0, 1.0 - exp(-delta * 6.2))
	_ult_show2 = lerpf(_ult_show2, _p2.ultimate_meter / 100.0, 1.0 - exp(-delta * 6.2))
	_paint_meters()
	_hint_t += delta
	var ha: float = 1.0 if _hint_t < 3.6 else clampf(1.0 - (_hint_t - 3.6) * 0.85, 0.0, 1.0)
	for n in _hints:
		n.modulate.a = ha
	if _combo_punch > 0.0:
		_combo_punch = max(0.0, _combo_punch - delta * 4.4)
		var s: float = 1.0 + _combo_punch * 0.22
		_combo.scale = Vector2(s, s)
		_combo.modulate = Color.WHITE.lerp(Color(1.45, 1.18, 0.5), _combo_punch)
	_hp_kick1 = max(0.0, _hp_kick1 - delta * 7.0)
	_hp_kick2 = max(0.0, _hp_kick2 - delta * 7.0)
	_p1_hp.position = _hp1_pos + Vector2(sin(_t * 62.0) * _hp_kick1 * 5.0, 0)
	_p2_hp.position = _hp2_pos + Vector2(sin(_t * 62.0) * _hp_kick2 * 5.0, 0)
	if _low1:
		_p1_hp.modulate = Color(1, 1, 1).lerp(Color(1.25, 0.75, 0.7), 0.5 + 0.5 * sin(_t * 8.0))
	else:
		_p1_hp.modulate = Color.WHITE
	if _low2:
		_p2_hp.modulate = Color(1, 1, 1).lerp(Color(1.25, 0.75, 0.7), 0.5 + 0.5 * sin(_t * 8.0))
	else:
		_p2_hp.modulate = Color.WHITE
	if _tbox:
		var pulse: float = 1.0 + (0.07 * sin(_t * 10.0) if _last_timer <= 10 and _last_timer >= 0 else 0.0)
		_tbox.scale = Vector2(4 * pulse, 4 * pulse)
		_tbox.position = Vector2(640.0 - 52.0 * pulse, 4.0 + (1.0 - pulse) * 26.0)
	if _p1_ult:
		_p1_ult.modulate = Color(1.15, 1.12, 0.9) if _ult_show1 >= 0.99 else Color.WHITE
		_p1_ult.modulate.a = 1.0
		if _ult_show1 >= 0.99:
			_p1_ult.modulate = Color.WHITE.lerp(Color(1.3, 1.25, 0.85), 0.5 + 0.5 * sin(_t * 7.0))
	if _p2_ult:
		if _ult_show2 >= 0.99:
			_p2_ult.modulate = Color.WHITE.lerp(Color(1.3, 1.22, 0.75), 0.5 + 0.5 * sin(_t * 7.0))
		else:
			_p2_ult.modulate = Color.WHITE
	if _max1:
		_max1.visible = _ult_show1 >= 0.99
		if _max1.visible:
			_max1.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 8.0))
	if _max2:
		_max2.visible = _ult_show2 >= 0.99
		if _max2.visible:
			_max2.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 8.0))
	if _ex1:
		_ex1.visible = _sp_show1 >= 0.99
		if _ex1.visible:
			_ex1.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 9.0))
	if _ex2:
		_ex2.visible = _sp_show2 >= 0.99
		if _ex2.visible:
			_ex2.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 9.0))
	if _rage1:
		_rage1.visible = _p1.raging()
		if _rage1.visible:
			_rage1.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 11.0))
	if _rage2:
		_rage2.visible = _p2.raging()
		if _rage2.visible:
			_rage2.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 11.0))
	if _buff1:
		_sync_buff(_buff1, _p1)
	if _buff2:
		_sync_buff(_buff2, _p2)
	if _poison1:
		_poison1.visible = _p1.poisoned()
		if _poison1.visible:
			_poison1.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 10.0))
	if _poison2:
		_poison2.visible = _p2.poisoned()
		if _poison2.visible:
			_poison2.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 10.0))
	if _p1_port:
		_p1_port.modulate = Color(1.25, 0.82, 0.78) if _p1.raging() else Color.WHITE
	if _p2_port:
		_p2_port.modulate = Color(1.25, 0.82, 0.78) if _p2.raging() else Color.WHITE
	if _hp_n1:
		_hp_n1.set_pix("%d" % int(round(_p1.health)), 1, Color(1, 0.45, 0.35) if _low1 else Color(0.98, 0.98, 0.94))
	if _hp_n2:
		_hp_n2.set_pix("%d" % int(round(_p2.health)), 1, Color(1, 0.45, 0.35) if _low2 else Color(0.98, 0.98, 0.94))
		_hp_n2.set_centered(552)
	_paint_guard()
	_paint_training()
	_refresh_combo()


func _tick_bar(delta: float, left: bool) -> void:
	var f: Fighter = _p1 if left else _p2
	var actual: float = clampf(f.health / max(f.max_health, 1.0), 0.0, 1.0)
	if left:
		if actual + 0.002 < _show1:
			_delay1 = 0.38
			_hp_kick1 = 1.0
		_show1 = lerpf(_show1, actual, 1.0 - exp(-delta * 14.0))
		if actual >= _chip1:
			_chip1 = actual
		else:
			_delay1 -= delta
			if _delay1 <= 0.0:
				_chip1 = move_toward(_chip1, actual, 0.85 * delta)
		_low1 = actual <= 0.18
		_paint_hp(_p1_hp, _show1, _chip1, true)
	else:
		if actual + 0.002 < _show2:
			_delay2 = 0.38
			_hp_kick2 = 1.0
		_show2 = lerpf(_show2, actual, 1.0 - exp(-delta * 14.0))
		if actual >= _chip2:
			_chip2 = actual
		else:
			_delay2 -= delta
			if _delay2 <= 0.0:
				_chip2 = move_toward(_chip2, actual, 0.85 * delta)
		_low2 = actual <= 0.18
		_paint_hp(_p2_hp, _show2, _chip2, false)


func _callsign(def: CharacterDef) -> String:
	return def.callsign()


func _sync_buff(lbl: PixelLabel, f: Fighter) -> void:
	lbl.visible = f.buffed()
	if not lbl.visible:
		return
	var flex: bool = f.def.ultimate_id == "flex"
	var tag := "FLEX" if flex else "VODKA"
	var col := Color(1.0, 0.72, 0.28) if flex else Color(0.62, 0.95, 0.88)
	lbl.set_pix(tag, 1, col)
	lbl.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 9.0))


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
	var col: Color = base if t > 0.32 else Color(0.96, 0.78, 0.16)
	if t <= 0.16:
		col = Color(0.96, 0.22, 0.18)
	bar.texture = PixelUI.tiny_hp(int(bar.get_meta("bw")), int(bar.get_meta("bh")), col, t, not left, chip)


func _paint_meters() -> void:
	var spc: Color = _p1_sp.get_meta("col")
	var uc: Color = _p1_ult.get_meta("col")
	_p1_sp.texture = PixelUI.meter_bar(int(_p1_sp.get_meta("bw")), int(_p1_sp.get_meta("bh")), spc, _sp_show1, _sp_show1 >= 0.99)
	_p2_sp.texture = PixelUI.meter_bar(int(_p2_sp.get_meta("bw")), int(_p2_sp.get_meta("bh")), _p2_sp.get_meta("col"), _sp_show2, _sp_show2 >= 0.99)
	_p1_ult.texture = PixelUI.meter_bar(int(_p1_ult.get_meta("bw")), int(_p1_ult.get_meta("bh")), uc, _ult_show1, _ult_show1 >= 0.99)
	_p2_ult.texture = PixelUI.meter_bar(int(_p2_ult.get_meta("bw")), int(_p2_ult.get_meta("bh")), _p2_ult.get_meta("col"), _ult_show2, _ult_show2 >= 0.99)


func _paint_guard() -> void:
	if _g1 == null or _p1 == null:
		return
	var t1: float = clampf(_p1.guard_meter / 100.0, 0.0, 1.0)
	var t2: float = clampf(_p2.guard_meter / 100.0, 0.0, 1.0)
	_g1.texture = PixelUI.meter_bar(int(_g1.get_meta("bw")), int(_g1.get_meta("bh")), _g1.get_meta("col"), t1, t1 >= 0.92)
	_g2.texture = PixelUI.meter_bar(int(_g2.get_meta("bw")), int(_g2.get_meta("bh")), _g2.get_meta("col"), t2, t2 >= 0.92)


func _paint_training() -> void:
	if _train == null or _p1 == null:
		return
	if GameState.training:
		_train.visible = true
		var adv: int = int(round(_p1.last_advantage * 60.0))
		var sign_s: String = "+" if adv >= 0 else ""
		var hist := ""
		for i in _p1.input_log.size():
			if i > 0:
				hist += " "
			hist += _p1.input_log[i]
		_train.set_pix("R RESET   F DUMMY %s   ADV %s%dF   %s\n%s" % [
			GameState.dummy_mode.to_upper(),
			sign_s,
			adv,
			_p1.last_move.to_upper(),
			hist
		], 1, Color(0.88, 0.92, 0.78), 48)
		return
	if GameState.survival:
		_train.visible = true
		_train.set_pix("WAVE %d   SCORE %d   MAX %d HIT" % [
			GameState.survival_wave, GameState.arcade_score, GameState.match_max_combo
		], 1, Color(0.88, 0.92, 0.78), 48)
		return
	if GameState.time_attack:
		_train.visible = true
		_train.set_pix("DMG %d   MAX %d HIT   HITS %d" % [
			int(GameState.match_damage), GameState.match_max_combo, GameState.match_hits
		], 1, Color(0.88, 0.92, 0.78), 48)
		return
	_train.visible = false


func set_timer(v: int) -> void:
	if v == _last_timer:
		return
	_last_timer = v
	_timer.set_pix("%02d" % v, 3, Color(1, 0.32, 0.28) if v <= 10 else Color(1, 1, 1))
	_timer.position = Vector2(588, 34)
	_timer.set_centered(104)


func set_rounds(a: int, b: int) -> void:
	for i in _p1_rounds.size():
		_p1_rounds[i].texture = PixelUI.round_gem(i < a)
	for i in _p2_rounds.size():
		_p2_rounds[i].texture = PixelUI.round_gem(i < b)


func set_combo(_side: int, n: int) -> void:
	if n >= 2:
		_combo.visible = true
		_combo_punch = 1.0
		_refresh_combo()
	else:
		_combo.visible = false
		_combo.modulate = Color.WHITE
		_combo.scale = Vector2.ONE
		if _rank:
			_rank.visible = false


func _refresh_combo() -> void:
	if _combo == null or _p1 == null or _p2 == null:
		return
	var n: int = maxi(_p1.combo_hits, _p2.combo_hits)
	if n < 2:
		if _combo.visible and _combo_punch <= 0.0:
			_combo.visible = false
		if _rank:
			_rank.visible = false
		return
	var dmg: float = _p1.combo_damage if _p1.combo_hits >= _p2.combo_hits else _p2.combo_damage
	var sc: int = int(round(CombatRules.combo_scale(n) * 100.0))
	var col := Color(1, 0.86, 0.28)
	if n >= 8:
		col = Color(1.0, 0.45, 0.22)
	elif n >= 5:
		col = Color(1.0, 0.72, 0.28)
	_combo.set_pix("%d HIT  %d  %d%%" % [n, int(round(dmg)), sc], 4, col)
	_combo.set_centered(1280)
	_combo.visible = true
	var rk: String = CombatRules.combo_rank(n)
	if _rank:
		if rk.is_empty():
			_rank.visible = false
		else:
			_rank.visible = true
			_rank.set_pix(rk, 2, col)
			_rank.set_centered(1280)
