class_name Fighter
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal meters_changed(special: float, ultimate: float)
signal defeated(fighter: Fighter)
signal hit_landed(fighter: Fighter, attack: Dictionary, counter: bool)
signal combo_changed(count: int)
signal super_started
signal announced(text: String)
signal clash_happened(pos: Vector2)

enum State { IDLE, WALK, RUN, BACKDASH, PREJUMP, JUMP, LAND, CROUCH, LIGHT, HEAVY, SPECIAL, ULTIMATE, BLOCK, GRAB, HIT, KNOCKDOWN, GETUP, VICTORY, DEFEAT }

const GRAVITY := 2180.0
const APEX_G := 0.46
const MAX_SPECIAL := 100.0
const MAX_ULTIMATE := 100.0
const WALK_BACK := 0.74
const RUN_MUL := 1.92
const ACCEL := 4600.0
const FRICTION := 3200.0
const TURN_MUL := 1.85
const AIR_ACCEL := 2600.0
const PREJUMP := 0.018
const LAND_T := 0.048
const GETUP_T := 0.14
const COYOTE := 0.12
const JBUF := 0.16
const ATK_BUF := 0.24
const CHAIN := 0.26

var fighter_id: int = 0
var def: CharacterDef
var is_cpu: bool = false
var opponent: Fighter
var input_map: Dictionary = {}

var state: State = State.IDLE
var facing: int = 1
var health: float = 1000.0
var max_health: float = 1000.0
var special_meter: float = 0.0
var ultimate_meter: float = 0.0
var hitstun: float = 0.0
var attack_timer: float = 0.0
var attack_duration: float = 0.0
var attack_active_from: float = 0.0
var attack_active_until: float = 0.0
var recovery_lock: bool = false
var on_ground: bool = false
var freeze_frames: float = 0.0
var invuln: float = 0.0
var combo_hits: int = 0
var combo_damage: float = 0.0
var combo_decay: float = 0.0
var current_attack: Dictionary = {}
var round_over: bool = false
var can_act: bool = true
var last_attack_was_hit: bool = false
var chain_window: float = 0.0
var last_chain: Array[String] = []
var air_done: bool = false
var _buf = preload("res://scripts/combat/motion_buffer.gd").new()
var _land_t: float = 0.0
var _dash_t: float = 0.0
var _jump_x: float = 0.0
var _was_air: bool = false
var guarding: bool = false
var crouch_guarding: bool = false
var _atk_buf: String = ""
var _atk_buf_t: float = 0.0
var _jbuf: float = 0.0
var _coyote: float = 0.0
var _guard_age: float = 99.0
var _taunt_t: float = 0.0
var _wall_used: bool = false
var _hit_pass: int = 0
var _fwd_guard: bool = false
var _air_dash_used: bool = false
var guard_meter: float = 0.0
const MAX_GUARD := 100.0
var input_log: Array[String] = []
var last_advantage: float = 0.0
var last_move: String = ""

var visual: FighterVisual
var hurtbox: Area2D
var hitbox: Hitbox
var _ai: FighterAI
var _ground_y := 0.0


func setup(id: int, character: CharacterDef, cpu: bool, start_pos: Vector2) -> void:
	fighter_id = id
	def = character
	is_cpu = cpu
	position = start_pos
	max_health = def.health
	health = max_health
	motion_mode = MOTION_MODE_GROUNDED
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 6.0
	floor_max_angle = 0.8
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON

	var vis_h: float = float(PixelFighterBake.H * PixelFighterBake.SCALE)
	var body := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = vis_h * 0.085 * def.width_scale
	cap.height = vis_h * 0.44 * def.height_scale
	body.shape = cap
	body.position = Vector2(0, -vis_h * 0.26 * def.height_scale)
	add_child(body)

	hurtbox = Area2D.new()
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 0
	hurtbox.monitorable = true
	hurtbox.monitoring = false
	hurtbox.set_meta("fighter_id", fighter_id)
	var hs := CollisionShape2D.new()
	var hrect := RectangleShape2D.new()
	hrect.size = Vector2(vis_h * 0.16 * def.width_scale, vis_h * 0.48 * def.height_scale)
	hs.shape = hrect
	hs.position = Vector2(0, -vis_h * 0.27 * def.height_scale)
	hurtbox.add_child(hs)
	add_child(hurtbox)
	var hdbg := ColorRect.new()
	hdbg.name = "HurtDebug"
	hdbg.color = Color(0.2, 0.85, 0.3, 0.28)
	hdbg.size = hrect.size
	hdbg.position = hs.position - hrect.size * 0.5
	hdbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdbg.visible = false
	hurtbox.add_child(hdbg)

	hitbox = Hitbox.new()
	hitbox.owner_fighter = self
	hitbox.landed.connect(_on_hitbox_landed)
	add_child(hitbox)

	visual = FighterVisual.new()
	add_child(visual)
	visual.build(def)

	input_map = ControlMap.map_for(id)
	if cpu:
		_ai = FighterAI.new()
		_ai.setup(self)
		add_child(_ai)

	health_changed.emit(health, max_health)
	meters_changed.emit(special_meter, ultimate_meter)


func reset_round(start_pos: Vector2) -> void:
	position = start_pos
	velocity = Vector2.ZERO
	health = max_health
	state = State.IDLE
	hitstun = 0.0
	attack_timer = 0.0
	round_over = false
	can_act = false
	invuln = 0.4
	combo_hits = 0
	combo_damage = 0.0
	last_chain.clear()
	hitbox.disarm()
	air_done = false
	_buf.reset()
	_dash_t = 0.0
	_land_t = 0.0
	_atk_buf = ""
	_atk_buf_t = 0.0
	_jbuf = 0.0
	_coyote = 0.12
	_guard_age = 99.0
	_taunt_t = 0.0
	_wall_used = false
	_hit_pass = -1
	_fwd_guard = false
	_air_dash_used = false
	guard_meter = 0.0
	last_advantage = 0.0
	last_move = ""
	rotation = 0
	visual.rotation = 0
	visual.set_pose_name("idle")
	health_changed.emit(health, max_health)


