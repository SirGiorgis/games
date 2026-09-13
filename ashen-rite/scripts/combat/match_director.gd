class_name MatchDirector
extends Node2D

const VersusScr := preload("res://scripts/ui/versus_overlay.gd")

signal request_pause
signal match_over(winner: int)

var arena: ArenaWorld
var cam: FightCamera
var fx: FX
var p1: Fighter
var p2: Fighter
var hud: FightHUD
var pause_layer: PauseMenu
var vs_layer

var round_index: int = 1
var time_left: float = 99.0
var phase: String = "vs"
var phase_t: float = 0.0
var _banner: PixelLabel
var _banner_bg: TextureRect
var _paused: bool = false
var _ko_pending: bool = false
var _last_tick: int = 99
var _aid: String = "grass_field"
var _pause_lock: float = 0.0
var _first_hit: bool = true
var _super_dip: float = 0.0
var _key_was: Dictionary = {}
var _stop_until_ms: int = 0
var _super_until_ms: int = 0
var _ko_line: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	arena = ArenaWorld.new()
	add_child(arena)
	_aid = GameState.arena_id
	if GameState.random_arena or GameState.attract:
		var ids := ArenaWorld.all_ids()
		if not ids.is_empty():
			_aid = ids[randi() % ids.size()]
			if not GameState.attract:
				GameState.arena_id = _aid
	arena.build(_aid)

	fx = FX.new()
	add_child(fx)

	p1 = Fighter.new()
	p2 = Fighter.new()
	var c1 := CharacterCatalog.get_def(GameState.p1_character_id)
	var c2 := CharacterCatalog.get_def(GameState.p2_character_id)
	p1.setup(0, c1, GameState.attract, Vector2(360, 500))
	p2.setup(1, c2, GameState.p2_is_cpu or GameState.attract, Vector2(920, 500))
	p1.opponent = p2
	p2.opponent = p1
	add_child(p1)
	add_child(p2)
	p1.defeated.connect(_on_ko)
	p2.defeated.connect(_on_ko)
	p1.hit_landed.connect(_on_hit)
	p2.hit_landed.connect(_on_hit)
	p1.super_started.connect(_on_super.bind(p1))
	p2.super_started.connect(_on_super.bind(p2))
	p1.announced.connect(_on_announced)
	p2.announced.connect(_on_announced)
	p1.clash_happened.connect(_on_clash)
	p2.clash_happened.connect(_on_clash)

	cam = FightCamera.new()
	add_child(cam)
	cam.bind(p1, p2)

	hud = FightHUD.new()
	add_child(hud)
	hud.bind(p1, p2, ArenaWorld.display_name(_aid))
	p1.combo_changed.connect(func(n): hud.set_combo(0, n))
	p2.combo_changed.connect(func(n): hud.set_combo(1, n))

	pause_layer = PauseMenu.new()
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)
	pause_layer.hide()
	pause_layer.resumed.connect(_resume)
	pause_layer.restarted.connect(_restart_match)
	pause_layer.quit_to_menu.connect(_quit_match)

	vs_layer = VersusScr.new()
	add_child(vs_layer)

	_banner = PixelLabel.new()
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(host)
	_banner_bg = TextureRect.new()
	_banner_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_banner_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_banner_bg.visible = false
	_banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(_banner_bg)
	host.add_child(_banner)
	_set_banner("")

	AudioDirector.play_music("fight")
	_open_match()


func _open_match() -> void:
	round_index = 1
	_clear_pickups()
	p1.reset_round(Vector2(360, 500))
	p2.reset_round(Vector2(920, 500))
	p1.can_act = false
	p2.can_act = false
	phase = "vs"
	phase_t = 0.0
	vs_layer.present(p1.def, p2.def, ArenaWorld.display_name(_aid))
	AudioDirector.play("round")


func _clear_pickups() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("cotton_pickup"):
		if n.has_method("discard"):
			n.discard()
		else:
			n.queue_free()
	if p1:
		p1.cotton_left = 0
	if p2:
		p2.cotton_left = 0


