class_name ControlsScreen
extends Control

signal closed


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_title(self, "CONTROLS", 40, Color(0.95, 0.22, 0.28))

	PixelUI.add_panel(self, Vector2(40, 120), Vector2(600, 520), PixelUI.GOLD)
	PixelUI.label_at(self, "KEYBOARD", Vector2(40, 132), 3, Color(0.95, 0.78, 0.35), 0, 600).set_centered(600)
	PixelUI.label_at(self, """P1  A/D WALK   W JUMP   S CROUCH
J LIGHT   K HEAVY   L SPECIAL
U BLOCK   I THROW   O SUPER
ESC / P   PAUSE
FWD+U PARRY   RUN+J/K DASH ATTACK
L+U HIT BURST   GETUP+A ROLL

P2  ARROWS MOVE
Z LIGHT  X HEAVY  C SPECIAL
V BLOCK  B THROW  N SUPER

LIGHT > (LIGHT) > HEAVY > SPECIAL > SUPER
LIGHTS MINUS ON BLOCK
JUMP CANCEL HEAVY ON HIT
THROW TECH  PRESS THROW
LOW HP  RAGE""", Vector2(64, 176), 2, Color(0.92, 0.9, 0.86), 28)

	PixelUI.add_panel(self, Vector2(640, 120), Vector2(600, 520), Color(0.35, 0.75, 1.0))
	PixelUI.label_at(self, "DUALSENSE  PS5", Vector2(640, 132), 3, Color(0.55, 0.85, 1.0), 0, 600).set_centered(600)
	PixelUI.label_at(self, """LS / DPAD     MOVE
LS UP / UP    JUMP
LS DOWN       CROUCH
SQUARE        LIGHT
TRIANGLE      HEAVY
CIRCLE        SPECIAL
L1 / L2       BLOCK
R1            THROW
R2            SUPER
OPTIONS       PAUSE
TOUCHPAD      PAUSE
FWD+L1        PARRY
RUN+SQ/TRI    DASH ATTACK
CIRCLE+L1 HIT BURST
GETUP+BACK    ROLL
CROSS         MENU OK
CIRCLE        MENU BACK
PAD 1 = P1    PAD 2 = P2""", Vector2(664, 176), 2, Color(0.88, 0.9, 0.94), 22)

	PixelUI.add_footer(self, "ESC / CIRCLE  BACK     ENTER / CROSS  OK")


func _process(_d: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(ControlMap.MENU.back) or Input.is_action_just_pressed(ControlMap.MENU.confirm):
		closed.emit()