func lock_out() -> void:
	round_over = true
	can_act = false
	hitbox.disarm()


func celebrate(win: bool) -> void:
	lock_out()
	state = State.VICTORY if win else State.DEFEAT
	visual.set_pose_name("victory" if win else "defeat")


func _physics_process(delta: float) -> void:
	_atk_buf_t = max(0.0, _atk_buf_t - delta)
	if _atk_buf_t <= 0.0:
		_atk_buf = ""
	_jbuf = max(0.0, _jbuf - delta)
	if visual:
		visual.frozen = freeze_frames > 0.0
	if freeze_frames > 0.0:
		freeze_frames -= delta
		if not round_over and can_act:
			_queue_inputs(_gather_command())
		_sync_visual()
		return
	invuln = max(0.0, invuln - delta)
	combo_decay = max(0.0, combo_decay - delta)
	chain_window = max(0.0, chain_window - delta)
	if combo_decay <= 0.0 and combo_hits != 0:
		combo_hits = 0
		combo_damage = 0.0
		last_chain.clear()
		combo_changed.emit(0)
	if not guarding:
		guard_meter = maxf(0.0, guard_meter - 32.0 * delta)
	_taunt_t = max(0.0, _taunt_t - delta)
	if on_ground and state != State.HIT:
		_wall_used = false

	on_ground = is_on_floor()
	if on_ground:
		_coyote = COYOTE
	else:
		_coyote = max(0.0, _coyote - delta)
		var g: float = GRAVITY
		if absf(velocity.y) < 150.0:
			g *= APEX_G
		velocity.y += g * delta
	if on_ground and _was_air:
		_on_landed()
	var cmd := _gather_command()
	_face_opponent()
	if not round_over:
		_think(cmd, delta)
	_integrate(delta)
	_sync_visual()
	move_and_slide()
	on_ground = is_on_floor()
	_was_air = not on_ground
	_separate_from_opponent()
	_keep_in_bounds()
	_wall_bounce()
	_debug_boxes()


func _gather_command() -> Dictionary:
	var cmd := {
		"left": false, "right": false, "up": false, "down": false,
		"light": false, "heavy": false, "special": false, "block": false,
		"grab": false, "ultimate": false,
		"fwd": false, "back": false, "run": false, "backdash": false,
		"qcf": false, "qcf2": false, "dp": false,
	}
	if round_over or not can_act:
		return cmd
	if is_cpu and _ai:
		var a: Dictionary = _ai.poll()
		for k in cmd.keys():
			if a.has(k):
				cmd[k] = a[k]
		cmd.fwd = (facing > 0 and cmd.right) or (facing < 0 and cmd.left)
		cmd.back = (facing > 0 and cmd.left) or (facing < 0 and cmd.right)
		return cmd
	for k in ["left", "right", "up", "down", "light", "heavy", "special", "block", "grab", "ultimate"]:
		if input_map.has(k):
			if k in ["light", "heavy", "special", "grab", "ultimate"]:
				cmd[k] = Input.is_action_just_pressed(input_map[k])
			else:
				cmd[k] = Input.is_action_pressed(input_map[k])
	var mot: Dictionary = _buf.push(cmd.left, cmd.right, cmd.up, cmd.down, facing, get_physics_process_delta_time())
	cmd.fwd = mot.fwd
	cmd.back = mot.back
	cmd.run = mot.run
	cmd.backdash = mot.backdash
	cmd.qcf = mot.qcf
	cmd.qcf2 = mot.qcf2
	cmd.dp = mot.dp
	return cmd


