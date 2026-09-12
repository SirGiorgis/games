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
var recoil: float = 0.0
var trail_timer: float = 0.0
var move_speed: float = 0.0
var frozen: bool = false
var _land_puff := false
var _stride := 0.0
var _flip_squash := 0.0
var _last_facing: int = 1

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
	var sc: int = PixelFighterBake.SCALE
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
		if p == "land":
			_land_puff = false


func pulse_hit() -> void:
	flash = 1.0
	impact = 1.0
	recoil = 1.0


func punch_impact(amount: float = 1.0) -> void:
	impact = max(impact, amount)


func set_attack_timing(startup: float, active: float, duration: float) -> void:
	_atk_startup = startup
	_atk_active = active
	_atk_duration = maxf(duration, 0.01)


func idle_tex() -> Texture2D:
	return _tex("idle", 0)


func _process(delta: float) -> void:
	if _sprite == null:
		return
	if facing != _last_facing:
		_flip_squash = 1.0
		_last_facing = facing
	if not frozen:
		_time += delta
		flash = max(0.0, flash - delta * 11.0)
		impact = max(0.0, impact - delta * 7.2)
		recoil = max(0.0, recoil - delta * 9.0)
		_flip_squash = max(0.0, _flip_squash - delta * 12.0)
		if pose in ONE_SHOT and one_shot_u >= 0.0:
			var rate: float = 1.0 / maxf(_one_shot_duration(), 0.04)
			one_shot_u = minf(one_shot_u + delta * rate, 1.0)
			if one_shot_u >= 0.98:
				_hold_pose = true
		if pose in ["walk", "run"]:
			_stride += maxf(absf(move_speed), 80.0) * delta * 0.082
		if pose in TRAIL_POSES and trail_timer <= 0.0:
			trail_timer = 0.08 if pose == "backdash" else 0.11
			_ghost()
		elif pose in ["light", "clight", "jlight", "heavy", "cheavy", "jheavy"] and attack_u > 0.22 and attack_u < 0.58 and trail_timer <= 0.0:
			trail_timer = 0.06
			_ghost()
		trail_timer = max(0.0, trail_timer - delta)
		if pose == "land" and not _land_puff:
			_land_puff = true
			_puff()

	_sprite.texture = _current_tex()
	_sprite.flip_h = facing < 0
	_apply_juice()


func _apply_juice() -> void:
	var squash: float = 1.0
	var stretch: float = 1.0
	if impact > 0.05:
		squash = 1.0 + impact * 0.16
		stretch = 1.0 - impact * 0.09
	elif pose == "land":
		var lu: float = clampf(one_shot_u, 0.0, 1.0)
		squash = 1.0 + (1.0 - lu) * 0.20
		stretch = 1.0 - (1.0 - lu) * 0.12
	elif pose == "prejump":
		squash = 1.12
		stretch = 0.90
	elif pose == "jump":
		if attack_u < 0.38:
			squash = 0.92
			stretch = 1.10
		else:
			squash = 1.06
			stretch = 0.94
	elif pose in ["light", "clight", "jlight"] and attack_u > 0.20 and attack_u < 0.55:
		squash = 1.06
		stretch = 0.95
	elif pose in ["heavy", "cheavy", "jheavy", "ultimate"] and attack_u > 0.26 and attack_u < 0.52:
		squash = 1.12
		stretch = 0.90

	var fx_w: float = 1.0 - _flip_squash * 0.18
	_sprite.scale = Vector2(_base_scale.x * (1.0 + impact * 0.05) * fx_w, _base_scale.y * stretch * squash)
	_sprite.position.y = _base_y() + _pose_bob() + impact * 5.0
	_sprite.position.x = _base_x() + _pose_shift() - float(facing) * recoil * 11.0
	_sprite.rotation = _pose_tilt() * facing
	_sprite.modulate = Color.WHITE.lerp(Color(1.75, 1.68, 1.52), flash)


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
			return sin(_time * 2.15) * 2.2
		"walk":
			return abs(sin(_stride * 1.15)) * 2.4
		"run", "backdash":
			return abs(sin(_stride * 1.35)) * 3.4
		"victory":
			return sin(_time * 5.0) * 2.5
	return 0.0


func _pose_shift() -> float:
	match pose:
		"backdash":
			return -facing * 3.0 * sin(_time * 18.0)
		"light", "clight", "jlight", "heavy", "cheavy", "jheavy":
			if attack_u > 0.18 and attack_u < 0.62:
				return facing * smoothstep(0.18, 0.48, attack_u) * 10.0
		"special", "ultimate":
			return facing * attack_u * 7.0
	return 0.0


func _pose_tilt() -> float:
	match pose:
		"hit", "block_hit":
			return deg_to_rad(-10.0 * maxf(impact, recoil))
		"launch", "air_hit":
			return deg_to_rad(sin(_time * 12.0) * 6.0)
		"run":
			return deg_to_rad(5.0)
		"backdash":
			return deg_to_rad(-7.0)
		"jump":
			return deg_to_rad(lerpf(-3.0, 4.0, clampf(attack_u, 0.0, 1.0)))
	return 0.0


func _one_shot_duration() -> float:
	match pose:
		"prejump": return 0.04
		"land": return 0.10
		"getup": return 0.14
		"hit", "block_hit": return 0.20
		"air_hit": return 0.16
		"launch": return 0.22
		"knockdown": return 0.42
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

	if pose in ["walk", "run"]:
		var idx_s: int = int(floor(_stride)) % arr.size()
		return arr[idx_s]

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
		"idle": return 8.0
	return 8.0


func _attack_index(arr: Array, u: float) -> int:
	var n: int = arr.size()
	if n <= 1:
		return 0
	var su: float = _atk_startup / _atk_duration
	var au: float = _atk_active / _atk_duration
	var eu: float = su + au
	if au > 0.01 and u >= su and u <= eu and pose in ["light", "clight", "jlight", "heavy", "cheavy", "jheavy", "special", "ultimate", "grab"]:
		var strike_u: float = su + au * 0.42
		return clampi(int(strike_u * float(n - 1)), 0, n - 1)
	var mapped: float = u
	match pose:
		"light", "clight", "jlight":
			mapped = _phase_map(u, 0.18, 0.32, 0.50)
		"heavy", "cheavy", "jheavy":
			mapped = _phase_map(u, 0.28, 0.30, 0.42)
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
	var alpha: float = 0.46 if pose == "backdash" else 0.30
	g.modulate = Color(def.accent, alpha)
	g.z_index = -1
	var p := get_parent()
	if p:
		p.add_child(g)
		var tw := g.create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(g, "modulate:a", 0.0, 0.12 if pose == "backdash" else 0.16)
		tw.parallel().tween_property(g, "global_position:x", g.global_position.x - facing * 14.0, 0.14)
		tw.tween_callback(g.queue_free)


func _puff() -> void:
	var p := get_parent()
	if p == null:
		return
	for i in 6:
		var img := Pix.image(4, 3, Color(0, 0, 0, 0))
		Pix.disc(img, 1, 1, 1, Color(0.62, 0.52, 0.28, 0.7))
		var s := Sprite2D.new()
		s.texture = Pix.tex(img)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(3, 3)
		s.centered = true
		s.position = Vector2((i - 2.5) * 9, 2)
		s.z_index = -1
		p.add_child(s)
		var tw := s.create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(s, "position", s.position + Vector2((i - 2.5) * 16, -10), 0.20)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.20)
		tw.tween_callback(s.queue_free)