func _begin_round() -> void:
	_restore_time()
	phase = "intro"
	phase_t = 0.0
	if GameState.time_attack:
		time_left = 60.0
		_last_tick = 60
	else:
		time_left = 99.0
		_last_tick = 99
	_ko_pending = false
	_clear_pickups()
	p1.reset_round(Vector2(360, 500))
	p2.reset_round(Vector2(920, 500))
	p1.can_act = false
	p2.can_act = false
	_first_hit = true
	_super_dip = 0.0
	var final_r: bool = GameState.p1_rounds >= GameState.rounds_to_win - 1 and GameState.p2_rounds >= GameState.rounds_to_win - 1 and round_index > 1
	if GameState.training:
		_set_banner("TRAINING")
	elif GameState.attract:
		_set_banner("DEMO")
	elif GameState.survival:
		_set_banner("WAVE %d" % GameState.survival_wave)
	elif GameState.time_attack:
		_set_banner("TIME ATTACK")
	elif GameState.arcade:
		_set_banner("BOUT %d" % (GameState.arcade_index + 1))
	elif final_r:
		_set_banner("FINAL ROUND")
	else:
		_set_banner("ROUND %d" % round_index)
	AudioDirector.play("round")
	hud.set_timer(int(ceil(time_left)))
	hud.set_rounds(GameState.p1_rounds, GameState.p2_rounds)


func _process(delta: float) -> void:
	_pause_lock = max(0.0, _pause_lock - delta)
	_sync_time_scale()
	if _super_dip > 0.0 and phase == "fight":
		_super_dip -= delta
	if _paused:
		return
	if GameState.attract and (Input.is_action_just_pressed(ControlMap.MENU.confirm) or Input.is_action_just_pressed(ControlMap.MENU.back) or Input.is_action_just_pressed(ControlMap.P1.pause)):
		_quit_match()
		return
	if _pause_lock <= 0.0 and Input.is_action_just_pressed(ControlMap.P1.pause):
		_pause()
		return
	if _ko_pending and phase == "fight":
		_resolve_ko()
		return
	match phase:
		"vs":
			phase_t += delta
			var vs_need: float = 0.85 if GameState.training else (1.25 if GameState.attract else 2.15)
			if GameState.arcade:
				vs_need = 1.05
			if phase_t > vs_need or Input.is_action_just_pressed(ControlMap.MENU.confirm):
				vs_layer.dismiss()
				_begin_round()
		"intro":
			phase_t += delta
			if phase_t > 1.05:
				_set_banner("FIGHT")
				AudioDirector.play("fight")
				cam.punch(0.055)
				cam.shake(0.32)
				phase = "fight_call"
				phase_t = 0.0
		"fight_call":
			phase_t += delta
			if phase_t > 0.55:
				_set_banner("")
				p1.can_act = true
				p2.can_act = true
				phase = "fight"
		"fight":
			if GameState.training:
				if p1 and not p1.is_cpu:
					p1.training_tick(delta)
				if _tap(KEY_R):
					_begin_round()
					return
				if _tap(KEY_F):
					var modes := ["cpu", "block", "stand", "crouch", "jump", "mash"]
					var di := modes.find(GameState.dummy_mode)
					if di < 0:
						di = 0
					GameState.dummy_mode = modes[posmod(di + 1, modes.size())]
					_flash_call(GameState.dummy_mode.to_upper())
			else:
				time_left = max(0.0, time_left - delta)
				var t: int = int(ceil(time_left))
				hud.set_timer(t)
				if t != _last_tick and t in [10, 5, 3, 2, 1]:
					AudioDirector.play("tick", 1.0 + (10 - t) * 0.04, 0.55)
				_last_tick = t
				if time_left <= 0.0:
					_timeout()
		"slowko":
			phase_t += delta
			if phase_t > 0.62:
				if not _ko_line.is_empty():
					_set_banner(_ko_line)
				_restore_time()
				phase = "ko"
				phase_t = 0.0
		"ko":
			phase_t += delta
			if phase_t > (0.55 if GameState.training else 1.85):
				_finish_round()
		"endwait":
			phase_t += delta
			if phase_t > 1.5:
				_restore_time()
				match_over.emit(GameState.last_winner)


func _on_ko(_f: Fighter) -> void:
	if phase != "fight":
		return
	_ko_pending = true