func _think(cmd: Dictionary, delta: float) -> void:
	_fwd_guard = bool(cmd.fwd)
	_log_buttons(cmd)
	var want_guard: bool = on_ground and (cmd.back or cmd.block) and not _busy_attack()
	if want_guard and not guarding:
		_guard_age = 0.0
	else:
		_guard_age += delta
	guarding = want_guard
	crouch_guarding = guarding and (cmd.down or state == State.CROUCH)

	if state == State.BLOCK and hitstun > 0.0:
		hitstun -= delta
		_accel_x(0.0, 2400.0, delta)
		_queue_inputs(cmd)
		if _try_burst(cmd):
			return
		if cmd.special and special_meter >= 25.0 and opponent:
			special_meter -= 25.0
			hitstun = 0.02
			opponent.velocity.x = float(facing) * 420.0
			opponent.freeze_frames = max(opponent.freeze_frames, 0.08)
			meters_changed.emit(special_meter, ultimate_meter)
			announced.emit("PUSHBLOCK")
			AudioDirector.play("whoosh", 0.7, 0.7)
			if visual:
				visual.dust()
			state = State.IDLE
			return
		if hitstun <= 0.0 and _flush_buffer():
			return
		return
	if state == State.HIT:
		hitstun -= delta
		if on_ground:
			_accel_x(0.0, 1600.0, delta)
		_queue_inputs(cmd)
		if _try_burst(cmd):
			return
		if not on_ground and health > 0.0 and hitstun <= 0.14:
			if cmd.up or cmd.light or cmd.heavy or _jbuf > 0.0:
				_air_tech()
				return
		if hitstun <= 0.0:
			if _flush_buffer():
				return
			state = State.IDLE if on_ground else State.JUMP
			air_done = not on_ground
		return
	if state == State.KNOCKDOWN:
		hitstun -= delta
		_accel_x(0.0, 1800.0, delta)
		_queue_inputs(cmd)
		if hitstun <= 0.0 and on_ground:
			state = State.GETUP
			_land_t = GETUP_T
			invuln = 0.20
		return
	if state == State.GETUP or state == State.LAND:
		var was_getup: bool = state == State.GETUP
		_land_t -= delta
		_accel_x(0.0, FRICTION, delta)
		_queue_inputs(cmd)
		if was_getup and (cmd.backdash or (cmd.back and not cmd.down and not cmd.fwd)):
			state = State.BACKDASH
			_dash_t = 0.20
			invuln = 0.24
			velocity.x = float(facing) * -440.0
			announced.emit("ROLL")
			AudioDirector.play("dash", 0.9, 0.65)
			if visual:
				visual.dust()
			return
		if state == State.LAND and _jbuf > 0.0 and _land_t <= 0.03:
			_begin_jump(cmd)
			return
		if _land_t <= 0.0:
			if _flush_buffer():
				if was_getup:
					invuln = max(invuln, 0.12)
					announced.emit("REVERSAL")
					AudioDirector.play("tech", 0.85, 0.65)
				return
			if _jbuf > 0.0:
				_begin_jump(cmd)
				return
			state = State.CROUCH if cmd.down else State.IDLE
		return
	if state == State.PREJUMP:
		_land_t -= delta
		_accel_x(_jump_x, ACCEL, delta)
		_queue_inputs(cmd)
		if _land_t <= 0.0:
			_leave_ground()
			if _flush_buffer():
				return
		return
	if state == State.BACKDASH:
		_dash_t -= delta
		_queue_inputs(cmd)
		if _dash_t <= 0.0:
			if _flush_buffer():
				return
			state = State.IDLE
		return
	if _busy_attack():
		attack_timer += delta
		visual.attack_u = clamp(attack_timer / max(attack_duration, 0.01), 0.0, 1.0)
		var hits: int = maxi(int(current_attack.get("hits", 1)), 1)
		var gap: float = float(current_attack.get("hit_gap", 0.08))
		var act: float = maxf(attack_active_until - attack_active_from, 0.02)
		var live := false
		var hit_i := 0
		for i in hits:
			var a0: float = attack_active_from + float(i) * (act + gap)
			var a1: float = a0 + act
			if attack_timer >= a0 and attack_timer <= a1:
				live = true
				hit_i = i
				break
		if live:
			if (not hitbox.active) or _hit_pass != hit_i:
				hitbox.disarm()
				hitbox.arm(current_attack)
				_hit_pass = hit_i
		elif hitbox.active:
			hitbox.disarm()
		_queue_inputs(cmd)
		if attack_timer >= attack_duration:
			hitbox.disarm()
			chain_window = CHAIN
			if _flush_buffer():
				return
			if _jbuf > 0.0 and on_ground:
				_begin_jump(cmd)
				return
			if not on_ground:
				state = State.JUMP
				air_done = true
			else:
				state = State.CROUCH if cmd.down else State.IDLE
		elif last_attack_was_hit and attack_timer > attack_active_until:
			if (cmd.ultimate or cmd.qcf2) and ultimate_meter >= MAX_ULTIMATE:
				_buf.consume_motion()
				announced.emit("SUPER CANCEL")
				_start_attack("ultimate")
				if opponent:
					opponent.freeze_frames = max(opponent.freeze_frames, 0.28)
				freeze_frames = max(freeze_frames, 0.12)
				return
			if _try_dash_cancel(cmd):
				return
			if not _try_jump_cancel(cmd):
				_try_chain(cmd)
		return

	if _taunt_t > 0.0:
		_accel_x(0.0, FRICTION, delta)
		return

	var want_super: bool = cmd.ultimate or (cmd.qcf2 and (cmd.light or cmd.heavy or cmd.special))
	if want_super and ultimate_meter >= MAX_ULTIMATE:
		_buf.consume_motion()
		_start_attack("ultimate")
		if opponent:
			opponent.freeze_frames = max(opponent.freeze_frames, 0.28)
		freeze_frames = max(freeze_frames, 0.12)
		return
	var want_special: bool = (cmd.special and special_meter >= 50.0) or ((cmd.qcf or cmd.dp) and (cmd.light or cmd.heavy or cmd.special) and special_meter >= 50.0) or (cmd.dp and special_meter >= 50.0)
	if want_special:
		_buf.consume_motion()
		_start_attack("special")
		return

	if cmd.grab and cmd.down and on_ground and _taunt_t <= 0.0:
		_taunt()
		return

	if cmd.grab and on_ground:
		_start_attack("grab")
		return

	if on_ground and state == State.RUN and (cmd.light or cmd.heavy):
		_start_attack("dash_atk")
		return

	if cmd.heavy:
		var hk := _normal_kind("heavy", cmd)
		if not (hk.begins_with("j") and air_done):
			_start_attack(hk)
			return
	if cmd.light:
		var lk := _normal_kind("light", cmd)
		if not (lk.begins_with("j") and air_done):
			_start_attack(lk)
			return

	if (cmd.up or _jbuf > 0.0) and _coyote > 0.0:
		_begin_jump(cmd)
		return

	if cmd.backdash and on_ground:
		state = State.BACKDASH
		_dash_t = 0.18
		invuln = 0.11
		velocity.x = float(facing) * -460.0
		AudioDirector.play("dash", 0.85, 0.6)
		if visual:
			visual.dust()
		return

	if not on_ground:
		if state != State.JUMP:
			state = State.JUMP
		if def.id == "nyx_hollow" and not _air_dash_used and (cmd.backdash or (cmd.fwd and cmd.special)):
			_air_dash_used = true
			invuln = max(invuln, 0.10)
			velocity.x = float(facing) * (620.0 if cmd.fwd else -520.0)
			velocity.y = minf(velocity.y, -40.0)
			if visual:
				visual.dust()
				visual.punch_impact(0.55)
			AudioDirector.play("whoosh", 1.45, 0.65)
			announced.emit("AIR DASH")
		var air_t: float = _jump_x
		if cmd.fwd:
			air_t = float(facing) * def.speed * 0.98
		elif cmd.back:
			air_t = float(facing) * -def.speed * 0.78
		_accel_x(air_t, AIR_ACCEL, delta)
		if not cmd.up and velocity.y < -180.0:
			velocity.y = move_toward(velocity.y, -70.0, 6400.0 * delta)
		if cmd.down and velocity.y > 40.0:
			velocity.y += GRAVITY * 0.55 * delta
		_queue_inputs(cmd)
		return

	if cmd.down:
		state = State.CROUCH
		_accel_x(0.0, FRICTION * 1.55, delta)
		return

	if cmd.block and not cmd.fwd:
		state = State.BLOCK
		_accel_x(0.0, FRICTION * 1.45, delta)
		return

	if cmd.run or (state == State.RUN and cmd.fwd):
		if state != State.RUN:
			velocity.x = float(facing) * def.speed * 1.12
			AudioDirector.play("dash", 1.05, 0.55)
			if visual:
				visual.dust()
		state = State.RUN
		_accel_x(float(facing) * def.speed * RUN_MUL, ACCEL * 1.35, delta)
		return

	if cmd.fwd:
		state = State.WALK
		_accel_x(float(facing) * def.speed, ACCEL, delta)
		return
	if cmd.back:
		state = State.WALK
		_accel_x(float(facing) * -def.speed * WALK_BACK, ACCEL, delta)
		return

	state = State.IDLE
	_accel_x(0.0, FRICTION, delta)
	if _flush_buffer():
		return


