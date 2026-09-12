class_name ResultScreen
extends Control

signal rematch
signal character_select
signal main_menu

var _index := 0
var _entries: Array[Dictionary] = []
const ITEMS := ["REMATCH", "CHARACTER SELECT", "MAIN MENU"]
var _title: PixelLabel
var _sub: PixelLabel
var _quote: PixelLabel
var _p1_spr: Sprite2D
var _p2_spr: Sprite2D
var _p1_walk: Array = []
var _p2_walk: Array = []
var _t := 0.0


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_panel(self, Vector2(220, 72), Vector2(840, 560), PixelUI.GOLD)
	_title = PixelUI.add_title(self, "VICTORY", 120, Color(0.95, 0.82, 0.32))
	_sub = PixelUI.label_at(self, "", Vector2(0, 196), 2, Color(0.85, 0.8, 0.75), 0, 1280)
	_sub.set_centered(1280)
	_quote = PixelUI.label_at(self, "", Vector2(0, 236), 2, Color(1, 0.86, 0.42), 0, 1280)
	_quote.set_centered(1280)

	var grass := TextureRect.new()
	grass.texture = PixelUI.stage_strip()
	grass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grass.position = Vector2(300, 392)
	grass.scale = Vector2(5.6, 3.2)
	add_child(grass)
	var vs := TextureRect.new()
	vs.texture = PixelUI.vs_emblem()
	vs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vs.position = Vector2(616, 292)
	vs.scale = Vector2(3, 3)
	add_child(vs)
	_p1_spr = Sprite2D.new()
	_p1_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_p1_spr.centered = true
	_p1_spr.scale = Vector2(3.2, 3.2)
	_p1_spr.position = Vector2(430, 372)
	add_child(_p1_spr)
	_p2_spr = Sprite2D.new()
	_p2_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_p2_spr.centered = true
	_p2_spr.scale = Vector2(-3.2, 3.2)
	_p2_spr.position = Vector2(850, 372)
	add_child(_p2_spr)
	for i in ITEMS.size():
		_entries.append(PixelUI.add_menu_row(self, 508.0 + i * 48.0, 480))
	PixelUI.add_footer(self, "W/S MOVE  ENTER CONFIRM")
	_refresh()


func present() -> void:
	_index = 0
	var p1_win := GameState.p1_rounds >= GameState.rounds_to_win
	var arcade_clear: bool = GameState.arcade and p1_win and GameState.arcade_index >= GameState.arcade_queue.size()
	if arcade_clear:
		_title.set_pix("ARCADE CLEAR", 5, Color(0.95, 0.82, 0.32))
		AudioDirector.play("victory")
	elif GameState.arcade and not p1_win:
		_title.set_pix("CONTINUE?", 5, Color(0.88, 0.22, 0.28))
		AudioDirector.play("defeat")
	elif p1_win:
		_title.set_pix("VICTORY", 6, Color(0.95, 0.82, 0.32))
		AudioDirector.play("victory")
	else:
		_title.set_pix("DEFEAT", 6, Color(0.88, 0.22, 0.28))
		AudioDirector.play("defeat")
	_title.set_centered(1280)
	var a := CharacterCatalog.get_def(GameState.p1_character_id).name
	var b := CharacterCatalog.get_def(GameState.p2_character_id).name
	_sub.set_pix("%s   %d  —  %d   %s" % [a, GameState.p1_rounds, GameState.p2_rounds, b], 2, Color(0.85, 0.8, 0.75))
	_sub.set_centered(1280)
	var winner := CharacterCatalog.get_def(GameState.p1_character_id if p1_win else GameState.p2_character_id)
	var q: String = winner.win_quote
	if arcade_clear:
		q = "SCORE %d   MAX %d HIT   %d DMG" % [GameState.arcade_score, GameState.match_max_combo, int(GameState.match_damage)]
	elif GameState.last_was_perfect:
		q = "PERFECT - " + q
	elif GameState.last_was_dramatic:
		q = "DRAMATIC - " + q
	else:
		q = "%s    MAX %d HIT  %d DMG" % [q, GameState.match_max_combo, int(GameState.match_damage)]
	_quote.set_pix(q, 2, Color(1, 0.86, 0.42), 42)
	_quote.set_centered(1280)
	AudioDirector.play_music("menu")
	var p1_frames: Dictionary = PixelFighterBake.bake(CharacterCatalog.get_def(GameState.p1_character_id))
	var p2_frames: Dictionary = PixelFighterBake.bake(CharacterCatalog.get_def(GameState.p2_character_id))
	_p1_walk = p1_frames.get("victory" if p1_win else "defeat", p1_frames.get("idle", []))
	_p2_walk = p2_frames.get("victory" if not p1_win else "defeat", p2_frames.get("idle", []))
	if _p1_spr and not _p1_walk.is_empty():
		_p1_spr.texture = _p1_walk[0]
	if _p2_spr and not _p2_walk.is_empty():
		_p2_spr.texture = _p2_walk[0]
	_refresh()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _title:
		_title.modulate = Color(1.0, 0.95 + sin(_t * 3.0) * 0.05, 0.9)
	if _p1_spr and not _p1_walk.is_empty():
		_p1_spr.texture = _p1_walk[int(_t * 10.0) % _p1_walk.size()]
		_p1_spr.position.y = 372.0 + sin(_t * 2.4) * 4.0
	if _p2_spr and not _p2_walk.is_empty():
		_p2_spr.texture = _p2_walk[int(_t * 10.0) % _p2_walk.size()]
		_p2_spr.position.y = 372.0 + sin(_t * 2.4 + 0.9) * 4.0
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
		match _index:
			0:
				rematch.emit()
			1:
				character_select.emit()
			2:
				main_menu.emit()


func _refresh() -> void:
	for i in _entries.size():
		PixelUI.set_menu_row(_entries[i], ITEMS[i], i == _index, 3)
