class_name VersusOverlay
extends CanvasLayer

var _root: Control
var _p1s: Sprite2D
var _p2s: Sprite2D
var _walk1: Array = []
var _walk2: Array = []
var _t := 0.0
var _vs: TextureRect


func present(p1: CharacterDef, p2: CharacterDef, arena_name: String) -> void:
	layer = 22
	for c in get_children():
		c.queue_free()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.04, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	PixelUI.add_panel(_root, Vector2(40, 140), Vector2(520, 420), PixelUI.GOLD)
	PixelUI.add_panel(_root, Vector2(720, 140), Vector2(520, 420), Color(0.35, 0.75, 1.0))

	var g1 := TextureRect.new()
	g1.texture = PixelUI.stage_strip()
	g1.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g1.position = Vector2(72, 430)
	g1.scale = Vector2(3.8, 3.2)
	_root.add_child(g1)
	var g2 := TextureRect.new()
	g2.texture = PixelUI.stage_strip()
	g2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g2.position = Vector2(752, 430)
	g2.scale = Vector2(3.8, 3.2)
	_root.add_child(g2)

	_p1s = Sprite2D.new()
	_p1s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_p1s.centered = true
	_p1s.scale = Vector2(2.35, 2.35)
	_p1s.position = Vector2(300, 380)
	_root.add_child(_p1s)
	_p2s = Sprite2D.new()
	_p2s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_p2s.centered = true
	_p2s.scale = Vector2(-2.35, 2.35)
	_p2s.position = Vector2(980, 380)
	_root.add_child(_p2s)

	var f1: Dictionary = PixelFighterBake.bake(p1)
	var f2: Dictionary = PixelFighterBake.bake(p2)
	_walk1 = f1.get("walk", f1.get("idle", []))
	_walk2 = f2.get("walk", f2.get("idle", []))
	if not _walk1.is_empty():
		_p1s.texture = _walk1[0]
	if not _walk2.is_empty():
		_p2s.texture = _walk2[0]

	PixelUI.label_at(_root, p1.callsign(), Vector2(40, 156), 4, Color(1, 0.88, 0.4), 0, 520).set_centered(520)
	PixelUI.label_at(_root, p1.title.to_upper(), Vector2(40, 204), 2, Color(0.85, 0.72, 0.42), 0, 520).set_centered(520)
	PixelUI.label_at(_root, p2.callsign(), Vector2(720, 156), 4, Color(0.55, 0.88, 1.0), 0, 520).set_centered(520)
	PixelUI.label_at(_root, p2.title.to_upper(), Vector2(720, 204), 2, Color(0.65, 0.82, 0.95), 0, 520).set_centered(520)

	_vs = TextureRect.new()
	_vs.texture = PixelUI.vs_emblem()
	_vs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_vs.position = Vector2(584, 304)
	_vs.scale = Vector2(2.05, 2.05)
	_root.add_child(_vs)

	PixelUI.label_at(_root, arena_name.to_upper(), Vector2(0, 560), 2, Color(0.92, 0.86, 0.7), 0, 1280).set_centered(1280)
	if GameState.arcade:
		PixelUI.label_at(_root, "ARCADE BOUT %d / %d" % [GameState.arcade_index + 1, maxi(GameState.arcade_queue.size(), 1)], Vector2(0, 88), 3, Color(1, 0.82, 0.32), 0, 1280).set_centered(1280)
	var q1: String = p1.intro_quote if p1.intro_quote != "" else p1.win_quote
	var q2: String = p2.intro_quote if p2.intro_quote != "" else p2.win_quote
	PixelUI.label_at(_root, q1, Vector2(40, 500), 2, Color(1, 0.88, 0.5), 0, 520).set_centered(520)
	PixelUI.label_at(_root, q2, Vector2(720, 500), 2, Color(0.65, 0.88, 1.0), 0, 520).set_centered(520)
	PixelUI.label_at(_root, "ENTER / CROSS SKIPS", Vector2(0, 620), 1, Color(0.75, 0.72, 0.68), 0, 1280).set_centered(1280)
	show()
	_t = 0.0
	_root.modulate = Color(1.3, 1.3, 1.2)
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_root, "modulate", Color.WHITE, 0.22)
	tw.parallel().tween_property(_p1s, "scale", Vector2(3.6, 3.6), 0.28)
	tw.parallel().tween_property(_p2s, "scale", Vector2(-3.6, 3.6), 0.28)
	tw.parallel().tween_property(_vs, "scale", Vector2(3.4, 3.4), 0.26)
	tw.parallel().tween_property(_vs, "position", Vector2(560, 280), 0.26)


func _process(delta: float) -> void:
	if not visible or _root == null:
		return
	_t += delta
	if _p1s and not _walk1.is_empty():
		_p1s.texture = _walk1[int(_t * 8.0) % _walk1.size()]
		_p1s.position.y = 380.0 + sin(_t * 2.4) * 4.0
		if _t > 0.32:
			var b: float = 1.0 + sin(_t * 2.2) * 0.012
			_p1s.scale = Vector2(3.6 * b, 3.6 * b)
	if _p2s and not _walk2.is_empty():
		_p2s.texture = _walk2[int(_t * 8.0) % _walk2.size()]
		_p2s.position.y = 380.0 + sin(_t * 2.4 + 0.8) * 4.0
		if _t > 0.32:
			var b2: float = 1.0 + sin(_t * 2.2 + 0.6) * 0.012
			_p2s.scale = Vector2(-3.6 * b2, 3.6 * b2)


func dismiss() -> void:
	hide()
	for c in get_children():
		c.queue_free()
	_root = null