func _normal_kind(base: String, cmd: Dictionary) -> String:
	if not on_ground:
		return "j" + base
	if cmd.down:
		return "c" + base
	return base


func _begin_jump(cmd: Dictionary) -> void:
	var jx: float = velocity.x
	if cmd.fwd:
		jx = float(facing) * def.speed * 1.08
	elif cmd.back:
		jx = float(facing) * -def.speed * 0.86
	_jump_x = jx
	state = State.PREJUMP
	_land_t = PREJUMP
	_jbuf = 0.0
	_coyote = 0.0
	if visual:
		visual.punch_impact(0.35)
	AudioDirector.play("whoosh", 1.25, 0.4)


func _leave_ground() -> void:
	velocity.y = -def.jump * 1.86
	velocity.x = _jump_x
	state = State.JUMP
	on_ground = false
	air_done = false


func _on_landed() -> void:
	air_done = false
	_air_dash_used = false
	velocity.x *= 0.62
	if visual:
		visual.punch_impact(0.45)
	AudioDirector.play("land", 1.0, 0.45)
	if _busy_attack() and str(current_attack.get("kind", "")).begins_with("j"):
		hitbox.disarm()
		state = State.LAND
		_land_t = LAND_T + 0.04
		attack_timer = attack_duration
	elif state == State.JUMP or state == State.PREJUMP or state == State.HIT:
		state = State.LAND
		_land_t = LAND_T


func _try_dash_cancel(cmd: Dictionary) -> bool:
	if not on_ground or not cmd.backdash:
		return false
	hitbox.disarm()
	state = State.BACKDASH
	_dash_t = 0.16
	invuln = 0.10
	velocity.x = float(facing) * -440.0
	return true


func _try_jump_cancel(cmd: Dictionary) -> bool:
	if not on_ground or not cmd.up:
		return false
	var k: String = str(current_attack.get("kind", ""))
	if k not in ["light", "clight", "heavy", "cheavy", "dash_atk"]:
		return false
	hitbox.disarm()
	_begin_jump(cmd)
	return true


func _try_chain(cmd: Dictionary) -> void:
	var next := ""
	if cmd.light:
		next = _normal_kind("light", cmd)
	elif cmd.heavy:
		next = _normal_kind("heavy", cmd)
	elif (cmd.special or cmd.qcf) and special_meter >= 50.0:
		next = "special"
	elif (cmd.ultimate or cmd.qcf2) and ultimate_meter >= MAX_ULTIMATE:
		next = "ultimate"
	if next.is_empty():
		return
	var k: String = str(current_attack.get("kind", ""))
	var allowed := false
	if k in ["light", "clight", "jlight"]:
		allowed = next in ["light", "clight", "heavy", "cheavy", "special", "ultimate"]
	elif k in ["heavy", "cheavy", "jheavy", "dash_atk"]:
		allowed = next in ["special", "ultimate"]
	elif k == "special":
		allowed = next in ["ultimate"] if ultimate_meter >= MAX_ULTIMATE else false
	if allowed:
		if next == "special":
			_buf.consume_motion()
		if next == "ultimate":
			announced.emit("SUPER CANCEL")
		_start_attack(next)


