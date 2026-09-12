class_name CharacterSelect
extends Control

signal confirmed
signal cancelled

var _p1_index := 0
var _p2_index := 1
var _focus := 0
var _cards: Array[TextureRect] = []
var _thumbs: Array[TextureRect] = []
var _names: Array[PixelLabel] = []
var _info: PixelLabel
var _stats: PixelLabel
var _cpu_label: PixelLabel
var _arena_lbl: PixelLabel
var _p1_preview: Sprite2D
var _p2_preview: Sprite2D
var _p1_walk: Array = []
var _p2_walk: Array = []
var _walk_t := 0.0
var _ids: PackedStringArray = PackedStringArray()
var _held: Dictionary = {}
var _frame_cache: Dictionary = {}

const CARD_W := 40
const CARD_H := 30
const CARD_SCALE := 2
const COLS := 8
const SLOT_W := 152
const SLOT_H := 86
const ROSTER_Y := 72


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_title(self, "CHOOSE YOUR RITE", 40, Color(0.95, 0.22, 0.3))

	_ids = CharacterCatalog.ids()
	var cols: int = mini(COLS, maxi(_ids.size(), 1))
	var start_x: float = (1280.0 - float(cols) * SLOT_W) * 0.5 + 8.0
	for i in _ids.size():
		var def := CharacterCatalog.get_def(_ids[i])
		var col: int = i % cols
		var row: int = int(i / cols)
		var card := TextureRect.new()
		card.position = Vector2(start_x + col * SLOT_W, ROSTER_Y + row * SLOT_H)
		card.size = Vector2(CARD_W * CARD_SCALE, CARD_H * CARD_SCALE)
		card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(card)
		_cards.append(card)

		var thumb := TextureRect.new()
		thumb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		thumb.position = Vector2(2, 1)
		thumb.size = Vector2(CARD_W * CARD_SCALE - 4, CARD_H * CARD_SCALE - 6)
		card.add_child(thumb)
		_thumbs.append(thumb)

		var nm := PixelLabel.new()
		nm.position = Vector2(start_x + col * SLOT_W, ROSTER_Y + row * SLOT_H + CARD_H * CARD_SCALE + 2)
		nm.set_pix(def.name.to_upper(), 1, def.accent, 10)
		add_child(nm)
		_names.append(nm)

	var vs := TextureRect.new()
	vs.texture = PixelUI.vs_emblem()
	vs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vs.position = Vector2(616, 268)
	vs.scale = Vector2(3, 3)
	add_child(vs)

	PixelUI.add_panel(self, Vector2(40, 248), Vector2(360, 300), PixelUI.GOLD)
	PixelUI.label_at(self, "PLAYER 1", Vector2(40, 256), 2, Color(0.95, 0.78, 0.35), 0, 360).set_centered(360)
	var g1 := TextureRect.new()
	g1.texture = PixelUI.stage_strip()
	g1.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g1.position = Vector2(56, 478)
	g1.scale = Vector2(2.7, 3.0)
	add_child(g1)
	_p1_preview = _make_preview(Vector2(220, 430))

	PixelUI.add_panel(self, Vector2(880, 248), Vector2(360, 300), Color(0.35, 0.75, 1.0))
	var p2_hdr := PixelUI.label_at(self, "OPPONENT", Vector2(880, 256), 2, Color(0.55, 0.85, 1.0), 0, 360)
	p2_hdr.set_centered(360)
	p2_hdr.position.x = 880
	var g2 := TextureRect.new()
	g2.texture = PixelUI.stage_strip()
	g2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g2.position = Vector2(896, 478)
	g2.scale = Vector2(2.7, 3.0)
	add_child(g2)
	_p2_preview = _make_preview(Vector2(1060, 430))

	PixelUI.add_panel(self, Vector2(420, 548), Vector2(440, 96), Color(0.45, 0.35, 0.55))
	_info = PixelUI.label_at(self, "", Vector2(432, 560), 2, Color(0.92, 0.9, 0.86), 38)
	_stats = PixelUI.label_at(self, "", Vector2(432, 604), 1, Color(0.78, 0.74, 0.68), 38)
	_cpu_label = PixelUI.label_at(self, "", Vector2(880, 552), 2, Color(0.65, 0.82, 0.95), 36)
	_arena_lbl = PixelUI.label_at(self, "", Vector2(420, 520), 2, Color(0.88, 0.78, 0.42), 36)

	PixelUI.add_footer(self, "A/D SELECT  J THEN STAGE  R RANDOM  C CPU  T ARENA  F FORGE  ESC BACK")
	if GameState.arcade:
		PixelUI.label_at(self, "ARCADE LADDER", Vector2(0, 12), 2, Color(1, 0.82, 0.32), 0, 1280).set_centered(1280)
	elif GameState.survival:
		PixelUI.label_at(self, "SURVIVAL", Vector2(0, 12), 2, Color(1, 0.82, 0.32), 0, 1280).set_centered(1280)
	elif GameState.time_attack:
		PixelUI.label_at(self, "TIME ATTACK", Vector2(0, 12), 2, Color(1, 0.82, 0.32), 0, 1280).set_centered(1280)
	_apply_indices_from_state()
	for id in _ids:
		_cached_frames(id)
	_refresh()
	_play_theme()


