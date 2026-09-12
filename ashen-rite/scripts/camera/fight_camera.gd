class_name FightCamera
extends Camera2D

var p1: Fighter
var p2: Fighter
var _shake := 0.0
var _base_zoom := Vector2.ONE


func bind(a: Fighter, b: Fighter) -> void:
	p1 = a
	p2 = b
	enabled = true
	position_smoothing_enabled = false
	position_smoothing_speed = 6.0
	ignore_rotation = true
	limit_left = 0
	limit_right = 1280
	limit_top = -40
	limit_bottom = 720
	make_current()


func shake(amount: float) -> void:
	_shake = max(_shake, amount * GameState.shake_strength)


func _process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	global_position = Vector2(640, 360)
	_base_zoom = Vector2.ONE
	_shake = max(0.0, _shake - delta * 8.0)
	offset = Vector2(_shake * randf_range(-1, 1), _shake * randf_range(-1, 1)) * 8.0
	zoom = _base_zoom