func _start_attack(kind: String) -> void:
	var atk := CombatRules.make_attack(kind, def)
	var ex := false
	if kind == "special" and special_meter >= MAX_SPECIAL:
		atk = CombatRules.apply_ex(atk, def)
		ex = true
	current_attack = atk
	last_attack_was_hit = false
	attack_timer = 0.0
	_hit_pass = -1
	var hits: int = maxi(int(atk.get("hits", 1)), 1)
	var extra: float = 0.0
	if hits > 1:
		extra = float(hits - 1) * (float(atk.active) + float(atk.get("hit_gap", 0.08)))
	attack_duration = float(atk.duration) + extra
	attack_active_from = atk.startup
	attack_active_until = atk.startup + atk.active
	hitbox.disarm()
	hitbox.configure(atk.size, Vector2(float(atk.reach) * float(facing), atk.y))
	visual.set_attack_timing(atk.startup, atk.active, attack_duration)
	invuln = max(invuln, float(atk.get("invuln", 0.0)))
	match kind:
		"light", "clight", "jlight":
			state = State.LIGHT
			AudioDirector.play("whoosh", 1.35, 0.5)
		"heavy", "cheavy", "jheavy", "dash_atk":
			state = State.HEAVY
			AudioDirector.play("whoosh", 0.85, 0.6)
			if kind == "dash_atk":
				_apply_special_motion(atk)
				announced.emit("DASH")
		"special":
			state = State.SPECIAL
			special_meter = 0.0 if ex else max(0.0, special_meter - 50.0)
			AudioDirector.play("special", 1.15 if ex else 1.0, 0.75 if ex else 0.55)
			if ex:
				announced.emit("EX")
			else:
				announced.emit(def.special_name.to_upper())
			_apply_special_motion(atk)
			_spawn_projectile_if_any()
		"ultimate":
			state = State.ULTIMATE
			ultimate_meter = 0.0
			AudioDirector.play("ultimate")
			_apply_special_motion(atk)
			_spawn_projectile_if_any()
			super_started.emit()
		"grab":
			state = State.GRAB
			AudioDirector.play("grab")
	meters_changed.emit(special_meter, ultimate_meter)
	last_chain.append(kind)
	if last_chain.size() > 6:
		last_chain.pop_front()
	var step: float = float(current_attack.get("step", 0.0))
	if on_ground and step != 0.0:
		velocity.x = lerpf(velocity.x, float(facing) * step, 0.78)


func _apply_special_motion(atk: Dictionary) -> void:
	var spd: float = float(atk.get("dash_spd", 0.0))
	if spd != 0.0:
		velocity.x = float(facing) * spd
		velocity.y = minf(velocity.y, -40.0)
		if visual:
			visual.dust()
	if def.special_id == "slam" and str(atk.get("kind", "")) == "special":
		velocity.y = -260.0
	if atk.get("teleport") and opponent:
		invuln = max(invuln, 0.16)
		position.x = clampf(opponent.position.x + float(facing) * 58.0, 80.0, 1200.0)
		facing = -facing
		visual.facing = facing
		if visual:
			visual.punch_impact(0.8)
		AudioDirector.play("whoosh", 1.4, 0.7)
	if atk.get("quake") and visual:
		visual.dust()
		AudioDirector.play("hit_h", 0.7, 0.8)


func _spawn_projectile_if_any() -> void:
	var kind: String = str(current_attack.get("projectile", ""))
	if kind.is_empty():
		return
	var n: int = maxi(int(current_attack.get("proj_count", 1)), 1)
	var spread: float = float(current_attack.get("proj_spread", 0.0))
	for i in n:
		var p := Projectile.new()
		p.setup(self, kind, def.accent)
		p.pierce = bool(current_attack.get("pierce", false))
		p.freeze = bool(current_attack.get("freeze", false))
		p.life = float(current_attack.get("proj_life", 0.7))
		p.position = global_position + Vector2(28 * facing, -58 - i * 6)
		var vy: float = 0.0
		if n > 1:
			vy = spread * (float(i) - float(n - 1) * 0.5) / maxf(float(n - 1), 1.0)
		p.velocity = Vector2(float(current_attack.get("proj_speed", 520.0)) * float(facing), vy)
		get_parent().add_child(p)


func _busy_attack() -> bool:
	return state in [State.LIGHT, State.HEAVY, State.SPECIAL, State.ULTIMATE, State.GRAB]


func _on_hitbox_landed(area: Area2D, attack: Dictionary) -> void:
	var other := area.get_parent()
	while other and not (other is Fighter):
		other = other.get_parent()
	if other == null or other == self:
		return
	var foe := other as Fighter
	if foe.hitbox and foe.hitbox.active and foe._busy_attack() and _busy_attack():
		_clash(foe)
		return
	foe.receive_hit(self, attack)


func _clash(foe: Fighter) -> void:
	hitbox.disarm()
	foe.hitbox.disarm()
	freeze_frames = max(freeze_frames, 0.14)
	foe.freeze_frames = max(foe.freeze_frames, 0.14)
	velocity.x = float(facing) * -200.0
	foe.velocity.x = float(foe.facing) * -200.0
	if visual:
		visual.punch_impact(0.9)
	if foe.visual:
		foe.visual.punch_impact(0.9)
	AudioDirector.play("clash", 1.0, 0.8)
	clash_happened.emit((global_position + foe.global_position) * 0.5 + Vector2(0, -70))


