class_name OptionsScreen
extends Control

signal closed

var _index := 0
var _entries: Array[Dictionary] = []
const KEYS := ["difficulty", "cpu", "arena", "music", "sfx", "shake", "hitboxes", "back"]


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	PixelUI.full_bg(self)
	PixelUI.add_panel(self, Vector2(240, 36), Vector2(800, 640), PixelUI.GOLD)
	PixelUI.add_title(self, "OPTIONS", 64, Color(0.95, 0.22, 0.28))
	for i in KEYS.size():
		_entries.append(PixelUI.add_menu_row(self, 140.0 + i * 46.0, 600))
	PixelUI.add_footer(self, "A/D ADJUST  ENTER CONFIRM  ESC BACK")
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
		"hitboxes":
			GameState.show_hitboxes = not GameState.show_hitboxes
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
		"HITBOXES  < %s >" % ("ON" if GameState.show_hitboxes else "OFF"),
		"BACK",
	]
	for i in _entries.size():
		PixelUI.set_menu_row(_entries[i], vals[i], i == _index, 2)
