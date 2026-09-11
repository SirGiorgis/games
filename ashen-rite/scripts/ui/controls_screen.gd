class_name ControlsScreen
extends Control

signal closed


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.label_at(self, "CONTROLS", Vector2(0, 40), 6, Color(0.92, 0.22, 0.28), 0, 1280).set_centered(1280)
	PixelUI.label_at(self, ControlMap.help_text(), Vector2(80, 120), 2, Color(0.88, 0.86, 0.82), 48)
	PixelUI.label_at(self, "BINDINGS IN SCRIPTS/INPUT/CONTROL_MAP.GD   ESC BACK", Vector2(0, 660), 2, Color(0.6, 0.58, 0.55), 0, 1280).set_centered(1280)


func _process(_d: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(ControlMap.MENU.back) or Input.is_action_just_pressed(ControlMap.MENU.confirm):
		closed.emit()
