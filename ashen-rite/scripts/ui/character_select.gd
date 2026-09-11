class_name CharacterSelect
extends Control

signal confirmed
signal cancelled

var _p1_index := 0
var _p2_index := 1
var _focus := 0
var _cards: Array[TextureRect] = []
var _info: PixelLabel
var _stats: PixelLabel
var _cpu_label: PixelLabel
var _preview: Sprite2D
var _ids: PackedStringArray = PackedStringArray()
var _held: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.label_at(self, "CHOOSE YOUR RITE", Vector2(0, 16), 4, Color(0.92, 0.22, 0.28), 0, 1280).set_centered(1280)
	_ids = CharacterCatalog.ids()
	for i in _ids.size():
		var def := CharacterCatalog.get_def(_ids[i])
		var card := TextureRect.new()
		card.position = Vector2(30 + i * 210, 70)
		card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card.scale = Vector2(4, 4)
		add_child(card)
		_cards.append(card)
		var nm := PixelLabel.new()
		nm.position = Vector2(30 + i * 210, 210)
		nm.set_pix(def.name.to_upper(), 1, def.accent, 14)
		add_child(nm)
	_preview = Sprite2D.new()
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.centered = false
	_preview.scale = Vector2(3, 3)
	_preview.position = Vector2(48, 300)
	add_child(_preview)
	_info = PixelUI.label_at(self, "", Vector2(360, 280), 2, Color(0.92, 0.9, 0.86), 42)
	_stats = PixelUI.label_at(self, "", Vector2(360, 400), 2, Color(0.8, 0.76, 0.68), 42)
	_cpu_label = PixelUI.label_at(self, "", Vector2(40, 600), 2, Color(0.7, 0.85, 0.9), 50)
	PixelUI.label_at(self, "A/D SELECT  W/S P1 OR CPU  J CONFIRM  R RANDOM CPU  F FORGE  C TOGGLE CPU  ESC BACK", Vector2(20, 660), 1, Color(0.6, 0.58, 0.55), 70)
	_apply_indices_from_state()
	_refresh()


func _apply_indices_from_state() -> void:
	for i in _ids.size():
		if _ids[i] == GameState.p1_character_id:
			_p1_index = i
		if _ids[i] == GameState.p2_character_id:
			_p2_index = i


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


func _refresh() -> void:
	for i in _cards.size():
		var border := Color(0.35, 0.3, 0.25)
		var fill := Color(0.1, 0.07, 0.12)
		if i == _p1_index:
			border = Color(0.95, 0.75, 0.3)
			fill = Color(0.18, 0.12, 0.08)
		elif i == _p2_index:
			border = Color(0.3, 0.75, 1.0)
			fill = Color(0.08, 0.12, 0.18)
		_cards[i].texture = PixelUI.panel(48, 32, fill, border)
	var def := CharacterCatalog.get_def(_ids[_p1_index if _focus == 0 else _p2_index])
	var who := "PLAYER 1" if _focus == 0 else "CPU / P2"
	_info.set_pix("%s - %s  %s  %s" % [who, def.name, def.title, def.description], 2, Color(0.92, 0.9, 0.86), 42)
	_stats.set_pix("HP %d  SPD %d  JMP %d  ATK %.2f  DEF %.2f  SPEC %s  ULT %s" % [
		int(def.health), int(def.speed), int(def.jump), def.attack, def.defense, def.special_name, def.ultimate_name
	], 2, Color(0.8, 0.76, 0.68), 42)
	_cpu_label.set_pix("OPPONENT %s  %s" % [
		CharacterCatalog.get_def(_ids[_p2_index]).name,
		"CPU " + GameState.difficulty_name() if GameState.p2_is_cpu else "HUMAN"
	], 2, Color(0.7, 0.85, 0.9), 50)
	var frames: Dictionary = PixelFighterBake.bake(def)
	_preview.texture = frames["idle"][0]
	var sc: float = 3.0 if _preview.texture.get_width() >= 120 else 4.0
	_preview.scale = Vector2(sc, sc)
