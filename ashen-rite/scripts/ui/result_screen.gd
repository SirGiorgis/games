class_name ResultScreen
extends Control

signal rematch
signal character_select
signal main_menu

var _index := 0
var _labels: Array[PixelLabel] = []
const ITEMS := ["REMATCH", "CHARACTER SELECT", "MAIN MENU"]
var _title: PixelLabel
var _sub: PixelLabel


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	_title = PixelUI.label_at(self, "VICTORY", Vector2(0, 110), 8, Color(0.95, 0.8, 0.3), 0, 1280)
	_title.set_centered(1280)
	_sub = PixelUI.label_at(self, "", Vector2(0, 200), 2, Color(0.85, 0.8, 0.75), 0, 1280)
	_sub.set_centered(1280)
	for i in ITEMS.size():
		var l := PixelLabel.new()
		l.position = Vector2(0, 320 + i * 52)
		add_child(l)
		_labels.append(l)
	_refresh()


func present() -> void:
	_index = 0
	var p1_win := GameState.p1_rounds >= GameState.rounds_to_win
	if p1_win:
		_title.set_pix("VICTORY", 8, Color(0.95, 0.82, 0.32))
		AudioDirector.play("victory")
	else:
		_title.set_pix("DEFEAT", 8, Color(0.85, 0.2, 0.25))
		AudioDirector.play("defeat")
	_title.set_centered(1280)
	var a := CharacterCatalog.get_def(GameState.p1_character_id).name
	var b := CharacterCatalog.get_def(GameState.p2_character_id).name
	_sub.set_pix("%s  %d - %d  %s" % [a, GameState.p1_rounds, GameState.p2_rounds, b], 2, Color(0.85, 0.8, 0.75))
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
	for i in _labels.size():
		var sel := i == _index
		_labels[i].set_pix(("> " + ITEMS[i] + " <") if sel else ITEMS[i], 3, Color(1, 0.85, 0.4) if sel else Color(0.8, 0.78, 0.76))
		_labels[i].set_centered(1280)
