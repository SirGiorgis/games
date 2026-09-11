class_name ResultScreen
extends Control

signal rematch
signal character_select
signal main_menu

var _index := 0
var _labels: Array[Label] = []
const ITEMS := ["REMATCH", "CHARACTER SELECT", "MAIN MENU"]
var _title: Label
var _sub: Label


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.04, 0.94)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	_title = Label.new()
	_title.position = Vector2(0, 120)
	_title.size = Vector2(1280, 90)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(_title, 64, Color(0.95, 0.8, 0.3))
	add_child(_title)
	_sub = Label.new()
	_sub.position = Vector2(0, 210)
	_sub.size = Vector2(1280, 50)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(_sub, 22, Color(0.85, 0.8, 0.75))
	add_child(_sub)
	for i in ITEMS.size():
		var l := Label.new()
		l.position = Vector2(0, 320 + i * 52)
		l.size = Vector2(1280, 44)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIKit.style_label(l, 30)
		add_child(l)
		_labels.append(l)
	_refresh()


func present() -> void:
	_index = 0
	var p1_win := GameState.p1_rounds >= GameState.rounds_to_win
	if p1_win:
		_title.text = "VICTORY"
		_title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.32))
		AudioDirector.play("victory")
	else:
		_title.text = "DEFEAT"
		_title.add_theme_color_override("font_color", Color(0.85, 0.2, 0.25))
		AudioDirector.play("defeat")
	var a := CharacterCatalog.get_def(GameState.p1_character_id).name
	var b := CharacterCatalog.get_def(GameState.p2_character_id).name
	_sub.text = "%s  %d  —  %d  %s    [%s]" % [a, GameState.p1_rounds, GameState.p2_rounds, b, ArenaWorld.display_name(GameState.arena_id)]
	AudioDirector.play_music("menu")
	_refresh()


func _process(_d: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(ControlMap.MENU.down):
		_index = (_index + 1) % ITEMS.size()
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.up):
		_index = (_index + ITEMS.size() - 1) % ITEMS.size()
		AudioDirector.play("ui")
		_refresh()
	elif Input.is_action_just_pressed(ControlMap.MENU.confirm):
		AudioDirector.play("ui_confirm")
		match _index:
			0:
				rematch.emit()
			1:
				character_select.emit()
			2:
				main_menu.emit()


func _refresh() -> void:
	for i in _labels.size():
		_labels[i].text = UIKit.make_button_label(ITEMS[i], i == _index)
		_labels[i].add_theme_color_override("font_color", Color(1, 0.85, 0.4) if i == _index else Color(0.8, 0.78, 0.76))
