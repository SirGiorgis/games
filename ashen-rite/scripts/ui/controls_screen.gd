class_name ControlsScreen
extends Control

signal closed


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_title(self, "CONTROLS", 40, Color(0.95, 0.22, 0.28))

	PixelUI.add_panel(self, Vector2(40, 120), Vector2(600, 520), PixelUI.GOLD)
	PixelUI.label_at(self, "PLAYER 1", Vector2(40, 132), 3, Color(0.95, 0.78, 0.35), 0, 600).set_centered(600)
	PixelUI.label_at(self, """A / D     WALK
DD        RUN
AA        BACKDASH
W         JUMP
S         CROUCH
J         LIGHT
K         HEAVY
L         SPECIAL
U         BLOCK
I         THROW
O         SUPER
S+I       TAUNT
ESC / P   PAUSE
FWD+U     PARRY
RUN+J/K   DASH ATTACK
L+U HIT   BURST
GETUP+A   ROLL""", Vector2(64, 184), 2, Color(0.92, 0.9, 0.86), 26)

	PixelUI.add_panel(self, Vector2(640, 120), Vector2(600, 520), Color(0.35, 0.75, 1.0))
	PixelUI.label_at(self, "PLAYER 2 / CPU", Vector2(640, 132), 3, Color(0.55, 0.85, 1.0), 0, 600).set_centered(600)
	PixelUI.label_at(self, """ARROWS    MOVE
Z / NP1   LIGHT
X / NP2   HEAVY
C / NP3   SPECIAL
V / NP4   BLOCK
B / NP5   THROW
N / NP6   SUPER

STAND BLOCK  MID AND HIGH
CROUCH BLOCK MID AND LOW
THROW BEATS BLOCK
LIGHT > (LIGHT) > HEAVY > SPECIAL > SUPER
ONE LIGHT GATLING  LIGHTS MINUS ON BLOCK
JUMP CANCEL HEAVY ON HIT
THROW TECH  PRESS I
AIR TECH    W ONLY
JUST GUARD  BLOCK LATE
PUSHBLOCK   L WHILE BLOCKSTUN
GETUP ATTACK IS A REVERSAL
MAX METER   EX SPECIAL
O SUPER     UNIQUE PER FIGHTER
FWD+BLOCK   PARRY
L+U ON HIT  BURST
LOW HP      RAGE
BLOCK TOO   GUARD BREAK""", Vector2(664, 184), 2, Color(0.88, 0.9, 0.94), 20)

	PixelUI.add_footer(self, "ESC / ENTER  BACK")


func _process(_d: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(ControlMap.MENU.back) or Input.is_action_just_pressed(ControlMap.MENU.confirm):
		closed.emit()
