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


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_panel(self, Vector2(220, 72), Vector2(840, 560), PixelUI.GOLD)
	_title = PixelUI.add_title(self, "VICTORY", 120, Color(0.95, 0.82, 0.32))
	_sub = PixelUI.label_at(self, "", Vector2(0, 200), 2, Color(0.85, 0.8, 0.75), 0, 1280)
	_sub.set_centered(1280)
	for i in ITEMS.size():
		_entries.append(PixelUI.add_menu_row(self, 300.0 + i * 52.0, 480))
	PixelUI.add_footer(self, "W/S MOVE  ENTER CONFIRM")
	_refresh()


func present() -> void:
	_index = 0
	var p1_win := GameState.p1_rounds >= GameState.rounds_to_win
	if p1_win:
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
	AudioDirector.play_music("menu")
	_refresh()


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
