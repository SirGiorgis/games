class_name FighterVisual
extends Node2D

var def: CharacterDef
var facing: int = 1
var pose: String = "idle"
var attack_u: float = 0.0
var crouch_blend: float = 0.0
var flash: float = 0.0
var trail_timer: float = 0.0

var _hip: Node2D
var _torso: Polygon2D
var _head: Polygon2D
var _hair: Polygon2D
var _arm_l: Polygon2D
var _arm_r: Polygon2D
var _leg_l: Polygon2D
var _leg_r: Polygon2D
var _cloak: Polygon2D
var _aura: CPUParticles2D
var _shadow: Polygon2D
var _time := 0.0
var _parts: Array[Polygon2D] = []


func build(d: CharacterDef) -> void:
	def = d
	_shadow = _poly([Vector2(-28, 6), Vector2(28, 6), Vector2(18, 14), Vector2(-18, 14)], Color(0, 0, 0, 0.45))
	_shadow.z_index = -2
	add_child(_shadow)

	_hip = Node2D.new()
	_hip.position = Vector2(0, -12)
	add_child(_hip)

	var racing: bool = def.style == "racing"
	_cloak = _limb(Vector2(18, 10), Vector2(28 if racing else 34, 70), def.outfit.darkened(0.18), -0.25 if racing else -0.4)
	_hip.add_child(_cloak)
	_leg_l = _limb(Vector2(8 if racing else 11, 12), Vector2(52, 16), Color(0.1, 0.11, 0.13) if racing else def.outfit, 0.18)
	_leg_r = _limb(Vector2(8 if racing else 11, 12), Vector2(52, 16), Color(0.13, 0.14, 0.17) if racing else def.outfit.lightened(0.08), -0.18)
	_hip.add_child(_leg_l)
	_hip.add_child(_leg_r)
	_torso = _limb(Vector2((18 if racing else 26) * def.width_scale, 18), Vector2(48, 22), def.outfit, 0.0)
	_torso.position = Vector2(0, -40)
	_hip.add_child(_torso)
	var trim := _limb(Vector2((16 if racing else 22) * def.width_scale, 8), Vector2(10, 10), def.trim, 0.0)
	trim.position = Vector2(0, -8)
	_torso.add_child(trim)
	if racing:
		var stripe := _poly([Vector2(-4, -6), Vector2(4, -6), Vector2(3, 44), Vector2(-3, 44)], def.accent)
		_torso.add_child(stripe)
		var stripe2 := _poly([Vector2(6, -4), Vector2(10, -4), Vector2(9, 44), Vector2(5, 44)], def.trim)
		_torso.add_child(stripe2)
		var collar := _poly([Vector2(-16, -4), Vector2(16, -4), Vector2(12, 8), Vector2(-12, 8)], def.accent.darkened(0.2))
		collar.position = Vector2(0, -2)
		_torso.add_child(collar)
	var sleeve := def.outfit if racing else def.skin
	_arm_l = _limb(Vector2(7 if racing else 9, 9), Vector2(40, 12), sleeve, 0.5)
	_arm_r = _limb(Vector2(7 if racing else 9, 9), Vector2(40, 12), sleeve.lightened(0.06), -0.35)
	_arm_l.position = Vector2(-8 if racing else -10, -16)
	_arm_r.position = Vector2(8 if racing else 10, -16)
	_torso.add_child(_arm_l)
	_torso.add_child(_arm_r)
	_head = _circ(15 if racing else 16, def.skin)
	_head.position = Vector2(0, -36)
	_torso.add_child(_head)
	_hair = _circ(16, def.hair)
	_hair.position = Vector2(-2, -7)
	_head.add_child(_hair)
	if racing:
		var curl_a := _circ(8, def.hair)
		curl_a.position = Vector2(-10, -4)
		_head.add_child(curl_a)
		var curl_b := _circ(7, def.hair.lightened(0.08))
		curl_b.position = Vector2(8, -6)
		_head.add_child(curl_b)
	var eye_l := _circ(3.2, def.eyes)
	var eye_r := _circ(3.2, def.eyes)
	eye_l.position = Vector2(5, -2)
	eye_r.position = Vector2(11, -2)
	_head.add_child(eye_l)
	_head.add_child(eye_r)

	_aura = CPUParticles2D.new()
	_aura.emitting = true
	_aura.amount = 18
	_aura.lifetime = 0.7
	_aura.direction = Vector2(0, -1)
	_aura.spread = 50
	_aura.gravity = Vector2(0, -40)
	_aura.initial_velocity_min = 20
	_aura.initial_velocity_max = 50
	_aura.scale_amount_min = 1.5
	_aura.scale_amount_max = 3.5
	_aura.color = Color(def.accent, 0.35)
	_aura.position = Vector2(0, -70)
	_aura.z_index = -1
	add_child(_aura)

	scale = Vector2(def.width_scale, def.height_scale)


