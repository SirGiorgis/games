class_name PauseMenu
extends CanvasLayer

signal resumed
signal restarted
signal quit_to_menu

var _index := 0
const ITEMS := ["RESUME", "RESTART MATCH", "MOVES", "QUIT TO MENU"]
var _entries: Array[Dictionary] = []
var _hint: PixelLabel
var _active := false
var _lock := 0.0


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = PixelUI.modal_dim()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(host)

	PixelUI.add_panel(host, Vector2(340, 100), Vector2(600, 520), PixelUI.GOLD)
	PixelUI.add_title(host, "PAUSED", 148, Color(0.95, 0.82, 0.35))

	for i in ITEMS.size():
		_entries.append(PixelUI.add_menu_row(host, 220.0 + i * 52.0, 440))

	_hint = PixelUI.label_at(host, "", Vector2(0, 520), 2, Color(0.72, 0.68, 0.64), 36, 1280)
	_hint.set_centered(1280)
	_refresh()
	hide()


func hide_menu() -> void:
	_active = false
	hide()


func show_menu() -> void:
	_active = true
	_index = 0
	_lock = 0.18
	_hint.set_pix("", 2, Color(0.72, 0.68, 0.64))
	show()
	_refresh()


func _process(delta: float) -> void:
	if not _active or not visible:
		return
	_lock = max(0.0, _lock - delta)
	if _lock > 0.0:
		return
	for i in _entries.size():
		_entries[i]["row"].modulate = Color(1.12, 1.08, 0.9) if i == _index else Color.WHITE
	if Input.is_action_just_pressed(ControlMap.MENU.down):
		_index = (_index + 1) % ITEMS.size()
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.up):
		_index = (_index + ITEMS.size() - 1) % ITEMS.size()
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.confirm):
		_pick()
	elif Input.is_action_just_pressed(ControlMap.MENU.back) or Input.is_action_just_pressed(ControlMap.P1.pause):
		_active = false
		resumed.emit()


func _pick() -> void:
	AudioDirector.play("ui_confirm")
	match _index:
		0:
			_active = false
			resumed.emit()
		1:
			_active = false
			restarted.emit()
		2:
			var d := CharacterCatalog.get_def(GameState.p1_character_id)
			_hint.set_pix("%s  L %s  O %s  RUN+J DASH  FWD+U PARRY  L+U BURST  GETUP BACK ROLL" % [d.callsign(), d.special_name.to_upper(), d.ultimate_name.to_upper()], 2, Color(0.82, 0.78, 0.72), 36)
			_hint.set_centered(1280)
		3:
			_active = false
			quit_to_menu.emit()


func _refresh() -> void:
	for i in _entries.size():
		PixelUI.set_menu_row(_entries[i], ITEMS[i], i == _index, 3)
