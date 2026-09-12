class_name FighterVisual
extends Node2D
## Pixel-art fighter with phased attack playback and motion juice.

const SCALE := PixelFighterBake.SCALE
const FW := PixelFighterBake.W
const FH := PixelFighterBake.H

var def: CharacterDef
var facing: int = 1
var pose: String = "idle"
var attack_u: float = 0.0
var one_shot_u: float = -1.0
var flash: float = 0.0
var impact: float = 0.0
var trail_timer: float = 0.0

var _sprite: Sprite2D
var _frames: Dictionary = {}
var _time := 0.0
var _last_pose := ""
var _hold_pose := false
var _base_scale := Vector2.ONE
var _atk_startup := 0.0
var _atk_active := 0.0
var _atk_duration := 1.0

const ONE_SHOT := ["hit", "air_hit", "launch", "knockdown", "defeat", "land", "getup", "prejump", "block_hit"]
const ATTACK_POSES := ["light", "clight", "jlight", "heavy", "cheavy", "jheavy", "special", "ultimate", "grab", "jump"]
const TRAIL_POSES := ["run", "backdash", "special", "ultimate"]


func build(d: CharacterDef) -> void:
	def = d
	_frames = PixelFighterBake.bake(d)
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = false
	_sprite.texture = _tex("idle", 0)
	var tw: int = _sprite.texture.get_width()
	var th: int = _sprite.texture.get_height()
	var sc: int = PixelFighterBake.MODEL_SCALE if tw >= 120 else PixelFighterBake.SCALE
	_base_scale = Vector2(sc, sc)
	_sprite.position = Vector2(-tw * sc / 2, -th * sc)
	_sprite.scale = _base_scale
	add_child(_sprite)
	var sh := Sprite2D.new()
	var simg := Pix.image(14, 5, Color(0, 0, 0, 0))
	Pix.dither_fill(simg, 0, 1, 14, 3, Color(0, 0, 0, 0.4), Color(0, 0, 0, 0.1))
	sh.texture = Pix.tex(simg)
	sh.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sh.centered = true
	sh.position = Vector2(0, 4)
	sh.scale = Vector2(sc, sc)
	sh.z_index = -2
	add_child(sh)


func set_pose_name(p: String) -> void:
	if pose != p:
		_last_pose = pose
		pose = p
		_hold_pose = false
		if p in ONE_SHOT:
			one_shot_u = 0.0


func pulse_hit() -> void:
	flash = 1.0
	impact = 1.0


func punch_impact(amount: float = 1.0) -> void:
	impact = max(impact, amount)


func set_attack_timing(startup: float, active: float, duration: float) -> void:
	_atk_startup = startup
	_atk_active = active
	_atk_duration = maxf(duration, 0.01)


func _process(delta: float) -> void:
	_time += delta
	flash = max(0.0, flash - delta * 9.0)
	impact = max(0.0, impact - delta * 5.5)
	if _sprite == null:
		return

	if pose in ONE_SHOT and one_shot_u >= 0.0:
		var rate: float = 1.0 / maxf(_one_shot_duration(), 0.04)
		one_shot_u = minf(one_shot_u + delta * rate, 1.0)
		if one_shot_u >= 0.98:
			_hold_pose = true

	_sprite.texture = _current_tex()
	_sprite.flip_h = facing < 0

	var squash: float = 1.0
	var stretch: float = 1.0
	if impact > 0.05:
		squash = 1.0 + impact * 0.14
		stretch = 1.0 - impact * 0.08
	elif pose == "land":
		var lu: float = clampf(one_shot_u, 0.0, 1.0)
		squash = 1.0 + (1.0 - lu) * 0.18
		stretch = 1.0 - (1.0 - lu) * 0.1
	elif pose in ["light", "clight", "jlight"] and attack_u > 0.22 and attack_u < 0.58:
		squash = 1.05
		stretch = 0.96
	elif pose in ["heavy", "cheavy", "jheavy", "ultimate"] and attack_u > 0.28 and attack_u < 0.52:
		squash = 1.1
		stretch = 0.92

	_sprite.scale = Vector2(_base_scale.x * (1.0 + impact * 0.06), _base_scale.y * stretch * squash)
	_sprite.position.y = _base_y() + _pose_bob() + impact * 6.0
	_sprite.position.x = _base_x() + _pose_shift()
	_sprite.rotation = _pose_tilt() * facing
	_sprite.modulate = Color.WHITE.lerp(Color(1.7, 1.65, 1.55), flash)

	if pose in TRAIL_POSES and trail_timer <= 0.0:
		trail_timer = 0.10 if pose == "backdash" else 0.14
		_ghost()
	trail_timer = max(0.0, trail_timer - delta)


func _base_x() -> float:
	if _sprite.texture == null:
		return 0.0
	var tw: int = _sprite.texture.get_width()
	var sc: float = absf(_sprite.scale.x)
	return -tw * sc / 2


func _base_y() -> float:
	if _sprite.texture == null:
		return 0.0
	var th: int = _sprite.texture.get_height()
	var sc: float = absf(_sprite.scale.y)
	return -th * sc


