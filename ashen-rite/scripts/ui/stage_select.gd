class_name StageSelect
extends Control

signal confirmed
signal cancelled

var _index := 0
var _ids: PackedStringArray = PackedStringArray()
var _cards: Array[TextureRect] = []
var _names: Array[PixelLabel] = []
var _preview: TextureRect
var _title: PixelLabel
var _t := 0.0


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_title(self, "SELECT STAGE", 40, Color(0.95, 0.22, 0.28))
	_ids = ArenaWorld.all_ids()
	_ids.append("random")
	var start_x: float = 70.0
	for i in _ids.size():
		var card := TextureRect.new()
		card.position = Vector2(start_x + i * 200.0, 120)
		card.size = Vector2(180, 110)
		card.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		add_child(card)
		_cards.append(card)
		var nm := PixelLabel.new()
		nm.position = Vector2(start_x + i * 200.0, 236)
		add_child(nm)
		_names.append(nm)

	PixelUI.add_panel(self, Vector2(160, 280), Vector2(960, 340), PixelUI.GOLD)
	_preview = TextureRect.new()
	_preview.position = Vector2(176, 296)
	_preview.size = Vector2(928, 260)
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_preview)
	_title = PixelUI.label_at(self, "", Vector2(0, 568), 3, Color(1, 0.88, 0.42), 0, 1280)
	_title.set_centered(1280)
	PixelUI.add_footer(self, "A/D SELECT  ENTER FIGHT  ESC BACK")
	_sync_from_state()
	_refresh()


func _sync_from_state() -> void:
	if GameState.random_arena:
		_index = _ids.size() - 1
		return
	for i in _ids.size():
		if _ids[i] == GameState.arena_id:
			_index = i


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	for i in _cards.size():
		var on: bool = i == _index
		_cards[i].modulate = Color(1.12, 1.08, 0.95) if on else Color(0.72, 0.72, 0.76)
		var s: float = 1.0 + (0.04 * sin(_t * 8.0) if on else 0.0)
		_cards[i].scale = Vector2(s, s)
	if Input.is_action_just_pressed(ControlMap.MENU.right):
		_index = posmod(_index + 1, _ids.size())
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.left):
		_index = posmod(_index - 1, _ids.size())
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.confirm):
		_commit()
		AudioDirector.play("ui_confirm")
		confirmed.emit()
	elif Input.is_action_just_pressed(ControlMap.MENU.back):
		cancelled.emit()


func _commit() -> void:
	if _ids[_index] == "random":
		GameState.random_arena = true
	else:
		GameState.random_arena = false
		GameState.arena_id = _ids[_index]


func _refresh() -> void:
	for i in _ids.size():
		var id: String = _ids[i]
		if id == "random":
			_cards[i].texture = PixelUI.panel(45, 28, Color(0.12, 0.08, 0.14), PixelUI.GOLD)
			_names[i].set_pix("RANDOM", 2, Color(1, 0.86, 0.4) if i == _index else Color(0.75, 0.72, 0.68), 12)
		else:
			_cards[i].texture = PixelArenaBake.texture(id)
			_names[i].set_pix(ArenaWorld.display_name(id), 1, Color(1, 0.86, 0.4) if i == _index else Color(0.75, 0.72, 0.68), 14)
	var pick: String = _ids[_index]
	if pick == "random":
		_preview.texture = PixelArenaBake.texture("grass_field")
		_title.set_pix("RANDOM STAGE", 3, Color(1, 0.88, 0.42))
	else:
		_preview.texture = PixelArenaBake.texture(pick)
		_title.set_pix(ArenaWorld.display_name(pick), 3, Color(1, 0.88, 0.42))
	_title.set_centered(1280)
