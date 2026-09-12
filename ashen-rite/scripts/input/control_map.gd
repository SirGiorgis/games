extends Node
## Keyboard plus DualSense / PS5 pads. Pad 1 = P1, pad 2 = P2.
## Face buttons use Sony layout: Square / Triangle / Circle / Cross.

const P1 := {
	"left": "p1_left",
	"right": "p1_right",
	"up": "p1_up",
	"down": "p1_down",
	"light": "p1_light",
	"heavy": "p1_heavy",
	"special": "p1_special",
	"block": "p1_block",
	"grab": "p1_grab",
	"ultimate": "p1_ultimate",
	"pause": "p1_pause",
}

const P2 := {
	"left": "p2_left",
	"right": "p2_right",
	"up": "p2_up",
	"down": "p2_down",
	"light": "p2_light",
	"heavy": "p2_heavy",
	"special": "p2_special",
	"block": "p2_block",
	"grab": "p2_grab",
	"ultimate": "p2_ultimate",
}

const MENU := {
	"up": "menu_up",
	"down": "menu_down",
	"left": "menu_left",
	"right": "menu_right",
	"confirm": "menu_confirm",
	"back": "menu_back",
}

const ANY_PAD := -1


func _ready() -> void:
	_ensure_action(P1.left, [KEY_A], 0.28)
	_ensure_action(P1.right, [KEY_D], 0.28)
	_ensure_action(P1.up, [KEY_W], 0.28)
	_ensure_action(P1.down, [KEY_S], 0.28)
	_ensure_action(P1.light, [KEY_J])
	_ensure_action(P1.heavy, [KEY_K])
	_ensure_action(P1.special, [KEY_L])
	_ensure_action(P1.block, [KEY_U], 0.22)
	_ensure_action(P1.grab, [KEY_I])
	_ensure_action(P1.ultimate, [KEY_O], 0.35)
	_ensure_action(P1.pause, [KEY_ESCAPE, KEY_P])

	_ensure_action(P2.left, [KEY_LEFT], 0.28)
	_ensure_action(P2.right, [KEY_RIGHT], 0.28)
	_ensure_action(P2.up, [KEY_UP], 0.28)
	_ensure_action(P2.down, [KEY_DOWN], 0.28)
	_ensure_action(P2.light, [KEY_KP_1, KEY_Z])
	_ensure_action(P2.heavy, [KEY_KP_2, KEY_X])
	_ensure_action(P2.special, [KEY_KP_3, KEY_C])
	_ensure_action(P2.block, [KEY_KP_4, KEY_V], 0.22)
	_ensure_action(P2.grab, [KEY_KP_5, KEY_B])
	_ensure_action(P2.ultimate, [KEY_KP_6, KEY_N], 0.35)

	_ensure_action(MENU.up, [KEY_W, KEY_UP], 0.28)
	_ensure_action(MENU.down, [KEY_S, KEY_DOWN], 0.28)
	_ensure_action(MENU.left, [KEY_A, KEY_LEFT], 0.28)
	_ensure_action(MENU.right, [KEY_D, KEY_RIGHT], 0.28)
	_ensure_action(MENU.confirm, [KEY_ENTER, KEY_J, KEY_SPACE])
	_ensure_action(MENU.back, [KEY_ESCAPE, KEY_BACKSPACE])

	bind_joypad()
	if not Input.joy_connection_changed.is_connected(_on_joy_changed):
		Input.joy_connection_changed.connect(_on_joy_changed)


func _on_joy_changed(_device: int, _connected: bool) -> void:
	bind_joypad()


func bind_joypad() -> void:
	# DualSense via SDL: Cross=A, Circle=B, Square=X, Triangle=Y, Options=Start, L2/R2=triggers.
	_bind_dualsense(P1, 0, true)
	_bind_dualsense(P2, 1, false)
	_bind_menu_pad()
	var pads := Input.get_connected_joypads()
	if pads.size() == 1 and int(pads[0]) != 0:
		_bind_dualsense(P1, int(pads[0]), true)
	# Second pad Options also pauses.
	_joy_button(P1.pause, 1, JOY_BUTTON_START)
	_joy_button(P1.pause, 1, JOY_BUTTON_TOUCHPAD)