func _pose_bob() -> float:
	match pose:
		"idle":
			return sin(_time * 2.4) * 1.5
		"walk":
			return abs(sin(_time * 10.0)) * 2.0
		"run", "backdash":
			return abs(sin(_time * 14.0)) * 3.0
		"victory":
			return sin(_time * 5.0) * 2.5
	return 0.0


func _pose_shift() -> float:
	match pose:
		"backdash":
			return -facing * 3.0 * sin(_time * 18.0)
		"light", "clight", "jlight", "heavy", "cheavy", "jheavy":
			if attack_u > 0.2 and attack_u < 0.65:
				return facing * smoothstep(0.2, 0.5, attack_u) * 8.0
		"special", "ultimate":
			return facing * attack_u * 6.0
	return 0.0


func _pose_tilt() -> float:
	match pose:
		"hit", "block_hit":
			return deg_to_rad(-8.0 * impact)
		"launch", "air_hit":
			return deg_to_rad(sin(_time * 12.0) * 6.0)
		"run":
			return deg_to_rad(4.0)
		"backdash":
			return deg_to_rad(-6.0)
	return 0.0


func _one_shot_duration() -> float:
	match pose:
		"prejump": return 0.05
		"land": return 0.12
		"getup": return 0.18
		"hit", "block_hit": return 0.22
		"air_hit": return 0.18
		"launch": return 0.24
		"knockdown": return 0.45
		"defeat": return 0.55
	return 0.2


func _current_tex() -> Texture2D:
	var key := pose
	if not _frames.has(key):
		key = "idle"
	var arr: Array = _frames[key]
	if arr.is_empty():
		return _tex("idle", 0)

	if pose in ATTACK_POSES:
		return arr[_attack_index(arr, attack_u)]

	if pose in ONE_SHOT:
		var u: float = one_shot_u if one_shot_u >= 0.0 else attack_u
		var idx: int = clampi(int(u * float(arr.size() - 1)), 0, arr.size() - 1)
		if _hold_pose:
			idx = arr.size() - 1
		return arr[idx]

	var spd: float = _loop_fps()
	var idx2: int = int(_time * spd) % arr.size()
	return arr[idx2]


func _loop_fps() -> float:
	match pose:
		"run": return 16.0
		"walk": return 12.0
		"backdash": return 18.0
		"victory": return 9.0
		"block": return 8.0
		"crouch": return 6.0
		"idle": return 7.0
	return 8.0


func _attack_index(arr: Array, u: float) -> int:
	var n: int = arr.size()
	if n <= 1:
		return 0
	var su: float = _atk_startup / _atk_duration
	var au: float = _atk_active / _atk_duration
	var eu: float = su + au
	# Hold the crisp strike frame while hitboxes are active
	if au > 0.01 and u >= su and u <= eu and pose in ["light", "clight", "jlight", "heavy", "cheavy", "jheavy", "special", "ultimate", "grab"]:
		var strike_u: float = su + au * 0.42
		return clampi(int(strike_u * float(n - 1)), 0, n - 1)
	var mapped: float = u
	match pose:
		"light", "clight", "jlight":
			mapped = _phase_map(u, 0.20, 0.30, 0.50)
		"heavy", "cheavy", "jheavy":
			mapped = _phase_map(u, 0.30, 0.28, 0.42)
		"special":
			mapped = _phase_map(u, 0.14, 0.36, 0.50)
		"ultimate":
			mapped = _phase_map(u, 0.20, 0.32, 0.48)
		"grab":
			mapped = _phase_map(u, 0.18, 0.38, 0.44)
		"jump":
			mapped = clampf(u, 0.0, 1.0)
	return clampi(int(mapped * float(n - 1)), 0, n - 1)


func _phase_map(u: float, wind: float, strike: float, recover: float) -> float:
	var total: float = wind + strike + recover
	wind /= total
	strike /= total
	recover /= total
	if u < wind:
		return (u / maxf(wind, 0.001)) * 0.34
	if u < wind + strike:
		var t: float = (u - wind) / maxf(strike, 0.001)
		return lerpf(0.34, 0.72, smoothstep(0.0, 1.0, t))
	var r: float = (u - wind - strike) / maxf(recover, 0.001)
	return lerpf(0.72, 1.0, smoothstep(0.0, 1.0, r))


func _tex(key: String, idx: int) -> Texture2D:
	var arr: Array = _frames.get(key, [])
	if arr.is_empty():
		return ImageTexture.new()
	return arr[clampi(idx, 0, arr.size() - 1)]


func _ghost() -> void:
	if def == null or _sprite.texture == null:
		return
	var g := Sprite2D.new()
	g.texture = _sprite.texture
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g.centered = false
	g.global_position = _sprite.global_position
	g.scale = _sprite.scale
	g.flip_h = _sprite.flip_h
	g.rotation = _sprite.rotation
	var alpha: float = 0.42 if pose == "backdash" else 0.32
	g.modulate = Color(def.accent, alpha)
	g.z_index = -1
	var p := get_parent()
	if p:
		p.add_child(g)
		var tw := g.create_tween()
		tw.tween_property(g, "modulate:a", 0.0, 0.14 if pose == "backdash" else 0.18)
		tw.parallel().tween_property(g, "global_position:x", g.global_position.x - facing * 12.0, 0.14)
		tw.tween_callback(g.queue_free)