func _make_preview(pos: Vector2) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = true
	spr.position = pos
	add_child(spr)
	return spr


func _apply_indices_from_state() -> void:
	for i in _ids.size():
		if _ids[i] == GameState.p1_character_id:
			_p1_index = i
		if _ids[i] == GameState.p2_character_id:
			_p2_index = i


func _process(delta: float) -> void:
	if not visible:
		return
	_walk_t += delta
	if _p1_preview and not _p1_walk.is_empty():
		_p1_preview.texture = _p1_walk[int(_walk_t * 14.0) % _p1_walk.size()]
		_p1_preview.position.y = 430.0 + sin(_walk_t * 2.3) * 5.0
	if _p2_preview and not _p2_walk.is_empty():
		_p2_preview.texture = _p2_walk[int(_walk_t * 14.0) % _p2_walk.size()]
		_p2_preview.position.y = 430.0 + sin(_walk_t * 2.3 + 0.8) * 5.0
	for i in _cards.size():
		var on: bool = i == _p1_index or i == _p2_index
		var pulse: float = 1.0 + (0.035 * sin(_walk_t * 9.0) if on else 0.0)
		_cards[i].modulate = Color(1.08, 1.06, 1.0) if on else Color(0.70, 0.70, 0.74, 1)
		_cards[i].scale = Vector2(pulse, pulse)
	if Input.is_action_just_pressed(ControlMap.MENU.right):
		_move(1)
	elif Input.is_action_just_pressed(ControlMap.MENU.left):
		_move(-1)
	elif Input.is_action_just_pressed(ControlMap.MENU.down) or Input.is_action_just_pressed(ControlMap.MENU.up):
		_focus = 1 - _focus
		AudioDirector.play("ui")
		_refresh()
		_play_theme()
	elif Input.is_action_just_pressed(ControlMap.MENU.confirm):
		_commit()
		AudioDirector.play("ui_confirm")
		confirmed.emit()
	elif Input.is_action_just_pressed(ControlMap.MENU.back):
		cancelled.emit()
	if _edge(KEY_R):
		_p2_index = randi() % maxi(_ids.size(), 1)
		AudioDirector.play("ui")
		_commit()
		_refresh()
	if _edge(KEY_F):
		CharacterCatalog.rebuild_custom(GameState.custom_description, GameState.custom_photo_path)
		PixelFighterBake.clear_cache("custom")
		_frame_cache.erase("custom")
		_ids = CharacterCatalog.ids()
		for i in _ids.size():
			if _ids[i] == "custom":
				_p1_index = i
		AudioDirector.play("special")
		_commit()
		_refresh()
		_play_theme()
	if _edge(KEY_C):
		GameState.p2_is_cpu = not GameState.p2_is_cpu
		_refresh()
	if _edge(KEY_T):
		_cycle_arena()
		AudioDirector.play("ui")
		_refresh()


func _edge(key: Key) -> bool:
	var down := Input.is_physical_key_pressed(key)
	var was: bool = _held.get(key, false)
	_held[key] = down
	return down and not was


func _move(dir: int) -> void:
	AudioDirector.play("ui")
	if _focus == 0:
		_p1_index = posmod(_p1_index + dir, _ids.size())
	else:
		_p2_index = posmod(_p2_index + dir, _ids.size())
	_commit()
	_refresh()
	_play_theme()


