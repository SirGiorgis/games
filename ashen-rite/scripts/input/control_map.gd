extends Node
## Central, expandable control map. Keyboard defaults live here.
## Add JoypadButton / JoypadMotion events in bind_joypad() when you add controllers.

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

func _ready() -> void:
	_ensure_action(P1.left, [KEY_A])
	_ensure_action(P1.right, [KEY_D])
	_ensure_action(P1.up, [KEY_W])
	_ensure_action(P1.down, [KEY_S])
	_ensure_action(P1.light, [KEY_J])
	_ensure_action(P1.heavy, [KEY_K])
	_ensure_action(P1.special, [KEY_L])
	_ensure_action(P1.block, [KEY_U])
	_ensure_action(P1.grab, [KEY_I])
	_ensure_action(P1.ultimate, [KEY_O])
	_ensure_action(P1.pause, [KEY_ESCAPE, KEY_P])

	_ensure_action(P2.left, [KEY_LEFT])
	_ensure_action(P2.right, [KEY_RIGHT])
	_ensure_action(P2.up, [KEY_UP])
	_ensure_action(P2.down, [KEY_DOWN])
	_ensure_action(P2.light, [KEY_KP_1, KEY_Z])
	_ensure_action(P2.heavy, [KEY_KP_2, KEY_X])
	_ensure_action(P2.special, [KEY_KP_3, KEY_C])
	_ensure_action(P2.block, [KEY_KP_4, KEY_V])
	_ensure_action(P2.grab, [KEY_KP_5, KEY_B])
	_ensure_action(P2.ultimate, [KEY_KP_6, KEY_N])

	_ensure_action(MENU.up, [KEY_W, KEY_UP])
	_ensure_action(MENU.down, [KEY_S, KEY_DOWN])
	_ensure_action(MENU.left, [KEY_A, KEY_LEFT])
	_ensure_action(MENU.right, [KEY_D, KEY_RIGHT])
	_ensure_action(MENU.confirm, [KEY_ENTER, KEY_J, KEY_SPACE])
	_ensure_action(MENU.back, [KEY_ESCAPE, KEY_BACKSPACE])

	bind_joypad()


func bind_joypad() -> void:
	## DualShock / Xbox style: left stick + face buttons. Device 0 = P1, device 1 = P2.
	_joy_axis(P1.left, 0, JOY_AXIS_LEFT_X, -1.0)
	_joy_axis(P1.right, 0, JOY_AXIS_LEFT_X, 1.0)
	_joy_button(P1.up, 0, JOY_BUTTON_DPAD_UP)
	_joy_button(P1.down, 0, JOY_BUTTON_DPAD_DOWN)
	_joy_button(P1.left, 0, JOY_BUTTON_DPAD_LEFT)
	_joy_button(P1.right, 0, JOY_BUTTON_DPAD_RIGHT)
	_joy_button(P1.light, 0, JOY_BUTTON_X)
	_joy_button(P1.heavy, 0, JOY_BUTTON_Y)
	_joy_button(P1.special, 0, JOY_BUTTON_B)
	_joy_button(P1.block, 0, JOY_BUTTON_LEFT_SHOULDER)
	_joy_button(P1.grab, 0, JOY_BUTTON_RIGHT_SHOULDER)
	_joy_button(P1.ultimate, 0, JOY_BUTTON_RIGHT_STICK)
	_joy_button(P1.pause, 0, JOY_BUTTON_START)

	_joy_axis(P2.left, 1, JOY_AXIS_LEFT_X, -1.0)
	_joy_axis(P2.right, 1, JOY_AXIS_LEFT_X, 1.0)
	_joy_button(P2.up, 1, JOY_BUTTON_DPAD_UP)
	_joy_button(P2.down, 1, JOY_BUTTON_DPAD_DOWN)
	_joy_button(P2.left, 1, JOY_BUTTON_DPAD_LEFT)
	_joy_button(P2.right, 1, JOY_BUTTON_DPAD_RIGHT)
	_joy_button(P2.light, 1, JOY_BUTTON_X)
	_joy_button(P2.heavy, 1, JOY_BUTTON_Y)
	_joy_button(P2.special, 1, JOY_BUTTON_B)
	_joy_button(P2.block, 1, JOY_BUTTON_LEFT_SHOULDER)
	_joy_button(P2.grab, 1, JOY_BUTTON_RIGHT_SHOULDER)
	_joy_button(P2.ultimate, 1, JOY_BUTTON_RIGHT_STICK)


func map_for(player_index: int) -> Dictionary:
	return P1 if player_index == 0 else P2


func _ensure_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
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
	return """PLAYER 1  (MUGEN STYLE)
  A / D     Walk  (hold back = guard, you can still walk back)
  DD        Run
  AA        Backdash (invuln)
  W         Jump  (WA back / WD forward)
  S         Crouch  (S+J crouch light, S+K sweep)
  J         Light  (air J = jump-in overhead)
  K         Heavy
  S,S+D+J   Special  (quarter circle + button, costs meter)
  L         Special
  U         Stand guard
  I         Throw  (beats guard)
  O         Super  (or 236236 + button)
  Esc / P   Pause

  Guard: standing blocks mid/high, crouch blocks mid/low.
  Sweeps must be crouch-blocked. Jump attacks must be stand-blocked.
  Lights cancel once into another light, then heavy/special/super.
  Lights are minus on block. Whiffs do not auto-fire. Jump-cancel heavies on hit.

PLAYER 2
  Arrows    Move / jump / crouch
  Numpad 1 / Z   Light
  Numpad 2 / X   Heavy
  Numpad 3 / C   Special
  Numpad 4 / V   Block
  Numpad 5 / B   Grab
  Numpad 6 / N   Super

MENUS
  W/S or Arrows   Navigate
  Enter / J / Space   Confirm
  Esc   Back
"""
