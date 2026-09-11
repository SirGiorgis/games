class_name OptionsScreen
extends Control

signal closed

var _index := 0
var _lines: Array[Label] = []
const KEYS := ["difficulty", "cpu", "arena", "music", "sfx", "shake", "back"]


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.02, 0.06)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "OPTIONS"
	title.position = Vector2(0, 80)
	title.size = Vector2(1280, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(title, 48, Color(0.92, 0.22, 0.28))
	add_child(title)
	for i in KEYS.size():
		var l := Label.new()
		l.position = Vector2(0, 200 + i * 50)
		l.size = Vector2(1280, 40)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIKit.style_label(l, 26)
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
		elif KEYS[_index] == "cpu":
			GameState.p2_is_cpu = not GameState.p2_is_cpu
			_refresh()
		elif KEYS[_index] == "arena":
			GameState.random_arena = not GameState.random_arena
			_refresh()
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
		"AI DIFFICULTY   < %s >" % GameState.difficulty_name(),
		"PLAYER 2        < %s >" % ("CPU" if GameState.p2_is_cpu else "HUMAN"),
		"ARENA           < %s >" % arena,
		"MUSIC           < %d%% >" % int(GameState.music_volume * 100),
		"SFX             < %d%% >" % int(GameState.sfx_volume * 100),
		"SCREEN SHAKE    < %.1f >" % GameState.shake_strength,
		"BACK",
	]
	for i in _lines.size():
		_lines[i].text = UIKit.make_button_label(vals[i], i == _index)
		_lines[i].add_theme_color_override("font_color", Color(1, 0.85, 0.4) if i == _index else Color(0.8, 0.78, 0.76))
