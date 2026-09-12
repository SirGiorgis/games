class_name MainMenu
extends Control

signal chosen(id: String)

var _index := 0
const ITEMS := ["PLAY", "CHARACTER SELECT", "OPTIONS", "CONTROLS", "QUIT"]
var _entries: Array[Dictionary] = []
var _preview: Sprite2D
var _preview_frames: Array = []
var _preview_t := 0.0


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_title(self, "GIORGIS FIGHTING", 52, Color(0.95, 0.2, 0.3))
	PixelUI.label_at(self, "CHRIS XRISAKIS  ·  BEST OF 3", Vector2(0, 118), 2, Color(0.88, 0.72, 0.38), 0, 1280).set_centered(1280)

	PixelUI.add_panel(self, Vector2(48, 168), Vector2(560, 480), PixelUI.GOLD)
	for i in ITEMS.size():
		_entries.append(PixelUI.add_menu_row(self, 196.0 + i * 52.0, 480))

	PixelUI.add_panel(self, Vector2(720, 168), Vector2(512, 480), Color(0.55, 0.12, 0.18))
	var frame_lbl := PixelUI.label_at(self, "FIGHTER PREVIEW", Vector2(720, 176), 2, Color(0.85, 0.72, 0.42), 0, 512)
	frame_lbl.set_centered(512)
	frame_lbl.position.x = 720

	_preview = Sprite2D.new()
	var def := CharacterCatalog.get_def(GameState.p1_character_id)
	var frames: Dictionary = PixelFighterBake.bake(def)
	_preview.texture = frames["idle"][0]
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.centered = true
	var sc: float = 5.0
	_preview.scale = Vector2(sc, sc)
	_preview.position = Vector2(976, 400)
	_preview_frames = frames["walk"]
	add_child(_preview)

	PixelUI.add_footer(self, "ENTER / J CONFIRM   W/S MOVE   ESC QUIT")
	_refresh()
	AudioDirector.play_music("menu")


func _process(delta: float) -> void:
	if not visible:
		return
	_preview_t += delta
	if _preview and not _preview_frames.is_empty():
		var idx: int = int(_preview_t * 10.0) % _preview_frames.size()
		_preview.texture = _preview_frames[idx]
	if Input.is_action_just_pressed(ControlMap.MENU.down):
		_index = (_index + 1) % ITEMS.size()
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.up):
		_index = (_index + ITEMS.size() - 1) % ITEMS.size()
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.confirm):
		AudioDirector.play("ui_confirm")
		chosen.emit(ITEMS[_index])


func _refresh() -> void:
	for i in _entries.size():
		PixelUI.set_menu_row(_entries[i], ITEMS[i], i == _index, 3)