func receive_hit(attacker: Fighter, attack: Dictionary) -> void:
	if invuln > 0.0 or state == State.DEFEAT:
		return
	var grabbing: bool = attack.get("kind", "") == "grab"
	if grabbing and (_atk_buf == "grab" or state == State.GRAB):
		_throw_tech(attacker)
		return
	if state == State.ULTIMATE and not grabbing:
		var chip: float = float(attack.damage) * attacker.def.attack / max(def.defense, 0.2) * 0.28
		health = max(1.0, health - chip)
		visual.pulse_hit()
		freeze_frames = max(freeze_frames, 0.05)
		health_changed.emit(health, max_health)
		attacker.last_attack_was_hit = true
		return
	if int(current_attack.get("armor", 0)) > 0 and _busy_attack() and not grabbing:
		var chip2: float = float(attack.damage) * 0.22
		health = max(1.0, health - chip2)
		visual.pulse_hit()
		freeze_frames = max(freeze_frames, 0.04)
		health_changed.emit(health, max_health)
		attacker.last_attack_was_hit = true
		announced.emit("ARMOR")
		return
	var gkind: String = str(attack.get("guard", "mid"))
	var can_guard: bool = guarding and on_ground and not grabbing and state != State.PREJUMP
	if can_guard and gkind == "low" and not crouch_guarding:
		can_guard = false
	if can_guard and gkind == "high" and crouch_guarding:
		can_guard = false
	if can_guard and _fwd_guard and _guard_age <= 0.12 and not grabbing:
		_do_parry(attacker)
		return
	var blocked := can_guard or ((state == State.BLOCK or state == State.BACKDASH) and not grabbing)
	var dmg: float = float(attack.damage) * attacker.def.attack / max(def.defense, 0.2)
	if attacker.raging():
		dmg *= 1.16
	var broke := false
	if blocked:
		guard_meter = minf(MAX_GUARD, guard_meter + CombatRules.guard_gain(str(attack.get("kind", ""))))
		if guard_meter >= MAX_GUARD:
			blocked = false
			broke = true
			guard_meter = 0.0
			announced.emit("GUARD BREAK")
			AudioDirector.play("ko", 1.35, 0.45)
			dmg *= 1.22
	if blocked:
		var just: bool = _guard_age <= 0.10
		dmg *= CombatRules.chip_mul(str(attack.get("kind", "")), just)
		AudioDirector.play("block", 1.2 if just else 1.0, 0.85 if just else 0.8)
		special_meter = min(MAX_SPECIAL, special_meter + (5.0 if just else 3.0))
		attacker.special_meter = min(MAX_SPECIAL, attacker.special_meter + 2.0)
		velocity.x = attacker.facing * (180.0 if just else 220.0)
		hitstun = float(attack.get("blockstun", 0.16)) * (0.52 if just else 1.0)
		state = State.BLOCK
		if health > 1.0:
			health = max(1.0, health - dmg)
			health_changed.emit(health, max_health)
		visual.pulse_hit()
		meters_changed.emit(special_meter, ultimate_meter)
		attacker.meters_changed.emit(attacker.special_meter, attacker.ultimate_meter)
		attacker.last_attack_was_hit = true
		attacker.last_move = str(attack.get("kind", ""))
		attacker.last_advantage = float(attack.get("blockstun", 0.16)) * (0.52 if just else 1.0) - maxf(attacker.attack_duration - attacker.attack_timer, 0.0)
		if just:
			announced.emit("JUST GUARD")
			AudioDirector.play("parry", 1.0, 0.6)
		return

	var counter := _busy_attack()
	var punish := counter and attack_timer > attack_active_until
	var crit := false
	if attack.get("kind", "") == "heavy" and randf() < 0.18:
		crit = true
		dmg *= 1.35
	if counter:
		dmg *= 1.18
	if punish:
		dmg *= 1.08
	var scale := CombatRules.combo_scale(attacker.combo_hits)
	dmg *= scale
	health = max(0.0, health - dmg)
	var kb: float = float(attack.knockback)
	var launch: float = float(attack.launch)
	if not on_ground:
		kb *= 0.85
		launch = minf(launch, -120.0)
	if counter:
		kb *= 1.12
		launch *= 1.15
	launch *= CombatRules.juggle_scale(attacker.combo_hits)
	if broke:
		launch = minf(launch, -160.0)
		hitstun = maxf(float(attack.hitstun) * 1.35, 0.42)
	else:
		hitstun = float(attack.hitstun) * (1.28 if counter else 1.0)
	velocity = Vector2(attacker.facing * kb, launch)
	var hard_kd: bool = bool(attack.get("knockdown", false)) or health <= 0.0 or broke
	state = State.KNOCKDOWN if hard_kd else State.HIT
	visual.pulse_hit()
	if attacker.visual:
		var heavyish: bool = str(attack.get("kind", "")) in ["heavy", "cheavy", "jheavy", "special", "ultimate", "dash_atk"] or crit or counter
		attacker.visual.punch_impact(1.2 if heavyish else 0.75)
	attacker.last_attack_was_hit = true
	if attacker.combo_hits == 0:
		attacker.combo_damage = 0.0
	attacker.combo_hits += 1
	attacker.combo_damage += dmg
	attacker.combo_decay = 1.25
	attacker.combo_changed.emit(attacker.combo_hits)
	var was_ult: float = attacker.ultimate_meter
	attacker.special_meter = min(MAX_SPECIAL, attacker.special_meter + float(attack.meter))
	attacker.ultimate_meter = min(MAX_ULTIMATE, attacker.ultimate_meter + float(attack.meter) * 0.65)
	if was_ult < MAX_ULTIMATE and attacker.ultimate_meter >= MAX_ULTIMATE:
		AudioDirector.play("meter", 1.0, 0.7)
	special_meter = min(MAX_SPECIAL, special_meter + 3.0)
	ultimate_meter = min(MAX_ULTIMATE, ultimate_meter + 2.2)
	var snd := "hit_h" if attack.get("kind", "") in ["heavy", "special", "ultimate", "dash_atk"] else "hit_l"
	AudioDirector.play(snd, randf_range(0.92, 1.08))
	freeze_frames = float(attack.hitstop) * (1.25 if counter else 1.0)
	attacker.freeze_frames = float(attack.hitstop) * 0.85
	if bool(attack.get("freeze", false)):
		freeze_frames = max(freeze_frames, 0.22)
		if visual:
			visual.flash = 1.0
	if bool(attack.get("ex", false)):
		freeze_frames = max(freeze_frames, 0.16)
		attacker.freeze_frames = max(attacker.freeze_frames, 0.10)
	health_changed.emit(health, max_health)
	meters_changed.emit(special_meter, ultimate_meter)
	attacker.meters_changed.emit(attacker.special_meter, attacker.ultimate_meter)
	attacker.last_move = str(attack.get("kind", ""))
	attacker.last_advantage = hitstun - maxf(attacker.attack_duration - attacker.attack_timer, 0.0)
	attack["dealt"] = dmg
	attack["counter"] = counter
	attack["punish"] = punish
	hit_landed.emit(self, attack, crit or counter)
	if health <= 0.0:
		defeated.emit(self)


func raging() -> bool:
	return health / maxf(max_health, 1.0) <= 0.22


