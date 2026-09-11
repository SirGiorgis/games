class_name MainMenu
extends Control

signal chosen(id: String)

var _index := 0
const ITEMS := ["PLAY", "CHARACTER SELECT", "OPTIONS", "CONTROLS", "QUIT"]
var _labels: Array[Label] = []


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.06)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	_atmosphere()
	var title := Label.new()
	title.text = "ASHEN RITE"
	title.position = Vector2(0, 90)
	title.size = Vector2(1280, 90)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(title, 72, Color(0.92, 0.2, 0.28))
	add_child(title)
	var sub := Label.new()
	sub.text = "A RITE WRITTEN IN SPARKS"
	sub.position = Vector2(0, 170)
	sub.size = Vector2(1280, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(sub, 18, Color(0.85, 0.72, 0.4))
	add_child(sub)
	for i in ITEMS.size():
		var l := Label.new()
		l.position = Vector2(0, 280 + i * 52)
		l.size = Vector2(1280, 44)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIKit.style_label(l, 32)
		add_child(l)
		_labels.append(l)
	var foot := Label.new()
	foot.text = "Enter / J confirm   W/S move   Esc quit"
	foot.position = Vector2(0, 660)
	foot.size = Vector2(1280, 30)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(foot, 16, Color(0.6, 0.58, 0.56))
	add_child(foot)
	_refresh()
	AudioDirector.play_music("menu")


func _atmosphere() -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(640, 720)
	p.emitting = true
	p.amount = 50
	p.lifetime = 5
	p.direction = Vector2(0, -1)
	p.spread = 30
	p.gravity = Vector2(0, -20)
	p.initial_velocity_min = 20
	p.initial_velocity_max = 80
	p.color = Color(0.8, 0.2, 0.25, 0.4)
	add_child(p)


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
		_labels[i].text = UIKit.make_button_label(ITEMS[i], i == _index)
		_labels[i].add_theme_color_override("font_color", Color(1, 0.85, 0.4) if i == _index else Color(0.8, 0.78, 0.76))
