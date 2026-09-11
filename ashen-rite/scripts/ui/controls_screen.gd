class_name ControlsScreen
extends Control

signal closed


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_panel(self, Vector2(120, 48), Vector2(1040, 620), PixelUI.GOLD)
	PixelUI.add_title(self, "CONTROLS", 88, Color(0.95, 0.22, 0.28))
	PixelUI.label_at(self, ControlMap.help_text(), Vector2(160, 160), 2, Color(0.9, 0.88, 0.84), 44)
	PixelUI.add_footer(self, "BINDINGS IN SCRIPTS/INPUT/CONTROL_MAP.GD   ESC BACK")


func _process(_d: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(ControlMap.MENU.back) or Input.is_action_just_pressed(ControlMap.MENU.confirm):
		closed.emit()