func _bind_dualsense(m: Dictionary, device: int, with_pause: bool) -> void:
	_joy_axis(m.left, device, JOY_AXIS_LEFT_X, -1.0)
	_joy_axis(m.right, device, JOY_AXIS_LEFT_X, 1.0)
	_joy_axis(m.up, device, JOY_AXIS_LEFT_Y, -1.0)
	_joy_axis(m.down, device, JOY_AXIS_LEFT_Y, 1.0)
	_joy_button(m.up, device, JOY_BUTTON_DPAD_UP)
	_joy_button(m.down, device, JOY_BUTTON_DPAD_DOWN)
	_joy_button(m.left, device, JOY_BUTTON_DPAD_LEFT)
	_joy_button(m.right, device, JOY_BUTTON_DPAD_RIGHT)
	_joy_button(m.light, device, JOY_BUTTON_X) # Square
	_joy_button(m.heavy, device, JOY_BUTTON_Y) # Triangle
	_joy_button(m.special, device, JOY_BUTTON_B) # Circle
	_joy_button(m.block, device, JOY_BUTTON_LEFT_SHOULDER) # L1
	_joy_axis(m.block, device, JOY_AXIS_TRIGGER_LEFT, 1.0) # L2
	_joy_button(m.grab, device, JOY_BUTTON_RIGHT_SHOULDER) # R1
	_joy_axis(m.ultimate, device, JOY_AXIS_TRIGGER_RIGHT, 1.0) # R2
	_joy_button(m.ultimate, device, JOY_BUTTON_RIGHT_STICK) # R3 extra
	if with_pause:
		_joy_button(m.pause, device, JOY_BUTTON_START) # Options
		_joy_button(m.pause, device, JOY_BUTTON_TOUCHPAD)


func _bind_menu_pad() -> void:
	_joy_axis(MENU.left, ANY_PAD, JOY_AXIS_LEFT_X, -1.0)
	_joy_axis(MENU.right, ANY_PAD, JOY_AXIS_LEFT_X, 1.0)
	_joy_axis(MENU.up, ANY_PAD, JOY_AXIS_LEFT_Y, -1.0)
	_joy_axis(MENU.down, ANY_PAD, JOY_AXIS_LEFT_Y, 1.0)
	_joy_button(MENU.up, ANY_PAD, JOY_BUTTON_DPAD_UP)
	_joy_button(MENU.down, ANY_PAD, JOY_BUTTON_DPAD_DOWN)
	_joy_button(MENU.left, ANY_PAD, JOY_BUTTON_DPAD_LEFT)
	_joy_button(MENU.right, ANY_PAD, JOY_BUTTON_DPAD_RIGHT)
	_joy_button(MENU.confirm, ANY_PAD, JOY_BUTTON_A) # Cross
	_joy_button(MENU.back, ANY_PAD, JOY_BUTTON_B) # Circle
	_joy_button(MENU.back, ANY_PAD, JOY_BUTTON_BACK) # Create


func map_for(player_index: int) -> Dictionary:
	return P1 if player_index == 0 else P2


func _ensure_action(action: String, keys: Array, deadzone: float = 0.5) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	else:
		InputMap.action_set_deadzone(action, deadzone)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		if not _has_event(action, ev):
			InputMap.action_add_event(action, ev)


func _joy_button(action: String, device: int, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	var ev := InputEventJoypadButton.new()
	ev.device = device
	ev.button_index = button
	if not _has_event(action, ev):
		InputMap.action_add_event(action, ev)


func _joy_axis(action: String, device: int, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	var ev := InputEventJoypadMotion.new()
	ev.device = device
	ev.axis = axis
	ev.axis_value = value
	if not _has_event(action, ev):
		InputMap.action_add_event(action, ev)


func _has_event(action: String, ev: InputEvent) -> bool:
	for existing in InputMap.action_get_events(action):
		if existing.as_text() == ev.as_text():
			return true
	return false


func help_text() -> String:
	return """PLAYER 1 KEYBOARD
  A / D     Walk
  DD        Run
  AA        Backdash
  W         Jump
  S         Crouch
  J         Light
  K         Heavy
  L         Special
  U         Block
  I         Throw
  O         Super
  Esc / P   Pause

DUALSENSE  PS5
  LS / D-pad   Move  (up jump, down crouch)
  Square       Light
  Triangle     Heavy
  Circle       Special
  L1 / L2      Block
  R1           Throw
  R2           Super
  Options      Pause
  Cross        Menu confirm
  Circle       Menu back
  Pad 1 = P1   Pad 2 = P2

PLAYER 2 KEYBOARD
  Arrows       Move
  Z X C        Light Heavy Special
  V B N        Block Throw Super
"""
