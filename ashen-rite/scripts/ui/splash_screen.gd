class_name SplashScreen
extends Control

signal finished
signal attract

var _press: PixelLabel
var _t := 0.0
var _chris: Sprite2D
var _giorgis: Sprite2D
var _walk_c: Array = []
var _walk_g: Array = []
var _done := false


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_title(self, "GIORGIS FIGHTING", 88, Color(0.95, 0.18, 0.28))
	PixelUI.label_at(self, "ARCADE BRAWL", Vector2(0, 164), 2, Color(0.92, 0.74, 0.32), 0, 1280).set_centered(1280)

	var grass := TextureRect.new()
	grass.texture = PixelUI.stage_strip()
	grass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grass.position = Vector2(200, 470)
	grass.scale = Vector2(7.4, 4.0)
	add_child(grass)

	var vs := TextureRect.new()
	vs.texture = PixelUI.vs_emblem()
	vs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vs.position = Vector2(568, 280)
	vs.scale = Vector2(3, 3)
	add_child(vs)

	_chris = _preview("chris_xrisakis", Vector2(430, 440), false)
	_giorgis = _preview("hoodrich_stacks", Vector2(850, 440), true)
	_walk_c = PixelFighterBake.bake(CharacterCatalog.get_def("chris_xrisakis")).get("walk", [])
	_walk_g = PixelFighterBake.bake(CharacterCatalog.get_def("hoodrich_stacks")).get("walk", [])

	PixelUI.label_at(self, "CHRIS", Vector2(350, 520), 2, Color(0.95, 0.78, 0.35), 0, 160).set_centered(160)
	PixelUI.label_at(self, "GIORGIS", Vector2(770, 520), 2, Color(0.62, 0.82, 0.95), 0, 160).set_centered(160)

	_press = PixelUI.label_at(self, "PRESS ENTER", Vector2(0, 600), 3, Color(1, 0.92, 0.45), 0, 1280)
	_press.set_centered(1280)
	PixelUI.add_footer(self, "ENTER START   WAIT FOR DEMO")
	AudioDirector.play_music("menu")


func _preview(id: String, pos: Vector2, flip: bool) -> Sprite2D:
	var spr := Sprite2D.new()
	var frames: Dictionary = PixelFighterBake.bake(CharacterCatalog.get_def(id))
	spr.texture = frames["idle"][0]
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = true
	spr.scale = Vector2(-3.6 if flip else 3.6, 3.6)
	spr.position = pos
	add_child(spr)
	return spr


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _chris and not _walk_c.is_empty():
		_chris.texture = _walk_c[int(_t * 14.0) % _walk_c.size()]
		_chris.position.y = 440.0 + sin(_t * 2.2) * 5.0
	if _giorgis and not _walk_g.is_empty():
		_giorgis.texture = _walk_g[int(_t * 14.0) % _walk_g.size()]
		_giorgis.position.y = 440.0 + sin(_t * 2.2 + 1.0) * 5.0
	if _press:
		_press.modulate.a = 0.35 + 0.65 * (0.5 + 0.5 * sin(_t * 6.0))
	if Input.is_action_just_pressed(ControlMap.MENU.confirm) or Input.is_action_just_pressed(ControlMap.MENU.back):
		_finish()
	elif _t > 8.0:
		_go_attract()


func _go_attract() -> void:
	if _done:
		return
	_done = true
	attract.emit()


func _finish() -> void:
	if _done:
		return
	_done = true
	AudioDirector.play("ui_confirm")
	finished.emit()
