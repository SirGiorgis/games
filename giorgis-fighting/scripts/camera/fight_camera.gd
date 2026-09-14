class_name FightCamera
extends Camera2D

var p1: Fighter
var p2: Fighter
var _shake := 0.0
var _look_x := 640.0
var _punch := 0.0
var _t := 0.0
var _ko := 0.0
var _nudge := Vector2.ZERO
var _focus_x := 640.0
var _focus_w := 0.0


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


func ko_zoom() -> void:
	_ko = 1.0
	_punch = max(_punch, 0.12)
	_shake = max(_shake, 1.35 * GameState.shake_strength)


func hit_nudge(dir: Vector2, amount: float) -> void:
	if dir.length_squared() < 0.01:
		dir = Vector2.RIGHT
	_nudge += dir.normalized() * amount * 22.0 * GameState.shake_strength
	_nudge.x = clampf(_nudge.x, -28.0, 28.0)
	_nudge.y = clampf(_nudge.y, -16.0, 16.0)


func focus_on(f: Fighter, dur: float = 0.42) -> void:
	if f == null:
		return
	_focus_x = f.global_position.x
	_focus_w = maxf(_focus_w, dur)
	_punch = max(_punch, 0.07)


func _process(delta: float) -> void:
	if p1 == null or p2 == null:
		return
	_t += delta
	var mid: float = (p1.global_position.x + p2.global_position.x) * 0.5
	var lead: float = (p1.velocity.x + p2.velocity.x) * 0.04
	var target: float = lerpf(640.0, clampf(mid + lead, 520.0, 760.0), 0.38)
	_focus_w = max(0.0, _focus_w - delta)
	if _focus_w > 0.0:
		target = lerpf(target, clampf(_focus_x, 500.0, 780.0), clampf(_focus_w * 3.2, 0.0, 1.0))
	_look_x = lerpf(_look_x, target, 1.0 - exp(-delta * 6.8))
	_shake = max(0.0, _shake - delta * 7.6)
	_punch = max(0.0, _punch - delta * 4.8)
	_ko = max(0.0, _ko - delta * 0.48)
	_nudge = _nudge.lerp(Vector2.ZERO, 1.0 - exp(-delta * 9.5))
	var mag: float = _shake * _shake
	var falloff: float = exp(-_shake * 1.25)
	offset = Vector2(cos(_t * 41.0), sin(_t * 53.0)) * mag * 11.0 * falloff + _nudge
	global_position = Vector2(_look_x, 360.0)
	var z: float = 1.0 + _punch + _ko * 0.16
	zoom = Vector2(z, z)
