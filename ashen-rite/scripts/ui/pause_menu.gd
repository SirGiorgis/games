class_name PauseMenu
extends CanvasLayer

signal resumed
signal restarted
signal quit_to_menu

var _index := 0
const ITEMS := ["RESUME", "RESTART MATCH", "CONTROLS", "QUIT TO MENU"]
var _labels: Array[PixelLabel] = []
var _hint: PixelLabel
var _active := false


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	PixelUI.label_at(self, "PAUSED", Vector2(0, 140), 6, Color(0.95, 0.8, 0.35), 0, 1280).set_centered(1280)
	for i in ITEMS.size():
		var l := PixelLabel.new()
		l.position = Vector2(0, 280 + i * 48)
		add_child(l)
		_labels.append(l)
	_hint = PixelUI.label_at(self, "", Vector2(0, 540), 2, Color(0.75, 0.72, 0.7), 40, 1280)
	_hint.set_centered(1280)
	_refresh()
	hide()


func show_menu() -> void:
	_active = true
	_index = 0
	_hint.set_pix("", 2, Color(0.75, 0.72, 0.7))
	show()
	_refresh()


func _process(_delta: float) -> void:
	if not _active or not visible:
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
		_pick()
	elif Input.is_action_just_pressed(ControlMap.MENU.back):
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
			_hint.set_pix("A/D MOVE  W JUMP  S CROUCH  J/K/L ATTACKS  U BLOCK  I GRAB  O ULT", 2, Color(0.8, 0.78, 0.7), 40)
			_hint.set_centered(1280)
		3:
			_active = false
			quit_to_menu.emit()


func _refresh() -> void:
	for i in _labels.size():
		var sel := i == _index
		_labels[i].set_pix(("> " + ITEMS[i] + " <") if sel else ITEMS[i], 3, Color(1, 0.85, 0.4) if sel else Color(0.8, 0.78, 0.76))
		_labels[i].set_centered(1280)
