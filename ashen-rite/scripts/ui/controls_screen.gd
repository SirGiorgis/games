class_name ControlsScreen
extends Control

signal closed


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.06)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "CONTROLS"
	title.position = Vector2(0, 50)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(title, 48, Color(0.92, 0.22, 0.28))
	add_child(title)
	var body := Label.new()
	body.text = ControlMap.help_text()
	body.position = Vector2(120, 130)
	body.size = Vector2(1040, 480)
	UIKit.style_label(body, 20, Color(0.88, 0.86, 0.82))
	add_child(body)
	var foot := Label.new()
	foot.text = "Bindings live in scripts/input/control_map.gd — Esc / Backspace to return"
	foot.position = Vector2(0, 650)
	foot.size = Vector2(1280, 30)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(foot, 16, Color(0.65, 0.62, 0.6))
	add_child(foot)


func _process(_d: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(ControlMap.MENU.back) or Input.is_action_just_pressed(ControlMap.MENU.confirm):
		closed.emit()
