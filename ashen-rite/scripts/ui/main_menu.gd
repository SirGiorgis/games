class_name MainMenu
extends Control

signal chosen(id: String)

var _index := 0
const ITEMS := ["PLAY", "CHARACTER SELECT", "OPTIONS", "CONTROLS", "QUIT"]
var _entries: Array[Dictionary] = []
var _chris: Sprite2D
var _giorgis: Sprite2D
var _chris_frames: Array = []
var _giorgis_frames: Array = []
var _preview_t := 0.0
var _title: PixelLabel


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	_title = PixelUI.add_title(self, "GIORGIS FIGHTING", 52, Color(0.95, 0.2, 0.3))
	PixelUI.label_at(self, "CHRIS  ·  GIORGIS", Vector2(0, 118), 2, Color(0.88, 0.72, 0.38), 0, 1280).set_centered(1280)

	PixelUI.add_panel(self, Vector2(48, 168), Vector2(560, 480), PixelUI.GOLD)
	for i in ITEMS.size():
		_entries.append(PixelUI.add_menu_row(self, 196.0 + i * 52.0, 480))

	PixelUI.add_panel(self, Vector2(720, 168), Vector2(512, 480), Color(0.55, 0.12, 0.18))
	var frame_lbl := PixelUI.label_at(self, "FIGHTER PREVIEW", Vector2(720, 176), 2, Color(0.85, 0.72, 0.42), 0, 512)
	frame_lbl.set_centered(512)
	frame_lbl.position.x = 720

	var vs := TextureRect.new()
	vs.texture = PixelUI.vs_emblem()
	vs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vs.position = Vector2(952, 300)
	vs.scale = Vector2(3, 3)
	add_child(vs)

	_chris = _make_preview(CharacterCatalog.get_def("chris_xrisakis"), Vector2(860, 430), false)
	_giorgis = _make_preview(CharacterCatalog.get_def("hoodrich_stacks"), Vector2(1090, 430), true)
	_chris_frames = PixelFighterBake.bake(CharacterCatalog.get_def("chris_xrisakis")).get("walk", [])
	_giorgis_frames = PixelFighterBake.bake(CharacterCatalog.get_def("hoodrich_stacks")).get("walk", [])

	PixelUI.add_footer(self, "ENTER / J CONFIRM   W/S MOVE   ESC QUIT")
	_refresh()
	AudioDirector.play_music("menu")


func _make_preview(def: CharacterDef, pos: Vector2, flip: bool) -> Sprite2D:
	var spr := Sprite2D.new()
	var frames: Dictionary = PixelFighterBake.bake(def)
	spr.texture = frames["idle"][0]
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = true
	spr.scale = Vector2(-3.4 if flip else 3.4, 3.4)
	spr.position = pos
	add_child(spr)
	return spr


func _process(delta: float) -> void:
	if not visible:
		return
	_preview_t += delta
	if _chris and not _chris_frames.is_empty():
		_chris.texture = _chris_frames[int(_preview_t * 12.0) % _chris_frames.size()]
	if _giorgis and not _giorgis_frames.is_empty():
		_giorgis.texture = _giorgis_frames[int(_preview_t * 12.0) % _giorgis_frames.size()]
	if _title:
		_title.modulate = Color(1.0, 0.94 + sin(_preview_t * 2.4) * 0.06, 0.92)
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
