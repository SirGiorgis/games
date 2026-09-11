class_name CharacterSelect
extends Control

signal confirmed
signal cancelled

var _p1_index := 0
var _p2_index := 1
var _focus := 0
var _cards: Array[Panel] = []
var _info: Label
var _stats: Label
var _hint: Label
var _cpu_label: Label
var _portrait_host: Control
var _preview: FighterVisual
var _ids: PackedStringArray = PackedStringArray()


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.02, 0.05)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "CHOOSE YOUR RITE"
	title.position = Vector2(0, 24)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(title, 36, Color(0.92, 0.22, 0.28))
	add_child(title)

	_ids = CharacterCatalog.ids()
	var row := HBoxContainer.new()
	row.position = Vector2(40, 90)
	row.size = Vector2(1200, 160)
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	for i in _ids.size():
		var def := CharacterCatalog.get_def(_ids[i])
		var card := _make_card(def)
		row.add_child(card)
		_cards.append(card)

	_portrait_host = Control.new()
	_portrait_host.position = Vector2(160, 420)
	add_child(_portrait_host)

	_info = Label.new()
	_info.position = Vector2(380, 290)
	_info.size = Vector2(820, 120)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(_info, 20)
	add_child(_info)

	_stats = Label.new()
	_stats.position = Vector2(380, 420)
	_stats.size = Vector2(820, 140)
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(_stats, 18, Color(0.85, 0.8, 0.7))
	add_child(_stats)

	_cpu_label = Label.new()
	_cpu_label.position = Vector2(40, 620)
	_cpu_label.size = Vector2(1200, 30)
	UIKit.style_label(_cpu_label, 18, Color(0.7, 0.85, 0.9))
	add_child(_cpu_label)

	_hint = Label.new()
	_hint.position = Vector2(40, 660)
	_hint.size = Vector2(1200, 40)
	_hint.text = "A/D select   W/S P1 or CPU slot   J/Enter confirm   R random CPU   F forge custom from description   Esc back"
	UIKit.style_label(_hint, 15, Color(0.62, 0.6, 0.58))
	add_child(_hint)

	_apply_indices_from_state()
	_refresh()


func _apply_indices_from_state() -> void:
	for i in _ids.size():
		if _ids[i] == GameState.p1_character_id:
			_p1_index = i
		if _ids[i] == GameState.p2_character_id:
			_p2_index = i


func _make_card(def: CharacterDef) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(180, 150)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.07, 0.12)
	sb.border_color = def.accent
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	var name := Label.new()
	name.text = def.name
	name.position = Vector2(8, 10)
	name.size = Vector2(164, 40)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(name, 16, def.accent)
	p.add_child(name)
	var t := Label.new()
	t.text = def.title
	t.position = Vector2(8, 50)
	t.size = Vector2(164, 30)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(t, 13, Color(0.8, 0.75, 0.55))
	p.add_child(t)
	var swatch := ColorRect.new()
	swatch.position = Vector2(50, 90)
	swatch.size = Vector2(80, 40)
	swatch.color = def.outfit
	p.add_child(swatch)
	var sw2 := ColorRect.new()
	sw2.position = Vector2(70, 100)
	sw2.size = Vector2(40, 20)
	sw2.color = def.accent
	p.add_child(sw2)
	return p


var _held: Dictionary = {}


func _process(_d: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(ControlMap.MENU.right):
		_move(1)
	elif Input.is_action_just_pressed(ControlMap.MENU.left):
		_move(-1)
	elif Input.is_action_just_pressed(ControlMap.MENU.down) or Input.is_action_just_pressed(ControlMap.MENU.up):
		_focus = 1 - _focus
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.confirm):
		_confirm()
	elif Input.is_action_just_pressed(ControlMap.MENU.back):
		cancelled.emit()
	if _edge(KEY_R):
		_p2_index = randi() % maxi(_ids.size(), 1)
		AudioDirector.play("ui")
		_commit()
		_refresh()
	if _edge(KEY_F):
		CharacterCatalog.rebuild_custom(GameState.custom_description, GameState.custom_photo_path)
		_ids = CharacterCatalog.ids()
		for i in _ids.size():
			if _ids[i] == "custom":
				_p1_index = i
		AudioDirector.play("special")
		_commit()
		_refresh()
	if _edge(KEY_C):
		GameState.p2_is_cpu = not GameState.p2_is_cpu
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


func _commit() -> void:
	GameState.p1_character_id = _ids[_p1_index]
	GameState.p2_character_id = _ids[_p2_index]


func _confirm() -> void:
	_commit()
	AudioDirector.play("ui_confirm")
	confirmed.emit()


func _rebuild_cards() -> void:
	# Cards stay; info updates from catalog.
	pass


func _refresh() -> void:
	for i in _cards.size():
		var sb := _cards[i].get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		var sel := (i == _p1_index) or (i == _p2_index)
		sb.border_width_left = 4 if sel else 2
		sb.border_width_top = 4 if sel else 2
		sb.border_width_right = 4 if sel else 2
		sb.border_width_bottom = 4 if sel else 2
		sb.bg_color = Color(0.18, 0.12, 0.08) if i == _p1_index else (Color(0.08, 0.12, 0.18) if i == _p2_index else Color(0.1, 0.07, 0.12))
		_cards[i].add_theme_stylebox_override("panel", sb)
	var def := CharacterCatalog.get_def(_ids[_p1_index if _focus == 0 else _p2_index])
	var who := "PLAYER 1" if _focus == 0 else "CPU / P2"
	_info.text = "%s — %s  “%s”\n%s" % [who, def.name, def.title, def.description]
	_stats.text = "HP %d   Speed %d   Jump %d   ATK %.2f   DEF %.2f\nSpecial: %s — %s\nUltimate: %s — %s\nPersonality: %s    AI: %s" % [
		int(def.health), int(def.speed), int(def.jump), def.attack, def.defense,
		def.special_name, def.special_desc, def.ultimate_name, def.ultimate_desc,
		def.personality, def.ai_profile
	]
	_cpu_label.text = "Opponent: %s (%s)    C toggle CPU/human    R random CPU    F forge Custom Rite from data/descriptions/example.txt" % [
		CharacterCatalog.get_def(_ids[_p2_index]).name,
		"CPU " + GameState.difficulty_name() if GameState.p2_is_cpu else "HUMAN"
	]
	_draw_preview(def)


func _draw_preview(def: CharacterDef) -> void:
	if _preview:
		_preview.queue_free()
	_preview = FighterVisual.new()
	_portrait_host.add_child(_preview)
	_preview.build(def)
	_preview.position = Vector2(80, 80)
	_preview.scale = Vector2(1.4, 1.4)
	_preview.set_pose_name("idle")
