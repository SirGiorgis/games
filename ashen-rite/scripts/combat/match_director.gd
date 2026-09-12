class_name MatchDirector
extends Node2D

signal request_pause
signal match_over(winner: int)

var arena: ArenaWorld
var cam: FightCamera
var fx: FX
var p1: Fighter
var p2: Fighter
var hud: FightHUD
var pause_layer: PauseMenu

var round_index: int = 1
var time_left: float = 99.0
var phase: String = "intro"
var phase_t: float = 0.0
var _banner: PixelLabel
var _banner_bg: TextureRect
var _paused: bool = false


func _ready() -> void:
	arena = ArenaWorld.new()
	add_child(arena)
	var aid := GameState.arena_id
	if GameState.random_arena:
		var ids := ArenaWorld.all_ids()
		aid = ids[randi() % ids.size()]
		GameState.arena_id = aid
	arena.build(aid)

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

	cam = FightCamera.new()
	add_child(cam)
	cam.bind(p1, p2)

	hud = FightHUD.new()
	add_child(hud)
	hud.bind(p1, p2, ArenaWorld.display_name(aid))
	p1.combo_changed.connect(func(n): hud.set_combo(0, n))
	p2.combo_changed.connect(func(n): hud.set_combo(1, n))

	pause_layer = PauseMenu.new()
	add_child(pause_layer)
	pause_layer.hide()
	pause_layer.resumed.connect(_resume)
	pause_layer.restarted.connect(_restart_match)
	pause_layer.quit_to_menu.connect(func(): match_over.emit(-2))

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
	_begin_round()


func _begin_round() -> void:
	phase = "intro"
	phase_t = 0.0
	time_left = 99.0
	p1.reset_round(Vector2(360, 500))
	p2.reset_round(Vector2(920, 500))
	p1.can_act = false
	p2.can_act = false
	_set_banner("ROUND %d" % round_index)
	AudioDirector.play("round")
	hud.set_timer(99)
	hud.set_rounds(GameState.p1_rounds, GameState.p2_rounds)


func _process(delta: float) -> void:
	if _paused:
		return
	if Input.is_action_just_pressed(ControlMap.P1.pause):
		_pause()
		return
	match phase:
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
			hud.set_timer(int(ceil(time_left)))
			if time_left <= 0.0:
				_timeout()
		"ko":
			phase_t += delta
			if phase_t > 1.8:
				_finish_round()
		"endwait":
			phase_t += delta
			if phase_t > 1.4:
				match_over.emit(GameState.last_winner)


func _on_ko(f: Fighter) -> void:
	if phase != "fight":
		return
	phase = "ko"
	phase_t = 0.0
	p1.lock_out()
	p2.lock_out()
	var winner := 1 if f == p1 else 0
	GameState.last_winner = winner
	GameState.last_was_timeout = false
	if winner == 0:
		GameState.p1_rounds += 1
		p1.celebrate(true)
		p2.celebrate(false)
	else:
		GameState.p2_rounds += 1
		p2.celebrate(true)
		p1.celebrate(false)
	_set_banner("RITE COMPLETE")
	AudioDirector.play("ko")
	cam.shake(1.4)
	hud.set_rounds(GameState.p1_rounds, GameState.p2_rounds)


func _timeout() -> void:
	phase = "ko"
	phase_t = 0.0
	p1.lock_out()
	p2.lock_out()
	GameState.last_was_timeout = true
	var winner := 0 if p1.health >= p2.health else 1
	if abs(p1.health - p2.health) < 1.0:
		winner = 0 if p1.health > p2.health else 1
	GameState.last_winner = winner
	if winner == 0:
		GameState.p1_rounds += 1
		p1.celebrate(true)
		p2.celebrate(false)
	else:
		GameState.p2_rounds += 1
		p2.celebrate(true)
		p1.celebrate(false)
	_set_banner("TIME")
	hud.set_rounds(GameState.p1_rounds, GameState.p2_rounds)


func _finish_round() -> void:
	if GameState.p1_rounds >= GameState.rounds_to_win or GameState.p2_rounds >= GameState.rounds_to_win:
		phase = "endwait"
		phase_t = 0.0
		_set_banner("MATCH")
		return
	round_index += 1
	_begin_round()


func _on_hit(f: Fighter, attack: Dictionary, crit: bool) -> void:
	var strong: bool = attack.get("kind", "") in ["heavy", "special", "ultimate"] or crit
	fx.spark(f.global_position + Vector2(0, -72), p1.def.accent if f == p2 else p2.def.accent, strong)
	cam.shake(0.42 if strong else 0.14)
	cam.punch(0.034 if strong else 0.018)
	var dealt: int = int(round(float(attack.get("dealt", attack.get("damage", 0)))))
	if dealt > 0:
		fx.popup(f.global_position + Vector2(randf_range(-12, 12), -40), str(dealt), Color(1, 0.92, 0.45) if not crit else Color(1, 0.55, 0.2))
	if crit:
		_set_banner("CRITICAL")
		get_tree().create_timer(0.35).timeout.connect(func(): if phase == "fight": _set_banner(""))


func _pause() -> void:
	if phase != "fight":
		return
	_paused = true
	pause_layer.show_menu()
	get_tree().paused = false
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS


func _resume() -> void:
	_paused = false
	pause_layer.hide()


func _restart_match() -> void:
	GameState.reset_match_score()
	round_index = 1
	_paused = false
	pause_layer.hide()
	_begin_round()


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
	elif text == "KO" or text == "RITE COMPLETE":
		col = Color(0.95, 0.78, 0.28)
	elif text == "TIME":
		col = Color(0.75, 0.82, 1.0)
	elif text == "CRITICAL":
		col = Color(1, 0.55, 0.2)
	_banner.set_pix(text, 6, col)
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
		var bw: int = clampi(text.length() * 14 + 48, 110, 190)
		_banner_bg.texture = PixelUI.round_banner(bw)
		_banner_bg.size = Vector2(bw * 4, 120)
		_banner_bg.position = Vector2(640.0 - _banner_bg.size.x * 0.5, 264)
		_banner_bg.visible = true
		_banner_bg.modulate = Color(1.2, 1.2, 1.15)
		var btw := create_tween()
		btw.tween_property(_banner_bg, "modulate", Color.WHITE, 0.2)
