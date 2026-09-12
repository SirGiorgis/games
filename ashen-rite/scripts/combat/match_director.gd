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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	arena = ArenaWorld.new()
	add_child(arena)
	_aid = GameState.arena_id
	if GameState.random_arena:
		var ids := ArenaWorld.all_ids()
		_aid = ids[randi() % ids.size()]
		GameState.arena_id = _aid
	arena.build(_aid)

	fx = FX.new()
	add_child(fx)

	p1 = Fighter.new()
	p2 = Fighter.new()
	var c1 := CharacterCatalog.get_def(GameState.p1_character_id)
	var c2 := CharacterCatalog.get_def(GameState.p2_character_id)
	p1.setup(0, c1, false, Vector2(360, 500))
	p2.setup(1, c2, GameState.p2_is_cpu, Vector2(920, 500))
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
	p1.reset_round(Vector2(360, 500))
	p2.reset_round(Vector2(920, 500))
	p1.can_act = false
	p2.can_act = false
	phase = "vs"
	phase_t = 0.0
	vs_layer.present(p1.def, p2.def, ArenaWorld.display_name(_aid))
	AudioDirector.play("round")


func _begin_round() -> void:
	_restore_time()
	phase = "intro"
	phase_t = 0.0
	time_left = 99.0
	_last_tick = 99
	_ko_pending = false
	p1.reset_round(Vector2(360, 500))
	p2.reset_round(Vector2(920, 500))
	p1.can_act = false
	p2.can_act = false
	_first_hit = true
	_super_dip = 0.0
	var final_r: bool = GameState.p1_rounds >= GameState.rounds_to_win - 1 and GameState.p2_rounds >= GameState.rounds_to_win - 1 and round_index > 1
	if final_r:
		_set_banner("FINAL ROUND")
	else:
		_set_banner("ROUND %d" % round_index)
	AudioDirector.play("round")
	hud.set_timer(99)
	hud.set_rounds(GameState.p1_rounds, GameState.p2_rounds)


func _process(delta: float) -> void:
	_pause_lock = max(0.0, _pause_lock - delta)
	if _super_dip > 0.0 and phase == "fight":
		_super_dip -= delta
		if _super_dip <= 0.0:
			_restore_time()
	if _paused:
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
			if phase_t > 1.85 or Input.is_action_just_pressed(ControlMap.MENU.confirm):
				vs_layer.dismiss()
				_begin_round()
		"intro":
			phase_t += delta
			if phase_t > 0.85:
				_set_banner("FIGHT")
				AudioDirector.play("fight")
				phase = "fight_call"
				phase_t = 0.0
		"fight_call":
			phase_t += delta
			if phase_t > 0.42:
				_set_banner("")
				p1.can_act = true
				p2.can_act = true
				phase = "fight"
		"fight":
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
			if phase_t > 0.42:
				_restore_time()
				phase = "ko"
				phase_t = 0.0
		"ko":
			phase_t += delta
			if phase_t > 1.7:
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
	var d1: bool = p1.health <= 0.0
	var d2: bool = p2.health <= 0.0
	GameState.last_was_timeout = false
	GameState.last_was_double = d1 and d2
	GameState.last_was_perfect = false
	GameState.last_was_dramatic = false
	if d1 and d2:
		GameState.last_winner = -1
		p1.celebrate(false)
		p2.celebrate(false)
		_set_banner("DOUBLE KO")
		AudioDirector.play("ko")
		AudioDirector.play("cheer", 0.85, 0.55)
		cam.shake(1.6)
		cam.ko_zoom()
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
		_set_banner("PERFECT")
	elif GameState.last_was_dramatic:
		_set_banner("DRAMATIC FINISH")
	else:
		_set_banner("%s WINS" % w.def.callsign())
	AudioDirector.play("ko")
	AudioDirector.play("cheer", 1.0, 0.7)
	cam.shake(1.4)
	cam.ko_zoom()
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
	Engine.time_scale = 0.38
	cam.punch(0.055)
	fx.super_flash(Color(1, 0.92, 0.75), 0.28)
	phase = "slowko"
	phase_t = 0.0


func _restore_time() -> void:
	Engine.time_scale = 1.0


func _finish_round() -> void:
	_restore_time()
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
	var strong: bool = attack.get("kind", "") in ["heavy", "special", "ultimate"] or crit or bool(attack.get("counter", false))
	fx.spark(f.global_position + Vector2(0, -72), p1.def.accent if f == p2 else p2.def.accent, strong)
	cam.shake(0.48 if strong else 0.14)
	cam.punch(0.038 if strong else 0.018)
	var dealt: int = int(round(float(attack.get("dealt", attack.get("damage", 0)))))
	if dealt > 0:
		var col := Color(1, 0.92, 0.45)
		if crit:
			col = Color(1, 0.55, 0.2)
		elif bool(attack.get("counter", false)):
			col = Color(1, 0.72, 0.28)
		fx.popup(f.global_position + Vector2(randf_range(-12, 12), -40), str(dealt), col)
	if _first_hit and phase == "fight":
		_first_hit = false
		_flash_call("FIRST HIT")
	elif bool(attack.get("counter", false)):
		_flash_call("COUNTER")
	elif crit:
		_flash_call("CRITICAL")


func _flash_call(text: String) -> void:
	if phase != "fight":
		return
	_set_banner(text)
	get_tree().create_timer(0.32).timeout.connect(func():
		if is_instance_valid(self) and phase == "fight":
			_set_banner("")
	)


func _on_super(f: Fighter) -> void:
	fx.super_flash(Color(0.95, 0.9, 1.0), 0.42)
	fx.shade(0.55)
	fx.shockwave(f.global_position + Vector2(0, -70))
	cam.punch(0.08)
	cam.shake(0.85)
	AudioDirector.play("super_call", 1.0, 0.8)
	if phase == "fight":
		Engine.time_scale = 0.22
		_super_dip = 0.12
		_flash_call(f.def.ultimate_name.to_upper())


func _on_announced(text: String) -> void:
	_flash_call(text)


func _on_clash(pos: Vector2) -> void:
	fx.clash_burst(pos)
	cam.shake(0.7)
	cam.punch(0.05)
	_flash_call("CLASH")


func _pause() -> void:
	if phase != "fight":
		return
	_paused = true
	_pause_lock = 0.22
	_restore_time()
	pause_layer.show_menu()
	get_tree().paused = true


func _resume() -> void:
	_paused = false
	_pause_lock = 0.22
	pause_layer.hide_menu()
	get_tree().paused = false
	_restore_time()


func _quit_match() -> void:
	_resume()
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
	elif text == "CRITICAL" or text == "COUNTER" or text == "PERFECT" or text == "DRAMATIC FINISH":
		col = Color(1, 0.55, 0.2)
	elif text == "CLASH" or text == "TECH" or text == "AIR TECH" or text == "JUST GUARD":
		col = Color(0.55, 0.88, 1.0)
	elif text == "REVERSAL" or text == "SUPER CANCEL" or text == "PUSHBLOCK" or text == "WALL BOUNCE":
		col = Color(1.0, 0.72, 0.28)
	elif text == "FINAL ROUND" or text == "FIRST HIT":
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
