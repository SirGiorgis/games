extends Node
## Builds every screen in code so the project runs from a single bootstrap scene.

var _host: Control
var _menu: MainMenu
var _select: CharacterSelect
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
	_show_menu()


func _clear_match() -> void:
	if _match:
		_match.queue_free()
		_match = null


func _hide_ui() -> void:
	for c in _host.get_children():
		c.visible = false


func _show_menu() -> void:
	_clear_match()
	_hide_ui()
	if _menu == null:
		_menu = MainMenu.new()
		_host.add_child(_menu)
		_menu.chosen.connect(_on_menu)
	_menu.visible = true
	AudioDirector.play_music("menu")


func _on_menu(id: String) -> void:
	match id:
		"PLAY":
			_start_match()
		"CHARACTER SELECT":
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
	_select.confirmed.connect(_start_match)
	_select.cancelled.connect(_show_menu)


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


func _start_match() -> void:
	_hide_ui()
	_clear_match()
	GameState.reset_match_score()
	_match = MatchDirector.new()
	add_child(_match)
	_match.match_over.connect(_on_match_over)


func _on_match_over(code: int) -> void:
	_clear_match()
	if code == -2:
		_show_menu()
		return
	_hide_ui()
	if _result == null:
		_result = ResultScreen.new()
		_host.add_child(_result)
		_result.rematch.connect(_start_match)
		_result.character_select.connect(_show_select)
		_result.main_menu.connect(_show_menu)
	_result.visible = true
	_result.present()