func _poly(pts: Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(pts)
	p.color = color
	_parts.append(p)
	return p


func _limb(radius: Vector2, length_size: Vector2, color: Color, rot: float) -> Polygon2D:
	var w := radius.x
	var h := length_size.x
	var p := _poly([
		Vector2(-w, 0), Vector2(w, 0), Vector2(w * 0.7, h), Vector2(-w * 0.7, h)
	], color)
	p.rotation = rot
	return p


func _circ(r: float, color: Color) -> Polygon2D:
	var pts: Array = []
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return _poly(pts, color)


func set_pose_name(p: String) -> void:
	pose = p


func pulse_hit() -> void:
	flash = 1.0


func _process(delta: float) -> void:
	_time += delta
	flash = max(0.0, flash - delta * 6.0)
	var breath := sin(_time * 3.2) * 0.03
	var walk := sin(_time * 9.0)
	match pose:
		"walk", "run":
			_leg_l.rotation = walk * 0.55
			_leg_r.rotation = -walk * 0.55
			_arm_l.rotation = -walk * 0.7
			_arm_r.rotation = walk * 0.7
			_torso.rotation = walk * 0.05
			_hip.position.y = -12 + abs(walk) * 3.0
		"jump":
			_leg_l.rotation = -0.45
			_leg_r.rotation = 0.35
			_arm_l.rotation = -1.1
			_arm_r.rotation = 0.9
			_torso.rotation = -0.12
		"crouch":
			_hip.position.y = 18
			_leg_l.rotation = 0.9
			_leg_r.rotation = -0.55
			_arm_l.rotation = 0.4
			_torso.rotation = 0.12
			_cloak.rotation = 0.2
		"block":
			_arm_l.rotation = -1.3
			_arm_r.rotation = -1.05
			_torso.rotation = 0.18
			_hip.position.y = -8
		"light":
			_punch(0.9)
		"heavy":
			_punch(1.35)
		"special":
			_spin_strike()
		"ultimate":
			_spin_strike()
			_aura.modulate = Color(1.4, 1.4, 1.4)
		"hit":
			_torso.rotation = 0.35
			_arm_l.rotation = 0.8
			_head.rotation = 0.25
		"knockdown":
			rotation = facing * 1.35
			_hip.position.y = 20
		"victory":
			_arm_r.rotation = -2.4 + sin(_time * 6.0) * 0.1
			_torso.rotation = -0.15
			_hip.position.y = -16 + sin(_time * 4.0) * 2.0
		"defeat":
			rotation = facing * 1.2
		_:
			rotation = 0
			_hip.position.y = -12 + breath * 10.0
			_leg_l.rotation = 0.12 + breath
			_leg_r.rotation = -0.12 - breath
			_arm_l.rotation = 0.45 + breath * 2.0
			_arm_r.rotation = -0.35 - breath * 2.0
			_torso.rotation = breath
			_head.rotation = -breath
			_cloak.rotation = -0.35 + breath
			_aura.modulate = Color.WHITE

	if pose != "knockdown" and pose != "defeat":
		rotation = lerp_angle(rotation, 0.0, delta * 8.0)

	scale.x = abs(scale.x) * facing
	var flash_c := Color.WHITE.lerp(Color(2.0, 2.0, 2.0), flash)
	modulate = flash_c
	if pose == "walk" or pose == "run" or pose == "special" or pose == "ultimate":
		trail_timer -= delta
		if trail_timer <= 0.0:
			trail_timer = 0.05
			_spawn_afterimage()


func _punch(power: float) -> void:
	var u := attack_u
	var swing := 0.0
	if u < 0.35:
		swing = lerpf(0.4, -0.2, u / 0.35)
	else:
		swing = lerpf(-0.2, -2.2 * power, clamp((u - 0.35) / 0.3, 0.0, 1.0))
	_arm_r.rotation = swing
	_arm_l.rotation = 0.6
	_torso.rotation = -0.25 * power * max(u - 0.3, 0.0)
	_hip.position.y = -12
	rotation = 0


func _spin_strike() -> void:
	var u := attack_u
	_arm_r.rotation = -2.6 * u
	_arm_l.rotation = 2.2 * u
	_torso.rotation = sin(u * TAU) * 0.4
	_leg_l.rotation = sin(u * TAU * 2.0) * 0.5
	_aura.modulate = Color(1.6, 1.6, 1.6)


func _spawn_afterimage() -> void:
	var ghost := Polygon2D.new()
	ghost.polygon = PackedVector2Array([Vector2(-10, -110), Vector2(10, -110), Vector2(16, 8), Vector2(-16, 8)])
	ghost.color = Color(def.accent, 0.22)
	ghost.global_position = global_position
	ghost.scale = scale
	ghost.z_index = -1
	var parent := get_parent()
	if parent:
		parent.add_child(ghost)
		var tw := ghost.create_tween()
		tw.tween_property(ghost, "modulate:a", 0.0, 0.18)
		tw.tween_callback(ghost.queue_free)
