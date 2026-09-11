class_name MainMenu
extends Control

signal chosen(id: String)

var _index := 0
const ITEMS := ["PLAY", "CHARACTER SELECT", "OPTIONS", "CONTROLS", "QUIT"]
var _labels: Array[PixelLabel] = []
var _preview: Sprite2D


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	var title := PixelUI.label_at(self, "GIORGIS FIGHTING", Vector2(0, 48), 6, Color(0.92, 0.18, 0.28), 0, 1280)
	title.set_centered(1280)
	PixelUI.label_at(self, "CHRIS XRISAKIS   BEST OF 3", Vector2(0, 128), 2, Color(0.85, 0.72, 0.4), 0, 1280).set_centered(1280)
	for i in ITEMS.size():
		var l := PixelLabel.new()
		l.position = Vector2(0, 250 + i * 48)
		add_child(l)
		_labels.append(l)
	PixelUI.label_at(self, "ENTER / J CONFIRM   W/S MOVE   ESC QUIT", Vector2(0, 660), 2, Color(0.55, 0.52, 0.5), 0, 1280).set_centered(1280)
	_preview = Sprite2D.new()
	var def := CharacterCatalog.get_def(GameState.p1_character_id)
	var frames: Dictionary = PixelFighterBake.bake(def)
	_preview.texture = frames["idle"][0]
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.centered = false
	var sc: float = 3.0 if _preview.texture.get_width() >= 120 else 4.0
	_preview.scale = Vector2(sc, sc)
	_preview.position = Vector2(48, 220)
	add_child(_preview)
	_refresh()
	AudioDirector.play_music("menu")


func _process(_d: float) -> void:
	if not visible:
		return
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
	for i in _labels.size():
		var sel := i == _index
		var txt: String = ("> " + ITEMS[i] + " <") if sel else ITEMS[i]
		_labels[i].set_pix(txt, 3, Color(1, 0.85, 0.35) if sel else Color(0.78, 0.76, 0.74))
		_labels[i].set_centered(1280)