func _resolve_ko() -> void:
	_ko_pending = false
	if phase != "fight":
		return
	p1.lock_out()
	p2.lock_out()
	if GameState.training:
		_set_banner("RESET")
		AudioDirector.play("ko")
		phase = "ko"
		phase_t = 0.0
		return
	var d1: bool = p1.health <= 0.0
	var d2: bool = p2.health <= 0.0
	GameState.last_was_timeout = false
	GameState.last_was_double = d1 and d2
	GameState.last_was_perfect = false
	GameState.last_was_dramatic = false
	_ko_line = ""
	if d1 and d2:
		GameState.last_winner = -1
		p1.celebrate(false)
		p2.celebrate(false)
		_ko_line = "DOUBLE KO"
		_set_banner("KO")
		AudioDirector.play("ko")
		AudioDirector.play("cheer", 0.85, 0.55)
		cam.shake(1.6)
		cam.ko_zoom()
		ControlMap.rumble(0, 0.55, 1.0, 0.42)
		ControlMap.rumble(1, 0.55, 1.0, 0.42)
		_start_slowmo()
		return
	var winner: int = 0 if d2 else 1
	var w: Fighter = p1 if winner == 0 else p2
	var l: Fighter = p2 if winner == 0 else p1
	GameState.last_winner = winner
	GameState.last_was_perfect = w.health >= w.max_health - 0.5
	if winner == 0:
		GameState.p1_rounds += 1
	else:
		GameState.p2_rounds += 1
	w.celebrate(true)
	l.celebrate(false)
	GameState.last_was_dramatic = w.health / maxf(w.max_health, 1.0) <= 0.14
	if GameState.last_was_perfect:
		_ko_line = "PERFECT"
	elif GameState.last_was_dramatic:
		_ko_line = "DRAMATIC FINISH"
	else:
		_ko_line = "%s WINS" % w.def.callsign()
	_set_banner("KO")
	AudioDirector.play("ko")
	AudioDirector.play("cheer", 1.0, 0.7)
	cam.shake(1.4)
	cam.ko_zoom()
	ControlMap.rumble(0, 0.55, 1.0, 0.42)
	ControlMap.rumble(1, 0.55, 1.0, 0.42)
	hud.set_rounds(GameState.p1_rounds, GameState.p2_rounds)
	_start_slowmo()


func _timeout() -> void:
	p1.lock_out()
	p2.lock_out()
	GameState.last_was_timeout = true
	GameState.last_was_double = false
	GameState.last_was_dramatic = false
	var winner := 0 if p1.health >= p2.health else 1
	if abs(p1.health - p2.health) < 1.0:
		GameState.last_was_double = true
		GameState.last_winner = -1
		p1.celebrate(false)
		p2.celebrate(false)
		_set_banner("TIME")
		hud.set_rounds(GameState.p1_rounds, GameState.p2_rounds)
		phase = "ko"
		phase_t = 0.0
		return
	GameState.last_winner = winner
	var w: Fighter = p1 if winner == 0 else p2
	var l: Fighter = p2 if winner == 0 else p1
	GameState.last_was_perfect = false
	if winner == 0:
		GameState.p1_rounds += 1
	else:
		GameState.p2_rounds += 1
	w.celebrate(true)
	l.celebrate(false)
	_set_banner("TIME")
	hud.set_rounds(GameState.p1_rounds, GameState.p2_rounds)
	phase = "ko"
	phase_t = 0.0


func _start_slowmo() -> void:
	Engine.time_scale = 0.32
	cam.punch(0.07)
	fx.super_flash(Color(1, 0.92, 0.75), 0.38)
	fx.letterbox(0.55)
	phase = "slowko"
	phase_t = 0.0


func _restore_time() -> void:
	_stop_until_ms = 0
	_super_until_ms = 0
	_super_dip = 0.0
	Engine.time_scale = 1.0


func _sync_time_scale() -> void:
	if _paused:
		return
	var now: int = Time.get_ticks_msec()
	if phase == "slowko":
		Engine.time_scale = 0.32
	elif now < _super_until_ms:
		Engine.time_scale = 0.14
	elif now < _stop_until_ms:
		Engine.time_scale = 0.05
	elif Engine.time_scale != 1.0:
		Engine.time_scale = 1.0


func world_stop(ms: int) -> void:
	if GameState.attract or _paused:
		return
	if Time.get_ticks_msec() < _super_until_ms:
		return
	_stop_until_ms = maxi(_stop_until_ms, Time.get_ticks_msec() + clampi(ms, 24, 150))


func _finish_round() -> void:
	_restore_time()
	if GameState.training:
		_begin_round()
		return
	if GameState.attract:
		match_over.emit(GameState.last_winner)
		return
	if GameState.last_was_double:
		_begin_round()
		return
	if GameState.p1_rounds >= GameState.rounds_to_win or GameState.p2_rounds >= GameState.rounds_to_win:
		phase = "endwait"
		phase_t = 0.0
		_set_banner("RITE COMPLETE")
		return
	round_index += 1
	_begin_round()


