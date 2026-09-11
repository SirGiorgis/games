class_name OptionsScreen
extends Control

signal closed

var _index := 0
var _lines: Array[PixelLabel] = []
const KEYS := ["difficulty", "cpu", "arena", "music", "sfx", "shake", "back"]


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.label_at(self, "OPTIONS", Vector2(0, 70), 6, Color(0.92, 0.22, 0.28), 0, 1280).set_centered(1280)
	for i in KEYS.size():
		var l := PixelLabel.new()
		l.position = Vector2(0, 180 + i * 46)
		add_child(l)
		_lines.append(l)
	_refresh()


func _process(_d: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(ControlMap.MENU.down):
		_index = (_index + 1) % KEYS.size()
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.up):
		_index = (_index + KEYS.size() - 1) % KEYS.size()
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.left):
		_nudge(-1)
	elif Input.is_action_just_pressed(ControlMap.MENU.right):
		_nudge(1)
	elif Input.is_action_just_pressed(ControlMap.MENU.confirm):
		if KEYS[_index] == "back":
			closed.emit()
		else:
			_nudge(1)
	elif Input.is_action_just_pressed(ControlMap.MENU.back):
		closed.emit()


func _nudge(dir: int) -> void:
	AudioDirector.play("ui")
	match KEYS[_index]:
		"difficulty":
			GameState.cycle_difficulty(dir)
		"cpu":
			GameState.p2_is_cpu = not GameState.p2_is_cpu
		"arena":
			var ids := ArenaWorld.all_ids()
			if GameState.random_arena:
				GameState.random_arena = false
				GameState.arena_id = ids[0]
			else:
				var i := 0
				for k in ids.size():
					if ids[k] == GameState.arena_id:
						i = k
				i += dir
				if i < 0 or i >= ids.size():
					GameState.random_arena = true
				else:
					GameState.arena_id = ids[i]
		"music":
			GameState.music_volume = clampf(GameState.music_volume + dir * 0.1, 0.0, 1.0)
			AudioDirector.music_player.volume_db = linear_to_db(clamp(GameState.music_volume, 0.001, 1.0))
		"sfx":
			GameState.sfx_volume = clampf(GameState.sfx_volume + dir * 0.1, 0.0, 1.0)
		"shake":
			GameState.shake_strength = clampf(GameState.shake_strength + dir * 0.2, 0.0, 2.0)
		"back":
			closed.emit()
	_refresh()


func _refresh() -> void:
	var arena := "RANDOM" if GameState.random_arena else ArenaWorld.display_name(GameState.arena_id)
	var vals := [
		"AI  < %s >" % GameState.difficulty_name(),
		"P2  < %s >" % ("CPU" if GameState.p2_is_cpu else "HUMAN"),
		"ARENA  < %s >" % arena,
		"MUSIC  < %d >" % int(GameState.music_volume * 100),
		"SFX  < %d >" % int(GameState.sfx_volume * 100),
		"SHAKE  < %.1f >" % GameState.shake_strength,
		"BACK",
	]
	for i in _lines.size():
		var sel := i == _index
		_lines[i].set_pix(("> " + vals[i] + " <") if sel else vals[i], 2, Color(1, 0.85, 0.4) if sel else Color(0.8, 0.78, 0.76))
		_lines[i].set_centered(1280)
