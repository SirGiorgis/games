extends Node
## Builds every screen in code so the project runs from a single bootstrap scene.

const SplashScr := preload("res://scripts/ui/splash_screen.gd")
const StageScr := preload("res://scripts/ui/stage_select.gd")

var _host: Control
var _splash: Control
var _menu: MainMenu
var _select: CharacterSelect
var _stage: Control
var _options: OptionsScreen
var _controls: ControlsScreen
var _result: ResultScreen
var _match: MatchDirector


func _ready() -> void:
	var world_env := CanvasModulate.new()
	world_env.color = Color(1, 1, 1)
	add_child(world_env)
	_host = Control.new()
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	var canvas := CanvasLayer.new()
	canvas.layer = 8
	add_child(canvas)
	canvas.add_child(_host)
	_show_splash()


func _clear_match() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if _match:
		_match.queue_free()
		_match = null


func _hide_ui() -> void:
	for c in _host.get_children():
		c.visible = false


func _show_splash() -> void:
	_clear_match()
	_hide_ui()
	GameState.attract = false
	if _splash:
		_splash.queue_free()
	_splash = SplashScr.new()
	_host.add_child(_splash)
	_splash.finished.connect(_show_menu)
	_splash.attract.connect(_start_attract)


func _show_menu() -> void:
	_clear_match()
	_hide_ui()
	GameState.attract = false
	GameState.training = false
	GameState.end_arcade()
	if _splash:
		_splash.queue_free()
		_splash = null
	if _menu == null:
		_menu = MainMenu.new()
		_host.add_child(_menu)
		_menu.chosen.connect(_on_menu)
	_menu.visible = true
	AudioDirector.play_music("menu")


func _on_menu(id: String) -> void:
	match id:
		"PLAY":
			GameState.training = false
			GameState.attract = false
			GameState.end_arcade()
			_start_match()
		"ARCADE":
			GameState.training = false
			GameState.attract = false
			GameState.arcade = true
			GameState.p2_is_cpu = true
			_show_select()
		"TRAINING":
			GameState.training = true
			GameState.attract = false
			GameState.end_arcade()
			GameState.p2_is_cpu = true
			_start_match()
		"CHARACTER SELECT":
			GameState.end_arcade()
			_show_select()
		"OPTIONS":
			_show_options()
		"CONTROLS":
			_show_controls()
		"QUIT":
			get_tree().quit()


func _show_select() -> void:
	_hide_ui()
	if _select:
		_select.queue_free()
	_select = CharacterSelect.new()
	_host.add_child(_select)
	_select.confirmed.connect(_show_stage)
	_select.cancelled.connect(_show_menu)


func _show_stage() -> void:
	_hide_ui()
	if _stage:
		_stage.queue_free()
	_stage = StageScr.new()
	_host.add_child(_stage)
	_stage.confirmed.connect(_on_stage_picked)
	_stage.cancelled.connect(_show_select)


func _on_stage_picked() -> void:
	GameState.training = false
	GameState.attract = false
	if GameState.arcade:
		GameState.begin_arcade(GameState.p1_character_id)
	else:
		GameState.rounds_to_win = 2
	_start_match()


func _show_options() -> void:
	_hide_ui()
	if _options == null:
		_options = OptionsScreen.new()
		_host.add_child(_options)
		_options.closed.connect(_show_menu)
	_options.visible = true
	_options._refresh()


func _show_controls() -> void:
	_hide_ui()
	if _controls == null:
		_controls = ControlsScreen.new()
		_host.add_child(_controls)
		_controls.closed.connect(_show_menu)
	_controls.visible = true


func _start_attract() -> void:
	GameState.attract = true
	GameState.training = false
	GameState.p2_is_cpu = true
	GameState.p1_character_id = "chris_xrisakis"
	GameState.p2_character_id = "hoodrich_stacks"
	_start_match()


func _start_match() -> void:
	_hide_ui()
	_clear_match()
	GameState.reset_match_score()
	_match = MatchDirector.new()
	add_child(_match)
	_match.match_over.connect(_on_match_over)


func _on_match_over(code: int) -> void:
	var was_attract: bool = GameState.attract
	GameState.attract = false
	_clear_match()
	if was_attract:
		_show_splash()
		return
	if code == -2:
		GameState.training = false
		GameState.end_arcade()
		_show_menu()
		return
	if GameState.training:
		_show_menu()
		return
	if GameState.arcade and GameState.p1_rounds >= GameState.rounds_to_win:
		if GameState.next_arcade_bout():
			_start_match()
			return
	_hide_ui()
	if _result == null:
		_result = ResultScreen.new()
		_host.add_child(_result)
		_result.rematch.connect(_on_rematch)
		_result.character_select.connect(_show_select)
		_result.main_menu.connect(_show_menu)
	_result.visible = true
	_result.present()


func _on_rematch() -> void:
	if GameState.arcade:
		var last_bout: bool = GameState.arcade_index >= GameState.arcade_queue.size()
		if last_bout and GameState.last_winner == 0:
			GameState.begin_arcade(GameState.p1_character_id)
	_start_match()