func _on_hit(f: Fighter, attack: Dictionary, crit: bool) -> void:
	var strong: bool = attack.get("kind", "") in ["heavy", "special", "ultimate", "dash_atk"] or crit or bool(attack.get("counter", false))
	var attacker: Fighter = p1 if f == p2 else p2
	var dir := Vector2(float(attacker.facing), -0.22)
	fx.spark(f.global_position + Vector2(float(attacker.facing) * 18.0, -72), attacker.def.accent, strong, dir)
	cam.shake(0.72 if strong else 0.28)
	cam.punch(0.055 if strong else 0.026)
	cam.hit_nudge(dir, 1.15 if strong else 0.55)
	if strong:
		fx.hit_flash(attacker.def.accent, 0.16, 0.07)
	var atk_side: int = 0 if attacker == p1 else 1
	var vic_side: int = 0 if f == p1 else 1
	ControlMap.rumble(atk_side, 0.10 if not strong else 0.22, 0.18 if not strong else 0.48, 0.06 if not strong else 0.11)
	ControlMap.rumble(vic_side, 0.16 if not strong else 0.38, 0.28 if not strong else 0.78, 0.08 if not strong else 0.14)
	var stop_ms: int = int(round(float(attack.get("hitstop", 0.05)) * 1000.0 * (1.35 if strong else 1.1)))
	world_stop(stop_ms)
	var dealt: int = int(round(float(attack.get("dealt", attack.get("damage", 0)))))
	if dealt > 0:
		var col := Color(1, 0.92, 0.45)
		if crit:
			col = Color(1, 0.55, 0.2)
		elif bool(attack.get("counter", false)):
			col = Color(1, 0.72, 0.28)
		fx.popup(f.global_position + Vector2(randf_range(-12, 12), -40), str(dealt), col)
		GameState.note_hit(p1.combo_hits if f == p2 else p2.combo_hits, float(dealt))
	if bool(attack.get("freeze", false)):
		fx.crystals(f.global_position + Vector2(0, -70))
	if bool(attack.get("quake", false)):
		fx.quake_dust(f.global_position)
		cam.shake(1.1)
	if _first_hit and phase == "fight":
		_first_hit = false
		_flash_call("FIRST HIT")
	elif bool(attack.get("punish", false)):
		_flash_call("PUNISH")
	elif bool(attack.get("counter", false)):
		_flash_call("COUNTER")
	elif bool(attack.get("stun", false)):
		_flash_call("STUN")
	elif crit:
		_flash_call("CRITICAL")


func _flash_call(text: String) -> void:
	if phase != "fight":
		return
	_set_banner(text)
	get_tree().create_timer(0.42).timeout.connect(func():
		if is_instance_valid(self) and phase == "fight":
			_set_banner("")
	)


func _on_super(f: Fighter) -> void:
	var flash_col := Color(0.95, 0.9, 1.0)
	match f.def.ultimate_id:
		"grid":
			flash_col = Color(0.86, 0.14, 0.12)
			fx.grid_streaks(f.global_position + Vector2(float(f.facing) * 40.0, -24), f.facing)
		"dempsey":
			flash_col = Color(0.95, 0.72, 0.38)
			fx.dempsey_burst(f.global_position + Vector2(float(f.facing) * 28.0, -70))
		"vodka":
			flash_col = Color(0.72, 0.95, 0.86)
			fx.vodka_glug(f.global_position + Vector2(0, -78))
		"fart":
			flash_col = Color(0.55, 0.88, 0.32)
			fx.fart_cloud(f.global_position + Vector2(float(f.facing) * 24.0, -28))
		"flex":
			flash_col = Color(0.35, 0.82, 0.92)
			fx.shirt_rip(f.global_position + Vector2(0, -70))
		"drip":
			flash_col = Color(0.92, 0.78, 0.32)
			fx.drip_drop(f.global_position + Vector2(0, -24))
		"cotton":
			flash_col = Color(0.96, 0.92, 0.78)
			fx.cotton_scatter(f.global_position + Vector2(0, -12))
	fx.super_flash(flash_col, 0.55)
	fx.shade(0.72)
	fx.shockwave(f.global_position + Vector2(0, -70))
	cam.punch(0.11)
	cam.shake(1.05)
	cam.focus_on(f, 0.48)
	AudioDirector.play("super_call", 1.0, 0.88)
	fx.letterbox(0.78)
	ControlMap.rumble(0 if f == p1 else 1, 0.42, 0.92, 0.28)
	ControlMap.rumble(1 if f == p1 else 0, 0.22, 0.48, 0.18)
	if phase == "fight":
		_super_until_ms = Time.get_ticks_msec() + 420
		Engine.time_scale = 0.14
		_super_dip = 0.08
		_flash_call(f.def.ultimate_name.to_upper())


