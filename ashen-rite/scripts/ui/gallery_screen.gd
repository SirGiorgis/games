class_name GalleryScreen
extends Control

signal closed

var _index := 0
var _title: PixelLabel
var _sub: PixelLabel
var _hint: PixelLabel
var _preview: Sprite2D
var _walk: Array = []
var _t := 0.0
var _ids: PackedStringArray = PackedStringArray()


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_title(self, "GALLERY RADIO", 40, Color(0.95, 0.22, 0.28))
	PixelUI.add_panel(self, Vector2(80, 130), Vector2(1120, 500), PixelUI.GOLD)
	_title = PixelUI.label_at(self, "", Vector2(0, 160), 3, Color(1, 0.88, 0.4), 0, 1280)
	_title.set_centered(1280)
	_sub = PixelUI.label_at(self, "", Vector2(0, 220), 2, Color(0.82, 0.78, 0.72), 0, 1280)
	_sub.set_centered(1280)
	_hint = PixelUI.label_at(self, "", Vector2(0, 520), 2, Color(0.7, 0.68, 0.62), 0, 1280)
	_hint.set_centered(1280)
	var grass := TextureRect.new()
	grass.texture = PixelUI.stage_strip()
	grass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grass.position = Vector2(360, 430)
	grass.scale = Vector2(4.6, 3.2)
	add_child(grass)
	_preview = Sprite2D.new()
	_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview.centered = true
	_preview.scale = Vector2(3.2, 3.2)
	_preview.position = Vector2(640, 390)
	add_child(_preview)
	_ids = CharacterCatalog.ids()
	PixelUI.add_footer(self, "A/D TRACK  ENTER PLAY  ESC BACK")
	_play_current()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _preview and not _walk.is_empty():
		_preview.texture = _walk[int(_t * 12.0) % _walk.size()]
		_preview.position.y = 390.0 + sin(_t * 2.2) * 5.0
	if Input.is_action_just_pressed(ControlMap.MENU.right):
		_index = posmod(_index + 1, maxi(AudioDirector.tracks.size(), 1))
		AudioDirector.play("ui")
		_play_current()
	elif Input.is_action_just_pressed(ControlMap.MENU.left):
		_index = posmod(_index - 1, maxi(AudioDirector.tracks.size(), 1))
		AudioDirector.play("ui")
		_play_current()
	elif Input.is_action_just_pressed(ControlMap.MENU.confirm):
		AudioDirector.play("ui_confirm")
		_play_current()
	elif Input.is_action_just_pressed(ControlMap.MENU.back):
		closed.emit()


func _play_current() -> void:
	if AudioDirector.tracks.is_empty():
		_title.set_pix("NO SOUNDTRACK", 3, Color(1, 0.5, 0.4))
		_title.set_centered(1280)
		return
	var tr: Dictionary = AudioDirector.tracks[_index]
	var tid: String = str(tr.get("id", ""))
	_title.set_pix(str(tr.get("title", tid)), 3, Color(1, 0.88, 0.4))
	_title.set_centered(1280)
	_sub.set_pix("%d / %d   %s   %ds" % [_index + 1, AudioDirector.tracks.size(), tid, int(tr.get("seconds", 0))], 2, Color(0.82, 0.78, 0.72))
	_sub.set_centered(1280)
	_hint.set_pix("FULL CABINET SOUNDTRACK", 2, Color(0.7, 0.68, 0.62))
	_hint.set_centered(1280)
	AudioDirector.play_music(tid)
	var cid := "chris_xrisakis"
	if tid.begins_with("theme:"):
		cid = tid.substr(6)
	elif _ids.size() > 0:
		cid = _ids[_index % _ids.size()]
	var frames: Dictionary = PixelFighterBake.bake(CharacterCatalog.get_def(cid))
	_walk = frames.get("walk", frames.get("idle", []))
	if _preview and not _walk.is_empty():
		_preview.texture = _walk[0]
