class_name PauseMenu
extends CanvasLayer

signal resumed
signal restarted
signal quit_to_menu

var _index := 0
const ITEMS := ["RESUME", "RESTART MATCH", "CONTROLS REMINDER", "QUIT TO MENU"]
var _labels: Array[Label] = []
var _hint: Label
var _active := false


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var title := Label.new()
	title.text = "PAUSED"
	title.position = Vector2(0, 160)
	title.size = Vector2(1280, 70)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(title, 56, Color(0.95, 0.8, 0.35))
	add_child(title)
	for i in ITEMS.size():
		var l := Label.new()
		l.position = Vector2(0, 280 + i * 48)
		l.size = Vector2(1280, 40)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIKit.style_label(l, 28)
		add_child(l)
		_labels.append(l)
	_hint = Label.new()
	_hint.position = Vector2(80, 540)
	_hint.size = Vector2(1120, 120)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = ""
	UIKit.style_label(_hint, 16, Color(0.75, 0.72, 0.7))
	add_child(_hint)
	_refresh()
	hide()


func show_menu() -> void:
	_active = true
	_index = 0
	_hint.text = ""
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
			_hint.text = "A/D move  W jump  S crouch  J/K/L attacks  U block  I grab  O ultimate"
		3:
			_active = false
			quit_to_menu.emit()


func _refresh() -> void:
	for i in _labels.size():
		_labels[i].text = UIKit.make_button_label(ITEMS[i], i == _index)
		_labels[i].add_theme_color_override("font_color", Color(1, 0.85, 0.4) if i == _index else Color(0.82, 0.8, 0.78))