func _try_burst(cmd: Dictionary) -> bool:
	if health <= 0.0 or round_over:
		return false
	if not cmd.special or not cmd.block or special_meter < 50.0:
		return false
	special_meter -= 50.0
	hitstun = 0.0
	invuln = 0.28
	state = State.IDLE if on_ground else State.JUMP
	velocity = Vector2(float(facing) * -380.0, -220.0 if not on_ground else -80.0)
	if opponent:
		opponent.velocity.x = float(facing) * 420.0
		opponent.freeze_frames = max(opponent.freeze_frames, 0.16)
	freeze_frames = max(freeze_frames, 0.10)
	hitbox.disarm()
	meters_changed.emit(special_meter, ultimate_meter)
	announced.emit("BURST")
	AudioDirector.play("ultimate", 1.25, 0.55)
	if visual:
		visual.punch_impact(1.0)
		visual.dust()
	return true


func _do_parry(attacker: Fighter) -> void:
	hitstun = 0.0
	state = State.IDLE
	invuln = 0.10
	freeze_frames = 0.06
	attacker.freeze_frames = max(attacker.freeze_frames, 0.30)
	attacker.velocity.x = float(facing) * -260.0
	special_meter = min(MAX_SPECIAL, special_meter + 16.0)
	ultimate_meter = min(MAX_ULTIMATE, ultimate_meter + 8.0)
	meters_changed.emit(special_meter, ultimate_meter)
	attacker.last_attack_was_hit = false
	attacker.last_move = "parry"
	attacker.last_advantage = -0.30
	announced.emit("PARRY")
	AudioDirector.play("parry", 0.9, 0.85)
	if visual:
		visual.punch_impact(0.9)
		visual.flash = 1.0
	if attacker.visual:
		attacker.visual.recoil = 1.0


func _log_buttons(cmd: Dictionary) -> void:
	var tag := ""
	if cmd.light:
		tag = "J"
	elif cmd.heavy:
		tag = "K"
	elif cmd.special:
		tag = "L"
	elif cmd.grab:
		tag = "I"
	elif cmd.ultimate:
		tag = "O"
	elif cmd.backdash:
		tag = "BD"
	if tag.is_empty():
		return
	if cmd.down:
		tag = "S+" + tag
	elif cmd.up:
		tag = "W+" + tag
	input_log.append(tag)
	if input_log.size() > 10:
		input_log.pop_front()


func _throw_tech(attacker: Fighter) -> void:
	_atk_buf = ""
	_atk_buf_t = 0.0
	attacker._atk_buf = ""
	attacker.hitbox.disarm()
	hitbox.disarm()
	state = State.IDLE
	attacker.state = State.IDLE
	velocity.x = float(facing) * -240.0
	attacker.velocity.x = float(attacker.facing) * -240.0
	freeze_frames = 0.12
	attacker.freeze_frames = 0.12
	invuln = 0.08
	attacker.invuln = 0.08
	AudioDirector.play("tech", 1.0, 0.7)
	announced.emit("TECH")
	if visual:
		visual.punch_impact(0.5)
	if attacker.visual:
		attacker.visual.punch_impact(0.5)


func _air_tech() -> void:
	state = State.JUMP
	hitstun = 0.0
	invuln = 0.16
	air_done = false
	_atk_buf = ""
	_atk_buf_t = 0.0
	velocity.y = -260.0
	velocity.x *= 0.45
	AudioDirector.play("tech", 1.15, 0.55)
	announced.emit("AIR TECH")
	if visual:
		visual.punch_impact(0.4)


func _wall_bounce() -> void:
	if state != State.HIT or on_ground or _wall_used:
		return
	if (position.x <= 92.0 and velocity.x < -90.0) or (position.x >= 1188.0 and velocity.x > 90.0):
		velocity.x *= -0.62
		velocity.y = minf(velocity.y, -200.0)
		_wall_used = true
		if visual:
			visual.punch_impact(0.85)
		AudioDirector.play("hit_h", 1.25, 0.45)
		announced.emit("WALL BOUNCE")


func _debug_boxes() -> void:
	var show: bool = GameState.show_hitboxes
	var hd := hurtbox.get_node_or_null("HurtDebug") as ColorRect
	if hd:
		hd.visible = show
		if show:
			var hs := hurtbox.get_child(0) as CollisionShape2D
			var r := hs.shape as RectangleShape2D
			hd.size = r.size
			hd.position = hs.position - r.size * 0.5
	if hitbox and hitbox._dbg:
		hitbox._dbg.visible = show and hitbox.active


func _face_opponent() -> void:
	if opponent == null:
		return
	if _busy_attack() or state in [State.HIT, State.KNOCKDOWN, State.VICTORY, State.DEFEAT, State.JUMP, State.PREJUMP, State.RUN, State.BACKDASH, State.GETUP]:
		return
	var dx: float = opponent.position.x - position.x
	if absf(dx) < 32.0:
		return
	var dir := signf(dx)
	if dir != 0:
		facing = int(dir)
		visual.facing = facing