func _on_announced(text: String) -> void:
	_flash_call(text)
	if text == "BURST" and p1 and p2:
		fx.burst_ring((p1.global_position + p2.global_position) * 0.5 + Vector2(0, -60))
		cam.shake(0.7)
	elif text == "PARRY" and p1:
		fx.shockwave(p1.global_position + Vector2(0, -60))


func _tap(key: Key) -> bool:
	var down := Input.is_physical_key_pressed(key)
	var was: bool = _key_was.get(key, false)
	_key_was[key] = down
	return down and not was


func _on_clash(pos: Vector2) -> void:
	fx.clash_burst(pos)
	cam.shake(0.7)
	cam.punch(0.05)
	ControlMap.rumble(0, 0.28, 0.55, 0.12)
	ControlMap.rumble(1, 0.28, 0.55, 0.12)
	_flash_call("CLASH")


func _pause() -> void:
	if phase != "fight":
		return
	_paused = true
	_pause_lock = 0.22
	_restore_time()
	AudioDirector.play_music("pause")
	pause_layer.show_menu()
	get_tree().paused = true


func _resume(restore_music: bool = true) -> void:
	_paused = false
	_pause_lock = 0.22
	pause_layer.hide_menu()
	get_tree().paused = false
	_restore_time()
	if restore_music:
		AudioDirector.play_music("fight")


func _quit_match() -> void:
	_resume(false)
	_restore_time()
	match_over.emit(-2)


func _restart_match() -> void:
	_resume()
	GameState.reset_match_score()
	vs_layer.dismiss()
	_open_match()


func _set_banner(text: String) -> void:
	if _banner == null:
		return
	if text.is_empty():
		_banner.visible = false
		if _banner_bg:
			_banner_bg.visible = false
		return
	_banner.visible = true
	var col := Color(1, 0.92, 0.42)
	if text == "FIGHT":
		col = Color(1, 0.32, 0.26)
	elif text == "KO" or text == "RITE COMPLETE" or text.ends_with("WINS"):
		col = Color(0.95, 0.78, 0.28)
	elif text == "TIME" or text == "DOUBLE KO":
		col = Color(0.75, 0.82, 1.0)
	elif text == "CRITICAL" or text == "COUNTER" or text == "PERFECT" or text == "DRAMATIC FINISH" or text == "PUNISH" or text == "GUARD BREAK":
		col = Color(1, 0.55, 0.2)
	elif text == "CLASH" or text == "TECH" or text == "AIR TECH" or text == "JUST GUARD" or text == "PARRY" or text == "BURST" or text == "ROLL" or text == "AIR DASH":
		col = Color(0.55, 0.88, 1.0)
	elif text == "REVERSAL" or text == "SUPER CANCEL" or text == "PUSHBLOCK" or text == "WALL BOUNCE" or text == "ARMOR":
		col = Color(1.0, 0.72, 0.28)
	elif text == "EX" or text == "TRAINING" or text == "DEMO" or text == "RESET" or text == "FINAL ROUND" or text == "FIRST HIT":
		col = Color(1.0, 0.86, 0.32)
	var sc: int = 5 if text.length() > 10 else 6
	_banner.set_pix(text, sc, col)
	_banner.set_centered(1280)
	_banner.position = Vector2(0, 292)
	_banner.modulate = Color(1.4, 1.4, 1.28)
	_banner.scale = Vector2(1.18, 1.18)
	_banner.pivot_offset = Vector2(640, 24)
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_banner, "modulate", Color.WHITE, 0.22)
	tw.parallel().tween_property(_banner, "scale", Vector2.ONE, 0.22)
	if _banner_bg:
		var bw: int = clampi(text.length() * 14 + 48, 110, 220)
		_banner_bg.texture = PixelUI.round_banner(bw)
		_banner_bg.size = Vector2(bw * 4, 120)
		_banner_bg.position = Vector2(640.0 - _banner_bg.size.x * 0.5, 264)
		_banner_bg.visible = true
		_banner_bg.modulate = Color(1.2, 1.2, 1.15)
		var btw := create_tween()
		btw.tween_property(_banner_bg, "modulate", Color.WHITE, 0.2)
