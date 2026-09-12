class_name FightCamera
extends Camera2D

var p1: Fighter
var p2: Fighter
var _shake := 0.0
var _look_x := 640.0
var _punch := 0.0
var _t := 0.0


func bind(a: Fighter, b: Fighter) -> void:
	p1 = a
	p2 = b
	enabled = true
	position_smoothing_enabled = false
	ignore_rotation = true
	limit_left = 0
	limit_right = 1280
	limit_top = -40
	limit_bottom = 720
	_look_x = 640.0
	make_current()


func shake(amount: float) -> void:
	_shake = max(_shake, amount * GameState.shake_strength)


func punch(amount: float = 0.028) -> void:
	_punch = max(_punch, amount)


func _process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	_t += delta
	var mid: float = (p1.global_position.x + p2.global_position.x) * 0.5
	var lead: float = (p1.velocity.x + p2.velocity.x) * 0.04
	var target: float = lerpf(640.0, clampf(mid + lead, 540.0, 740.0), 0.32)
	_look_x = lerpf(_look_x, target, 1.0 - exp(-delta * 6.4))
	_shake = max(0.0, _shake - delta * 8.4)
	_punch = max(0.0, _punch - delta * 5.6)
	var mag: float = _shake * _shake
	var falloff: float = exp(-_shake * 1.4)
	offset = Vector2(cos(_t * 41.0), sin(_t * 53.0)) * mag * 8.0 * falloff
	global_position = Vector2(_look_x, 360.0)
	var z: float = 1.0 + _punch
	zoom = Vector2(z, z)