func _sync_visual() -> void:
	visual.move_speed = absf(velocity.x)
	if _taunt_t > 0.0:
		visual.set_pose_name("victory")
		return
	if _busy_attack():
		var posek: String = str(current_attack.get("kind", "light"))
		if posek == "dash_atk":
			posek = "heavy"
		visual.set_pose_name(posek)
	else:
		match state:
			State.WALK:
				if absf(velocity.x) > def.speed * 1.4:
					visual.set_pose_name("run")
				else:
					visual.set_pose_name("walk")
			State.RUN:
				visual.set_pose_name("run")
			State.BACKDASH:
				visual.set_pose_name("backdash")
			State.PREJUMP:
				visual.set_pose_name("prejump")
				visual.one_shot_u = 1.0 - clampf(_land_t / PREJUMP, 0.0, 1.0)
			State.JUMP:
				visual.set_pose_name("jump")
				var ju: float = clampf((velocity.y + 900.0) / 1800.0, 0.0, 1.0)
				visual.attack_u = ju
				if velocity.y < -420.0:
					visual.attack_u = lerpf(ju, 0.55, 0.35)
			State.LAND:
				visual.set_pose_name("land")
				visual.one_shot_u = 1.0 - clampf(_land_t / LAND_T, 0.0, 1.0)
			State.GETUP:
				visual.set_pose_name("getup")
				visual.one_shot_u = 1.0 - clampf(_land_t / GETUP_T, 0.0, 1.0)
			State.CROUCH:
				visual.set_pose_name("crouch")
			State.BLOCK:
				visual.set_pose_name("block_hit" if hitstun > 0.0 and guarding else "block")
			State.HIT:
				if not on_ground or absf(velocity.y) > 120.0:
					visual.set_pose_name("air_hit" if velocity.y < 0.0 else "launch")
				else:
					visual.set_pose_name("hit")
				visual.one_shot_u = clampf(1.0 - hitstun / 0.35, 0.0, 1.0)
			State.KNOCKDOWN:
				visual.set_pose_name("knockdown")
			State.VICTORY:
				visual.set_pose_name("victory")
			State.DEFEAT:
				visual.set_pose_name("defeat")
			State.IDLE:
				if absf(velocity.x) > 48.0:
					visual.set_pose_name("walk")
				else:
					visual.set_pose_name("idle")
			_:
				visual.set_pose_name("idle")
	var vis_h: float = float(PixelFighterBake.H * PixelFighterBake.SCALE)
	var hs := hurtbox.get_child(0) as CollisionShape2D
	if state == State.CROUCH:
		(hs.shape as RectangleShape2D).size.y = vis_h * 0.28 * def.height_scale
		hs.position.y = -vis_h * 0.16 * def.height_scale
	else:
		(hs.shape as RectangleShape2D).size.y = vis_h * 0.48 * def.height_scale
		hs.position.y = -vis_h * 0.27 * def.height_scale


func _taunt() -> void:
	_taunt_t = 0.48
	special_meter = min(MAX_SPECIAL, special_meter + 10.0)
	ultimate_meter = min(MAX_ULTIMATE, ultimate_meter + 6.0)
	meters_changed.emit(special_meter, ultimate_meter)
	AudioDirector.play("ui_confirm", 0.7, 0.45)
	if visual:
		visual.set_pose_name("victory")
		visual.punch_impact(0.35)


func training_tick(delta: float) -> void:
	if round_over:
		return
	special_meter = min(MAX_SPECIAL, special_meter + 30.0 * delta)
	ultimate_meter = min(MAX_ULTIMATE, ultimate_meter + 18.0 * delta)
	meters_changed.emit(special_meter, ultimate_meter)


func _integrate(_delta: float) -> void:
	pass


func _accel_x(target: float, rate: float, delta: float) -> void:
	if absf(target) < 10.0:
		velocity.x = move_toward(velocity.x, 0.0, rate * delta)
		if absf(velocity.x) < 16.0:
			velocity.x = 0.0
		return
	var r: float = rate
	if velocity.x * target < 0.0:
		r *= TURN_MUL
	velocity.x = move_toward(velocity.x, target, r * delta)


func _queue_inputs(cmd: Dictionary) -> void:
	if cmd.light:
		_atk_buf = _normal_kind("light", cmd)
		_atk_buf_t = ATK_BUF
	elif cmd.heavy:
		_atk_buf = _normal_kind("heavy", cmd)
		_atk_buf_t = ATK_BUF
	elif (cmd.special or cmd.qcf) and special_meter >= 50.0:
		_atk_buf = "special"
		_atk_buf_t = ATK_BUF
	elif cmd.grab:
		_atk_buf = "grab"
		_atk_buf_t = ATK_BUF
	elif cmd.ultimate and ultimate_meter >= MAX_ULTIMATE:
		_atk_buf = "ultimate"
		_atk_buf_t = ATK_BUF
	if cmd.up:
		_jbuf = JBUF


func _flush_buffer() -> bool:
	if _atk_buf.is_empty() or _atk_buf_t <= 0.0:
		return false
	if _atk_buf.begins_with("j") and on_ground:
		_atk_buf = _atk_buf.substr(1)
	elif not on_ground and _atk_buf in ["light", "heavy"]:
		_atk_buf = "j" + _atk_buf
	if _atk_buf == "grab" and not on_ground:
		_atk_buf = ""
		return false
	if _atk_buf == "special" and special_meter < 50.0:
		_atk_buf = ""
		return false
	if _atk_buf == "ultimate" and ultimate_meter < MAX_ULTIMATE:
		_atk_buf = ""
		return false
	if _atk_buf.begins_with("j") and air_done:
		_atk_buf = ""
		return false
	var k: String = _atk_buf
	_atk_buf = ""
	_atk_buf_t = 0.0
	_start_attack(k)
	return true


func _separate_from_opponent() -> void:
	if opponent == null:
		return
	var dx := opponent.global_position.x - global_position.x
	var vis_h: float = float(PixelFighterBake.H * PixelFighterBake.SCALE)
	if absf(dx) < vis_h * 0.22 and absf(opponent.global_position.y - global_position.y) < vis_h * 0.40:
		var push: float = (vis_h * 0.22 - absf(dx)) * 0.5
		var s := signf(dx)
		if s == 0.0:
			s = 1.0 if fighter_id == 0 else -1.0
		position.x -= s * push


func _keep_in_bounds() -> void:
	position.x = clamp(position.x, 80.0, 1200.0)
	if position.y > 900:
		position.y = 620
		velocity.y = 0


func distance_to_opponent() -> float:
	if opponent == null:
		return 9999.0
	return abs(opponent.position.x - position.x)