func _cycle_arena() -> void:
	var ids := ArenaWorld.all_ids()
	if GameState.random_arena:
		GameState.random_arena = false
		GameState.arena_id = ids[0]
		return
	var i := 0
	for k in ids.size():
		if ids[k] == GameState.arena_id:
			i = k
	i += 1
	if i >= ids.size():
		GameState.random_arena = true
	else:
		GameState.arena_id = ids[i]


func _commit() -> void:
	GameState.p1_character_id = _ids[_p1_index]
	GameState.p2_character_id = _ids[_p2_index]


func _cached_frames(id: String) -> Dictionary:
	if not _frame_cache.has(id):
		_frame_cache[id] = PixelFighterBake.bake(CharacterCatalog.get_def(id))
	return _frame_cache[id]


func _refresh() -> void:
	for i in _cards.size():
		var def := CharacterCatalog.get_def(_ids[i])
		var p1 := i == _p1_index
		var p2 := i == _p2_index
		_cards[i].texture = PixelUI.char_card(CARD_W, CARD_H, def.accent, p1, p2)
		var frames: Dictionary = _cached_frames(_ids[i])
		var idle: Array = frames.get("idle", [])
		if not idle.is_empty():
			_thumbs[i].texture = idle[0]
		var nm_col: Color = def.accent
		if p1:
			nm_col = Color(1, 0.88, 0.4)
		elif p2:
			nm_col = Color(0.55, 0.88, 1.0)
		_names[i].set_pix(def.name.to_upper(), 1, nm_col, 12)

	var p1_def := CharacterCatalog.get_def(_ids[_p1_index])
	var p2_def := CharacterCatalog.get_def(_ids[_p2_index])
	var focus_def := p1_def if _focus == 0 else p2_def
	var who := "PLAYER 1" if _focus == 0 else "CPU / P2"
	_info.set_pix("%s — %s  %s" % [who, focus_def.name, focus_def.title], 2, Color(0.92, 0.9, 0.86), 38)
	_stats.set_pix("HP %s  SPD %s  ATK %s  DEF %s" % [
		_pips(focus_def.health, 700.0, 1200.0),
		_pips(focus_def.speed, 240.0, 380.0),
		_pips(focus_def.attack, 0.85, 1.15),
		_pips(focus_def.defense, 0.75, 1.15)
	], 1, Color(0.78, 0.74, 0.68), 42)
	_cpu_label.set_pix("%s  ·  %s  ·  L %s  O %s" % [
		p2_def.name,
		"CPU " + GameState.difficulty_name() if GameState.p2_is_cpu else "HUMAN",
		focus_def.special_name,
		focus_def.ultimate_name
	], 2, Color(0.65, 0.82, 0.95), 36)
	if _arena_lbl:
		var an: String = "RANDOM" if GameState.random_arena else ArenaWorld.display_name(GameState.arena_id)
		_arena_lbl.set_pix("STAGE  %s" % an, 2, Color(0.88, 0.78, 0.42), 36)

	var p1_frames: Dictionary = _cached_frames(_ids[_p1_index])
	var p2_frames: Dictionary = _cached_frames(_ids[_p2_index])
	_p1_walk = p1_frames.get("walk", p1_frames["idle"])
	_p2_walk = p2_frames.get("walk", p2_frames["idle"])
	_p1_preview.texture = _p1_walk[0]
	_p2_preview.texture = _p2_walk[0]
	_p1_preview.scale = Vector2(3.0 * p1_def.width_scale, 3.0 * p1_def.height_scale)
	_p2_preview.scale = Vector2(-3.0 * p2_def.width_scale, 3.0 * p2_def.height_scale)


func _pips(v: float, lo: float, hi: float) -> String:
	var n := clampi(int(round((v - lo) / maxf(hi - lo, 0.01) * 8.0)), 1, 8)
	var s := ""
	for i in 8:
		s += "I" if i < n else "."
	return s


func _play_theme() -> void:
	if _ids.is_empty():
		return
	var idx: int = _p1_index if _focus == 0 else _p2_index
	AudioDirector.play_music("theme:" + _ids[idx])
